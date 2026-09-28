// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Explains exactly what Pip can and cannot access, how to delete data,
/// how to report or block users, and where to find the full privacy policy.
/// TODO(prod): Link to a real hosted privacy policy URL before shipping.
struct PrivacySafetyView: View {
    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    pipAccessSection
                    neverAccessSection
                    deleteDataSection
                    reportBlockSection
                    policySection

                    Text("This screen describes the MVP privacy model. Production implementation requires a full privacy policy, server-side data deletion, and jurisdiction-specific disclosures.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .navigationTitle("Privacy & Safety")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: What Pip can access

    private var pipAccessSection: some View {
        InfoSection(
            icon: "checkmark.shield.fill",
            iconColor: Theme.Palette.forestBright,
            title: "What Pip can access",
            rows: [
                InfoRow(symbol: "book.fill", text: "Your reading progress — which chapter you're on, books you're reading and have finished."),
                InfoRow(symbol: "person.fill", text: "Your profile — name, genres, pace and spoiler preference you set during onboarding."),
                InfoRow(symbol: "person.3.fill", text: "Your squad — members, current group read, upcoming events."),
                InfoRow(symbol: "note.text", text: "Notes and highlights — only when you've allowed it in Privacy settings. You can revoke this at any time."),
                InfoRow(symbol: "calendar", text: "Your upcoming reading events — to help you plan and RSVP.")
            ]
        )
    }

    // MARK: What Pip never accesses

    private var neverAccessSection: some View {
        InfoSection(
            icon: "xmark.shield.fill",
            iconColor: Theme.Palette.danger,
            title: "What Pip never accesses",
            rows: [
                InfoRow(symbol: "camera.fill", text: "Your camera, microphone or photos."),
                InfoRow(symbol: "location.fill", text: "Your location."),
                InfoRow(symbol: "iphone", text: "Other apps on your device."),
                InfoRow(symbol: "antenna.radiowaves.left.and.right", text: "Any data outside this app — Pip is self-contained."),
                InfoRow(symbol: "eye.slash.fill", text: "Your screen outside Bookmark Buddy — no screen recording or monitoring."),
                InfoRow(symbol: "creditcard.fill", text: "Payment or health information.")
            ]
        )
    }

    // MARK: Delete data

    private var deleteDataSection: some View {
        InfoSection(
            icon: "trash.fill",
            iconColor: Theme.Palette.gold,
            title: "How to delete your data",
            rows: [
                InfoRow(symbol: "1.circle.fill", text: "Go to Profile \u{2192} tap Delete all my data."),
                InfoRow(symbol: "2.circle.fill", text: "Confirm in the sheet that appears. All local data — profile, notes, saved moments and settings — is erased."),
                InfoRow(symbol: "3.circle.fill", text: "The app returns to onboarding. Nothing is retained on device.")
            ],
            footnote: "TODO(prod): Production delete must also call an authenticated server-side endpoint that purges all data from backend storage, in compliance with GDPR/CCPA."
        )
    }

    // MARK: Report & block

    private var reportBlockSection: some View {
        InfoSection(
            icon: "exclamationmark.shield.fill",
            iconColor: Theme.Palette.lavender,
            title: "How to report or block a user",
            rows: [
                InfoRow(symbol: "ellipsis.circle.fill", text: "In the Squad tab, tap the ⋯ menu on any activity item to Report or Block."),
                InfoRow(symbol: "hand.raised.fill", text: "Blocking hides that member's activity from your feed and prevents them from inviting you."),
                InfoRow(symbol: "exclamationmark.bubble.fill", text: "Reported content is flagged for review. The member is not told who reported it.")
            ],
            footnote: "TODO(prod): Reports must route to a human moderation queue with SLA, appeal process, and escalation policy."
        )
    }

    // MARK: Policy link

    private var policySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Privacy Policy")
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("A full privacy policy will be published at a dedicated URL before this app is released publicly.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)

                // TODO(prod): Replace with a real URL once the privacy policy is published.
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(Theme.Palette.lavender)
                        .accessibilityHidden(true)
                    Text("privacy.bookmarkbuddy.app (placeholder)")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.lavender)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Privacy policy link — placeholder, not yet live")

                Text("For questions: contact@bookmarkbuddy.app (placeholder)")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            .bbCard()
        }
    }
}

// MARK: - Helpers

private struct InfoRow: Identifiable {
    let id = UUID()
    let symbol: String
    let text: String
}

private struct InfoSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let rows: [InfoRow]
    var footnote: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label(title, systemImage: icon)
                .font(.bbTitle3)
                .foregroundStyle(iconColor)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: row.symbol)
                            .font(.callout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .frame(width: 22)
                            .accessibilityHidden(true)
                        Text(row.text)
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchment)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(Theme.Spacing.md)

                    if index < rows.count - 1 {
                        Divider().background(Theme.Palette.hairline)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.inkRaised)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Palette.hairline, lineWidth: 1))
            )

            if let footnote {
                Text(footnote)
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySafetyView()
    }
    .withPreviewEnvironment()
}
