// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// In-memory squad data seeded from `DemoData`.
/// TODO(prod): Squad membership, posts and reactions must be authorized server-side
/// (only members can read/post), rate-limited, and routed through moderation.
actor MockSquadRepository: SquadRepository {
    private var squad: ReadingSquad
    private var feed: [ActivityFeedItem]
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.squad = DemoData.squad
        self.feed = DemoData.activity
        self.latency = latency
    }

    func currentSquad() async throws -> ReadingSquad {
        await DemoLatency.pause(latency)
        return squad
    }

    func join(squadID: UUID, as profile: UserProfile) async throws -> ReadingSquad {
        await DemoLatency.pause(latency)
        guard squadID == squad.id else { throw DemoServiceError.notFound }
        if let index = squad.members.firstIndex(where: { $0.id == profile.id }) {
            squad.members[index].displayName = profile.displayName
        } else {
            let me = SquadMember(
                id: profile.id,
                displayName: profile.displayName,
                avatarSeed: 0,
                isCurrentUser: true,
                currentChapter: DemoData.progress.first(where: { $0.bookID == squad.currentBookID })?.currentChapter,
                weeklyPoints: profile.squadPoints
            )
            squad.members.append(me)
            feed.insert(
                ActivityFeedItem(memberID: profile.id, kind: .joined, message: "joined Midnight Margins", timestamp: .now),
                at: 0
            )
        }
        return squad
    }

    func activity(squadID: UUID) async throws -> [ActivityFeedItem] {
        await DemoLatency.pause(latency)
        return feed.sorted { $0.timestamp > $1.timestamp }
    }

    func toggleReaction(itemID: UUID) async throws -> ActivityFeedItem {
        guard let index = feed.firstIndex(where: { $0.id == itemID }) else { throw DemoServiceError.notFound }
        feed[index].viewerReacted.toggle()
        feed[index].reactionCount = max(0, feed[index].reactionCount + (feed[index].viewerReacted ? 1 : -1))
        return feed[index]
    }

    func post(_ item: ActivityFeedItem, squadID: UUID) async throws {
        await DemoLatency.pause(latency)
        // TODO(prod): Run text through ModerationService before it becomes visible to others.
        feed.insert(item, at: 0)
    }

    func leaderboard(squadID: UUID) async throws -> [LeaderboardEntry] {
        await DemoLatency.pause(latency)
        return squad.members
            .sorted { $0.weeklyPoints > $1.weeklyPoints }
            .enumerated()
            .map { offset, member in
                LeaderboardEntry(
                    memberID: member.id,
                    displayName: member.displayName,
                    avatarSeed: member.avatarSeed,
                    points: member.weeklyPoints,
                    rank: offset + 1,
                    isCurrentUser: member.isCurrentUser
                )
            }
    }

    func awardPoints(_ points: Int, to memberID: UUID) async throws {
        guard let index = squad.members.firstIndex(where: { $0.id == memberID }) else { throw DemoServiceError.notFound }
        squad.members[index].weeklyPoints += max(0, points)
    }
}
