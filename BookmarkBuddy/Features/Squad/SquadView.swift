// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct SquadView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var model = SquadViewModel()
    @State private var reportingItem: ActivityFeedItem?

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    switch model.state {
                    case .idle, .loading:
                        LoadingCard(label: "Loading your squad", lines: 4)
                        LoadingCard(label: "Loading activity", lines: 3)
                    case .failed(let message):
                        ErrorStateView(message: message) {
                            Task { await model.load(services: services) }
                        }
                    case .loaded(let content):
                        SquadHeaderCard(squad: content.squad, blocked: content.blocked) { member in
                            router.requestConfirmation(.blockMember(member))
                        }
                        actionButtons
                        if let challenge = content.squad.challenge {
                            ChallengeCard(challenge: challenge)
                        }
                        if let book = content.currentBook {
                            SharedReadCard(book: book, members: content.memberProgress)
                        }
                        eventsSection(content)
                        feedSection(content)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .refreshable { await model.load(services: services) }
        }
        .navigationTitle("Squad")
        .task(id: router.dataVersion) {
            await model.load(services: services)
        }
        .sheet(item: $reportingItem) { item in
            ReportSheet(item: item, memberName: model.content?.member(for: item.memberID)?.displayName ?? "this member")
        }
    }

    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.sm) { buttons }
            VStack(spacing: Theme.Spacing.sm) { buttons }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        PrimaryButton(title: "Create an Event", systemImage: "calendar.badge.plus") {
            router.present(.createEvent(nil))
        }
        .guideAnchor(.createEventButton)
        SecondaryButton(title: "Start a Buddy Read", systemImage: "person.2.fill") {
            router.present(.buddyRead(bookID: nil))
        }
    }

    // MARK: Events

    private func eventsSection(_ content: SquadViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Upcoming events")
            if content.events.isEmpty {
                EmptyStateView(
                    systemImage: "calendar",
                    title: "Nothing scheduled",
                    message: "Plan a trivia night or a sprint session for your squad.",
                    actionTitle: "Create an Event"
                ) {
                    router.present(.createEvent(nil))
                }
                .guideAnchor(.createEventButton)
                .bbCard()
            } else {
                ForEach(content.events) { event in
                    EventRow(
                        event: event,
                        attendees: event.rsvpMemberIDs.compactMap { content.member(for: $0) },
                        isAttending: appState.profile.map { event.isAttending($0.id) } ?? false,
                        isBusy: model.busyEventIDs.contains(event.id),
                        onRSVP: { Task { await model.toggleRSVP(event, profile: appState.profile, services: services) } },
                        onOpen: { router.push(.eventDetail(event.id), in: .squad) }
                    )
                }
            }
        }
    }

    // MARK: Feed

    private func feedSection(_ content: SquadViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Activity")
            if content.visibleActivity.isEmpty {
                Text("No activity yet.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(content.visibleActivity) { item in
                        let member = content.member(for: item.memberID)
                        FeedItemView(
                            item: item,
                            member: member,
                            onReact: { Task { await model.toggleReaction(item, services: services) } },
                            onReport: { reportingItem = item },
                            onBlock: {
                                if let member { router.requestConfirmation(.blockMember(member)) }
                            }
                        )
                        if item.id != content.visibleActivity.last?.id {
                            Divider().overlay(Theme.Palette.hairline)
                        }
                    }
                }
                .bbCard(padding: Theme.Spacing.md)
            }
            if content.hiddenActivityCount > 0 {
                Label("\(content.hiddenActivityCount) update(s) hidden from blocked members", systemImage: "hand.raised")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
        }
    }
}

// MARK: - Header

