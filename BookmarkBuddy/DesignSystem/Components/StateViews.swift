// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.Palette.lavender)
                .accessibilityHidden(true)
            Text(title)
                .font(.bbTitle3)
                .foregroundStyle(Theme.Palette.parchment)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                SecondaryButton(title: actionTitle, fullWidth: false, action: action)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}

/// Placeholder card shown while content loads.
struct LoadingCard: View {
    var label: String = "Loading"
    var lines = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.Palette.parchment.opacity(0.10))
                    .frame(height: index == 0 ? 20 : 14)
                    .frame(maxWidth: index == lines - 1 ? CGFloat(180) : CGFloat.infinity, alignment: .leading)
            }
        }
        .bbCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        EmptyStateView(
            systemImage: "exclamationmark.triangle",
            title: "Hmm, that didn't load",
            message: message,
            actionTitle: "Try again",
            action: retry
        )
        .bbCard()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LoadingCard()
            EmptyStateView(systemImage: "books.vertical", title: "No saved moments", message: "Save a moment from any book to see it here.", actionTitle: "Browse library") {}
            ErrorStateView(message: "Check your connection and try again.") {}
        }
        .padding()
    }
    .background(InkBackground())
}
