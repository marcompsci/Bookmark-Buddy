// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Dependency container. Views and view models depend on protocols only, so swapping a mock
/// for a production service is a change in exactly one place: `AppServices.live()`.
struct AppServices: Sendable {
    let books: any BookRepository
    let squads: any SquadRepository
    let quizzes: any QuizService
    let summaries: any SummaryService
    let pip: any PipAssistantService
    let events: any EventService
    let privacy: any PrivacySettingsStore
    let profiles: any UserProfileStore
    let moderation: any ModerationService

    /// Live services backed by Supabase. Quiz, summary, Pip, and moderation run locally
    /// since they require no server data. Profile, books, squads, and events hit the database.
    static func live() -> AppServices {
        AppServices(
            books: SupabaseBookRepository(),
            squads: SupabaseSquadRepository(),
            quizzes: MockQuizService(),
            summaries: MockSummaryService(),
            pip: MockPipAssistantService(),
            events: SupabaseEventService(),
            privacy: SupabasePrivacyStore(),
            profiles: SupabaseUserProfileStore(),
            moderation: MockModerationService()
        )
    }

    /// On-device services used when Supabase credentials are not yet configured.
    /// Profile and privacy settings persist locally; books, squads, and events use demo data.
    static func localFallback() -> AppServices {
        AppServices(
            books: MockBookRepository(latency: .milliseconds(300)),
            squads: MockSquadRepository(latency: .milliseconds(300)),
            quizzes: MockQuizService(),
            summaries: MockSummaryService(),
            pip: MockPipAssistantService(),
            events: MockEventService(latency: .milliseconds(300)),
            privacy: LocalPrivacySettingsStore(store: LocalStore()),
            profiles: LocalUserProfileStore(store: LocalStore()),
            moderation: MockModerationService()
        )
    }

    /// Instant, in-memory services for SwiftUI previews. Nothing touches disk.
    static func preview(profile: UserProfile? = nil, failing: Bool = false) -> AppServices {
        AppServices(
            books: MockBookRepository(latency: .zero, shouldFail: failing),
            squads: MockSquadRepository(latency: .zero),
            quizzes: MockQuizService(latency: .zero),
            summaries: MockSummaryService(latency: .zero),
            pip: MockPipAssistantService(latency: .zero),
            events: MockEventService(latency: .zero),
            privacy: LocalPrivacySettingsStore(store: nil),
            profiles: LocalUserProfileStore(store: nil, seed: profile),
            moderation: MockModerationService(latency: .zero)
        )
    }
}

extension EnvironmentValues {
    @Entry var services: AppServices = .preview()
}
