// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

/// Shared Supabase client. All service implementations pull from this singleton.
final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.projectURL)!,
            supabaseKey: SupabaseConfig.anonKey,
            options: SupabaseClientOptions(
                // Opt in to the new initial-session behavior (supabase-swift PR #822).
                // `client.auth.session` still refreshes an expired session before returning it.
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
