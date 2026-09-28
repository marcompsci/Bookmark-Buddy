// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// In-memory book data seeded from `DemoData`.
/// TODO(prod): Back with licensed book metadata (e.g. a publisher/catalog API) plus the
/// user's own synced progress. Requires authentication and per-user authorization.
actor MockBookRepository: BookRepository {
    private var books: [Book]
    private var progressByBook: [UUID: ReadingProgress]
    private var notes: [BookNote]
    private var moments: [SavedMoment]
    private let latency: Duration
    private let shouldFail: Bool

    init(latency: Duration = .milliseconds(300), shouldFail: Bool = false) {
        self.books = DemoData.books + PersonalShelf.books
        self.progressByBook = Dictionary(
            (DemoData.progress + PersonalShelf.progress).map { ($0.bookID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.notes = DemoData.notes
        self.moments = DemoData.moments
        self.latency = latency
        self.shouldFail = shouldFail
    }

    private func simulate() async throws {
        await DemoLatency.pause(latency)
        if shouldFail { throw DemoServiceError.simulatedFailure }
    }

    func allBooks() async throws -> [Book] {
        try await simulate()
        return books
    }

    func book(id: UUID) async throws -> Book {
        try await simulate()
        guard let book = books.first(where: { $0.id == id }) else { throw DemoServiceError.notFound }
        return book
    }

    func allProgress() async throws -> [ReadingProgress] {
        try await simulate()
        return Array(progressByBook.values)
    }

    func progress(for bookID: UUID) async throws -> ReadingProgress? {
        try await simulate()
        return progressByBook[bookID]
    }

    func updateProgress(_ progress: ReadingProgress) async throws {
        try await simulate()
        progressByBook[progress.bookID] = progress
    }

    func notes(for bookID: UUID) async throws -> [BookNote] {
        try await simulate()
        return notes.filter { $0.bookID == bookID }.sorted { $0.createdAt > $1.createdAt }
    }

    func addNote(_ note: BookNote) async throws {
        try await simulate()
        notes.append(note)
    }

    func deleteNote(id: UUID) async throws {
        try await simulate()
        notes.removeAll { $0.id == id }
    }

    func moments(for bookID: UUID) async throws -> [SavedMoment] {
        try await simulate()
        return moments.filter { $0.bookID == bookID }.sorted { $0.createdAt > $1.createdAt }
    }

    func allMoments() async throws -> [SavedMoment] {
        try await simulate()
        return moments.sorted { $0.createdAt > $1.createdAt }
    }

    func addMoment(_ moment: SavedMoment) async throws {
        try await simulate()
        moments.append(moment)
    }
}
