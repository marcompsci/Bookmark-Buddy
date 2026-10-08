// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Public links shown in the app. Set these before submitting to the App Store —
/// Apple requires a reachable privacy policy URL.
enum AppLinks {
    /// Your hosted privacy policy. `nil` shows a "coming soon" note instead of a link.
    static let privacyPolicy: URL? = nil
    /// Support contact shown on Privacy & Safety.
    static let supportEmail: String? = nil
}