private struct SquadHeaderCard: View {
    let squad: ReadingSquad
    let blocked: Set<UUID>
    let onBlock: (SquadMember) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(squad.name)
                    .font(.bbDisplay)
                    .foregroundStyle(Theme.Palette.parchment)
                    .accessibilityAddTraits(.isHeader)
                Text(squad.tagline)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                Text("\(squad.memberCount) members")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.gold)
                    .padding(.top, 2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    ForEach(squad.members) { member in
                        memberChip(member)
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .bbCard()
    }

    @ViewBuilder
    private func memberChip(_ member: SquadMember) -> some View {
        let isBlocked = blocked.contains(member.id)
        let chip = VStack(spacing: Theme.Spacing.xs) {
            MemberAvatar(name: member.displayName, seed: member.avatarSeed, size: 48, isCurrentUser: member.isCurrentUser)
                .opacity(isBlocked ? 0.35 : 1)
            Text(member.isCurrentUser ? "You" : member.displayName.split(separator: " ").first.map(String.init) ?? member.displayName)
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchment)
                .lineLimit(1)
            if isBlocked {
                Text("Blocked")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.danger)
            }
        }
        .frame(minWidth: 56)

        if member.isCurrentUser || isBlocked {
            chip
                .accessibilityElement(children: .combine)
        } else {
            Menu {
                Button(role: .destructive) {
                    onBlock(member)
                } label: {
                    Label("Block \(member.displayName)", systemImage: "hand.raised")
                }
            } label: {
                chip
            }
            .accessibilityLabel(member.displayName)
            .accessibilityHint("Opens options for this member")
        }
    }
}

// MARK: - Challenge

struct ChallengeCard: View {
    let challenge: SquadChallenge

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "globe.europe.africa.fill")
                    .foregroundStyle(Theme.Palette.forestBright)
                    .accessibilityHidden(true)
                Text("SQUAD CHALLENGE")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.forestBright)
            }
            Text(challenge.title)
                .font(.bbTitle3)
                .foregroundStyle(Theme.Palette.parchment)
            Text(challenge.detail)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
            ReadingProgressBar(fraction: challenge.fraction, tint: Theme.Palette.forestBright, label: "Challenge progress")
            HStack {
                Text("\(challenge.progress) of \(challenge.goal) books")
                Spacer()
                Text("Ends \(challenge.endsAt.formatted(.dateTime.month(.abbreviated).day()))")
            }
            .font(.bbCaption)
            .foregroundStyle(Theme.Palette.parchmentMuted)
        }
        .bbCard()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared read

struct SharedReadCard: View {
    let book: Book
    let members: [SquadMember]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Reading together", subtitle: "Chapter numbers only — no spoilers here.")
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    BookCoverPlaceholder(book: book, size: .small, isDecorative: true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title)
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text(book.author)
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                }
                .accessibilityElement(children: .combine)

                ForEach(members) { member in
                    HStack(spacing: Theme.Spacing.md) {
                        MemberAvatar(name: member.displayName, seed: member.avatarSeed, size: 30, isCurrentUser: member.isCurrentUser)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(member.isCurrentUser ? "You" : member.displayName)
                                    .font(member.isCurrentUser ? .bbHeadline : .bbCallout)
                                    .foregroundStyle(Theme.Palette.parchment)
                                Spacer()
                                Text(chapterText(member))
                                    .font(.bbCaption)
                                    .foregroundStyle(Theme.Palette.parchmentMuted)
                            }
                            ReadingProgressBar(
                                fraction: fraction(member),
                                tint: member.isCurrentUser ? Theme.Palette.gold : Theme.Palette.lavender,
                                height: 6,
                                label: "\(member.displayName) progress"
                            )
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(member.isCurrentUser ? "You" : member.displayName), \(chapterText(member))")
                }
            }
            .bbCard()
        }
    }

    private func chapterText(_ member: SquadMember) -> String {
        guard let chapter = member.currentChapter, chapter > 0 else { return "Not started" }
        return "Ch. \(chapter) of \(book.chapterCount)"
    }

    private func fraction(_ member: SquadMember) -> Double {
        guard let chapter = member.currentChapter, book.chapterCount > 0 else { return 0 }
        return Double(chapter) / Double(book.chapterCount)
    }
}

