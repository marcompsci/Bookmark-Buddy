// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router

    private var profile: UserProfile? { appState.profile }
    private var permissions: PipPermissionSettings { appState.pipPermissions }

    private var finishedBooks: [Book] {
        DemoData.books.filter { book in
            DemoData.progress.first { $0.bookID == book.id }?.state == .finished
        }
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    profileHeader
                    publicShelfSection
                    statsSection
                    achievementsSection
                    pipPrivacySection
                    dangerSection

                    Text("Profile and shelf are stored on this device only in this MVP.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
        }
        .navigationTitle("Profile")
        .toolbar(.hidden, for: .navigationBar)
        .screenshotProtected()
    }

    // MARK: Header

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .center, spacing: Theme.Spacing.lg) {
                MemberAvatar(
                    name: profile?.displayName ?? "Reader",
                    seed: Int(profile?.id.hashValue ?? 0),
                    size: 72,
                    isCurrentUser: true
                )
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(profile?.displayName ?? "Reader")
                        .font(.bbTitle)
                        .foregroundStyle(Theme.Palette.parchment)
                        .accessibilityAddTraits(.isHeader)
                    Text(profile?.favoriteGenres.prefix(2).map(\.displayName).joined(separator: " · ") ?? "")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                    HStack(spacing: Theme.Spacing.sm) {
                        StatPill(value: "\(profile?.currentStreakDays ?? 0)", label: "day streak", systemImage: "flame.fill")
                        StatPill(value: "\(profile?.squadPoints ?? 0)", label: "pts", systemImage: "star.fill", tint: Theme.Palette.lavender)
                    }
                }
                Spacer()
            }

            if let pace = profile?.pace {
                Label(pace.displayName + " reader", systemImage: pace.symbol)
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
        }
        .bbCard()
    }

    // MARK: Public spine shelf

    private var publicShelfSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Your Public Shelf")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Spacer()
                Label("Visible in Explore", systemImage: "eye")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
            }
            .padding(.horizontal, Theme.Spacing.xs)

            BookShelfRow(
                books: finishedBooks,
                emptyMessage: "Finish a book and it will appear on your public shelf."
            ) { _ in }
        }
    }

    // MARK: Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Reading Stats")
            let finished = DemoData.progress.filter { $0.state == .finished }.count
            let totalPages = DemoData.progress.reduce(0) { $0 + $1.pagesRead }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                StatCard(value: "\(finished)", label: "Books finished", icon: "checkmark.seal.fill", tint: Theme.Palette.forestBright)
                StatCard(value: "\(totalPages)", label: "Pages read", icon: "doc.text.fill", tint: Theme.Palette.lavender)
                StatCard(value: "\(profile?.currentStreakDays ?? 0)", label: "Day streak", icon: "flame.fill", tint: Theme.Palette.gold)
                StatCard(value: "\(profile?.squadPoints ?? 0)", label: "Squad points", icon: "star.fill", tint: Theme.Palette.gold)
            }
        }
    }

    // MARK: Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Achievements")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                ForEach(DemoData.achievements) { badge in
                    AchievementBadge(achievement: badge)
                }
            }
        }
    }

    // MARK: Pip privacy

    private var pipPrivacySection: some View {
        @Bindable var appState = appState
        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                SectionHeader(title: "Pip Privacy")
                Spacer()
                Button {
                    router.push(.privacySafety, in: .profile)
                } label: {
                    Label("Details", systemImage: "info.circle")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                }
                .accessibilityLabel("Open Privacy & Safety details")
            }

            VStack(spacing: 0) {
                privacyRow(
                    label: "Reading activity visibility",
                    value: permissions.activityVisibility.displayName,
                    icon: "eye"
                ) {
                    Menu {
                        ForEach(ActivityVisibility.allCases) { vis in
                            Button(vis.displayName) {
                                Task {
                                    await appState.updatePipPermissions { $0.activityVisibility = vis }
                                }
                            }
                        }
                    } label: {
                        Text(permissions.activityVisibility.displayName)
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.gold)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Theme.Palette.gold)
                    }
                }

                Divider().background(Theme.Palette.hairline)

                Toggle(isOn: Binding(
                    get: { permissions.allowReadingProgress },
                    set: { val in Task { await appState.updatePipPermissions { $0.allowReadingProgress = val } } }
                )) {
                    Label("Allow Pip to use reading progress", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchment)
                }
                .tint(Theme.Palette.gold)
                .padding(Theme.Spacing.md)

                Divider().background(Theme.Palette.hairline)

                Toggle(isOn: Binding(
                    get: { permissions.allowsNotes },
                    set: { val in Task { await appState.updatePipPermissions { $0.notesConsent = val ? .always : .denied } } }
                )) {
                    Label("Allow Pip to use notes & highlights", systemImage: "note.text")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchment)
                }
                .tint(Theme.Palette.gold)
                .padding(Theme.Spacing.md)

                Divider().background(Theme.Palette.hairline)

                Button {
                    router.requestConfirmation(.resetPipMemory)
                } label: {
                    Label("Reset Pip's memory", systemImage: "arrow.counterclockwise")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reset Pip's memory — requires confirmation")
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.inkRaised)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Palette.hairline, lineWidth: 1))
            )
        }
    }

    private func privacyRow(label: String, value: String, icon: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
            Spacer()
            trailing()
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: Danger zone

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Data & Account")
            VStack(spacing: 0) {
                Button {
                    router.push(.privacySafety, in: .profile)
                } label: {
                    Label("Privacy & Safety", systemImage: "lock.shield")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchment)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)

                Divider().background(Theme.Palette.hairline)

                Button {
                    router.requestConfirmation(.deleteAllLocalData)
                } label: {
                    Label("Delete all my data", systemImage: "trash")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete all local data — requires confirmation")
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Palette.inkRaised)
                    .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Palette.hairline, lineWidth: 1))
            )
        }
    }
}

// MARK: - Sub-components

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    var tint: Color = Theme.Palette.gold

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.Palette.parchment)
            Text(label)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.inkRaised)
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md).strokeBorder(Theme.Palette.hairline, lineWidth: 1))
        )
        .accessibilityElement(children: .combine)
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(achievement.isEarned ? Theme.Palette.gold.opacity(0.18) : Theme.Palette.inkRaised)
                    .frame(width: 52, height: 52)
                Image(systemName: achievement.symbol)
                    .font(.title2)
                    .foregroundStyle(achievement.isEarned ? Theme.Palette.gold : Theme.Palette.parchmentMuted.opacity(0.4))
                    .accessibilityHidden(true)
            }
            Text(achievement.title)
                .font(.bbCaption)
                .foregroundStyle(achievement.isEarned ? Theme.Palette.parchment : Theme.Palette.parchmentMuted.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(achievement.title): \(achievement.detail). \(achievement.isEarned ? "Earned" : "Not yet earned")")
    }
}

#Preview("Profile") {
    NavigationStack {
        ProfileView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
