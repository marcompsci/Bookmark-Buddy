// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    struct Content {
        var current: BookWithProgress?
        var libraryBooks: [BookWithProgress] = []
        var squad: ReadingSquad
        var event: ReadingEvent?
        var refresh: MemoryRefreshItem?
        var activity: [ActivityFeedItem]

        func member(for id: UUID) -> SquadMember? {
            squad.members.first { $0.id == id }
        }

        /// Books suitable for the personal spine shelf: reading + finished, by recency.
        var shelfBooks: [Book] {
            libraryBooks
                .filter { $0.state == .reading || $0.state == .finished }
                .sorted {
                    let lDate = $0.progress?.startedAt ?? .distantPast
                    let rDate = $1.progress?.startedAt ?? .distantPast
                    return lDate > rDate
                }
                .map(\.book)
        }
    }

    enum RefreshPhase: Equatable {
        case collapsed
        case asking
        case answered(selected: Int, correct: Bool)
    }

    private(set) var state: LoadState<Content> = .idle
    private(set) var refreshPhase: RefreshPhase = .collapsed
    private(set) var isUpdatingRSVP = false

    var content: Content? { state.value }

    func load(services: AppServices) async {
        // Keep showing existing content during background reloads.
        if content == nil { state = .loading }
        do {
            async let current = services.books.currentRead()
            async let library = services.books.library()
            async let squad = services.squads.currentSquad()
            async let refresh = services.quizzes.memoryRefreshItem()
            let loadedSquad = try await squad
            async let events = services.events.upcomingEvents(squadID: loadedSquad.id)
            async let activity = services.squads.activity(squadID: loadedSquad.id)

            let loadedCurrent = try await current
            let loadedLibrary = try await library
            let loadedEvents = try await events
            let loadedActivity = try await activity
            let loadedRefresh = try await refresh

            let newContent = Content(
                current: loadedCurrent,
                libraryBooks: loadedLibrary,
                squad: loadedSquad,
                event: loadedEvents.first,
                // Don't swap the question out from under someone mid-answer.
                refresh: refreshPhase == .collapsed ? loadedRefresh : content?.refresh,
                activity: Array(loadedActivity.prefix(3))
            )
            state = .loaded(newContent)
        } catch {
            if content == nil {
                state = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: RSVP

    func isAttending(_ profile: UserProfile?) -> Bool {
        guard let profile, let event = content?.event else { return false }
        return event.isAttending(profile.id)
    }

    /// RSVPs are a lightweight, reversible personal choice, so they don't need the confirmation gate.
    func toggleRSVP(profile: UserProfile?, services: AppServices) async {
        guard let profile, var current = content, let event = current.event, !isUpdatingRSVP else { return }
        isUpdatingRSVP = true
        defer { isUpdatingRSVP = false }
        do {
            let updated = try await services.events.setRSVP(
                eventID: event.id,
                memberID: profile.id,
                attending: !event.isAttending(profile.id)
            )
            current.event = updated
            state = .loaded(current)
        } catch {
            // Leave state unchanged; the button simply doesn't flip.
        }
    }

    // MARK: Memory refresh

    func startRefresh() {
        refreshPhase = .asking
    }

    func answerRefresh(_ index: Int, services: AppServices) async {
        guard refreshPhase == .asking, let item = content?.refresh else { return }
        let correct = item.question.isCorrect(index)
        refreshPhase = .answered(selected: index, correct: correct)
        await services.quizzes.recordRefresh(bookID: item.book.id, wasCorrect: correct)
    }

    func nextRefresh(services: AppServices) async {
        refreshPhase = .collapsed
        guard var current = content else { return }
        current.refresh = try? await services.quizzes.memoryRefreshItem()
        state = .loaded(current)
    }

    // MARK: Greeting

    static func greeting(for date: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<22: "Good evening"
        default: "Hello, night owl"
        }
    }
}
