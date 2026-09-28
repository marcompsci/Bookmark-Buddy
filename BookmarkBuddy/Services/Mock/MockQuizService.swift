// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Deterministic quizzes and memory refresh.
///
/// Content rules:
/// - Demo titles use original, invented questions (see `DemoData`).
/// - Real books from the personal shelf only get metadata questions ("Who wrote…?"),
///   so no book content is ever reproduced.
///
/// TODO(prod): Generate questions from licensed, source-linked material with human review,
/// and enforce spoiler limits server-side using the reader's verified progress.
actor MockQuizService: QuizService {
    private let allBooks: [Book]
    private var strengths: [UUID: Double]
    private var lastRefreshed: [UUID: Date] = [:]
    private var refreshCursor = 0
    private let latency: Duration

    static let pointsPerCorrectAnswer = 20
    static let libraryQuizID = DemoData.id(502)

    init(latency: Duration = .milliseconds(250)) {
        self.latency = latency
        self.allBooks = DemoData.books + PersonalShelf.books
        self.strengths = Dictionary(
            (DemoData.progress + PersonalShelf.progress)
                .filter { $0.state == .finished }
                .map { ($0.bookID, $0.memoryStrength) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: Quizzes

    func availableModes(for bookID: UUID) async -> [QuizMode] {
        // Quick Recall is fully built for The Glass Harbor only in the MVP.
        bookID == DemoData.IDs.glassHarbor ? [.quickRecall] : []
    }

    func quiz(bookID: UUID?, mode: QuizMode) async throws -> Quiz? {
        await DemoLatency.pause(latency)
        switch mode {
        case .quickRecall:
            guard bookID == DemoData.IDs.glassHarbor else { return nil }
            return DemoData.glassHarborQuiz
        case .titleAndAuthor:
            return titleAndAuthorQuiz()
        case .characterMatch, .timelineOrder, .themeTalk:
            return nil
        }
    }

    func score(quiz: Quiz, answers: [Int]) async -> QuizResult {
        var correct = 0
        for (question, answer) in zip(quiz.questions, answers) where question.isCorrect(answer) {
            correct += 1
            strengthen(question.bookID ?? quiz.bookID, by: 0.05)
        }
        return QuizResult(
            quizID: quiz.id,
            bookID: quiz.bookID,
            correctCount: correct,
            totalCount: quiz.questions.count,
            pointsEarned: correct * Self.pointsPerCorrectAnswer
        )
    }

    /// Three metadata-only questions drawn from the whole library, reshuffled daily.
    private func titleAndAuthorQuiz() -> Quiz {
        var generator = SeededGenerator(seed: Self.daySeed())
        let uniqueByAuthor = Dictionary(allBooks.map { ($0.author, $0) }, uniquingKeysWith: { first, _ in first })
        let picks = Array(uniqueByAuthor.values.sorted { $0.title < $1.title }.shuffled(using: &generator).prefix(3))

        let questions = picks.enumerated().map { index, book in
            index == 1
                ? whichBookQuestion(for: book, using: &generator)
                : whoWroteQuestion(for: book, using: &generator)
        }

        return Quiz(
            id: Self.libraryQuizID,
            bookID: Self.libraryQuizID,
            mode: .titleAndAuthor,
            title: "Title & Author",
            questions: questions
        )
    }

    // MARK: Memory refresh

    func memoryRefreshItem() async throws -> MemoryRefreshItem? {
        await DemoLatency.pause(latency)
        // Prefer the weakest memory so refresh time goes where it helps most.
        let weakest = gardenBooks.sorted { (strengths[$0.id] ?? 0) < (strengths[$1.id] ?? 0) }
        guard !weakest.isEmpty else { return nil }
        // Rotate among the three weakest so Home doesn't repeat the same prompt.
        let book = weakest[refreshCursor % min(3, weakest.count)]
        refreshCursor += 1
        return makeRefreshItem(for: book)
    }

    func refreshItem(for bookID: UUID) async throws -> MemoryRefreshItem? {
        await DemoLatency.pause(latency)
        guard let book = allBooks.first(where: { $0.id == bookID }) else { return nil }
        return makeRefreshItem(for: book)
    }

    func recordRefresh(bookID: UUID, wasCorrect: Bool) async {
        strengthen(bookID, by: wasCorrect ? 0.12 : -0.04)
    }

    func memoryGarden() async throws -> [MemoryGardenEntry] {
        await DemoLatency.pause(latency)
        return gardenBooks
            .map { MemoryGardenEntry(book: $0, strength: strengths[$0.id] ?? 0, lastRefreshed: lastRefreshed[$0.id]) }
            .sorted { $0.strength > $1.strength }
    }

    // MARK: Helpers

    private var gardenBooks: [Book] {
        allBooks.filter { strengths[$0.id] != nil }
    }

    private func strengthen(_ bookID: UUID, by delta: Double) {
        guard let current = strengths[bookID] else { return }
        strengths[bookID] = min(1, max(0, current + delta))
        lastRefreshed[bookID] = .now
    }

    private func makeRefreshItem(for book: Book) -> MemoryRefreshItem {
        if let written = DemoData.refreshQuestions[book.id], !written.isEmpty {
            return MemoryRefreshItem(book: book, question: written[refreshCursor % written.count])
        }
        var generator = SeededGenerator(seed: Self.daySeed() &+ UInt64(abs(book.title.hashValue % 10_000)))
        return MemoryRefreshItem(book: book, question: whoWroteQuestion(for: book, using: &generator))
    }

    private func whoWroteQuestion(for book: Book, using generator: inout SeededGenerator) -> QuizQuestion {
        let distractors = Array(Set(allBooks.map(\.author)).subtracting([book.author]).sorted().shuffled(using: &generator).prefix(3))
        var options = distractors + [book.author]
        options.shuffle(using: &generator)
        return QuizQuestion(
            id: UUID(),
            prompt: "Who wrote “\(book.title)”?",
            options: options,
            correctIndex: options.firstIndex(of: book.author) ?? 0,
            explanation: "“\(book.title)” is by \(book.author).",
            drawsOnChapter: 0,
            bookID: book.id
        )
    }

    private func whichBookQuestion(for book: Book, using generator: inout SeededGenerator) -> QuizQuestion {
        let others = allBooks.filter { $0.author != book.author }.map(\.title)
        let distractors = Array(others.sorted().shuffled(using: &generator).prefix(3))
        var options = distractors + [book.title]
        options.shuffle(using: &generator)
        return QuizQuestion(
            id: UUID(),
            prompt: "Which of these books is by \(book.author)?",
            options: options,
            correctIndex: options.firstIndex(of: book.title) ?? 0,
            explanation: "\(book.author) wrote “\(book.title)”.",
            drawsOnChapter: 0,
            bookID: book.id
        )
    }

    /// Stable within a day so a quiz doesn't reshuffle mid-attempt.
    private static func daySeed() -> UInt64 {
        let days = Int(Date.now.timeIntervalSince1970 / 86_400)
        return UInt64(max(0, days))
    }
}
