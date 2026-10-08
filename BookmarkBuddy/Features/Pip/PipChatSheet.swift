// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// Pip's bottom-sheet chat panel with deterministic command routing,
/// notes consent gate, and a "What Pip can see" disclosure.
struct PipChatSheet: View {
    /// If non-nil, the sheet was opened from a specific book's detail view.
    var bookID: UUID?

    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [PipMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping = false
    @State private var showWhatPipCanSee = false
    @State private var showNotesConsent = false
    @State private var pendingPromptAfterConsent: String? = nil

    private let quickCommands = [
        "What should I do next?",
        "Quiz me on The Glass Harbor.",
        "Summarize my current book.",
        "Take me to my squad.",
        "Show my upcoming event.",
        "What can you access?"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Palette.ink.ignoresSafeArea()
                VStack(spacing: 0) {
                    pipHeader
                    Divider().background(Theme.Palette.hairline)
                    messageList
                    Divider().background(Theme.Palette.hairline)
                    inputRow
                }
            }
            .navigationTitle(PipIdentity.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWhatPipCanSee.toggle()
                    } label: {
                        Label("What Pip can see", systemImage: "eye.circle")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.lavender)
                    }
                }
            }
            .sheet(isPresented: $showWhatPipCanSee) {
                PipAccessDisclosure()
            }
            .sheet(isPresented: $showNotesConsent) {
                NotesConsentGate {
                    // "Always Allow"
                    Task {
                        await appState.updatePipPermissions { $0.notesConsent = .always }
                        if let prompt = pendingPromptAfterConsent {
                            pendingPromptAfterConsent = nil
                            await send(prompt)
                        }
                    }
                } onDenied: {
                    pendingPromptAfterConsent = nil
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            // Greeting on first open
            if messages.isEmpty {
                let name = appState.profile?.firstName ?? "friend"
                let greeting = PipMessage(
                    role: .pip,
                    text: "Hi \(name)! I'm here to help. Tap a quick command below, or type anything.",
                    action: nil
                )
                messages.append(greeting)

                if let bookID, let book = try? await services.books.book(id: bookID) {
                    let scoped = PipMessage(
                        role: .pip,
                        text: "You opened me from \(book.title). Ask me anything about it!",
                        action: .openBook(book.id)
                    )
                    messages.append(scoped)
                }
            }
        }
    }

    // MARK: Header

    private var pipHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            PipAvatar(size: 44, mood: isTyping ? .thinking : .idle)
            VStack(alignment: .leading, spacing: 2) {
                Text(PipIdentity.name)
                    .font(.bbHeadline)
                    .foregroundStyle(Theme.Palette.parchment)
                Text(isTyping ? "Thinking…" : "Your reading companion")
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.lavender)
                    .animation(.easeInOut, value: isTyping)
            }
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(PipIdentity.name), your reading companion. \(isTyping ? "Thinking." : "Ready.")")
    }

    // MARK: Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    ForEach(messages) { message in
                        PipMessageBubble(message: message, onAction: { handleAction($0) })
                            .id(message.id)
                    }
                    if isTyping {
                        TypingIndicator()
                            .id("typing")
                    }

                    // Quick command chips (shown when there are few messages)
                    if messages.count <= 2 {
                        quickCommandsRow
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .onChange(of: messages.count) {
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isTyping) {
                if isTyping { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private var quickCommandsRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Try asking:")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
            FlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(quickCommands, id: \.self) { cmd in
                    Button(cmd) {
                        Task { await sendUserMessage(cmd) }
                    }
                    .font(.bbCaption)
                    .foregroundStyle(Theme.Palette.parchment)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.Palette.inkRaised))
                    .overlay(Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1))
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Input row

    private var inputRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Ask \(PipIdentity.name)…", text: $inputText, axis: .vertical)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .lineLimit(1...4)
                .padding(Theme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Palette.inkRaised)
                )
                .accessibilityLabel("Message Pip")
                .onSubmit { Task { await sendUserMessage(inputText) } }

            Button {
                Task { await sendUserMessage(inputText) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(inputText.isEmpty ? Theme.Palette.parchmentMuted : Theme.Palette.gold)
            }
            .disabled(inputText.isEmpty || isTyping)
            .accessibilityLabel("Send message to Pip")
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Palette.inkRaised)
    }

    // MARK: Send logic

    private func sendUserMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        messages.append(PipMessage(role: .user, text: trimmed))
        await send(trimmed)
    }

    private func send(_ prompt: String) async {
        // If the prompt implies notes and the user hasn't consented yet, gate it.
        let notesKeywords = ["note", "highlight", "saved moment", "what i wrote"]
        let wantsNotes = notesKeywords.contains { prompt.localizedCaseInsensitiveContains($0) }
        if wantsNotes && appState.pipPermissions.notesConsent == .notAsked {
            pendingPromptAfterConsent = prompt
            showNotesConsent = true
            return
        }

        isTyping = true
        let context = await buildContext()
        let reply = await services.pip.reply(to: prompt, context: context)
        isTyping = false
        messages.append(reply)

        // Route navigation actions automatically.
        if let action = reply.action {
            handleAction(action)
        }
    }

    /// Pulls Pip's context from the live services (Supabase when configured, demo data otherwise),
    /// filtered by the person's privacy settings. Failures just leave that piece out.
    private func buildContext() async -> PipContext {
        let profile = appState.profile
        let permissions = appState.pipPermissions

        let currentBook: BookWithProgress? = permissions.allowReadingProgress
            ? (try? await services.books.currentRead())
            : nil
        let squad = try? await services.squads.currentSquad()
        var event: ReadingEvent? = nil
        if let squad {
            event = (try? await services.events.upcomingEvents(squadID: squad.id))?
                .filter { $0.startsAt > .now }
                .min { $0.startsAt < $1.startsAt }
        }

        var notes: [BookNote]? = nil
        var moments: [SavedMoment]? = nil
        if permissions.allowsNotes {
            if let bookID = bookID ?? currentBook?.book.id {
                notes = try? await services.books.notes(for: bookID)
            }
            moments = try? await services.books.allMoments()
        }

        return PipContext(
            profile: profile,
            currentBook: currentBook,
            squad: squad,
            upcomingEvent: event,
            notes: notes,
            moments: moments
        )
    }

    private func handleAction(_ action: PipAction) {
        switch action {
        case .openTab(let tab):
            dismiss()
            router.select(tab)
        case .openBook(let id):
            dismiss()
            router.push(.bookDetail(id), in: .library)
            router.select(.library)
        case .startQuiz(let bookID):
            dismiss()
            router.push(.quiz(bookID: bookID, mode: .quickRecall), in: .play)
            router.select(.play)
        case .createEvent(let type):
            dismiss()
            router.present(.createEvent(type))
        case .startBuddyRead:
            dismiss()
            router.present(.buddyRead(bookID: nil))
        case .showUpcomingEvent:
            Task {
                guard let squad = try? await services.squads.currentSquad(),
                      let event = (try? await services.events.upcomingEvents(squadID: squad.id))?
                        .filter({ $0.startsAt > .now })
                        .min(by: { $0.startsAt < $1.startsAt })
                else {
                    dismiss()
                    router.select(.squad)
                    return
                }
                dismiss()
                router.push(.eventDetail(event.id), in: .squad)
                router.select(.squad)
            }
        case .startGuide(let walkthroughID):
            dismiss()
            router.guide.start(walkthroughID)
        case .showPrivacy:
            dismiss()
            router.push(.privacySafety, in: .profile)
            router.select(.profile)
        }
    }
}

