// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

// MARK: - Row types

private struct SquadRow: Codable, Sendable {
    let id: UUID
    let name: String
    let tagline: String
    let currentBookId: UUID?
    enum CodingKeys: String, CodingKey {
        case id, name, tagline
        case currentBookId = "current_book_id"
    }
}

private struct SquadMemberRow: Codable, Sendable {
    let id: UUID
    let squadId: UUID
    let userId: UUID
    let displayName: String
    let avatarSeed: Int
    let weeklyPoints: Int
    let currentChapter: Int?
    enum CodingKeys: String, CodingKey {
        case id, displayName = "display_name"
        case squadId      = "squad_id"
        case userId       = "user_id"
        case avatarSeed   = "avatar_seed"
        case weeklyPoints = "weekly_points"
        case currentChapter = "current_chapter"
    }
}

private struct SupabaseActivityRow: Codable, Sendable {
    let id: UUID
    let squadId: UUID
    let memberId: UUID
    let kind: String
    let message: String
    let timestamp: Date
    let reactionCount: Int
    enum CodingKeys: String, CodingKey {
        case id, kind, message, timestamp
        case squadId      = "squad_id"
        case memberId     = "member_id"
        case reactionCount = "reaction_count"
    }
    var toItem: ActivityFeedItem {
        ActivityFeedItem(
            id: id, memberID: memberId,
            kind: ActivityKind(rawValue: kind) ?? .joined,
            message: message, timestamp: timestamp,
            reactionCount: reactionCount
        )
    }
}

// MARK: - Repository

struct SupabaseSquadRepository: SquadRepository {

    private let db = SupabaseManager.shared.client

    private var userID: UUID {
        get async throws {
            guard let id = await SupabaseAuthService.shared.currentUserID else {
                throw RepositoryError.notAuthenticated
            }
            return id
        }
    }

    func currentSquad() async throws -> ReadingSquad {
        let uid = try await userID

        // Find the first squad this user belongs to.
        let memberRows: [SquadMemberRow] = try await db.from("squad_members")
            .select()
            .eq("user_id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        guard let myMembership = memberRows.first else { throw RepositoryError.notFound }

        // Load the squad record.
        let squadRows: [SquadRow] = try await db.from("squads")
            .select()
            .eq("id", value: myMembership.squadId.uuidString)
            .limit(1)
            .execute()
            .value
        guard let squadRow = squadRows.first else { throw RepositoryError.notFound }

        // Load all members for the squad.
        let allMemberRows: [SquadMemberRow] = try await db.from("squad_members")
            .select()
            .eq("squad_id", value: squadRow.id.uuidString)
            .execute()
            .value
        let members = allMemberRows.map { row in
            SquadMember(
                id: row.userId,
                displayName: row.displayName,
                avatarSeed: row.avatarSeed,
                isCurrentUser: row.userId == uid,
                currentChapter: row.currentChapter,
                weeklyPoints: row.weeklyPoints
            )
        }

        return ReadingSquad(
            id: squadRow.id,
            name: squadRow.name,
            tagline: squadRow.tagline,
            members: members,
            currentBookID: squadRow.currentBookId,
            challenge: nil
        )
    }

    func join(squadID: UUID, as profile: UserProfile) async throws -> ReadingSquad {
        let uid = try await userID
        // weekly_points is left out on purpose: the database only lets award_points() change it.
        struct Insert: Encodable {
            let squadId: UUID; let userId: UUID
            let displayName: String; let avatarSeed: Int
            enum CodingKeys: String, CodingKey {
                case displayName = "display_name"; case avatarSeed = "avatar_seed"
                case squadId = "squad_id"; case userId = "user_id"
            }
        }
        // Stable across launches (hashValue is randomized per process).
        let avatarSeed = Int(uid.uuid.0 % 6)
        try await db.from("squad_members").upsert(Insert(
            squadId: squadID, userId: uid,
            displayName: profile.displayName, avatarSeed: avatarSeed
        ), onConflict: "squad_id,user_id").execute()
        return try await currentSquad()
    }

    func activity(squadID: UUID) async throws -> [ActivityFeedItem] {
        let rows: [SupabaseActivityRow] = try await db.from("activity_feed")
            .select()
            .eq("squad_id", value: squadID.uuidString)
            .order("timestamp", ascending: false)
            .limit(40)
            .execute()
            .value
        return rows.map { $0.toItem }
    }

    func toggleReaction(itemID: UUID) async throws -> ActivityFeedItem {
        // RPC call — increment/decrement reaction_count server-side to prevent race conditions.
        struct Args: Encodable { let item_id: UUID }
        let rows: [SupabaseActivityRow] = try await db.rpc("toggle_reaction", params: Args(item_id: itemID))
            .execute()
            .value
        guard let row = rows.first else { throw RepositoryError.notFound }
        return row.toItem
    }

    func post(_ item: ActivityFeedItem, squadID: UUID) async throws {
        struct Insert: Encodable {
            let id: UUID; let squadId: UUID; let memberId: UUID
            let kind: String; let message: String; let timestamp: Date; let reactionCount: Int
            enum CodingKeys: String, CodingKey {
                case id, kind, message, timestamp
                case squadId      = "squad_id"
                case memberId     = "member_id"
                case reactionCount = "reaction_count"
            }
        }
        try await db.from("activity_feed").insert(Insert(
            id: item.id, squadId: squadID, memberId: item.memberID,
            kind: item.kind.rawValue, message: item.message,
            timestamp: item.timestamp, reactionCount: item.reactionCount
        )).execute()
    }

    func leaderboard(squadID: UUID) async throws -> [LeaderboardEntry] {
        let uid = try await userID
        let rows: [SquadMemberRow] = try await db.from("squad_members")
            .select()
            .eq("squad_id", value: squadID.uuidString)
            .order("weekly_points", ascending: false)
            .execute()
            .value
        return rows.enumerated().map { idx, row in
            LeaderboardEntry(
                memberID: row.userId, displayName: row.displayName,
                avatarSeed: row.avatarSeed, points: row.weeklyPoints,
                rank: idx + 1, isCurrentUser: row.userId == uid
            )
        }
    }

    func awardPoints(_ points: Int, to memberID: UUID) async throws {
        // Server-side RPC: the database only accepts points for the signed-in person,
        // bounded per call and per day, and records each award in points_ledger.
        struct Args: Encodable { let member_id: UUID; let points: Int }
        try await db.rpc("award_points", params: Args(member_id: memberID, points: points)).execute()
    }
}
