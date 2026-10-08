// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var model = HomeViewModel()
    @State private var showCustomize = false
    @State private var isWiggling = false

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    HomeHeader(profile: appState.profile)
                    content
                    Text("All books shown are fictional demo titles.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
            }
            .refreshable { await model.load(services: services) }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        isWiggling = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                            showCustomize = true
                        }
                    }
            )

            if showCustomize {
                CustomizeOverlay(isPresented: $showCustomize)
            }
        }
        .onChange(of: showCustomize) { _, isShowing in
            if !isShowing { isWiggling = false }
        }
        .navigationTitle("Home")
        .toolbar(.hidden, for: .navigationBar)
        .task(id: router.dataVersion) {
            await model.load(services: services)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            VStack(spacing: Theme.Spacing.lg) {
                LoadingCard(label: "Loading your current book", lines: 4)
                LoadingCard(label: "Loading Pip's nudge", lines: 2)
                LoadingCard(label: "Loading your squad", lines: 3)
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await model.load(services: services) }
            }
        case .loaded(let content):
            loaded(content)
        }
    }

    @ViewBuilder
    private func loaded(_ content: HomeViewModel.Content) -> some View {
        // ── Digital Library welcome + personal spine shelf ──────────────
        DigitalLibraryWelcome()
        PersonalSpineShelf(content: content, isWiggling: isWiggling) { book in
            router.push(.bookDetail(book.id), in: .home)
        }
        // ── Current book card ────────────────────────────────────────────
        if let current = content.current {
            CurrentBookCard(item: current) {
                router.push(.bookDetail(current.book.id), in: .home)
            }
        } else {
            EmptyStateView(
                systemImage: "book.closed",
                title: "No book in progress",
                message: "Pick something from your library to get started.",
                actionTitle: "Open Library"
            ) {
                router.select(.library)
            }
            .bbCard()
        }

        let nudge = PipNudgeBuilder.nudge(
            profile: appState.profile,
            current: content.current,
            event: content.event,
            refresh: content.refresh,
            permissions: appState.pipPermissions
        )
        PipNudgeCard(nudge: nudge) {
            router.present(.pip(bookID: nil))
        }

        if let event = content.event {
            UpcomingEventCard(
                event: event,
                attendees: event.rsvpMemberIDs.compactMap { content.member(for: $0) },
                isAttending: model.isAttending(appState.profile),
                isUpdating: model.isUpdatingRSVP,
                onRSVP: { Task { await model.toggleRSVP(profile: appState.profile, services: services) } },
                onOpen: { router.push(.eventDetail(event.id), in: .home) }
            )
        }

        if let refresh = content.refresh {
            MemoryRefreshCard(
                item: refresh,
                phase: model.refreshPhase,
                onStart: { model.startRefresh() },
                onAnswer: { index in Task { await model.answerRefresh(index, services: services) } },
                onNext: { Task { await model.nextRefresh(services: services) } }
            )
        }

        MemoryGardenTeaser {
            router.select(.play)
        }

        QuickActionsRow(
            onQuiz: { router.select(.play) },
            onCreateEvent: { router.present(.createEvent(nil)) },
            onAskPip: { router.present(.pip(bookID: nil)) }
        )

        SquadActivityCard(
            squad: content.squad,
            items: content.activity,
            member: { content.member(for: $0) },
            onSeeAll: { router.select(.squad) }
        )
    }
}

// MARK: - Header

private struct HomeHeader: View {
    let profile: UserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .textCase(.uppercase)
                Text("\(HomeViewModel.greeting()), \(profile?.firstName ?? "reader")")
                    .font(.bbDisplay)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.sm) { pills }
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) { pills }
            }
        }
    }

    @ViewBuilder
    private var pills: some View {
        let streak = profile?.currentStreakDays ?? 0
        StatPill(value: "\(streak)", label: "day streak", systemImage: "flame.fill")
        StatPill(value: "\(profile?.squadPoints ?? 0)", label: "squad points", systemImage: "star.fill", tint: Theme.Palette.lavender)
    }
}

#Preview("Home") {
    NavigationStack {
        HomeView()
    }
    .withPreviewEnvironment()
}

#Preview("Home – loading error") {
    NavigationStack {
        HomeView()
    }
    // Inner environment wins, so this failing service overrides the preview default.
    .environment(\.services, AppServices.preview(profile: PreviewFixtures.profile, failing: true))
    .withPreviewEnvironment()
}
