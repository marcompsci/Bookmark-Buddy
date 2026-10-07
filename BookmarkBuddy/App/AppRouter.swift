// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import Observation

/// Single source of truth for navigation. Views, Pip and App Intents all navigate through here,
/// so no screen needs to know about any other.
@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .home
    var paths: [AppTab: NavigationPath] = [:]
    var sheet: AppSheet?
    /// A consequential action awaiting explicit approval in `ConfirmationSheet`.
    var pendingConfirmation: PendingAction?
    /// Brief, non-blocking feedback after an action completes.
    var toast: Toast?
    /// Guide Me walkthrough state (Phase 8).
    let guide = GuideCoordinator()
    /// Bumped whenever shared data changes, so screens can reload with `.task(id:)`.
    private(set) var dataVersion = 0

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let text: String
        var systemImage: String = "checkmark.circle.fill"
    }

    func dataChanged() {
        dataVersion += 1
    }

    func showToast(_ text: String, systemImage: String = "checkmark.circle.fill") {
        toast = Toast(text: text, systemImage: systemImage)
    }

    /// Clears navigation state, e.g. after deleting all data.
    func reset() {
        selectedTab = .home
        paths = [:]
        sheet = nil
        pendingConfirmation = nil
        guide.end()
    }

    func path(for tab: AppTab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.paths[tab] = $0 }
        )
    }

    func select(_ tab: AppTab, popToRoot: Bool = false) {
        selectedTab = tab
        if popToRoot { paths[tab] = NavigationPath() }
    }

    func push(_ route: AppRoute, in tab: AppTab? = nil) {
        let target = tab ?? selectedTab
        selectedTab = target
        var path = paths[target] ?? NavigationPath()
        path.append(route)
        paths[target] = path
    }

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func requestConfirmation(_ action: PendingAction) {
        pendingConfirmation = action
    }

    func dismissSheet() {
        sheet = nil
    }
}
