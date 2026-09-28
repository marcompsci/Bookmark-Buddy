// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

// MARK: - Row types (map Supabase snake_case → Swift models)

private struct BookRow: Codable, Sendable {
    let id: UUID
    let title: String
    let author: String
    let genres: [String]
    let pageCount: Int
    let chapterCount: Int
    let premise: String
    let coverPaletteIndex: Int
    let coverMotif: String
    let isDemoContent: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, author, genres, premise
        case pageCount        = "page_count"
        case chapterCount     = "chapter_count"
        case coverPaletteIndex = "cover_palette_index"
        case coverMotif       = "cover_motif"
        case isDemoContent    = "is_demo_content"
    }

    var toBook: Book {
        Book(
            id: id,
            title: title,
            author: author,
            genres: genres.compactMap { Genre(rawValue: $0) },
            pageCount: pageCount,
            chapterCount: chapterCount,
            premise: premise,
            cover: CoverStyle(
                paletteIndex: coverPaletteIndex,
                motif: CoverMotif(rawValue: coverMotif) ?? .harbor
            ),
            characters: [],
            isDemoContent: isDemoContent,
            source: isDemoContent ? .demo : .personalShelf
        )
    }
}

private struct ProgressRow: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let bookId: UUID
    let state: String
    let currentChapter: Int
    let pagesRead: Int
    let memoryStrength: Double
    let startedAt: Date?
    let finishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, state
        case userId         = "user_id"
        case bookId         = "book_id"
        case currentChapter = "current_chapter"
        case pagesRead      = "pages_read"
        case memoryStrength = "memory_strength"
        case startedAt      = "started_at"
        case finishedAt     = "finished_at"
    }

    var toProgress: ReadingProgress {
        ReadingProgress(
            bookID: bookId,
            state: ReadingState(rawValue: state) ?? .wantToRead,
            currentChapter: currentChapter,
            pagesRead: pagesRead,
            startedAt: startedAt,
            finishedAt: finishedAt,
            memoryStrength: memoryStrength
        )
    }
}

private struct NoteRow: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let bookId: UUID
    let chapter: Int
    let text: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, chapter, text
        case userId    = "user_id"
        case bookId    = "book_id"
        case createdAt = "created_at"
    }

    var toNote: BookNote {
        BookNote(id: id, bookID: bookId, chapter: chapter, text: text, createdAt: createdAt)
    }
}

private struct MomentRow: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let bookId: UUID
    let chapter: Int
    let title: String
    let reflection: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, chapter, title, reflection
        case userId    = "user_id"
        case bookId    = "book_id"
        case createdAt = "created_at"
    }

    var toMoment: SavedMoment {
        SavedMoment(id: id, bookID: bookId, chapter: chapter,
                    title: title, reflection: reflection, createdAt: createdAt)
    }
}

// MARK: - Repository

struct SupabaseBookRepository: BookRepository {

    private let db = SupabaseManager.shared.client

    private var userID: UUID {
        get async throws {
            guard let id = await SupabaseAuthService.shared.currentUserID else {
                throw RepositoryError.notAuthenticated
            }
            return id
        }
    }

    // MARK: Books

    func allBooks() async throws -> [Book] {
        let rows: [BookRow] = try await db.from("books").select().execute().value
        return rows.map { $0.toBook }
    }

    func book(id: UUID) async throws -> Book {
        let rows: [BookRow] = try await db.from("books")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { throw RepositoryError.notFound }
        return row.toBook
    }

    // MARK: Progress

    func allProgress() async throws -> [ReadingProgress] {
        let uid = try await userID
        let rows: [ProgressRow] = try await db.from("reading_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows.map { $0.toProgress }
    }

    func progress(for bookID: UUID) async throws -> ReadingProgress? {
        let uid = try await userID
        let rows: [ProgressRow] = try await db.from("reading_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("book_id", value: bookID.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.toProgress
    }

    func updateProgress(_ progress: ReadingProgress) async throws {
        let uid = try await userID
        struct Upsert: Encodable {
            let userId: UUID; let bookId: UUID
            let state: String; let currentChapter: Int
            let pagesRead: Int; let memoryStrength: Double
            let startedAt: Date?; let finishedAt: Date?
            enum CodingKeys: String, CodingKey {
                case state
                case userId         = "user_id"
                case bookId         = "book_id"
                case currentChapter = "current_chapter"
                case pagesRead      = "pages_read"
                case memoryStrength = "memory_strength"
                case startedAt      = "started_at"
                case finishedAt     = "finished_at"
            }
        }
        try await db.from("reading_progress").upsert(Upsert(
            userId: uid, bookId: progress.bookID,
            state: progress.state.rawValue, currentChapter: progress.currentChapter,
            pagesRead: progress.pagesRead, memoryStrength: progress.memoryStrength,
            startedAt: progress.startedAt, finishedAt: progress.finishedAt
        ), onConflict: "user_id,book_id").execute()
    }

    // MARK: Notes

    func notes(for bookID: UUID) async throws -> [BookNote] {
        let uid = try await userID
        let rows: [NoteRow] = try await db.from("book_notes")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("book_id", value: bookID.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows.map { $0.toNote }
    }

    func addNote(_ note: BookNote) async throws {
        let uid = try await userID
        struct Insert: Encodable {
            let id: UUID; let userId: UUID; let bookId: UUID
            let chapter: Int; let text: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id, chapter, text
                case userId    = "user_id"
                case bookId    = "book_id"
                case createdAt = "created_at"
            }
        }
        try await db.from("book_notes").insert(Insert(
            id: note.id, userId: uid, bookId: note.bookID,
            chapter: note.chapter, text: note.text, createdAt: note.createdAt
        )).execute()
    }

    func deleteNote(id: UUID) async throws {
        try await db.from("book_notes").delete().eq("id", value: id.uuidString).execute()
    }

    // MARK: Moments

    func moments(for bookID: UUID) async throws -> [SavedMoment] {
        let uid = try await userID
        let rows: [MomentRow] = try await db.from("saved_moments")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("book_id", value: bookID.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        return rows.map { $0.toMoment }
    }

    func allMoments() async throws -> [SavedMoment] {
        let uid = try await userID
        let rows: [MomentRow] = try await db.from("saved_moments")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toMoment }
    }

    func addMoment(_ moment: SavedMoment) async throws {
        let uid = try await userID
        struct Insert: Encodable {
            let id: UUID; let userId: UUID; let bookId: UUID
            let chapter: Int; let title: String; let reflection: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id, chapter, title, reflection
                case userId    = "user_id"
                case bookId    = "book_id"
                case createdAt = "created_at"
            }
        }
        try await db.from("saved_moments").insert(Insert(
            id: moment.id, userId: uid, bookId: moment.bookID,
            chapter: moment.chapter, title: moment.title,
            reflection: moment.reflection, createdAt: moment.createdAt
        )).execute()
    }
}

// MARK: - Shared errors

enum RepositoryError: LocalizedError {
    case notAuthenticated
    case notFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to access your library."
        case .notFound:         return "The requested item was not found."
        }
    }
}
