// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

@main
struct BookmarkBuddyApp: App {
    @State private var appState: AppState
    @State private var router = AppRouter()
    @State private var customization = LibraryCustomization()

    @State private var securityAlert: String? = nil

    init() {
        let services = SupabaseConfig.isConfigured ? AppServices.live() : AppServices.localFallback()
        _appState = State(initialValue: AppState(services: services))
        SecurityGuard.shared.startScreenshotMonitoring {
            // Global screenshot event — individual screens apply .screenshotProtected()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
                .environment(\.services, appState.services)
                .environment(customization)
                .preferredColorScheme(.dark)
                .tint(Theme.Palette.gold)
                .onAppear {
                    securityAlert = SecurityGuard.shared.auditEnvironment()
                }
                // bookmarkbuddy://auth/callback — email confirmation and password-reset links.
                // Completing the session fires authStateChanges, which RootView turns into sign-in.
                .onOpenURL { url in
                    guard url.scheme == "bookmarkbuddy", SupabaseConfig.isConfigured else { return }
                    Task { try? await SupabaseAuthService.shared.handleOpenURL(url) }
                }
                .alert("Security Warning", isPresented: Binding(
                    get: { securityAlert != nil },
                    set: { if !$0 { securityAlert = nil } }
                )) {
                    Button("OK", role: .cancel) { securityAlert = nil }
                } message: {
                    Text(securityAlert ?? "")
                }
        }
    }
}

/// Decides between launch, onboarding and the main app.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @AppStorage(StorageKeys.hasCompletedOnboarding) private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            switch appState.status {
            case .loading:
                LaunchView()

            case .unauthenticated:
                // Not signed in — show the auth gate.
                AuthView()
                    .transition(.opacity)
                    .task(id: "authWatch") {
                        // Once the user signs in, transition to profile loading.
                        for await (event, _) in await SupabaseManager.shared.client.auth.authStateChanges {
                            if event == .signedIn {
                                await appState.handleSignIn()
                            }
                        }
                    }

            case .ready:
                if hasCompletedOnboarding {
                    RootTabView()
                        .transition(.opacity)
                } else {
                    OnboardingView { hasCompletedOnboarding = true }
                        .transition(.opacity)
                }

            case .missing:
                OnboardingView { hasCompletedOnboarding = true }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.status)
        .task {
            await appState.loadProfile()
        }
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            InkBackground()
            VStack(spacing: Theme.Spacing.lg) {
                PipAvatar(size: 72)
                ProgressView()
                    .tint(Theme.Palette.parchment)
                    .accessibilityLabel("Loading Bookmark Buddy")
            }
        }
    }
}

#Preview("Onboarding") {
    let services = AppServices.preview()
    RootView()
        .environment(AppState(services: services, profile: nil))
        .environment(AppRouter())
        .environment(\.services, services)
        .preferredColorScheme(.dark)
}
