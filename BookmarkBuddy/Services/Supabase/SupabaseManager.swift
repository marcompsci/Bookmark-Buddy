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
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
