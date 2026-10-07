// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Identifies a view that Guide Me can highlight. Views opt in with `.guideAnchor(_:)`.
enum GuideTarget: String, Codable, Hashable, Sendable {
    case squadTab, createEventButton, eventTypeTrivia, eventDatePicker, eventConfirmButton, pipButton

    /// Steps shown inside the Create Event sheet rather than on the main screen.
    var isInEventPlanner: Bool {
        switch self {
        case .eventTypeTrivia, .eventDatePicker, .eventConfirmButton: true
        default: false
        }
    }
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
