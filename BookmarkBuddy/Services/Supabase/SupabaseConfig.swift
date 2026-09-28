// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Supabase project credentials.
///
/// HOW TO CONFIGURE:
/// 1. Go to https://app.supabase.com → your project → Settings → API
/// 2. In Xcode: Edit Scheme → Run → Environment Variables, add:
///      SUPABASE_URL      = https://xxxxxxxxxxxx.supabase.co
///      SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
///
/// Never hard-code these values or commit them to git.
enum SupabaseConfig {
    static let projectURL: String = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"], !env.isEmpty {
            return env
        }
        return "https://YOUR_PROJECT_ID.supabase.co"
    }()

    static let anonKey: String = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !env.isEmpty {
            return env
        }
        return "YOUR_ANON_KEY"
    }()

    /// Returns `true` once the developer has filled in real credentials.
    static var isConfigured: Bool {
        !projectURL.contains("YOUR_PROJECT_ID") && !anonKey.contains("YOUR_ANON_KEY")
    }

    /// Custom URL scheme registered in Info.plist for OAuth callbacks (Apple / Google).
    /// Must match the redirect URL configured in the Supabase Auth dashboard.
    static let oauthRedirectURL = "bookmarkbuddy://auth/callback"
}
