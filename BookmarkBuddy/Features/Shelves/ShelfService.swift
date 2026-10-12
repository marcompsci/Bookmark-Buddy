// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

protocol ShelfService: Sendable {
    /// The signed-in reader's shelf, or `nil` if they haven't made one yet.
    func myShelf() async throws -> ShelfSnapshot?
    func save(_ shelf: ReaderShelf) async throws
    func addEntry(title: String, author: String, note: String, colorIndex: Int) async throws -> ShelfEntry
    func removeEntry(id: UUID) async throws
    /// A public shelf by handle. `nil` when it doesn't exist or is private.
    func publicShelf(handle: String) async throws -> ShelfSnapshot?
}

/// Shared cleanup and validation for every implementation.
enum ShelfValidator {
    static func shelf(_ shelf: ReaderShelf) throws -> ReaderShelf {
        let handle = ReaderShelf.normalizedHandle(shelf.handle)
        guard ReaderShelf.isValidHandle(handle) else { throw ShelfError.invalidHandle }
        return ReaderShelf(
            handle: handle,
            displayName: TextSanitizer.clean(shelf.displayName, limit: ReaderShelf.Limits.displayName),
            bio: TextSanitizer.clean(shelf.bio, limit: ReaderShelf.Limits.bio),
            isPublic: shelf.isPublic
        )
    }

    static func entry(title: String, author: String, note: String, colorIndex: Int)
        throws -> (title: String, author: String, note: String, colorIndex: Int) {
        let limits = DLRecommendation.Limits.self
        let t = TextSanitizer.clean(title, limit: limits.title)
        let a = TextSanitizer.clean(author, limit: limits.author)
        guard !t.isEmpty, !a.isEmpty else { throw ShelfError.missingTitleOrAuthor }
        return (t, a, TextSanitizer.clean(note, limit: limits.note),
                min(max(colorIndex, 0), DLRecommendation.palette.count - 1))
    }
}

// MARK: - Supabase

/// Tables `reader_shelves` and `reader_shelf_books` (Docs/supabase_phase10_shelves.sql).
/// Public shelves are readable by everyone; only the owner can write. The database also
/// enforces handle format, lengths, and the 50-book limit.
struct SupabaseShelfService: ShelfService {
    private let db = SupabaseManager.shared.client

    private struct ShelfRow: Codable {
        let userId: UUID?
        let handle: String
        let displayName: String
        let bio: String
        let isPublic: Bool
        enum CodingKeys: String, CodingKey {
            case handle, bio
            case userId = "user_id"
            case displayName = "display_name"
            case isPublic = "is_public"
        }
        var model: ReaderShelf { ReaderShelf(handle: handle, displayName: displayName, bio: bio, isPublic: isPublic) }
    }

    private struct EntryRow: Codable {
        let id: UUID
        let title: String
        let author: String
        let note: String
        let color: Int
        let position: Int
        var model: ShelfEntry {
            ShelfEntry(id: id, title: title, author: author, note: note, colorIndex: color, position: position)
        }
    }

    private func uid() async throws -> UUID {
        guard let id = await SupabaseAuthService.shared.currentUserID else { throw ShelfError.notSignedIn }
        return id
    }

    private func entries(for userID: UUID) async throws -> [ShelfEntry] {
        let rows: [EntryRow] = try await db.from("reader_shelf_books")
            .select("id,title,author,note,color,position")
            .eq("user_id", value: userID.uuidString)
            .order("position", ascending: true)
            .order("created_at", ascending: true)
            .execute().value
        return rows.map(\.model)
    }

    func myShelf() async throws -> ShelfSnapshot? {
        let id = try await uid()
        do {
            let rows: [ShelfRow] = try await db.from("reader_shelves")
                .select("user_id,handle,display_name,bio,is_public")
                .eq("user_id", value: id.uuidString)
                .limit(1)
                .execute().value
            guard let row = rows.first else { return nil }
            return ShelfSnapshot(shelf: row.model, entries: try await entries(for: id))
        } catch {
            throw Self.map(error)
        }
    }

    func save(_ shelf: ReaderShelf) async throws {
        let id = try await uid()
        let clean = try ShelfValidator.shelf(shelf)
        do {
            try await db.from("reader_shelves").upsert(ShelfRow(
                userId: id, handle: clean.handle, displayName: clean.displayName,
                bio: clean.bio, isPublic: clean.isPublic
            ), onConflict: "user_id").execute()
        } catch {
            throw Self.map(error)
        }
    }

