// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

// All services are async so mock and production implementations are interchangeable.
// Production implementations will need authentication, server-side authorization and
// rate limits — see the TODO(prod) notes in each mock.

protocol BookRepository: Sendable {
    func allBooks() async throws -> [Book]
    func book(id: UUID) async throws -> Book
    func allProgress() async throws -> [ReadingProgress]
    func progress(for bookID: UUID) async throws -> ReadingProgress?
    func updateProgress(_ progress: ReadingProgress) async throws
    func notes(for bookID: UUID) async throws -> [BookNote]
    func addNote(_ note: BookNote) async throws
    func deleteNote(id: UUID) async throws
    func moments(for bookID: UUID) async throws -> [SavedMoment]
    func allMoments() async throws -> [SavedMoment]
    func addMoment(_ moment: SavedMoment) async throws
}

extension BookRepository {
    /// Books joined with their progress, in a stable order.
    func library() async throws -> [BookWithProgress] {
        let books = try await allBooks()
        let progress = try await allProgress()
        let byID = Dictionary(progress.map { ($0.bookID, $0) }, uniquingKeysWith: { first, _ in first })
        return books.map { BookWithProgress(book: $0, progress: byID[$0.id]) }
    }

    /// The book the person is actively reading, if any.
    func currentRead() async throws -> BookWithProgress? {
        try await library()
            .filter { $0.state == .reading }
            .max { ($0.progress?.startedAt ?? .distantPast) < ($1.progress?.startedAt ?? .distantPast) }
    }
}

protocol SquadRepository: Sendable {
    func currentSquad() async throws -> ReadingSquad
    func join(squadID: UUID, as profile: UserProfile) async throws -> ReadingSquad
    func activity(squadID: UUID) async throws -> [ActivityFeedItem]
    func toggleReaction(itemID: UUID) async throws -> ActivityFeedItem
    func post(_ item: ActivityFeedItem, squadID: UUID) async throws
    func leaderboard(squadID: UUID) async throws -> [LeaderboardEntry]
    /// TODO(prod): Points must be awarded server-side from verified quiz results, never trusted from the client.
    func awardPoints(_ points: Int, to memberID: UUID) async throws
}

protocol QuizService: Sendable {
    func availableModes(for bookID: UUID) async -> [QuizMode]
    /// `bookID` is ignored for library-wide modes such as Title & Author.
    func quiz(bookID: UUID?, mode: QuizMode) async throws -> Quiz?
    func score(quiz: Quiz, answers: [Int]) async -> QuizResult
    func memoryRefreshItem() async throws -> MemoryRefreshItem?
    func refreshItem(for bookID: UUID) async throws -> MemoryRefreshItem?
    func recordRefresh(bookID: UUID, wasCorrect: Bool) async
    func memoryGarden() async throws -> [MemoryGardenEntry]
}

protocol SummaryService: Sendable {
    /// Must enforce spoiler rules: never return content beyond what `spoilerLevel` and `progress` allow.
    func summary(for book: Book, mode: SummaryMode, progress: ReadingProgress?, spoilerLevel: SpoilerLevel) async throws -> SummaryResult
}

protocol PipAssistantService: Sendable {
    func reply(to prompt: String, context: PipContext) async -> PipMessage
    func resetMemory() async
}

protocol EventService: Sendable {
    func upcomingEvents(squadID: UUID) async throws -> [ReadingEvent]
    func event(id: UUID) async throws -> ReadingEvent
    func create(_ event: ReadingEvent) async throws -> ReadingEvent
    func setRSVP(eventID: UUID, memberID: UUID, attending: Bool) async throws -> ReadingEvent
    func startBuddyRead(_ buddyRead: BuddyRead) async throws -> BuddyRead
    func buddyReads() async throws -> [BuddyRead]
}

protocol PrivacySettingsStore: Sendable {
    func load() async -> PipPermissionSettings
    func save(_ settings: PipPermissionSettings) async
    func reset() async
}

protocol UserProfileStore: Sendable {
    func load() async -> UserProfile?
    func save(_ profile: UserProfile) async throws
    func delete() async
}

struct ReportReceipt: Hashable, Sendable {
    var id: UUID
    var submittedAt: Date
}

protocol ModerationService: Sendable {
    func report(item: ActivityFeedItem, note: String) async throws -> ReportReceipt
    func block(memberID: UUID) async throws
    func unblock(memberID: UUID) async throws
    func blockedMemberIDs() async -> Set<UUID>
}
