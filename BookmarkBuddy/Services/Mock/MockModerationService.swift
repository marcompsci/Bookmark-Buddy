// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Local-only report/block handling for demo social-safety UI.
///
/// TODO(prod):
/// - Send reports to a server-side moderation queue with reviewer tooling and SLAs.
/// - Enforce blocks server-side (hide content, prevent invites/DMs) — never client-only.
/// - Rate-limit reports to prevent abuse; keep reporter identity confidential.
/// - Add appeal flows and a transparency notice in the privacy policy.
actor MockModerationService: ModerationService {
    private var reports: [ReportReceipt] = []
    private var blocked: Set<UUID> = []
    private let latency: Duration

    init(latency: Duration = .milliseconds(300)) {
        self.latency = latency
    }

    func report(item: ActivityFeedItem, note: String) async throws -> ReportReceipt {
        await DemoLatency.pause(latency)
        let receipt = ReportReceipt(id: UUID(), submittedAt: .now)
        reports.append(receipt)
        return receipt
    }

    func block(memberID: UUID) async throws {
        await DemoLatency.pause(latency)
        blocked.insert(memberID)
    }

    func unblock(memberID: UUID) async throws {
        await DemoLatency.pause(latency)
        blocked.remove(memberID)
    }

    func blockedMemberIDs() async -> Set<UUID> {
        blocked
    }
}
