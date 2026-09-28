// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Plan a squad event. Nothing is created until the person approves the confirmation sheet.
struct CreateEventFlow: View {
    let initialType: EventType?

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services

    @State private var type: EventType
    @State private var title: String
    @State private var startsAt: Date
    @State private var durationMinutes: Int
    @State private var bookID: UUID?
    @State private var notes = ""
    @State private var books: [Book] = []
    @State private var pending: PendingAction?
    @State private var titleEdited = false

    init(initialType: EventType?) {
        self.initialType = initialType
        let type = initialType ?? .triviaNight
        _type = State(initialValue: type)
        _title = State(initialValue: type.displayName)
        _startsAt = State(initialValue: Self.defaultStart())
        _durationMinutes = State(initialValue: type.defaultDurationMinutes)
        _bookID = State(initialValue: type == .triviaNight ? DemoData.IDs.glassHarbor : DemoData.IDs.orbitOfAshes)
    }

    /// Tomorrow at 7:30 PM.
    static func defaultStart(now: Date = .now) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
        return calendar.date(bySettingHour: 19, minute: 30, second: 0, of: tomorrow) ?? tomorrow
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validationMessage: String? {
        if trimmedTitle.isEmpty { return "Give your event a name." }
        if startsAt <= .now { return "Pick a time in the future." }
        if appState.profile == nil { return "Finish setting up your profile first." }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                typeSection
                detailsSection
                bookSection
                notesSection

                VStack(spacing: Theme.Spacing.sm) {
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.gold)
                    }
                    PrimaryButton(title: "Review & create", systemImage: "checkmark.circle") {
                        review()
                    }
                    .disabled(validationMessage != nil)
                    Text("You'll confirm before your squad is notified.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(InkBackground())
        .navigationTitle("Create an Event")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            books = (try? await services.books.allBooks()) ?? []
        }
        .confirmationGate($pending) { action in
            await ActionPerformer(services: services, appState: appState, router: router).perform(action)
            router.dismissSheet()
        }
    }

    // MARK: Sections

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "What kind of event?")
            ForEach(EventType.allCases) { option in
                SelectableCard(isSelected: type == option, action: { select(option) }) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: option.symbol)
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.lavender)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.displayName)
                                .font(.bbHeadline)
                                .foregroundStyle(Theme.Palette.parchment)
                            Text(option.blurb)
                                .font(.bbCallout)
                                .foregroundStyle(Theme.Palette.parchmentMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Details")
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                TextField("", text: $title, prompt: Text("Event name").foregroundStyle(Theme.Palette.parchmentMuted))
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .padding(Theme.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
                    .onChange(of: title) {
                        titleEdited = true
                        if title.count > 60 { title = String(title.prefix(60)) }
                    }
                    .accessibilityLabel("Event name")

                DatePicker(
                    "Starts",
                    selection: $startsAt,
                    in: Date.now...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .foregroundStyle(Theme.Palette.parchment)
                .tint(Theme.Palette.gold)

                Stepper(value: $durationMinutes, in: 15...180, step: 15) {
                    Text("Length: \(durationMinutes) min")
                        .foregroundStyle(Theme.Palette.parchment)
                }
                .accessibilityValue("\(durationMinutes) minutes")
            }
            .bbCard()
        }
    }

    private var bookSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Book", subtitle: type == .triviaNight ? "Trivia works best on a book everyone has finished." : nil)
            Picker("Book", selection: $bookID) {
                Text("No specific book").tag(UUID?.none)
                ForEach(books) { book in
                    Text(book.title).tag(UUID?.some(book.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.Palette.gold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bbCard(padding: Theme.Spacing.md)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Notes (optional)")
            TextField("", text: $notes, prompt: Text("Spoiler rules, snacks, a theme…").foregroundStyle(Theme.Palette.parchmentMuted), axis: .vertical)
                .lineLimit(2...5)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
                .onChange(of: notes) { if notes.count > 300 { notes = String(notes.prefix(300)) } }
                .accessibilityLabel("Event notes")
        }
    }

    // MARK: Actions

    private func select(_ option: EventType) {
        let previousDefault = type.displayName
        type = option
        durationMinutes = option.defaultDurationMinutes
        // Only replace the name if the person hasn't customized it.
        if !titleEdited || title == previousDefault {
            title = option.displayName
            titleEdited = false
        }
    }

    private func review() {
        guard validationMessage == nil, let profile = appState.profile else { return }
        let event = ReadingEvent(
            squadID: DemoData.IDs.midnightMargins,
            type: type,
            title: trimmedTitle,
            startsAt: startsAt,
            durationMinutes: durationMinutes,
            hostMemberID: profile.id,
            rsvpMemberIDs: [profile.id],
            bookID: bookID,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        pending = .createEvent(event)
    }
}

#Preview {
    NavigationStack {
        CreateEventFlow(initialType: .triviaNight)
    }
    .withPreviewEnvironment()
}