    func addEntry(title: String, author: String, note: String, colorIndex: Int) async throws -> ShelfEntry {
        let id = try await uid()
        let clean = try ShelfValidator.entry(title: title, author: author, note: note, colorIndex: colorIndex)
        struct Insert: Encodable {
            let userId: UUID; let title: String; let author: String
            let note: String; let color: Int; let position: Int
            enum CodingKeys: String, CodingKey {
                case title, author, note, color, position
                case userId = "user_id"
            }
        }
        do {
            let count = try await entries(for: id).count
            guard count < ReaderShelf.Limits.books else { throw ShelfError.full }
            let row: EntryRow = try await db.from("reader_shelf_books")
                .insert(Insert(userId: id, title: clean.title, author: clean.author,
                               note: clean.note, color: clean.colorIndex, position: count))
                .select("id,title,author,note,color,position")
                .single()
                .execute().value
            return row.model
        } catch let error as ShelfError {
            throw error
        } catch {
            throw Self.map(error)
        }
    }

    func removeEntry(id entryID: UUID) async throws {
        let id = try await uid()
        do {
            try await db.from("reader_shelf_books").delete()
                .eq("id", value: entryID.uuidString)
                .eq("user_id", value: id.uuidString)
                .execute()
        } catch {
            throw Self.map(error)
        }
    }

    func publicShelf(handle: String) async throws -> ShelfSnapshot? {
        let handle = ReaderShelf.normalizedHandle(handle)
        guard ReaderShelf.isValidHandle(handle) else { return nil }
        do {
            let rows: [ShelfRow] = try await db.from("reader_shelves")
                .select("user_id,handle,display_name,bio,is_public")
                .eq("handle", value: handle)
                .eq("is_public", value: true)
                .limit(1)
                .execute().value
            guard let row = rows.first, let owner = row.userId else { return nil }
            return ShelfSnapshot(shelf: row.model, entries: try await entries(for: owner))
        } catch {
            throw Self.map(error)
        }
    }

    private static func map(_ error: Error) -> Error {
        if error is ShelfError { return error }
        let text = String(describing: error).lowercased()
        if text.contains("duplicate key") || text.contains("reader_shelves_handle_key") { return ShelfError.handleTaken }
        if text.contains("does not exist") || text.contains("pgrst205") || text.contains("could not find the table") { return ShelfError.notSetUp }
        if text.contains("shelf holds up to") { return ShelfError.full }
        return ShelfError.server
    }
}

// MARK: - Local (no Supabase credentials, previews)

actor LocalShelfService: ShelfService {
    private var snapshot: ShelfSnapshot?
    private let persist: Bool
    private static let key = "bb.localShelf"

    private struct Stored: Codable { var shelf: ReaderShelf; var entries: [ShelfEntry] }

    init(persist: Bool = true, seed: ShelfSnapshot? = nil) {
        self.persist = persist
        if let seed {
            snapshot = seed
        } else if persist, let data = UserDefaults.standard.data(forKey: Self.key),
                  let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            snapshot = ShelfSnapshot(shelf: stored.shelf, entries: stored.entries)
        }
    }

    private func save() {
        guard persist, let snapshot else { return }
        if let data = try? JSONEncoder().encode(Stored(shelf: snapshot.shelf, entries: snapshot.entries)) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    func myShelf() async throws -> ShelfSnapshot? { snapshot }

    func save(_ shelf: ReaderShelf) async throws {
        let clean = try ShelfValidator.shelf(shelf)
        snapshot = ShelfSnapshot(shelf: clean, entries: snapshot?.entries ?? [])
        save()
    }

    func addEntry(title: String, author: String, note: String, colorIndex: Int) async throws -> ShelfEntry {
        let clean = try ShelfValidator.entry(title: title, author: author, note: note, colorIndex: colorIndex)
        var current = snapshot ?? ShelfSnapshot(shelf: .empty, entries: [])
        guard current.entries.count < ReaderShelf.Limits.books else { throw ShelfError.full }
        let entry = ShelfEntry(id: UUID(), title: clean.title, author: clean.author, note: clean.note,
                               colorIndex: clean.colorIndex, position: current.entries.count)
        current.entries.append(entry)
        snapshot = current
        save()
        return entry
    }

    func removeEntry(id: UUID) async throws {
        snapshot?.entries.removeAll { $0.id == id }
        save()
    }

    func publicShelf(handle: String) async throws -> ShelfSnapshot? {
        guard let snapshot, snapshot.shelf.isPublic,
              snapshot.shelf.handle == ReaderShelf.normalizedHandle(handle) else { return nil }
        return snapshot
    }
}
