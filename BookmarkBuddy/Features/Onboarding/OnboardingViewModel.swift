// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    enum Step: Int, CaseIterable, Hashable {
        case welcome, genres, goal, spoilers

        var accessibilityTitle: String {
            switch self {
            case .welcome: "Welcome"
            case .genres: "Favorite genres"
            case .goal: "Reading goal"
            case .spoilers: "Spoiler preference"
            }
        }
    }

    static let nameLimit = 30
    static let booksPerMonthRange = 1...12

    var step: Step = .welcome
    var displayName = ""
    var selectedGenres: Set<Genre> = []
    var booksPerMonth = 2
    var pace: ReadingPace = .steady
    var spoilerLevel: SpoilerLevel = .currentChapter

    private(set) var isSaving = false
    var errorMessage: String?

    // MARK: Derived state

    var canContinue: Bool {
        switch step {
        case .genres: !selectedGenres.isEmpty
        default: true
        }
    }

    var isFirstStep: Bool { step == .welcome }
    var isLastStep: Bool { step == .spoilers }

    var progressLabel: String {
        "Step \(step.rawValue + 1) of \(Step.allCases.count)"
    }

    var continueTitle: String {
        switch step {
        case .welcome: "Get started"
        case .spoilers: "Start reading"
        default: "Continue"
        }
    }

    /// A friendly translation of the monthly goal, assuming ~300-page books.
    var weeklyPagesEstimate: Int {
        Int((Double(booksPerMonth) * 300.0 / 4.3).rounded())
    }

    var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Intents

    func enforceNameLimit() {
        if displayName.count > Self.nameLimit {
            displayName = String(displayName.prefix(Self.nameLimit))
        }
    }

    func toggle(_ genre: Genre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
    }

    func incrementGoal() {
        booksPerMonth = min(Self.booksPerMonthRange.upperBound, booksPerMonth + 1)
    }

    func decrementGoal() {
        booksPerMonth = max(Self.booksPerMonthRange.lowerBound, booksPerMonth - 1)
    }

    func next() {
        guard canContinue, let nextStep = Step(rawValue: step.rawValue + 1) else { return }
        step = nextStep
    }

    func back() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func makeProfile() -> UserProfile {
        UserProfile(
            displayName: trimmedName.isEmpty ? "Reader" : trimmedName,
            // Keep a stable, readable order rather than Set order.
            favoriteGenres: Genre.allCases.filter { selectedGenres.contains($0) },
            booksPerMonth: booksPerMonth,
            pace: pace,
            spoilerLevel: spoilerLevel,
            currentStreakDays: 1,
            squadPoints: 0
        )
    }

    /// Creates the profile, joins the demo squad and persists it. Returns true on success.
    func finish(appState: AppState) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await appState.completeOnboarding(with: makeProfile())
            return true
        } catch {
            errorMessage = "We couldn't save your profile on this device. Please try again."
            return false
        }
    }
}
