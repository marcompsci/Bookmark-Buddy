// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

struct SquadMember: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var displayName: String
    /// Seeds the generated avatar gradient so each member keeps a stable color.
    var avatarSeed: Int
    var isCurrentUser: Bool = false
    /// Chapter reached in the squad's current read, if they've started it.
    var currentChapter: Int?
    var weeklyPoints: Int

    var initials: String { Initials.from(displayName) }
}

struct SquadChallenge: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var detail: String
    var goal: Int
    var progress: Int
    var endsAt: Date

    var fraction: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(progress) / Double(goal))
    }
}

struct ReadingSquad: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var name: String
    var tagline: String
    var members: [SquadMember]
    var currentBookID: UUID?
    var challenge: SquadChallenge?

    var memberCount: Int { members.count }
}

enum ActivityKind: String, Codable, CaseIterable, Hashable, Sendable {
    case chapterCompleted, quizWin, reaction, eventRSVP, joined, buddyReadStarted, eventCreated

    var symbol: String {
        switch self {
        case .chapterCompleted: "book.pages"
        case .quizWin: "trophy"
        case .reaction: "hands.clap"
        case .eventRSVP: "calendar.badge.checkmark"
        case .joined: "person.badge.plus"
        case .buddyReadStarted: "person.2"
        case .eventCreated: "calendar.badge.plus"
        }
    }
}

struct ActivityFeedItem: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var memberID: UUID
    var kind: ActivityKind
    var message: String
    var timestamp: Date
    var reactionCount: Int = 0
    var viewerReacted: Bool = false
}

struct LeaderboardEntry: Codable, Identifiable, Hashable, Sendable {
    var id: UUID { memberID }
    var memberID: UUID
    var displayName: String
    var avatarSeed: Int
    var points: Int
    var rank: Int
    var isCurrentUser: Bool
}

enum Initials {
    static func from(_ name: String) -> String {
        let parts = name.split(whereSeparator: { $0 == " " || $0 == "-" }).prefix(2)
        let letters = parts.compactMap { $0.first.map { String($0).uppercased() } }
        return letters.isEmpty ? "?" : letters.joined()
    }
}
