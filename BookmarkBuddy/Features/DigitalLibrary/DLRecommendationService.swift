// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

/// Reads and adds recommendations on Omari's floating shelf.
protocol DLRecommendationService: Sendable {
    func all() async throws -> [DLRecommendation]
    func add(title: String, author: String, from: String, note: String, colorIndex: Int) async throws -> DLRecommendation
}

enum DLRecommendationError: LocalizedError {
    case missingTitleOrAuthor
    case tooSoon
    case limitReached
    case notSignedIn
    case server(String)

    var errorDescription: String? {
        switch self {
        case .missingTitleOrAuthor: "Add both the title and the author."
        case .tooSoon: "Give it a few seconds before recommending another."
        case .limitReached: "You've reached the limit of 10 recommendations."
        case .notSignedIn: "Sign in to recommend a book."
        case .server(let message): message
        }
    }
}

/// Shared validation for every implementation. Returns cleaned fields or throws a plain-language error.
enum DLRecommendationValidator {
    static func clean(title: String, author: String, from: String, note: String, colorIndex: Int)
        throws -> (title: String, author: String, from: String, note: String, colorIndex: Int) {
        let limits = DLRecommendation.Limits.self
        let t = TextSanitizer.clean(title, limit: limits.title)
        let a = TextSanitizer.clean(author, limit: limits.author)
        guard !t.isEmpty, !a.isEmpty else { throw DLRecommendationError.missingTitleOrAuthor }
        return (
            t, a,
            TextSanitizer.clean(from, limit: limits.from),
            TextSanitizer.clean(note, limit: limits.note),
            min(max(colorIndex, 0), DLRecommendation.palette.count - 1)
        )
    }
}

// MARK: - Supabase

/// Backed by `public.book_recommendations`. Everyone can read; signed-in readers can add.
/// The database enforces length limits, 1 submission per 15 seconds and 10 per person.
struct SupabaseDLRecommendationService: DLRecommendationService {
    private let db = SupabaseManager.shared.client

    private struct Row: Decodable {
        let id: Int
        let title: String
        let author: String
        let recommenderName: String
        let note: String
        let color: Int
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id, title, author, note, color
            case recommenderName = "recommender_name"
            case createdAt = "created_at"
        }
        var model: DLRecommendation {
            DLRecommendation(id: String(id), title: title, author: author, from: recommenderName,
                             note: note, colorIndex: color, createdAt: createdAt)
        }
    }

    func all() async throws -> [DLRecommendation] {
        let rows: [Row] = try await db.from("book_recommendations")
            .select("id,title,author,recommender_name,note,color,created_at")
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
        return rows.map(\.model)
    }

    func add(title: String, author: String, from: String, note: String, colorIndex: Int) async throws -> DLRecommendation {
        guard let uid = await SupabaseAuthService.shared.currentUserID else { throw DLRecommendationError.notSignedIn }
        let clean = try DLRecommendationValidator.clean(title: title, author: author, from: from, note: note, colorIndex: colorIndex)
        struct Insert: Encodable {
            let title: String; let author: String; let recommenderName: String
            let note: String; let color: Int; let createdBy: UUID
            enum CodingKeys: String, CodingKey {
                case title, author, note, color
                case recommenderName = "recommender_name"
                case createdBy = "created_by"
            }
        }
        do {
            let row: Row = try await db.from("book_recommendations")
                .insert(Insert(title: clean.title, author: clean.author, recommenderName: clean.from,
                               note: clean.note, color: clean.colorIndex, createdBy: uid))
                .select("id,title,author,recommender_name,note,color,created_at")
                .single()
                .execute()
                .value
            return row.model
        } catch {
            let message = String(describing: error)
            if message.contains("few seconds") { throw DLRecommendationError.tooSoon }
            if message.contains("limit of 10") { throw DLRecommendationError.limitReached }
            throw DLRecommendationError.server("Couldn't save that right now. Try again in a moment.")
        }
    }
}

// MARK: - Local (no Supabase credentials, previews)

actor LocalDLRecommendationService: DLRecommendationService {
    private var items: [DLRecommendation]
    private var lastSubmission: Date?
    private var submittedCount = 0

    init(seed: [DLRecommendation] = LocalDLRecommendationService.sample) {
        items = seed
    }

    func all() async throws -> [DLRecommendation] { items }

    func add(title: String, author: String, from: String, note: String, colorIndex: Int) async throws -> DLRecommendation {
        let clean = try DLRecommendationValidator.clean(title: title, author: author, from: from, note: note, colorIndex: colorIndex)
        if let lastSubmission, Date.now.timeIntervalSince(lastSubmission) < 15 { throw DLRecommendationError.tooSoon }
        guard submittedCount < 10 else { throw DLRecommendationError.limitReached }
        let rec = DLRecommendation(id: UUID().uuidString, title: clean.title, author: clean.author,
                                   from: clean.from, note: clean.note, colorIndex: clean.colorIndex, createdAt: .now)
        items.insert(rec, at: 0)
        lastSubmission = .now
        submittedCount += 1
        return rec
    }

    static let sample: [DLRecommendation] = [
        DLRecommendation(id: "sample-1", title: "Can't Hurt Me", author: "David Goggins", from: "Jay",
                         note: "You'd like the discipline angle.", colorIndex: 7, createdAt: .now.addingTimeInterval(-86_400)),
        DLRecommendation(id: "sample-2", title: "The Psychology of Money", author: "Morgan Housel", from: "",
                         note: "", colorIndex: 2, createdAt: .now.addingTimeInterval(-172_800))
    ]
}
