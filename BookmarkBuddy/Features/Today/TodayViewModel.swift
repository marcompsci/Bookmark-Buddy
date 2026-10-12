// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

/// Today = "what are you reading, and do you still remember it?"
/// Every section loads on its own, so one failing service never blanks the screen.
@Observable
@MainActor
final class TodayViewModel {
    private(set) var hasLoaded = false
    private(set) var current: BookWithProgress?
    private(set) var refresh: MemoryRefreshItem?
    private(set) var garden: [MemoryGardenEntry] = []
    private(set) var shelf: ShelfSnapshot?
    private(set) var refreshPhase: HomeViewModel.RefreshPhase = .collapsed
    var refreshingBook: Book?
    var showsFullGarden = false

    static let collapsedGardenCount = 6

    func load(services: AppServices) async {
        current = (try? await services.books.currentRead()) ?? nil
        let loadedRefresh = (try? await services.quizzes.memoryRefreshItem()) ?? nil
        // Don't swap the question out from under someone mid-answer.
        if refreshPhase == .collapsed { refresh = loadedRefresh }
        garden = ((try? await services.quizzes.memoryGarden()) ?? []).sorted { $0.strength < $1.strength }
        shelf = (try? await services.shelves.myShelf()) ?? nil
        hasLoaded = true
    }

    // MARK: Memory refresh

    func startRefresh() { refreshPhase = .asking }

    func answerRefresh(_ index: Int, services: AppServices) async {
        guard refreshPhase == .asking, let item = refresh else { return }
        let correct = item.question.isCorrect(index)
        refreshPhase = .answered(selected: index, correct: correct)
        await services.quizzes.recordRefresh(bookID: item.book.id, wasCorrect: correct)
        garden = ((try? await services.quizzes.memoryGarden()) ?? garden).sorted { $0.strength < $1.strength }
    }

    func nextRefresh(services: AppServices) async {
        refreshPhase = .collapsed
        refresh = try? await services.quizzes.memoryRefreshItem()
    }

    // MARK: Garden

    var visibleGarden: [MemoryGardenEntry] {
        showsFullGarden ? garden : Array(garden.prefix(Self.collapsedGardenCount))
    }

    var hiddenGardenCount: Int { max(0, garden.count - Self.collapsedGardenCount) }

    var averageStrength: Double {
        guard !garden.isEmpty else { return 0 }
        return garden.map(\.strength).reduce(0, +) / Double(garden.count)
    }

    /// The weakest memory — the book most worth refreshing next.
    var weakest: MemoryGardenEntry? { garden.first }
}