// MARK: - Message bubble

private struct PipMessageBubble: View {
    let message: PipMessage
    let onAction: (PipAction) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.sm) {
            if message.role == .pip {
                PipAvatar(size: 28, mood: .happy, animated: false)
                    .accessibilityHidden(true)
            } else {
                Spacer(minLength: 48)
            }

            VStack(alignment: message.role == .pip ? .leading : .trailing, spacing: Theme.Spacing.xs) {
                Text(message.text)
                    .font(.bbBody)
                    .foregroundStyle(message.role == .pip ? Theme.Palette.parchment : Theme.Palette.ink)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .fill(message.role == .pip ? Theme.Palette.inkRaised : Theme.Palette.gold)
                    )
                    .frame(maxWidth: .infinity, alignment: message.role == .pip ? .leading : .trailing)

                if let action = message.action {
                    Button(action.buttonTitle) { onAction(action) }
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.ink)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.Palette.gold))
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if message.role == .user {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.Palette.lavender)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.role == .pip ? PipIdentity.name : "You"): \(message.text)")
    }
}

// MARK: - Typing indicator

private struct TypingIndicator: View {
    @State private var phase: Double = 0

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            PipAvatar(size: 28, mood: .thinking, animated: true)
                .accessibilityHidden(true)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Theme.Palette.parchmentMuted)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1 + 0.4 * sin(phase + Double(i) * .pi / 1.5))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Palette.inkRaised))
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    phase = 2 * .pi
                }
            }
        }
        .accessibilityLabel("\(PipIdentity.name) is typing")
    }
}

// MARK: - What Pip can see

private struct PipAccessDisclosure: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                InkBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        accessRow(icon: "book.fill", text: "Your current book and reading progress")
                        accessRow(icon: "person.fill", text: "Your name, genres and reading goal")
                        accessRow(icon: "person.3.fill", text: "Your squad activity and events")
                        accessRow(icon: "note.text", text: "Notes and highlights — only when you've allowed it")
                        Divider().background(Theme.Palette.hairline)
                        accessRow(icon: "xmark.circle.fill", text: "Not your location, camera, microphone or other apps", isNever: true)
                        accessRow(icon: "xmark.circle.fill", text: "Not any app outside Bookmark Buddy", isNever: true)
                        Text("All data stays on your device in this MVP. No content is sent to any server.")
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .padding(.top, Theme.Spacing.sm)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("What \(PipIdentity.name) can see")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func accessRow(icon: String, text: String, isNever: Bool = false) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(isNever ? Theme.Palette.danger : Theme.Palette.forestBright)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(text)
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchment)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Notes consent gate

private struct NotesConsentGate: View {
    let onAlwaysAllow: () -> Void
    let onDenied: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                InkBackground()
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    PipAvatar(size: 72, mood: .happy)
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("Can Pip read your notes?")
                            .font(.bbTitle)
                            .foregroundStyle(Theme.Palette.parchment)
                            .multilineTextAlignment(.center)
                        Text("To help you, Pip would like to access your saved notes and highlights. Your notes stay on your device and are never sent anywhere in this MVP.")
                            .font(.bbBody)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(spacing: Theme.Spacing.sm) {
                        PrimaryButton(title: "Always Allow", systemImage: "checkmark") {
                            dismiss()
                            onAlwaysAllow()
                        }
                        SecondaryButton(title: "Not Now") {
                            dismiss()
                            onDenied()
                        }
                    }
                    Text("You can change this any time in Profile → Pip Privacy.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
            .navigationTitle("Notes Access")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Simple flow layout for chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? 300
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview("Pip Chat") {
    PipChatSheet(bookID: nil)
        .withPreviewEnvironment()
}
