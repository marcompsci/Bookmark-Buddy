// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class QuizViewModel {
    enum Phase: Equatable {
        case loading
        case unavailable(String)
        case intro
        case question(index: Int)
        case finished(QuizResult)
    }

    let bookID: UUID?
    let mode: QuizMode

    private(set) var phase: Phase = .loading
    private(set) var quiz: Quiz?
    private(set) var book: Book?
    private(set) var answers: [Int] = []
    private(set) var selectedAnswer: Int?
    private(set) var hiddenForSpoilers = 0
    private(set) var isScoring = false

    init(bookID: UUID?, mode: QuizMode) {
        self.bookID = bookID
        self.mode = mode
    }

    // MARK: Loading

    func load(services: AppServices, spoilerLevel: SpoilerLevel) async {
        guard phase == .loading else { return }
        do {
            guard let loaded = try await services.quizzes.quiz(bookID: bookID, mode: mode) else {
                phase = .unavailable("\(mode.displayName) isn't available for this book yet. Try Quick Recall on The Glass Harbor or Title & Author.")
                return
            }
            var progress: ReadingProgress?
            if let bookID {
                book = try await services.books.book(id: bookID)
                progress = try await services.books.progress(for: bookID)
            }
            let allowed = SpoilerPolicy.allowedQuestions(loaded.questions, book: book, progress: progress, level: spoilerLevel)
            hiddenForSpoilers = loaded.questions.count - allowed.count
            guard !allowed.isEmpty else {
                phase = .unavailable("Every question in this quiz goes past where you are. Keep reading, or change your spoiler setting in Profile.")
                return
            }
            var filtered = loaded
            filtered.questions = allowed
            quiz = filtered
            phase = .intro
        } catch {
            phase = .unavailable("The quiz couldn't load. Go back and try again.")
        }
    }

    // MARK: Playing

    var questionCount: Int { quiz?.questions.count ?? 0 }

    var currentIndex: Int? {
        if case .question(let index) = phase { return index }
        return nil
    }

    var currentQuestion: QuizQuestion? {
        guard let quiz, let index = currentIndex, quiz.questions.indices.contains(index) else { return nil }
        return quiz.questions[index]
    }

    var isLastQuestion: Bool {
        guard let index = currentIndex else { return false }
        return index >= questionCount - 1
    }

    /// Fraction of the quiz completed, for the progress bar.
    var progressFraction: Double {
        guard questionCount > 0, let index = currentIndex else { return 0 }
        let answered = selectedAnswer == nil ? index : index + 1
        return Double(answered) / Double(questionCount)
    }

    var correctSoFar: Int {
        guard let quiz else { return 0 }
        return zip(quiz.questions, answers).filter { question, answer in question.isCorrect(answer) }.count
    }

    func start() {
        answers = []
        selectedAnswer = nil
        phase = questionCount > 0 ? .question(index: 0) : .intro
    }

    func select(_ option: Int) {
        guard currentQuestion != nil, selectedAnswer == nil else { return }
        selectedAnswer = option
        answers.append(option)
    }

    func next(services: AppServices, appState: AppState) async {
        guard let index = currentIndex, selectedAnswer != nil else { return }
        if isLastQuestion {
            await finish(services: services, appState: appState)
        } else {
            selectedAnswer = nil
            phase = .question(index: index + 1)
        }
    }

    private func finish(services: AppServices, appState: AppState) async {
        guard let quiz, !isScoring else { return }
        isScoring = true
        defer { isScoring = false }
        let result = await services.quizzes.score(quiz: quiz, answers: answers)
        if let profile = appState.profile, result.pointsEarned > 0 {
            // TODO(prod): Points must be awarded server-side from a verified result.
            try? await services.squads.awardPoints(result.pointsEarned, to: profile.id)
            await appState.updateProfile { $0.squadPoints += result.pointsEarned }
        }
        selectedAnswer = nil
        phase = .finished(result)
    }

    // MARK: Pip commentary

    static func pipComment(for result: QuizResult) -> String {
        switch (result.correctCount, result.totalCount) {
        case let (correct, total) where total > 0 && correct == total:
            "Flawless! That book is blooming in your Memory Garden."
        case let (correct, total) where total > 0 && Double(correct) / Double(total) >= 0.6:
            "So close to perfect. One more round and it's yours."
        case (0, _):
            "Tough round! Every miss plants a seed. Try again and watch it grow."
        default:
            "Nice start. A quick replay tomorrow will lock these in."
        }
    }
}
