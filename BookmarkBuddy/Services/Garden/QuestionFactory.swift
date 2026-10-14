// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Builds one refresh question for a book, matched to how well the reader remembers it.
///
/// Difficulty adapts to the plant's strength:
/// - fading (< 0.35): easy — who wrote it, which book is by this author
/// - growing (< 0.7): medium — match the book to its description, pick its shelf
/// - strong: hard — characters, and the hand-written questions for demo titles
///
/// Content rules (unchanged): real books only get questions built from our own metadata
/// (title, author, shelf, our written description, character names) — never quoted text.
/// Characters and written questions respect the reader's current chapter (spoiler-safe).
enum QuestionFactory {
    enum Difficulty: Int, Comparable {
        case easy, medium, hard
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

        init(strength: Double) {
            switch strength {
            case ..<0.35: self = .easy
            case ..<0.7: self = .medium
            default: self = .hard
            }
        }
    }

    /// - Parameter allowedChapter: the furthest chapter the reader has reached (`Int.max` when finished).
    static func question(
        for book: Book,
        strength: Double,
        catalogue: [Book],
        allowedChapter: Int,
        written: [QuizQuestion] = []
    ) -> QuizQuestion {
        var rng = SystemRandomNumberGenerator()
        var target = Difficulty(strength: strength)
        // Keep it fun: sometimes step down a level so it isn't always the hardest kind.
        if target > .easy, Double.random(in: 0..<1, using: &rng) < 0.3 {
            target = Difficulty(rawValue: target.rawValue - 1) ?? .easy
        }

        var pools: [Difficulty: [QuizQuestion]] = [.easy: [], .medium: [], .hard: []]
        pools[.easy]?.append(contentsOf: [whoWrote(book, catalogue, &rng), whichByAuthor(book, catalogue, &rng)].compactMap { $0 })
        pools[.medium]?.append(contentsOf: [premiseMatch(book, catalogue, &rng), shelfMatch(book, &rng)].compactMap { $0 })
        pools[.hard]?.append(contentsOf: [characterMatch(book, catalogue, allowedChapter, &rng)].compactMap { $0 })
        pools[.hard]?.append(contentsOf: written.filter { $0.drawsOnChapter <= allowedChapter })

        // Try the target tier, then fall back toward easy, then upward.
        let order: [Difficulty] = [target] + [Difficulty.medium, .easy, .hard].filter { $0 != target }
        for tier in order {
            if let pick = pools[tier]?.randomElement(using: &rng) { return pick }
        }
        return whoWrote(book, catalogue, &rng) ?? fallback(book)
    }

    // MARK: Easy

    private static func whoWrote(_ book: Book, _ catalogue: [Book], _ rng: inout SystemRandomNumberGenerator) -> QuizQuestion? {
        let distractors = Array(Set(catalogue.map(\.author)).subtracting([book.author]).shuffled(using: &rng).prefix(2))
        guard distractors.count == 2 else { return nil }
        return make(book, prompt: "Who wrote “\(book.title)”?", answer: book.author, distractors: distractors,
                    explanation: "“\(book.title)” is by \(book.author).", &rng)
    }

    private static func whichByAuthor(_ book: Book, _ catalogue: [Book], _ rng: inout SystemRandomNumberGenerator) -> QuizQuestion? {
        let distractors = Array(catalogue.filter { $0.author != book.author }.map(\.title).shuffled(using: &rng).prefix(2))
        guard distractors.count == 2 else { return nil }
        return make(book, prompt: "Which of these did \(book.author) write?", answer: book.title, distractors: distractors,
                    explanation: "\(book.author) wrote “\(book.title)”.", &rng)
    }

    // MARK: Medium

    private static func premiseMatch(_ book: Book, _ catalogue: [Book], _ rng: inout SystemRandomNumberGenerator) -> QuizQuestion? {
        let premise = book.premise.trimmingCharacters(in: .whitespacesAndNewlines)
        guard premise.count >= 40 else { return nil }
        let distractors = Array(catalogue.filter { $0.id != book.id && $0.title != book.title }.map(\.title).shuffled(using: &rng).prefix(3))
        guard distractors.count == 3 else { return nil }
        let short = premise.count > 170 ? String(premise.prefix(167)) + "…" : premise
        return make(book, prompt: "Which book is this?\n“\(short)”", answer: book.title, distractors: distractors,
                    explanation: "That's the setup of “\(book.title)” by \(book.author).", &rng)
    }

    private static func shelfMatch(_ book: Book, _ rng: inout SystemRandomNumberGenerator) -> QuizQuestion? {
        guard let genre = book.genres.first else { return nil }
        let distractors = Array(Genre.allCases.filter { !book.genres.contains($0) }.shuffled(using: &rng).prefix(3)).map(\.displayName)
        guard distractors.count == 3 else { return nil }
        return make(book, prompt: "Which shelf does “\(book.title)” belong on?", answer: genre.displayName, distractors: distractors,
                    explanation: "“\(book.title)” sits on the \(genre.displayName) shelf.", &rng)
    }

    // MARK: Hard

    private static func characterMatch(_ book: Book, _ catalogue: [Book], _ allowedChapter: Int, _ rng: inout SystemRandomNumberGenerator) -> QuizQuestion? {
        let known = book.characters.filter { $0.introducedInChapter <= allowedChapter }
        guard let character = known.randomElement(using: &rng) else { return nil }
        let distractors = Array(catalogue.filter { $0.id != book.id }.map(\.title).shuffled(using: &rng).prefix(3))
        guard distractors.count == 3 else { return nil }
        return make(book, prompt: "In which book do you meet \(character.name)?", answer: book.title, distractors: distractors,
                    explanation: "\(character.name) — \(character.role) — is from “\(book.title)”.", &rng)
    }

    // MARK: Helpers

    private static func make(
        _ book: Book, prompt: String, answer: String, distractors: [String], explanation: String,
        _ rng: inout SystemRandomNumberGenerator
    ) -> QuizQuestion {
        var options = distractors + [answer]
        options.shuffle(using: &rng)
        return QuizQuestion(
            id: UUID(),
            prompt: prompt,
            options: options,
            correctIndex: options.firstIndex(of: answer) ?? 0,
            explanation: explanation,
            drawsOnChapter: 0,
            bookID: book.id
        )
    }

    private static func fallback(_ book: Book) -> QuizQuestion {
        QuizQuestion(
            id: UUID(),
            prompt: "Who wrote “\(book.title)”?",
            options: [book.author],
            correctIndex: 0,
            explanation: "“\(book.title)” is by \(book.author).",
            drawsOnChapter: 0,
            bookID: book.id
        )
    }
}
