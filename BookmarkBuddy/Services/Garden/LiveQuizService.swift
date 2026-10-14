// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// The reader's own Memory Garden.
///
/// Plants are the books *this reader* is reading or has finished (from their reading progress),
/// plus anything planted on device (e.g. the first-run pick). Strength lives in `GardenStore`
/// so it grows and fades across launches, and is mirrored to `reading_progress.memory_strength`.
/// Questions come from `QuestionFactory` and adapt to how well each book is remembered.
/// Full quizzes (Play tab) still use the demo quiz service.
actor LiveQuizService: QuizService {
    private let books: any BookRepository
    private let demo = MockQuizService()
    private var refreshCursor = 0

    init(books: any BookRepository) {
        self.books = books
    }

    // MARK: Quizzes (unchanged — demo content)

    func availableModes(for bookID: UUID) async -> [QuizMode] { await demo.availableModes(for: bookID) }
    func quiz(bookID: UUID?, mode: QuizMode) async throws -> Quiz? { try await demo.quiz(bookID: bookID, mode: mode) }
    func score(quiz: Quiz, answers: [Int]) async -> QuizResult { await demo.score(quiz: quiz, answers: answers) }

    // MARK: Garden

    private struct Plot {
        let book: Book
        let progress: ReadingProgress?
        let strength: Double
        let lastWatered: Date?
    }

    private func plots() async -> [Plot] {
        let catalogue = (try? await books.allBooks()) ?? []
        let progress = (try? await books.allProgress()) ?? []
        let byID = Dictionary(progress.map { ($0.bookID, $0) }, uniquingKeysWith: { first, _ in first })
        let planted = await MainActor.run { GardenStore.shared.plantedIDs }

        let gardenIDs = Set(progress.filter { $0.state == .finished || $0.state == .reading }.map(\.bookID)).union(planted)
        var result: [Plot] = []
        for book in catalogue where gardenIDs.contains(book.id) {
            let entry = byID[book.id]
            let seed = Self.seedStrength(entry)
            let (strength, watered) = await MainActor.run {
                (GardenStore.shared.strength(for: book.id, seed: seed), GardenStore.shared.lastWatered(book.id))
            }
            result.append(Plot(book: book, progress: entry, strength: strength, lastWatered: watered))
        }
        return result
    }

    private static func seedStrength(_ progress: ReadingProgress?) -> Double {
        guard let progress else { return 0.25 }
        if progress.state == .finished { return progress.memoryStrength > 0 ? progress.memoryStrength : 0.5 }
        return 0.25
    }

    func memoryGarden() async throws -> [MemoryGardenEntry] {
        await plots()
            .map { MemoryGardenEntry(book: $0.book, strength: $0.strength, lastRefreshed: $0.lastWatered) }
            .sorted { $0.strength > $1.strength }
    }

    func memoryRefreshItem() async throws -> MemoryRefreshItem? {
        let weakest = await plots().sorted { $0.strength < $1.strength }
        guard !weakest.isEmpty else { return nil }
        // Rotate among the three weakest so the same book doesn't come up every time.
        let plot = weakest[refreshCursor % min(3, weakest.count)]
        refreshCursor += 1
        return await makeItem(plot)
    }

    func refreshItem(for bookID: UUID) async throws -> MemoryRefreshItem? {
        if let plot = await plots().first(where: { $0.book.id == bookID }) {
            return await makeItem(plot)
        }
        guard let book = try? await books.book(id: bookID) else { return nil }
        let progress = try? await books.progress(for: bookID)
        return await makeItem(Plot(book: book, progress: progress ?? nil, strength: 0.25, lastWatered: nil))
    }

    private func makeItem(_ plot: Plot) async -> MemoryRefreshItem {
        let catalogue = (try? await books.allBooks()) ?? [plot.book]
        let allowed = plot.progress?.state == .finished ? Int.max : max(0, plot.progress?.currentChapter ?? 0)
        let question = QuestionFactory.question(
            for: plot.book,
            strength: plot.strength,
            catalogue: catalogue,
            allowedChapter: allowed,
            written: DemoData.refreshQuestions[plot.book.id] ?? []
        )
        return MemoryRefreshItem(book: plot.book, question: question)
    }

    func recordRefresh(bookID: UUID, wasCorrect: Bool) async {
        let progress = (try? await books.progress(for: bookID)) ?? nil
        let title = (try? await books.book(id: bookID))?.title
        let seed = Self.seedStrength(progress)
        let newStrength = await MainActor.run {
            GardenStore.shared.water(bookID: bookID, correct: wasCorrect, seed: seed, bookTitle: title)
        }
        // Mirror to the server so the garden survives a reinstall (best effort).
        if var progress {
            progress.memoryStrength = newStrength
            try? await books.updateProgress(progress)
        }
    }
}
