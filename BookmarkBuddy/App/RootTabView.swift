// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import UIKit

/// Main six-tab shell. Hosts every tab's NavigationStack, app-wide sheets,
/// the shared confirmation gate, toasts, and the floating Pip button.
struct RootTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.services) private var services

    var body: some View {
        @Bindable var router = router
        ZStack {
            TabView(selection: $router.selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Tab(tab.title, systemImage: tab.symbol, value: tab) {
                        NavigationStack(path: router.path(for: tab)) {
                            TabRootView(tab: tab)
                                .navigationDestination(for: AppRoute.self) { route in
                                    RouteDestinationView(route: route)
                                }
                        }
                    }
                }
            }
            .toolbarBackground(Theme.Palette.inkRaised, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)

            // Floating Pip button — lives above all tab content, below sheets.
            PipFloatingButton()
                .ignoresSafeArea()
                .allowsHitTesting(true)
        }
        .sheet(item: $router.sheet) { sheet in
            AppSheetView(sheet: sheet)
        }
        .confirmationGate($router.pendingConfirmation) { action in
            await ActionPerformer(services: services, appState: appState, router: router).perform(action)
        }
        .overlay(alignment: .top) {
            ToastOverlay()
        }
    }
}

/// Root screen for each tab.
private struct TabRootView: View {
    let tab: AppTab

    var body: some View {
        switch tab {
        case .home:
            HomeView()
        case .squad:
            SquadView()
        case .play:
            PlayView()
        case .library:
            LibraryView()
        case .explore:
            ExploreView()
        case .profile:
            ProfileView()
        }
    }
}

/// Push destinations.
struct RouteDestinationView: View {
    let route: AppRoute

    var body: some View {
        switch route {
        case .bookDetail(let bookID):
            BookDetailView(bookID: bookID)
        case .quiz(let bookID, let mode):
            QuizFlowView(bookID: bookID, mode: mode)
        case .eventDetail(let eventID):
            EventDetailView(eventID: eventID)
        case .privacySafety:
            PrivacySafetyView()
        case .userPublicShelf(let user):
            UserPublicShelfView(user: user)
        case .recommendedShelf:
            RecommendedShelfView()
        }
    }
}

/// App-wide modal flows.
struct AppSheetView: View {
    let sheet: AppSheet
    @Environment(AppRouter.self) private var router

    var body: some View {
        switch sheet {
        case .createEvent(let type):
            NavigationStack {
                CreateEventFlow(initialType: type)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { router.dismissSheet() }
                        }
                    }
            }
            .presentationDragIndicator(.visible)

        case .buddyRead(let bookID):
            NavigationStack {
                BuddyReadFlow(bookID: bookID)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { router.dismissSheet() }
                        }
                    }
            }
            .presentationDragIndicator(.visible)

        case .pip(let bookID):
            PipChatSheet(bookID: bookID)

        case .recommendBook:
            NavigationStack {
                RecommendBookFlow()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { router.dismissSheet() }
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
    }
}

struct ComingSoonView: View {
    let title: String
    let phase: Int
    let systemImage: String

    var body: some View {
        ZStack {
            InkBackground()
            EmptyStateView(
                systemImage: systemImage,
                title: title,
                message: "This screen arrives in Phase \(phase) of the build."
            )
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Top banner that confirms completed actions and announces them to VoiceOver.
private struct ToastOverlay: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if let toast = router.toast {
                Label(toast.text, systemImage: toast.systemImage)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.ink)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Capsule().fill(Theme.Palette.parchment))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.sm)
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .onTapGesture { router.toast = nil }
                    .accessibilityAddTraits(.isStaticText)
                    .task(id: toast.id) {
                        UIAccessibility.post(notification: .announcement, argument: toast.text)
                        try? await Task.sleep(for: .seconds(2.5))
                        if router.toast?.id == toast.id {
                            router.toast = nil
                        }
                    }
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: router.toast)
    }
}

#Preview {
    RootTabView()
        .withPreviewEnvironment()
}
