// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// The first tab in v1. Three questions, top to bottom:
/// 1. What are you reading?  2. Do you still remember it?  3. What's your garden look like?
/// Plus a quiet invitation to share your shelf.
struct TodayView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var model = TodayViewModel()
    @State private var showsBiteIntro = false

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                    if model.hasLoaded {
                        readingSection
                        if FirstRefreshPromise.isUpcoming, let title = FirstRefreshPromise.title, let date = FirstRefreshPromise.date {
                            RefreshPromiseCard(title: title, date: date)
                        }
                        rememberSection
                        gardenSection
                        RefreshScheduleCard()
                        shareSection
                        BetaFeedbackCard()
                    } else {
                        LoadingCard(label: "Loading your current book", lines: 3)
                        LoadingCard(label: "Loading today's question", lines: 4)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .refreshable { await model.load(services: services) }
        }
        .navigationTitle("Today")
        .toolbar(.hidden, for: .navigationBar)
        .task(id: router.dataVersion) {
            await model.load(services: services)
            if !UserDefaults.standard.bool(forKey: StorageKeys.biteIntroDone) { showsBiteIntro = true }
        }
        .sheet(isPresented: $showsBiteIntro) {
            BiteIntroSheet(currentBook: model.current?.book) {
                router.dataChanged()
            }
        }
        .onChange(of: RefreshNotifier.shared.openRefreshRequest) {
            // Tapped a refresh notification: reload so the due question is on screen, then open it.
            Task {
                await model.load(services: services)
                if model.refresh != nil { model.startRefresh() }
            }
        }
        .sheet(item: $model.refreshingBook) { book in
            GardenRefreshSheet(book: book)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .textCase(.uppercase)
            Text("\(HomeViewModel.greeting()), \(appState.profile?.firstName ?? "reader")")
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let streak = appState.profile?.currentStreakDays, streak > 0 {
                StatPill(value: "\(streak)", label: "day streak", systemImage: "flame.fill")
            }
        }
    }

    // MARK: 1. What are you reading?

    @ViewBuilder
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "What are you reading?")
            if let current = model.current {
                CurrentBookCard(item: current) {
                    router.push(.bookDetail(current.book.id), in: .home)
                }
            } else {
                EmptyStateView(
                    systemImage: "book.closed",
                    title: "Nothing in progress",
                    message: "Pick a book from your library and mark it as reading.",
                    actionTitle: "Open Library"
                ) {
                    router.select(.library)
                }
                .bbCard()
            }
        }
    }

    // MARK: 2. Do you still remember it?

    @ViewBuilder
    private var rememberSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Do you still remember it?", subtitle: "One question a day keeps a book from fading.")
            if let refresh = model.refresh {
                MemoryRefreshCard(
                    item: refresh,
                    phase: model.refreshPhase,
                    onStart: { model.startRefresh() },
                    onAnswer: { index in Task { await model.answerRefresh(index, services: services) } },
                    onNext: { Task { await model.nextRefresh(services: services) } }
                )
            } else {
                EmptyStateView(
                    systemImage: "brain.head.profile",
                    title: "No question yet",
                    message: "Finish a book and questions about it will show up here."
                )
                .bbCard()
            }
        }
    }

    // MARK: 3. Memory Garden

    @ViewBuilder
    private var gardenSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Memory Garden", subtitle: "Books you still remember. Tap one to refresh it.")
            if model.garden.isEmpty {
                EmptyStateView(systemImage: "leaf", title: "Nothing planted yet", message: "Finish a book and it will sprout here.")
                    .bbCard()
            } else {
                HStack(spacing: Theme.Spacing.sm) {
                    StatPill(value: "\(model.garden.count)", label: "books", systemImage: "leaf.fill", tint: Theme.Palette.forestBright)
                    StatPill(
                        value: Int((model.averageStrength * 100).rounded()).formatted(.percent),
                        label: "avg. memory",
                        systemImage: "brain.head.profile",
                        tint: Theme.Palette.lavender
                    )
                }
                if let weakest = model.weakest, weakest.strength < 0.6 {
                    SecondaryButton(title: "Refresh \(weakest.book.title)", systemImage: "arrow.clockwise") {
                        model.refreshingBook = weakest.book
                    }
                }
                MemoryGardenView(entries: model.visibleGarden) { entry in
                    model.refreshingBook = entry.book
                }
                if model.hiddenGardenCount > 0 || model.showsFullGarden {
                    SecondaryButton(
                        title: model.showsFullGarden ? "Show fewer" : "Show all \(model.garden.count) books",
                        systemImage: model.showsFullGarden ? "chevron.up" : "chevron.down"
                    ) {
                        model.showsFullGarden.toggle()
                    }
                }
            }
        }
    }

    // MARK: Share your shelf

    private var shareSection: some View {
        Button {
            Analytics.log(.shelfOpened)
            router.push(.myShelf, in: .home)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "square.and.arrow.up.on.square.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Palette.gold)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.shelf == nil ? "Make your shelf" : "Your shelf")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                    Text(shareSubtitle)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
            }
            .bbCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var shareSubtitle: String {
        guard let shelf = model.shelf else {
            return "Put the books that shaped you on a shelf and share it — like Omari's Digital Library."
        }
        let count = shelf.entries.count
        let books = count == 1 ? "1 book" : "\(count) books"
        return shelf.shelf.isPublic ? "@\(shelf.shelf.handle) · \(books) · public" : "\(books) · private"
    }
}

#Preview {
    NavigationStack { TodayView() }
        .withPreviewEnvironment()
}
