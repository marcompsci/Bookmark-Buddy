// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

enum QuizMode: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case quickRecall, characterMatch, titleAndAuthor, timelineOrder, themeTalk

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quickRecall: "Quick Recall"
        case .characterMatch: "Character Match"
        case .titleAndAuthor: "Title & Author"
        case .timelineOrder: "Timeline Order"
        case .themeTalk: "Theme Talk"
        }
    }

    var blurb: String {
        switch self {
        case .quickRecall: "Three fast questions on what happened."
        case .characterMatch: "Who did what? Match names to moments."
        case .titleAndAuthor: "Pair the book with the writer."
        case .timelineOrder: "Put the key events in order."
        case .themeTalk: "Open prompts for your next discussion."
        }
    }

    var symbol: String {
        switch self {
        case .quickRecall: "bolt.fill"
        case .characterMatch: "person.2.fill"
        case .titleAndAuthor: "text.book.closed.fill"
        case .timelineOrder: "list.number"
        case .themeTalk: "bubble.left.and.bubble.right.fill"
        }
    }
}

struct QuizQuestion: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var prompt: String
    var options: [String]
    var correctIndex: Int
    var explanation: String
    /// The latest chapter this question draws on. Used to keep quizzes spoiler-safe.
    var drawsOnChapter: Int
    /// The book this question is about, when a quiz spans several books (e.g. Title & Author).
    var bookID: UUID? = nil

    func isCorrect(_ index: Int) -> Bool { index == correctIndex }
}

struct Quiz: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var bookID: UUID
    var mode: QuizMode
    var title: String
    var questions: [QuizQuestion]
}

struct QuizResult: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var quizID: UUID
    var bookID: UUID
    var correctCount: Int
    var totalCount: Int
    var pointsEarned: Int
    var completedAt: Date = .now

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
}

/// A single spaced-repetition prompt drawn from a finished book.
struct MemoryRefreshItem: Identifiable, Hashable, Sendable {
    var id: UUID { question.id }
    var book: Book
    var question: QuizQuestion
}

/// A plant in the Memory Garden. Strength grows with correct refresh answers.
struct MemoryGardenEntry: Identifiable, Hashable, Sendable {
    var id: UUID { book.id }
    var book: Book
    var strength: Double
    var lastRefreshed: Date?
}
