// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Start a buddy read: one book, 1–3 invitees, a goal date and spoiler rules.
/// Invites are only "sent" after the confirmation sheet.
struct BuddyReadFlow: View {
    static let maxInvitees = 3

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services

    @State private var bookID: UUID?
    @State private var invited: Set<UUID> = []
    @State private var goalDate: Date
    @State private var spoilerLevel: SpoilerLevel = .currentChapter
    @State private var books: [BookWithProgress] = []
    @State private var members: [SquadMember] = []
    @State private var blocked: Set<UUID> = []
    @State private var isLoading = true
    @State private var pending: PendingAction?

    init(bookID: UUID?) {
        _bookID = State(initialValue: bookID)
        let threeWeeks = Calendar.current.date(byAdding: .day, value: 21, to: .now) ?? Date.now.addingTimeInterval(21 * 86_400)
        _goalDate = State(initialValue: threeWeeks)
    }

    private var invitees: [SquadMember] {
        members.filter { invited.contains($0.id) }
    }

    private var validationMessage: String? {
        if bookID == nil { return "Pick a book." }
        if invited.isEmpty { return "Invite at least one person." }
        if invited.count > Self.maxInvitees { return "You can invite up to \(Self.maxInvitees) people." }
        if goalDate <= .now { return "Choose a goal date in the future." }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                if isLoading {
                    LoadingCard(label: "Loading books and members", lines: 4)
                } else {
                    bookSection
                    inviteSection
                    goalSection
                    spoilerSection

                    VStack(spacing: Theme.Spacing.sm) {
                        if let validationMessage {
                            Text(validationMessage)
                                .font(.bbCaption)
                                .foregroundStyle(Theme.Palette.gold)
                        }
                        PrimaryButton(title: "Review & invite", systemImage: "paperplane.fill") {
                            review()
                        }
                        .disabled(validationMessage != nil)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(InkBackground())
        .navigationTitle("Start a Buddy Read")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .confirmationGate($pending) { action in
            await ActionPerformer(services: services, appState: appState, router: router).perform(action)
            router.dismissSheet()
        }
    }

    private func load() async {
        async let library = services.books.library()
        async let squad = services.squads.currentSquad()
        async let blockedIDs = services.moderation.blockedMemberIDs()
        let preselected = bookID
        books = ((try? await library) ?? [])
            // Offer unread demo titles and anything on your shelf you haven't finished,
            // plus whichever book this flow was opened from.
            .filter { $0.state != .finished || $0.book.id == preselected }
            .sorted { $0.book.title < $1.book.title }
        members = ((try? await squad)?.members ?? []).filter { !$0.isCurrentUser }
        blocked = await blockedIDs
        isLoading = false
    }

    // MARK: Sections

    private var bookSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "1. Pick a book")
            Picker("Book", selection: $bookID) {
                Text("Choose a book").tag(UUID?.none)
                ForEach(books) { item in
                    Text(item.book.title).tag(UUID?.some(item.book.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.Palette.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bbCard(padding: Theme.Spacing.md)
        }
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "2. Invite 1–\(Self.maxInvitees) people", subtitle: "\(invited.count) of \(Self.maxInvitees) selected")
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(members) { member in
                    let isSelected = invited.contains(member.id)
                    let isBlocked = blocked.contains(member.id)
                    let atLimit = invited.count >= Self.maxInvitees && !isSelected
                    SelectableCard(
                        isSelected: isSelected,
                        accessibilityHint: atLimit ? "You've reached the invite limit." : "Double-tap to toggle invite.",
                        action: { toggle(member) }
                    ) {
                        HStack(spacing: Theme.Spacing.md) {
                            MemberAvatar(name: member.displayName, seed: member.avatarSeed, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(member.displayName)
                                    .font(.bbHeadline)
                                    .foregroundStyle(Theme.Palette.parchment)
                                if isBlocked {
                                    Text("Blocked")
                                        .font(.bbCaption)
                                        .foregroundStyle(Theme.Palette.danger)
                                }
                            }
                        }
                    }
                    .disabled(atLimit || isBlocked)
                    .opacity(atLimit || isBlocked ? 0.5 : 1)
                }
            }
        }
    }

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "3. Goal date")
            DatePicker("Finish by", selection: $goalDate, in: Date.now..., displayedComponents: .date)
                .foregroundStyle(Theme.Palette.parchment)
                .tint(Theme.Palette.gold)
                .bbCard(padding: Theme.Spacing.md)
        }
    }

    private var spoilerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "4. Spoiler rules", subtitle: "What can people talk about in this buddy read?")
            ForEach(SpoilerLevel.allCases) { level in
                SelectableCard(isSelected: spoilerLevel == level, action: { spoilerLevel = level }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(level.displayName, systemImage: level.symbol)
                            .font(.bbHeadline)
                            .foregroundStyle(Theme.Palette.parchment)
                        Text(level.detail)
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func toggle(_ member: SquadMember) {
        if invited.contains(member.id) {
            invited.remove(member.id)
        } else if invited.count < Self.maxInvitees, !blocked.contains(member.id) {
            invited.insert(member.id)
        }
    }

    private func review() {
        guard validationMessage == nil, let bookID else { return }
        let read = BuddyRead(
            bookID: bookID,
            invitedMemberIDs: invitees.map(\.id),
            goalDate: goalDate,
            spoilerLevel: spoilerLevel
        )
        pending = .startBuddyRead(read, inviteeNames: invitees.map(\.displayName))
    }
}

#Preview {
    NavigationStack {
        BuddyReadFlow(bookID: DemoData.IDs.lastPaperGarden)
    }
    .withPreviewEnvironment()
}
