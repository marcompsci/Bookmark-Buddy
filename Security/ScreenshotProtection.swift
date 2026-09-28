// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - View modifier

/// Blurs the view and shows a lock icon whenever a screenshot is taken.
/// Apply to screens that contain personal reading data or private notes.
private struct ScreenshotProtected: ViewModifier {
    @State private var isObscured = false

    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isObscured ? 24 : 0)
                .animation(.easeInOut(duration: 0.2), value: isObscured)

            if isObscured {
                screenshotOverlay
                    .transition(.opacity)
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.userDidTakeScreenshotNotification
            )
        ) { _ in
            isObscured = true
            // Auto-clear after 3 seconds so the user can keep using the screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isObscured = false
            }
        }
    }

    private var screenshotOverlay: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Palette.gold)
            Text("Screenshot taken")
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
            Text("Your reading data is personal.\nPlease be mindful when sharing.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Palette.inkRaised)
                .shadow(color: .black.opacity(0.4), radius: 20)
        )
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Public API

extension View {
    /// Blurs this view momentarily when the user takes a screenshot.
    /// Use on Profile, Notes, and Privacy screens.
    func screenshotProtected() -> some View {
        modifier(ScreenshotProtected())
    }
}
