// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

struct BookDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @State private var model: BookDetailViewModel
    @State private var isSavingMoment = false

    init(bookID: UUID) {
        _model = State(initialValue: BookDetailViewModel(bookID: bookID))
    }

    private var spoilerLevel: SpoilerLevel {
        appState.profile?.spoilerLevel ?? .premiseOnly
    }

    var body: some View {
        ZStack {
            InkBackground()
            switch model.state {
            case .idle, .loading:
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        LoadingCard(label: "Loading book", lines: 5)
                        LoadingCard(label: "Loading summary", lines: 3)
                    }
                    .padding(Theme.Spacing.lg)
                }
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.load(services: services) }
                }
                .padding(Theme.Spacing.lg)
            case .loaded(let content):
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        BookDetailHeader(book: content.book)
                        progressSection(content)
                        summarySection(content)
                        if !content.book.characters.isEmpty {
                            charactersSection(content)
                        }
                        notesSection(content)
                        momentsSection(content)
                        actionsSection(content)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
        .navigationTitle(model.content?.book.title ?? "Book")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: router.dataVersion) {
            await model.load(services: services)
        }
        .task(id: summaryKey) {
            guard model.content != nil else { return }
            await model.loadSummary(services: services, spoilerLevel: spoilerLevel)
        }
        .sheet(isPresented: $isSavingMoment) {
            SaveMomentSheet { title, reflection in
                await model.addMoment(title: title, reflection: reflection, services: services)
            }
        }
    }

    /// Reload the summary whenever the mode, spoiler setting or reading position changes.
    private var summaryKey: String {
        let chapter = model.content?.progress?.currentChapter ?? -1
        let state = model.content?.state.rawValue ?? "none"
        return "\(model.summaryMode.rawValue)|\(spoilerLevel.rawValue)|\(chapter)|\(state)"
    }

    // MARK: Progress

    @ViewBuilder
    private func progressSection(_ content: BookDetailViewModel.Content) -> some View {
        let item = BookWithProgress(book: content.book, progress: content.progress)
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label(content.state.displayName, systemImage: stateSymbol(content.state))
                    .font(.bbHeadline)
                    .foregroundStyle(stateTint(content.state))
                Spacer()
                if let progress = content.progress, content.book.hasChapterData, content.state != .wantToRead {
                    Text("Chapter \(progress.currentChapter) of \(content.book.chapterCount)")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
            }
            .accessibilityElement(children: .combine)

            if content.state != .wantToRead, content.book.hasChapterData || content.state == .finished {
                ReadingProgressBar(fraction: item.fraction, label: "Progress in \(content.book.title)")
            }

            switch content.state {
            case .reading where content.book.hasChapterData:
                SecondaryButton(title: "I finished a chapter", systemImage: "plus.circle") {
                    Task { await model.logChapter(services: services) }
                }
            case .wantToRead:
                PrimaryButton(title: "Start reading", systemImage: "book.fill") {
                    Task { await model.startReading(services: services) }
                }
            case .finished:
                if let finishedAt = content.progress?.finishedAt, content.book.source == .demo {
                    Text("Finished \(finishedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                } else if content.book.source == .personalShelf {
                    Text("On your shelf. Exact dates and page counts will come from licensed metadata.")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            default:
                EmptyView()
            }
        }
        .bbCard()
    }

    private func stateSymbol(_ state: ReadingState) -> String {
        switch state {
        case .reading: "book"
        case .wantToRead: "bookmark"
        case .finished: "checkmark.seal.fill"
        }
    }

    private func stateTint(_ state: ReadingState) -> Color {
        switch state {
        case .reading: Theme.Palette.gold
        case .wantToRead: Theme.Palette.lavender
        case .finished: Theme.Palette.forestBright
        }
    }

    // MARK: Summary

    private func summarySection(_ content: BookDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Summary", subtitle: "Spoiler setting: \(spoilerLevel.displayName)")

            Picker("Summary mode", selection: $model.summaryMode) {
                ForEach(SummaryMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                switch model.summary {
                case .idle, .loading:
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView().tint(Theme.Palette.lavender)
                        Text("\(PipIdentity.name) is writing a summary…")
                            .font(.bbCallout)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                    .accessibilityElement(children: .combine)
                case .failed(let message):
                    Text(message)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.danger)
                case .loaded(let result):
                    summaryBody(result)
                }

                Divider().overlay(Theme.Palette.hairline)

                Label("Demo content — replace with licensed metadata and source-linked summaries in production.", systemImage: "info.circle")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .bbCard()
        }
    }

    @ViewBuilder
    private func summaryBody(_ result: SummaryResult) -> some View {
        switch result {
        case .available(let summary):
            DemoContentBadge()
            Text(summary.text)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if let chapter = summary.coveredThroughChapter, summary.mode != .premise {
                Text("Covers through Chapter \(chapter)")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
        case .locked(let reason):
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Palette.lavender)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hidden to protect you from spoilers")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.parchment)
                    Text(reason)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Characters

    private func charactersSection(_ content: BookDetailViewModel.Content) -> some View {
        let result = SpoilerPolicy.visibleCharacters(book: content.book, progress: content.progress, level: spoilerLevel)
        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Key characters")
            VStack(spacing: 0) {
                ForEach(result.visible) { character in
                    HStack(spacing: Theme.Spacing.md) {
                        MemberAvatar(name: character.name, seed: character.name.count, size: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(character.name)
                                .font(.bbHeadline)
                                .foregroundStyle(Theme.Palette.parchment)
                            Text(character.role)
                                .font(.bbCallout)
                                .foregroundStyle(Theme.Palette.parchmentMuted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .accessibilityElement(children: .combine)
                }
                if result.hiddenCount > 0 {
                    Label(
                        result.hiddenCount == 1
                            ? "1 more character appears later"
                            : "\(result.hiddenCount) more characters appear later",
                        systemImage: "eye.slash"
                    )
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .padding(.top, Theme.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .bbCard(padding: Theme.Spacing.md)
        }
    }

    // MARK: Notes

    private func notesSection(_ content: BookDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Personal notes", subtitle: "Private to this device")
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
                    TextField(
                        "",
                        text: $model.draftNote,
                        prompt: Text("Add a note…").foregroundStyle(Theme.Palette.parchmentMuted),
                        axis: .vertical
                    )
                    .lineLimit(1...5)
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .padding(Theme.Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
                    .onChange(of: model.draftNote) { model.enforceNoteLimit() }
                    .accessibilityLabel("New note")

                    Button {
                        Task { await model.addNote(services: services) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(model.canAddNote ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                            .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
                    }
                    .disabled(!model.canAddNote)
                    .accessibilityLabel("Save note")
                }

                if content.notes.isEmpty {
                    Text("No notes yet. Jot down a question or a thought to bring to your squad.")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(content.notes) { note in
                        NoteRow(note: note) {
                            router.requestConfirmation(.deleteNote(note))
                        }
                    }
                }
            }
            .bbCard()
        }
    }

    // MARK: Moments

    private func momentsSection(_ content: BookDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Saved moments", actionTitle: "Save a moment") {
                isSavingMoment = true
            }
            if content.moments.isEmpty {
                Text("Save a scene or idea in your own words so you can find it again.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(content.moments) { moment in
                    SavedMomentRow(moment: moment, bookTitle: nil)
                }
            }
        }
    }

    // MARK: Actions

    private func actionsSection(_ content: BookDetailViewModel.Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Do more with this book")
            PrimaryButton(title: "Ask \(PipIdentity.name) about this book", systemImage: "sparkles") {
                router.present(.pip(bookID: content.book.id))
            }
            SecondaryButton(title: "Create a quiz", systemImage: "bolt.fill") {
                router.push(.quiz(bookID: content.book.id, mode: .quickRecall))
            }
            .disabled(!content.hasQuiz)
            if !content.hasQuiz {
                Text("Quizzes for this title are coming soon.")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            SecondaryButton(title: "Start a buddy read", systemImage: "person.2.fill") {
                router.present(.buddyRead(bookID: content.book.id))
            }
        }
    }
}

// MARK: - Header

private struct BookDetailHeader: View {
    let book: Book

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            BookCoverPlaceholder(book: book, size: .large)
                .padding(.top, Theme.Spacing.md)
            VStack(spacing: Theme.Spacing.xs) {
                Text(book.title)
                    .font(.bbDisplay)
                    .foregroundStyle(Theme.Palette.parchment)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("by \(book.author)")
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(book.genres) { genre in
                    Label(genre.displayName, systemImage: genre.symbol)
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.lavender)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Capsule().fill(Theme.Palette.lavender.opacity(0.14)))
                }
            }
            Label(book.source.label, systemImage: book.source == .demo ? "theatermasks" : "books.vertical")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Notes

private struct NoteRow: View {
    let note: BookNote
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(note.text)
                    .font(.bbBody)
                    .foregroundStyle(Theme.Palette.parchment)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.chapter > 0
                     ? "Ch. \(note.chapter) · \(note.createdAt.formatted(date: .abbreviated, time: .omitted))"
                     : note.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            Spacer(minLength: 0)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(Theme.Palette.danger)
                    .frame(width: Theme.minTapTarget, height: Theme.minTapTarget)
            }
            .accessibilityLabel("Delete note")
        }
        .padding(.vertical, Theme.Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Delete note", onDelete)
    }
}

// MARK: - Save a moment

private struct SaveMomentSheet: View {
    let onSave: (String, String) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var reflection = ""
    @State private var isSaving = false
    @State private var failed = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name this moment", text: $title)
                        .onChange(of: title) { if title.count > 80 { title = String(title.prefix(80)) } }
                    TextField("What stayed with you?", text: $reflection, axis: .vertical)
                        .lineLimit(3...8)
                        .onChange(of: reflection) { if reflection.count > 500 { reflection = String(reflection.prefix(500)) } }
                } footer: {
                    Text("Write it in your own words. Saved moments stay on this device.")
                }
                if failed {
                    Text("That didn't save. Please try again.")
                        .foregroundStyle(Theme.Palette.danger)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.inkRaised)
            .navigationTitle("Save a moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            isSaving = true
                            let ok = await onSave(
                                title.trimmingCharacters(in: .whitespacesAndNewlines),
                                reflection.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                            isSaving = false
                            if ok { dismiss() } else { failed = true }
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Demo book – reading") {
    NavigationStack {
        BookDetailView(bookID: DemoData.IDs.orbitOfAshes)
    }
    .withPreviewEnvironment()
}

#Preview("Shelf book") {
    NavigationStack {
        BookDetailView(bookID: DemoData.id(809))
    }
    .withPreviewEnvironment()
}
