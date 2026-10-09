// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import UserNotifications

struct PlayView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var model = PlayViewModel()

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Text("Grow your memory garden, quiz yourself, and stay sharp.")
                        .font(.bbBody)
                        .foregroundStyle(Theme.Palette.parchmentMuted)

                    switch model.state {
                    case .idle, .loading:
                        LoadingCard(label: "Loading leaderboard", lines: 4)
                        LoadingCard(label: "Loading Memory Garden", lines: 3)
                    case .failed(let message):
                        ErrorStateView(message: message) {
                            Task { await model.load(services: services) }
                        }
                    case .loaded(let content):
                        LeaderboardCard(entries: content.leaderboard)
                        quizModes
                        gardenSection(content)
                    }

                    RefreshScheduleCard()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .refreshable { await model.load(services: services) }
        }
        .navigationTitle("Garden")
        .task(id: router.dataVersion) {
            await model.load(services: services)
        }
        .sheet(item: $model.refreshingBook) { book in
            GardenRefreshSheet(book: book)
        }
    }

    // MARK: Quiz modes

    private var modeColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.md), count: count)
    }

    private var quizModes: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Quiz modes")
            LazyVGrid(columns: modeColumns, spacing: Theme.Spacing.md) {
                ForEach(QuizMode.allCases) { mode in
                    let availability = model.availability(of: mode)
                    Button {
                        if case .playable(let bookID) = availability {
                            router.push(.quiz(bookID: bookID, mode: mode), in: .play)
                        }
                    } label: {
                        QuizModeTile(mode: mode, isPlayable: availability != .comingSoon)
                    }
                    .buttonStyle(.plain)
                    .disabled(availability == .comingSoon)
                }
            }
        }
    }

    // MARK: Garden

    private func gardenSection(_ content: PlayViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(
                title: "Memory Garden",
                subtitle: "Books you still remember. Tap one to refresh it."
            )
            if content.garden.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "Nothing planted yet", message: "Finish a book and it will sprout here.")
                    .bbCard()
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    StatPill(value: "\(content.garden.count)", label: "books", systemImage: "leaf.fill", tint: Theme.Palette.forestBright)
                    StatPill(
                        value: Int((model.averageStrength * 100).rounded()).formatted(.percent),
                        label: "avg. memory",
                        systemImage: "brain.head.profile",
                        tint: Theme.Palette.lavender
                    )
                }
                MemoryGardenView(entries: model.visibleGarden) { entry in
                    model.refreshingBook = entry.book
                }
                if model.hiddenGardenCount > 0 || model.showsFullGarden {
                    SecondaryButton(
                        title: model.showsFullGarden ? "Show fewer" : "Show all \(content.garden.count) books",
                        systemImage: model.showsFullGarden ? "chevron.up" : "chevron.down"
                    ) {
                        model.showsFullGarden.toggle()
                    }
                }
            }
        }
    }
}

// MARK: - Leaderboard

struct LeaderboardCard: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Weekly leaderboard", subtitle: "Midnight Margins · resets Monday")
            VStack(spacing: 0) {
                ForEach(entries.prefix(6)) { entry in
                    HStack(spacing: Theme.Spacing.md) {
                        Text("\(entry.rank)")
                            .font(.bbHeadline)
                            .foregroundStyle(entry.rank == 1 ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                            .frame(minWidth: 24)
                        MemberAvatar(name: entry.displayName, seed: entry.avatarSeed, size: 34, isCurrentUser: entry.isCurrentUser)
                            .accessibilityHidden(true)
                        Text(entry.isCurrentUser ? "You" : entry.displayName)
                            .font(entry.isCurrentUser ? .bbHeadline : .bbBody)
                            .foregroundStyle(Theme.Palette.parchment)
                        Spacer(minLength: Theme.Spacing.sm)
                        if entry.rank == 1 {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Theme.Palette.gold)
                                .accessibilityHidden(true)
                        }
                        Text("\(entry.points) pts")
                            .font(.bbCallout.monospacedDigit())
                            .foregroundStyle(Theme.Palette.parchment)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                            .fill(entry.isCurrentUser ? Theme.Palette.inkHighlight : Color.clear)
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Rank \(entry.rank), \(entry.isCurrentUser ? "you" : entry.displayName), \(entry.points) points")
                }
            }
            .bbCard(padding: Theme.Spacing.md)
        }
    }
}

private struct QuizModeTile: View {
    let mode: QuizMode
    let isPlayable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: mode.symbol)
                    .font(.title3)
                    .foregroundStyle(isPlayable ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
                Spacer()
                Text(isPlayable ? "Play" : "Soon")
                    .font(.bbCaption)
                    .foregroundStyle(isPlayable ? Theme.Palette.ink : Theme.Palette.parchmentMuted)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(isPlayable ? Theme.Palette.gold : Theme.Palette.inkHighlight))
            }
            Text(mode.displayName)
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.parchment)
            Text(mode.blurb)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.Palette.inkRaised)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(isPlayable ? Theme.Palette.gold.opacity(0.4) : Theme.Palette.hairline, lineWidth: 1)
        )
        .opacity(isPlayable ? 1 : 0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mode.displayName). \(mode.blurb)")
        .accessibilityValue(isPlayable ? "Ready to play" : "Coming soon")
    }
}

// MARK: - Reminder settings (placeholder)

struct RefreshScheduleCard: View {
    @AppStorage(StorageKeys.refreshReminderEnabled) private var isEnabled = false
    @AppStorage(StorageKeys.refreshReminderHour) private var hour = 19
    @State private var authorizationDenied = false

    private func label(for hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Schedule memory refresh")
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Toggle(isOn: $isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily refresh reminder")
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text("One quick question a day keeps finished books fresh.")
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(Theme.Palette.gold)
                .onChange(of: isEnabled) { _, newValue in
                    authorizationDenied = false
                    if newValue {
                        Task { await requestAndSchedule() }
                    } else {
                        cancelNotification()
                    }
                }

                if isEnabled {
                    Picker("Reminder time", selection: $hour) {
                        ForEach(6...22, id: \.self) { value in
                            Text(label(for: value)).tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.Palette.gold)
                    .onChange(of: hour) { _, _ in
                        Task { await scheduleNotification() }
                    }
                }

                if authorizationDenied {
                    Label("Enable notifications in Settings → Bookmark Buddy to receive daily reminders.", systemImage: "bell.slash")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.danger.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .bbCard()
        }
    }

    private func requestAndSchedule() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else {
            isEnabled = false
            authorizationDenied = true
            return
        }
        await scheduleNotification()
    }

    private func scheduleNotification() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["bb.memoryRefresh"])

        let content = UNMutableNotificationContent()
        content.title = "Memory Refresh"
        content.body = "One quick question keeps your finished books alive. Tap to start."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "bb.memoryRefresh",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["bb.memoryRefresh"])
    }
}

#Preview("Play") {
    NavigationStack {
        PlayView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
