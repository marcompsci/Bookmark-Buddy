// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Shared fixtures for SwiftUI previews. Everything is in-memory with zero latency.
enum PreviewFixtures {
    static let profile = UserProfile(
        id: DemoData.id(900),
        displayName: "Riley Morgan",
        favoriteGenres: [.mystery, .sciFi, .biography],
        booksPerMonth: 3,
        pace: .steady,
        spoilerLevel: .currentChapter,
        currentStreakDays: 12,
        squadPoints: 320,
        joinedSquadIDs: [DemoData.IDs.midnightMargins]
    )

    static var services: AppServices { AppServices.preview(profile: profile) }

    @MainActor static var appState: AppState { AppState(services: services, profile: profile) }

    @MainActor static var router: AppRouter { AppRouter() }

    static var glassHarbor: Book? {
        DemoData.books.first { $0.id == DemoData.IDs.glassHarbor }
    }
}

extension View {
    /// Injects preview app state, router and services in one call.
    @MainActor
    func withPreviewEnvironment(profile: UserProfile? = PreviewFixtures.profile) -> some View {
        let services = AppServices.preview(profile: profile)
        return self
            .environment(AppState(services: services, profile: profile))
            .environment(AppRouter())
            .environment(\.services, services)
            .environment(LibraryCustomization())
            .preferredColorScheme(.dark)
    }
}
