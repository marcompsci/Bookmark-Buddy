// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct EventDetailView: View {
    let eventID: UUID

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var state: LoadState<Loaded> = .idle
    @State private var isUpdating = false

    struct Loaded {
        var event: ReadingEvent
        var squad: ReadingSquad
        var book: Book?
    }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    switch state {
                    case .idle, .loading:
                        LoadingCard(label: "Loading event", lines: 5)
                    case .failed(let message):
                        ErrorStateView(message: message) { Task { await load() } }
                    case .loaded(let loaded):
                        details(loaded)
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationTitle(state.value?.event.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: router.dataVersion) { await load() }
    }

    private func load() async {
        if state.value == nil { state = .loading }
        do {
            let event = try await services.events.event(id: eventID)
            let squad = try await services.squads.currentSquad()
            var book: Book?
            if let bookID = event.bookID {
                book = try? await services.books.book(id: bookID)
            }
            state = .loaded(Loaded(event: event, squad: squad, book: book))
        } catch {
            if state.value == nil { state = .failed(error.localizedDescription) }
        }
    }

    @ViewBuilder
    private func details(_ loaded: Loaded) -> some View {
        let event = loaded.event
        let attendees = event.rsvpMemberIDs.compactMap { id in loaded.squad.members.first { $0.id == id } }
        let host = loaded.squad.members.first { $0.id == event.hostMemberID }
        let attending = appState.profile.map { event.isAttending($0.id) } ?? false

        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label(event.type.displayName, systemImage: event.type.symbol)
                .font(.bbHeadline)
                .foregroundStyle(Theme.Palette.lavender)
            Text(event.title)
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
                .accessibilityAddTraits(.isHeader)
            Label(event.startsAt.formatted(date: .complete, time: .shortened), systemImage: "calendar")
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
            Label("\(event.durationMinutes) minutes", systemImage: "clock")
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
            if let host {
                Label("Hosted by \(host.isCurrentUser ? "you" : host.displayName)", systemImage: "person.crop.circle")
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
            }
            Text(event.type.blurb)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .bbCard()

        if let book = loaded.book {
            Button {
                router.push(.bookDetail(book.id))
            } label: {
                LibraryBookRow(item: BookWithProgress(book: book, progress: nil))
            }
            .buttonStyle(.plain)
        }

        if !event.notes.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionHeader(title: "Notes from the host")
                Text(event.notes)
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                    .bbCard()
            }
        }

        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Who's going", subtitle: "\(attendees.count) of \(loaded.squad.memberCount) members")
            VStack(spacing: 0) {
                ForEach(attendees) { member in
                    HStack(spacing: Theme.Spacing.md) {
                        MemberAvatar(name: member.displayName, seed: member.avatarSeed, size: 32, isCurrentUser: member.isCurrentUser)
                        Text(member.isCurrentUser ? "You" : member.displayName)
                            .font(.bbBody)
                            .foregroundStyle(Theme.Palette.parchment)
                        Spacer()
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                    .accessibilityElement(children: .combine)
                }
                if attendees.isEmpty {
                    Text("No RSVPs yet — be the first.")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .bbCard(padding: Theme.Spacing.md)
        }

        if attending {
            SecondaryButton(title: "You're going · Cancel RSVP", systemImage: "checkmark") {
                Task { await toggle(loaded) }
            }
            .disabled(isUpdating)
        } else {
            PrimaryButton(title: "RSVP", systemImage: "hand.raised.fill", isLoading: isUpdating) {
                Task { await toggle(loaded) }
            }
        }
    }

    private func toggle(_ loaded: Loaded) async {
        guard let profile = appState.profile, !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        if let updated = try? await services.events.setRSVP(
            eventID: loaded.event.id,
            memberID: profile.id,
            attending: !loaded.event.isAttending(profile.id)
        ) {
            var next = loaded
            next.event = updated
            state = .loaded(next)
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(eventID: DemoData.IDs.triviaNight)
    }
    .withPreviewEnvironment()
}