// MARK: - Event row

struct EventRow: View {
    let event: ReadingEvent
    let attendees: [SquadMember]
    let isAttending: Bool
    let isBusy: Bool
    let onRSVP: () -> Void
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Button(action: onOpen) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: event.type.symbol)
                        .font(.title3)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.lavender))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text(event.startsAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows event details")

            HStack {
                AvatarStack(members: attendees, size: 28)
                Text("\(attendees.count) going")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .accessibilityHidden(true)
                Spacer()
                if isAttending {
                    SecondaryButton(title: "Going", systemImage: "checkmark", fullWidth: false, action: onRSVP)
                        .disabled(isBusy)
                        .accessibilityLabel("You're going to \(event.title)")
                        .accessibilityHint("Double-tap to cancel your RSVP")
                } else {
                    PrimaryButton(title: "RSVP", isLoading: isBusy, fullWidth: false, action: onRSVP)
                }
            }
        }
        .bbCard()
    }
}

// MARK: - Feed item

struct FeedItemView: View {
    let item: ActivityFeedItem
    let member: SquadMember?
    let onReact: () -> Void
    let onReport: () -> Void
    let onBlock: () -> Void

    private var isOwn: Bool { member?.isCurrentUser ?? false }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            ActivityRow(item: item, member: member)

            Button(action: onReact) {
                VStack(spacing: 0) {
                    Image(systemName: item.viewerReacted ? "hands.clap.fill" : "hands.clap")
                        .foregroundStyle(item.viewerReacted ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                    if item.reactionCount > 0 {
                        Text("\(item.reactionCount)")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                }
                .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
            }
            .accessibilityLabel(item.viewerReacted ? "Remove cheer" : "Cheer")
            .accessibilityValue("\(item.reactionCount) cheers")

            if !isOwn {
                Menu {
                    Button(action: onReport) {
                        Label("Report…", systemImage: "exclamationmark.bubble")
                    }
                    if member != nil {
                        Button(role: .destructive, action: onBlock) {
                            Label("Block \(member?.displayName ?? "member")", systemImage: "hand.raised")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
                }
                .accessibilityLabel("More options")
            }
        }
    }
}

// MARK: - Report

enum ReportReason: String, CaseIterable, Identifiable {
    case spoilers, spam, harassment, inappropriate, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spoilers: "Unmarked spoilers"
        case .spam: "Spam"
        case .harassment: "Harassment or bullying"
        case .inappropriate: "Inappropriate content"
        case .other: "Something else"
        }
    }
}

/// Collects a reason, then routes through the shared confirmation gate before anything is "sent".
/// Reports land in the server-side `content_reports` queue (rate-limited by the database).
struct ReportSheet: View {
    let item: ActivityFeedItem
    let memberName: String

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason = .spoilers
    @State private var note = ""
    @State private var pending: PendingAction?

    var body: some View {
        NavigationStack {
            Form {
                Section("What's wrong with this update from \(memberName)?") {
                    Picker("Reason", selection: $reason) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.title).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    TextField("Add details (optional)", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .onChange(of: note) { if note.count > 300 { note = String(note.prefix(300)) } }
                } footer: {
                    Text("Reports are confidential. \(memberName) won't be told who reported this.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.inkRaised)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") {
                        let details = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        pending = .reportContent(item, reporterNote: details.isEmpty ? reason.title : "\(reason.title): \(details)")
                    }
                }
            }
        }
        .confirmationGate($pending) { action in
            await ActionPerformer(services: services, appState: appState, router: router).perform(action)
            dismiss()
        }
    }
}

#Preview("Squad") {
    NavigationStack {
        SquadView()
            .navigationDestination(for: AppRoute.self) { RouteDestinationView(route: $0) }
    }
    .withPreviewEnvironment()
}
