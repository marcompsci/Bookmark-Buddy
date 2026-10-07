// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Supabase project credentials.
///
/// HOW TO CONFIGURE:
/// Fill in BookmarkBuddy/Config/SupabaseCredentials.swift with your project URL
/// and anon key from https://app.supabase.com → Settings → API.
/// That file is gitignored so your credentials stay local.
///
/// Env var override (CI / Xcode scheme): SUPABASE_URL, SUPABASE_ANON_KEY
enum SupabaseConfig {
    static let projectURL: String = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_URL"], !env.isEmpty { return env }
        return SupabaseCredentials.projectURL
    }()

    static let anonKey: String = {
        if let env = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !env.isEmpty { return env }
        return SupabaseCredentials.anonKey
    }()

    /// Returns `true` once real credentials are present in SupabaseCredentials.swift.
    static var isConfigured: Bool {
        !projectURL.contains("YOUR_PROJECT_ID") && !anonKey.contains("YOUR_ANON_KEY")
    }

    /// Custom URL scheme for OAuth callbacks. Must match the Supabase Auth dashboard.
    static let oauthRedirectURL = "bookmarkbuddy://auth/callback"
}
