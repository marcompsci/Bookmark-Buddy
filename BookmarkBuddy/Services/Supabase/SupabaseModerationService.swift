// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

/// Reports go to the `content_reports` queue (readable only by the reporter and reviewers);
/// blocks live in `blocked_members` and are enforced server-side by the activity feed's RLS policy.
/// Rate limits (10 reports per hour) are enforced by a database trigger.
struct SupabaseModerationService: ModerationService {

    private let db = SupabaseManager.shared.client

    private var userID: UUID {
        get async throws {
            guard let id = await SupabaseAuthService.shared.currentUserID else {
                throw RepositoryError.notAuthenticated
            }
            return id
        }
    }

    func report(item: ActivityFeedItem, note: String) async throws -> ReportReceipt {
        let uid = try await userID
        struct Insert: Encodable {
            let id: UUID
            let reporterId: UUID
            let itemId: UUID
            let reportedMemberId: UUID
            let note: String
            enum CodingKeys: String, CodingKey {
                case id, note
                case reporterId = "reporter_id"
                case itemId = "item_id"
                case reportedMemberId = "reported_member_id"
            }
        }
        let receipt = ReportReceipt(id: UUID(), submittedAt: .now)
        try await db.from("content_reports").insert(Insert(
            id: receipt.id,
            reporterId: uid,
            itemId: item.id,
            reportedMemberId: item.memberID,
            note: TextSanitizer.clean(note, limit: 500)
        )).execute()
        return receipt
    }

    func block(memberID: UUID) async throws {
        let uid = try await userID
        struct Upsert: Encodable {
            let userId: UUID
            let blockedId: UUID
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case blockedId = "blocked_id"
            }
        }
        try await db.from("blocked_members")
            .upsert(Upsert(userId: uid, blockedId: memberID), onConflict: "user_id,blocked_id")
            .execute()
    }

    func unblock(memberID: UUID) async throws {
        let uid = try await userID
        try await db.from("blocked_members")
            .delete()
            .eq("user_id", value: uid.uuidString)
            .eq("blocked_id", value: memberID.uuidString)
            .execute()
    }

    func blockedMemberIDs() async -> Set<UUID> {
        struct Row: Decodable {
            let blockedId: UUID
            enum CodingKeys: String, CodingKey { case blockedId = "blocked_id" }
        }
        guard let uid = try? await userID else { return [] }
        let rows: [Row]? = try? await db.from("blocked_members")
            .select("blocked_id")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return Set((rows ?? []).map(\.blockedId))
    }
}
