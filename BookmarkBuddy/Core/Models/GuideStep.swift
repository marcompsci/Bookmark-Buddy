// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Identifies a view that Guide Me can highlight. Views opt in with `.guideAnchor(_:)` (Phase 8).
enum GuideTarget: String, Codable, Hashable, Sendable {
    case squadTab, createEventButton, eventTypeTrivia, eventDatePicker, eventConfirmButton, pipButton
}

struct GuideStep: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var target: GuideTarget
    var title: String
    var message: String
}

struct GuideWalkthrough: Codable, Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var steps: [GuideStep]
}
