// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class SquadViewModel {
    struct Content {
        var squad: ReadingSquad
        var currentBook: Book?
        var activity: [ActivityFeedItem]
        var events: [ReadingEvent]
        var blocked: Set<UUID>

        func member(for id: UUID) -> SquadMember? {
            squad.members.first { $0.id == id }
        }

        /// Members sorted by how far they are in the shared read. Blocked members are hidden.
        var memberProgress: [SquadMember] {
            squad.members
                .filter { !blocked.contains($0.id) }
                .sorted { ($0.currentChapter ?? -1) > ($1.currentChapter ?? -1) }
        }

        var visibleActivity: [ActivityFeedItem] {
            activity.filter { !blocked.contains($0.memberID) }
        }

        var hiddenActivityCount: Int {
            activity.count - visibleActivity.count
        }
    }

    private(set) var state: LoadState<Content> = .idle
    private(set) var busyEventIDs: Set<UUID> = []

    var content: Content? { state.value }

    func load(services: AppServices) async {
        if content == nil { state = .loading }
        do {
            let squad = try await services.squads.currentSquad()
            async let activity = services.squads.activity(squadID: squad.id)
            async let events = services.events.upcomingEvents(squadID: squad.id)
            async let blocked = services.moderation.blockedMemberIDs()
            var currentBook: Book?
            if let bookID = squad.currentBookID {
                currentBook = try? await services.books.book(id: bookID)
            }
            let loadedActivity = try await activity
            let loadedEvents = try await events
            let loadedBlocked = await blocked
            state = .loaded(Content(
                squad: squad,
                currentBook: currentBook,
                activity: loadedActivity,
                events: loadedEvents,
                blocked: loadedBlocked
            ))
        } catch {
            if content == nil { state = .failed(error.localizedDescription) }
        }
    }

    /// Reactions are lightweight and reversible, so they update immediately without confirmation.
    func toggleReaction(_ item: ActivityFeedItem, services: AppServices) async {
        guard var current = content else { return }
        do {
            let updated = try await services.squads.toggleReaction(itemID: item.id)
            if let index = current.activity.firstIndex(where: { $0.id == updated.id }) {
                current.activity[index] = updated
                state = .loaded(current)
            }
        } catch {}
    }

    func toggleRSVP(_ event: ReadingEvent, profile: UserProfile?, services: AppServices) async {
        guard let profile, var current = content, !busyEventIDs.contains(event.id) else { return }
        busyEventIDs.insert(event.id)
        defer { busyEventIDs.remove(event.id) }
        do {
            let updated = try await services.events.setRSVP(
                eventID: event.id,
                memberID: profile.id,
                attending: !event.isAttending(profile.id)
            )
            if let index = current.events.firstIndex(where: { $0.id == updated.id }) {
                current.events[index] = updated
                state = .loaded(current)
            }
        } catch {}
    }
}
