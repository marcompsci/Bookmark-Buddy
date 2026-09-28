// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

enum EventType: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case readTogether, triviaNight, discussionCircle, sprintSession

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .readTogether: "Read Together"
        case .triviaNight: "Trivia Night"
        case .discussionCircle: "Discussion Circle"
        case .sprintSession: "Sprint Session"
        }
    }

    var blurb: String {
        switch self {
        case .readTogether: "Quiet co-reading with check-ins."
        case .triviaNight: "Pip hosts a squad quiz. Points count toward the weekly board."
        case .discussionCircle: "Talk through themes with spoiler rules set in advance."
        case .sprintSession: "A focused 25-minute read with a finish-line cheer."
        }
    }

    var symbol: String {
        switch self {
        case .readTogether: "book"
        case .triviaNight: "questionmark.bubble"
        case .discussionCircle: "bubble.left.and.bubble.right"
        case .sprintSession: "timer"
        }
    }

    var defaultDurationMinutes: Int {
        switch self {
        case .readTogether: 60
        case .triviaNight: 45
        case .discussionCircle: 60
        case .sprintSession: 25
        }
    }
}

struct ReadingEvent: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var squadID: UUID
    var type: EventType
    var title: String
    var startsAt: Date
    var durationMinutes: Int
    var hostMemberID: UUID
    var rsvpMemberIDs: [UUID]
    var bookID: UUID?
    var notes: String = ""

    func isAttending(_ memberID: UUID) -> Bool { rsvpMemberIDs.contains(memberID) }
}

struct BuddyRead: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var bookID: UUID
    var invitedMemberIDs: [UUID]
    var goalDate: Date
    var spoilerLevel: SpoilerLevel
    var createdAt: Date = .now
}
