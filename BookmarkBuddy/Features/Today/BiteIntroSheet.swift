// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// First run: Bite asks what you're reading, then promises one question tomorrow.
/// Day one ends with a reason to come back.
struct BiteIntroSheet: View {
    /// The book already marked as reading, if any — skips straight to the promise.
    let currentBook: Book?
    let onFinish: () -> Void

    @Environment(\.services) private var services
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private enum Step: Equatable { case pick, schedule(Book), promise(Book, notificationsOn: Bool) }

    @State private var step: Step = .pick
    @State private var books: [Book] = []
    @State private var search = ""
    @State private var hour = RefreshNotifier.shared.hour
    @State private var isSaving = false

    private var isPromise: Bool {
        if case .promise = step { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                InkBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        switch step {
                        case .pick: pickStep
                        case .schedule(let book): scheduleStep(book)
                        case .promise(let book, let on): promiseStep(book, notificationsOn: on)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .animation(.easeInOut(duration: 0.25), value: step)
                }
            }
            .toolbar {
                if !isPromise {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Later") { finish() }
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .task {
            books = ((try? await services.books.allBooks()) ?? []).sorted { $0.title < $1.title }
            if let currentBook { step = .schedule(currentBook) }
        }
    }

    // MARK: Bite speaking

    private func biteSays(_ text: String, mood: PipAvatar.Mood = .happy) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            PipAvatar(size: 64, mood: mood)
            Text(text)
                .font(.bbTitle3)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                        .fill(Theme.Palette.inkRaised)
                )
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: 1. What are you reading?

    private var filteredBooks: [Book] {
        let query = search.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.author.localizedCaseInsensitiveContains(query)
        }
    }

    private var greetingName: String {
        if let name = appState.profile?.firstName, !name.isEmpty { return ", \(name)" }
        return ""
    }

    private var pickStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            biteSays("Hi\(greetingName)! I'm \(PipIdentity.name). What are you reading right now?")

            TextField("", text: $search, prompt: Text("Search title or author").foregroundStyle(Theme.Palette.parchmentMuted))
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .autocorrectionDisabled()
                .padding(.horizontal, Theme.Spacing.lg)
                .frame(minHeight: 48)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Palette.inkRaised))
                .accessibilityLabel("Search books")

            if books.isEmpty {
                ProgressView().tint(Theme.Palette.parchment).frame(maxWidth: .infinity)
            } else if filteredBooks.isEmpty {
                Text("No match yet — try another title, or tap Later and add it from your Library.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            } else {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(filteredBooks) { book in
                        Button {
                            Analytics.log(.bookStarted, ["source": "first_run"])
                            step = .schedule(book)
                        } label: {
                            HStack(spacing: Theme.Spacing.md) {
                                BookCoverPlaceholder(book: book, size: .small, isDecorative: true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(book.title).font(.bbHeadline).foregroundStyle(Theme.Palette.parchment)
                                    Text(book.author).font(.bbCallout).foregroundStyle(Theme.Palette.parchmentMuted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").foregroundStyle(Theme.Palette.parchmentMuted)
                            }
                            .bbCard(padding: Theme.Spacing.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(book.title) by \(book.author)")
                    }
                }
            }
        }
    }

    // MARK: 2. Tomorrow's question

    private func hourLabel(_ value: Int) -> String {
        var components = DateComponents()
        components.hour = value
        return (Calendar.current.date(from: components) ?? .now).formatted(date: .omitted, time: .shortened)
    }

    private func scheduleStep(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            biteSays("Love it. Tomorrow I'll ask you one quick question about “\(book.title)” so it sticks.")

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("When should I check in?")
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Picker("Reminder time", selection: $hour) {
                    ForEach(6...22, id: \.self) { Text(hourLabel($0)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 140)
                Text("You can answer right from the notification — no need to open the app.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .bbCard()

            PrimaryButton(title: "Remind me tomorrow", systemImage: "bell.fill", isLoading: isSaving) {
                Task { await commit(book) }
            }
            if currentBook == nil {
                SecondaryButton(title: "Pick a different book", systemImage: "arrow.uturn.backward") {
                    step = .pick
                }
            }
        }
    }

    private func commit(_ book: Book) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        // Mark the book as reading (keeping any progress that already exists).
        let existing = try? await services.books.progress(for: book.id)
        if existing?.state != .reading {
            let progress = ReadingProgress(
                bookID: book.id,
                state: .reading,
                currentChapter: existing?.currentChapter ?? 1,
                pagesRead: existing?.pagesRead ?? 0,
                startedAt: existing?.startedAt ?? .now,
                finishedAt: nil,
                memoryStrength: existing?.memoryStrength ?? 0.5
            )
            try? await services.books.updateProgress(progress)
        }

        GardenStore.shared.plant(bookID: book.id)

        let notifier = RefreshNotifier.shared
        notifier.hour = hour
        let allowed = await notifier.requestAuthorization()
        notifier.isEnabled = allowed
        let promiseDate = RefreshNotifier.upcomingDates(hour: hour, count: 1, startTomorrow: true).first ?? .now.addingTimeInterval(86_400)
        FirstRefreshPromise.make(bookID: book.id, title: book.title, date: promiseDate)
        if allowed {
            await notifier.reschedule(startTomorrow: true, firstBookID: book.id)
            Analytics.log(.reminderScheduled, ["hour": "\(hour)", "source": "first_run"])
        }
        step = .promise(book, notificationsOn: allowed)
    }

    // MARK: 3. The promise

    private func promiseStep(_ book: Book, notificationsOn: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            biteSays(
                notificationsOn
                    ? "Deal! See you tomorrow at \(hourLabel(hour)) 👋 I'll bring one question about “\(book.title)”."
                    : "Deal! Your first question about “\(book.title)” will be waiting on the Today tab tomorrow.",
                mood: .cheering
            )
            if !notificationsOn {
                Label("Want me to tap you on the shoulder? Turn on notifications in Settings → Bookmark Buddy.", systemImage: "bell.slash")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryButton(title: "Start reading", systemImage: "book.fill") { finish() }
        }
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: StorageKeys.biteIntroDone)
        Analytics.log(.firstRunCompleted, ["picked_book": FirstRefreshPromise.pendingBookID == nil ? "no" : "yes"])
        onFinish()
        dismiss()
    }
}
