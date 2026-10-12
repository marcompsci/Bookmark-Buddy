// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Product switches for the focused v1: "what are you reading, and do you still remember it?"
/// Flip `socialTabs` back on to restore Squad, Garden (quiz hub) and Explore as tabs —
/// none of their code was removed.
enum AppFeatures {
    /// Squad, Garden (Play) and Explore tabs. Hidden while we test the memory loop with real readers.
    static let socialTabs = false
}
