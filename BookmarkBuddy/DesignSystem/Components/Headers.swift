// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bbTitle3)
                    .foregroundStyle(Theme.Palette.parchment)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            Spacer(minLength: Theme.Spacing.sm)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.gold)
                    .frame(minHeight: Theme.minTapTarget)
            }
        }
    }
}

/// Small pill showing a stat, e.g. "🔥 12-day streak".
struct StatPill: View {
    let value: String
    let label: String
    var systemImage: String?
    var tint: Color = Theme.Palette.gold

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
            Text(label)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Capsule().fill(Theme.Palette.inkHighlight))
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

/// Labels anything produced by mock AI so it's never mistaken for real, sourced content.
struct DemoContentBadge: View {
    var text: String = "Demo AI summary"

    var body: some View {
        Label(text, systemImage: "sparkles")
            .font(.bbCaption)
            .foregroundStyle(Theme.Palette.lavender)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Capsule().fill(Theme.Palette.lavender.opacity(0.14)))
    }
}

/// Linear progress bar with an accessible percentage value.
struct ReadingProgressBar: View {
    let fraction: Double
    var tint: Color = Theme.Palette.gold
    var height: CGFloat = 8
    var label: String = "Reading progress"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.parchment.opacity(0.12))
                Capsule()
                    .fill(tint)
                    .frame(width: max(height, proxy.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(Text(min(1, max(0, fraction)), format: .percent.precision(.fractionLength(0))))
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeader(title: "Your squad", subtitle: "Midnight Margins", actionTitle: "See all") {}
        HStack {
            StatPill(value: "12", label: "day streak", systemImage: "flame.fill")
            StatPill(value: "86%", label: "accuracy", systemImage: "target", tint: Theme.Palette.forestBright)
        }
        DemoContentBadge()
        ReadingProgressBar(fraction: 0.42)
    }
    .padding()
    .background(InkBackground())
}
