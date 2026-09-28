// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

struct Achievement: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var detail: String
    var symbol: String
    var earnedAt: Date?

    var isEarned: Bool { earnedAt != nil }
}
