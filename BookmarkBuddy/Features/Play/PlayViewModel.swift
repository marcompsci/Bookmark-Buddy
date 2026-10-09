// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class PlayViewModel {
    struct Content {
        var leaderboard: [LeaderboardEntry]
        var garden: [MemoryGardenEntry]
    }

    /// Where each quiz mode leads in the MVP.
    enum ModeAvailability: Equatable {
        case playable(bookID: UUID?)
        case comingSoon
    }

    static let collapsedGardenCount = 6

    private(set) var state: LoadState<Content> = .idle
    var showsFullGarden = false
    var refreshingBook: Book?
    private(set) var quickRecallBookID: UUID? = DemoData.IDs.glassHarbor

    var content: Content? { state.value }

    func load(services: AppServices) async {
        if content == nil { state = .loading }
        do {
            let squad = try await services.squads.currentSquad()
            async let leaderboard = services.squads.leaderboard(squadID: squad.id)
            async let garden = services.quizzes.memoryGarden()
            let loadedBoard = try await leaderboard
            let loadedGarden = try await garden
            state = .loaded(Content(leaderboard: loadedBoard, garden: loadedGarden))
            let candidate = loadedGarden
                .filter { DemoData.refreshQuestions[$0.book.id] != nil }
                .min { $0.strength < $1.strength }
            quickRecallBookID = candidate?.book.id ?? DemoData.IDs.glassHarbor
        } catch {
            if content == nil { state = .failed(error.localizedDescription) }
        }
    }

    func availability(of mode: QuizMode) -> ModeAvailability {
        switch mode {
        case .quickRecall: .playable(bookID: quickRecallBookID)
        case .titleAndAuthor: .playable(bookID: nil)
        case .characterMatch, .timelineOrder, .themeTalk: .comingSoon
        }
    }

    var visibleGarden: [MemoryGardenEntry] {
        let garden = content?.garden ?? []
        return showsFullGarden ? garden : Array(garden.prefix(Self.collapsedGardenCount))
    }

    var hiddenGardenCount: Int {
        max(0, (content?.garden.count ?? 0) - Self.collapsedGardenCount)
    }

    var averageStrength: Double {
        let garden = content?.garden ?? []
        guard !garden.isEmpty else { return 0 }
        return garden.map(\.strength).reduce(0, +) / Double(garden.count)
    }
}
