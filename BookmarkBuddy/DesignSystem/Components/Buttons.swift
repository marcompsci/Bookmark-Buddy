// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Gold, high-contrast call to action. Minimum 44pt tall.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    var fullWidth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(Theme.Palette.ink)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: Theme.minTapTarget)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
    }
}

/// Outlined secondary action.
struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    var fullWidth = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: Theme.minTapTarget)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bbHeadline)
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(Theme.Palette.gold.opacity(isEnabled ? 1 : 0.45))
            )
            .contentShape(Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bbHeadline)
            .foregroundStyle(Theme.Palette.parchment.opacity(isEnabled ? 1 : 0.5))
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? Theme.Palette.inkHighlight : Color.clear)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Theme.Palette.lavender.opacity(isEnabled ? 0.8 : 0.3), lineWidth: 1.5)
            )
            .contentShape(Capsule(style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A selectable card used for single/multi choice (genres, pace, spoiler level, event type).
/// Exposes the `.isSelected` trait to VoiceOver.
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    var accessibilityHint: String = "Double-tap to select."
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                content()
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(isSelected ? Theme.Palette.inkHighlight : Theme.Palette.inkRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(isSelected ? Theme.Palette.gold : Theme.Palette.hairline, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityHint(accessibilityHint)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", systemImage: "arrow.right") {}
        PrimaryButton(title: "Saving", isLoading: true) {}
        SecondaryButton(title: "Back") {}
        SelectableCard(isSelected: true, action: {}) {
            Text("Steady").foregroundStyle(Theme.Palette.parchment)
        }
    }
    .padding()
    .background(InkBackground())
}
