// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import StoreKit
import SwiftUI

/// "Bite will ask you tomorrow" — keeps the first-run promise visible on Today.
struct RefreshPromiseCard: View {
    let title: String
    let date: Date

    private var when: String {
        let time = date.formatted(date: .omitted, time: .shortened)
        return Calendar.current.isDateInTomorrow(date) ? "tomorrow at \(time)" : date.formatted(.dateTime.weekday(.wide).hour().minute())
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            PipAvatar(size: 44, mood: .happy, animated: false)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your first question is coming")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Text("\(PipIdentity.name) will ask you about “\(title)” \(when).")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .bbCard()
        .accessibilityElement(children: .combine)
    }
}

/// Beta-only: tells testers how to send feedback that lands in TestFlight.
struct BetaFeedbackCard: View {
    @AppStorage(StorageKeys.feedbackCardDismissed) private var dismissed = false
    @Environment(\.openURL) private var openURL

    /// Shown for TestFlight installs (sandbox environment) and debug builds only.
    @State private var isBetaBuild: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()

    var body: some View {
        Group {
        if isBetaBuild && !dismissed {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .top) {
                    Label("Help shape Bookmark Buddy", systemImage: "bubble.left.and.text.bubble.right.fill")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.gold)
                    Spacer()
                    Button {
                        dismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Hide feedback tips")
                }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    tip("camera.viewfinder", "Take a screenshot of anything confusing or broken — TestFlight lets you send it with a note.")
                    tip("heart.text.square", "Loved something? Screenshot that too. It tells us what to keep.")
                    tip("exclamationmark.triangle", "If the app crashes, say yes when TestFlight asks to send a report.")
                }
                SecondaryButton(title: "Send written feedback", systemImage: "paperplane.fill") {
                    Analytics.log(.feedbackCardTapped)
                    // Opens the TestFlight app, where "Send Beta Feedback" lives.
                    if let url = URL(string: "itms-beta://") { openURL(url) }
                }
            }
            .bbCard()
        }
        }
        .task {
            guard !isBetaBuild, let result = try? await AppTransaction.shared,
                  case .verified(let transaction) = result else { return }
            isBetaBuild = transaction.environment == .sandbox
        }
    }

    private func tip(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol).foregroundStyle(Theme.Palette.lavender)
        }
    }
}
