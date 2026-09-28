// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// In-memory events and buddy reads.
/// TODO(prod): Server-side authorization (only squad members can create/RSVP), rate limits on
/// invites, and notification delivery gated behind explicit notification consent.
actor MockEventService: EventService {
    private var events: [ReadingEvent]
    private var reads: [BuddyRead] = []
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.events = DemoData.events
        self.latency = latency
    }

    func upcomingEvents(squadID: UUID) async throws -> [ReadingEvent] {
        await DemoLatency.pause(latency)
        return events
            .filter { $0.squadID == squadID && $0.startsAt > Date.now.addingTimeInterval(-3_600) }
            .sorted { $0.startsAt < $1.startsAt }
    }

    func event(id: UUID) async throws -> ReadingEvent {
        await DemoLatency.pause(latency)
        guard let event = events.first(where: { $0.id == id }) else { throw DemoServiceError.notFound }
        return event
    }

    func create(_ event: ReadingEvent) async throws -> ReadingEvent {
        await DemoLatency.pause(latency)
        events.append(event)
        return event
    }

    func setRSVP(eventID: UUID, memberID: UUID, attending: Bool) async throws -> ReadingEvent {
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { throw DemoServiceError.notFound }
        if attending {
            if !events[index].rsvpMemberIDs.contains(memberID) { events[index].rsvpMemberIDs.append(memberID) }
        } else {
            events[index].rsvpMemberIDs.removeAll { $0 == memberID }
        }
        return events[index]
    }

    func startBuddyRead(_ buddyRead: BuddyRead) async throws -> BuddyRead {
        await DemoLatency.pause(latency)
        reads.append(buddyRead)
        return buddyRead
    }

    func buddyReads() async throws -> [BuddyRead] {
        reads
    }
}
