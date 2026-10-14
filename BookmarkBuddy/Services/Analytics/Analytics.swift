// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

/// The handful of moments that tell us whether the beta is working.
/// Names are stable — dashboards and SQL queries depend on them.
enum AnalyticsEvent: String, Sendable {
    case appOpened = "app_opened"
    case onboardingCompleted = "onboarding_completed"
    case bookStarted = "book_started"
    case firstRunCompleted = "first_run_completed"
    case reminderScheduled = "reminder_scheduled"
    case refreshAnswered = "refresh_answered"
    case notificationOpened = "notification_opened"
    case feedbackCardTapped = "feedback_card_tapped"
    case shelfOpened = "shelf_opened"
    case crossfallPromoTapped = "crossfall_promo_tapped"
}

/// Fire-and-forget event logging into the Supabase `events` table
/// (see `Docs/supabase_phase11_events.sql`). Never throws, never blocks the UI,
/// and does nothing when signed out or running without Supabase.
/// Only the event name and a few small labels are sent — never notes, answers text or book content.
enum Analytics {
    static func log(_ event: AnalyticsEvent, _ props: [String: String] = [:]) {
        guard SupabaseConfig.isConfigured else { return }
        let version = appVersion
        Task.detached(priority: .utility) {
            guard let uid = await SupabaseAuthService.shared.currentUserID else { return }
            struct Row: Encodable {
                let userId: UUID
                let name: String
                let props: [String: String]
                let appVersion: String
                enum CodingKeys: String, CodingKey {
                    case name, props
                    case userId = "user_id"
                    case appVersion = "app_version"
                }
            }
            _ = try? await SupabaseManager.shared.client
                .from("events")
                .insert(Row(userId: uid, name: event.rawValue, props: props, appVersion: version))
                .execute()
        }
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
