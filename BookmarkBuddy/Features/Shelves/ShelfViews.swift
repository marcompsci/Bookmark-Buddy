// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

// MARK: - Spine row

/// A row of spines on a ledge — the same look as Omari's Digital Library.
struct ShelfSpineRow: View {
    let entries: [ShelfEntry]
    var scale: CGFloat = 0.5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(entries) { entry in
                        DLSpineView(book: entry.spineBook, scale: scale)
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(hex: "#5A4632"), Color(hex: "#3B2D20")], startPoint: .top, endPoint: .bottom))
                    .frame(height: 9)
                    .shadow(color: .black.opacity(0.5), radius: 5, y: 4)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shelf with \(entries.count) books: " + entries.prefix(10).map { "\($0.title) by \($0.author)" }.joined(separator: ", "))
    }
}

// MARK: - My shelf (editor)

struct MyShelfView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.services) private var services

    @State private var shelf = ReaderShelf.empty
    @State private var entries: [ShelfEntry] = []
    @State private var hasSavedShelf = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showAddBook = false
    @State private var shareImage: Image?

    var body: some View {
        ZStack {
            InkBackground()
            if isLoading {
                ProgressView().tint(Theme.Palette.parchment)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        intro
                        if !entries.isEmpty { ShelfSpineRow(entries: entries) }
                        detailsCard
                        booksCard
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.bbCallout)
                                .foregroundStyle(Theme.Palette.gold)
                        }
                        PrimaryButton(title: hasSavedShelf ? "Save changes" : "Create my shelf", systemImage: "checkmark.circle", isLoading: isSaving) {
                            Task { await saveShelf() }
                        }
                        .disabled(isSaving)
                        if hasSavedShelf, shelf.isPublic, !entries.isEmpty { shareCard }
                    }
                    .padding(Theme.Spacing.lg)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle("My Shelf")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showAddBook) {
            AddShelfBookSheet { title, author, note, color in
                try await addBook(title: title, author: author, note: note, colorIndex: color)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            DLEyebrow(text: "Your shelf")
            Text("The books that shaped you, spine out.")
                .font(.system(.title2, design: .serif).italic())
                .foregroundStyle(Theme.Palette.parchment)
            Text("Make it public and anyone with Bookmark Buddy can open it from your link. Share the card on Instagram or TikTok.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                DLEyebrow(text: "Handle")
                HStack(spacing: 2) {
                    Text("@").foregroundStyle(Theme.Palette.parchmentMuted)
                    TextField("", text: $shelf.handle, prompt: Text("yourname").foregroundStyle(Theme.Palette.parchmentMuted))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: shelf.handle) {
                            let normalized = ReaderShelf.normalizedHandle(shelf.handle)
                            if normalized != shelf.handle { shelf.handle = normalized }
                        }
                        .accessibilityLabel("Handle")
                        .accessibilityHint("3 to 24 lowercase letters, numbers or underscores")
                }
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
            }
            field("Display name", text: $shelf.displayName, limit: ReaderShelf.Limits.displayName, prompt: appState.profile?.displayName ?? "Your name")
            field("Short bio", text: $shelf.bio, limit: ReaderShelf.Limits.bio, prompt: "What you read and why")
            Toggle(isOn: $shelf.isPublic) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Public shelf").font(.bbHeadline).foregroundStyle(Theme.Palette.parchment)
                    Text("Anyone with the app can see your shelf, handle and bio. Notes on books are public too.")
                        .font(.bbCaption)
                        .foregroundStyle(Theme.Palette.parchmentMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.Palette.gold)
        }
        .bbCard()
    }

    private func field(_ label: String, text: Binding<String>, limit: Int, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            DLEyebrow(text: label)
            TextField("", text: text, prompt: Text(prompt).foregroundStyle(Theme.Palette.parchmentMuted))
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
                .onChange(of: text.wrappedValue) {
                    if text.wrappedValue.count > limit { text.wrappedValue = String(text.wrappedValue.prefix(limit)) }
                }
                .accessibilityLabel(label)
        }
    }

    private var booksCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                SectionHeader(title: "Books (\(entries.count)/\(ReaderShelf.Limits.books))")
                Spacer()
                Button {
                    showAddBook = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.gold)
                        .frame(minHeight: Theme.minTapTarget)
                }
                .disabled(!hasSavedShelf || entries.count >= ReaderShelf.Limits.books)
            }
            if !hasSavedShelf {
                Text("Create your shelf first, then add books.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            } else if entries.isEmpty {
                Text("No books yet. Add the ones you'd hand a friend.")
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.parchmentMuted)
            }
            ForEach(entries) { entry in
                HStack(spacing: Theme.Spacing.md) {
                    Color(hex: DLRecommendation.palette[min(max(entry.colorIndex, 0), 7)].background)
                        .frame(width: 6, height: 40)
                        .clipShape(Capsule())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: entry.title)
                            .font(.system(.body, design: .serif).italic())
                            .foregroundStyle(Theme.Palette.parchment)
                        Text(verbatim: entry.author)
                            .font(.bbCaption)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        Task { await remove(entry) }
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(Theme.Palette.danger)
                            .frame(minWidth: Theme.minTapTarget, minHeight: Theme.minTapTarget)
                    }
                    .accessibilityLabel("Remove \(entry.title)")
                }
            }
        }
        .bbCard()
    }

    private var shareCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(title: "Share", subtitle: "A ready-made image for your stories, plus your shelf link.")
            ShelfShareCard(shelf: shelf, entries: entries)
                .scaleEffect(0.8)
                .frame(width: 288, height: 512)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            if let shareImage, let url = shelf.shareURL {
                ShareLink(
                    item: shareImage,
                    subject: Text("My Bookmark Buddy shelf"),
                    message: Text("The books that shaped me — open my shelf in Bookmark Buddy: \(url.absoluteString)"),
                    preview: SharePreview("@\(shelf.handle) on Bookmark Buddy", image: shareImage)
                ) {
                    Label("Share my shelf", systemImage: "square.and.arrow.up")
                        .font(.bbHeadline)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                        .background(Capsule().fill(Theme.Palette.gold))
                }
                Button {
                    router.push(.publicShelf(handle: shelf.handle))
                } label: {
                    Text("See it the way others do")
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.lavender)
                        .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
                }
            }
        }
        .task(id: "\(shelf.handle)|\(entries.count)") { renderShareImage() }
    }

    // MARK: Actions

    private func load() async {
        defer { isLoading = false }
        do {
            if let snapshot = try await services.shelves.myShelf() {
                shelf = snapshot.shelf
                entries = snapshot.entries
                hasSavedShelf = true
            } else {
                shelf.displayName = appState.profile?.displayName ?? ""
                shelf.handle = ReaderShelf.normalizedHandle(appState.profile?.displayName ?? "")
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't load your shelf."
        }
    }

    private func saveShelf() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await services.shelves.save(shelf)
            let wasNew = !hasSavedShelf
            hasSavedShelf = true
            router.dataChanged()
            router.showToast(wasNew ? "Shelf created" : "Shelf saved")
            if wasNew { showAddBook = true }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? ShelfError.server.errorDescription
        }
    }

    private func addBook(title: String, author: String, note: String, colorIndex: Int) async throws {
        let entry = try await services.shelves.addEntry(title: title, author: author, note: note, colorIndex: colorIndex)
        entries.append(entry)
        router.dataChanged()
    }

    private func remove(_ entry: ShelfEntry) async {
        do {
            try await services.shelves.removeEntry(id: entry.id)
            entries.removeAll { $0.id == entry.id }
            router.dataChanged()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? ShelfError.server.errorDescription
        }
    }

    @MainActor
    private func renderShareImage() {
        let renderer = ImageRenderer(content: ShelfShareCard(shelf: shelf, entries: entries))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }
}

// MARK: - Add a book

struct AddShelfBookSheet: View {
    let onAdd: (_ title: String, _ author: String, _ note: String, _ colorIndex: Int) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.services) private var services
    @State private var title = ""
    @State private var author = ""
    @State private var note = ""
    @State private var colorIndex = 1
    @State private var library: [Book] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    if !library.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            DLEyebrow(text: "From your library")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    ForEach(library) { book in
                                        FilterChip(title: book.title, isSelected: title == book.title, style: .subtle) {
                                            title = book.title
                                            author = book.author
                                        }
                                    }
                                }
                            }
                        }
                    }
                    input("Title", text: $title, limit: DLRecommendation.Limits.title)
                    input("Author", text: $author, limit: DLRecommendation.Limits.author)
                    input("Why it matters to you (optional)", text: $note, limit: DLRecommendation.Limits.note, axis: .vertical)
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        DLEyebrow(text: "Spine color")
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(DLRecommendation.palette.indices, id: \.self) { index in
                                Button { colorIndex = index } label: {
                                    Circle()
                                        .fill(Color(hex: DLRecommendation.palette[index].background))
                                        .frame(width: 28, height: 28)
                                        .overlay(Circle().strokeBorder(Theme.Palette.parchment, lineWidth: colorIndex == index ? 3 : 0.5))
                                        .frame(width: 36, height: Theme.minTapTarget)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Color \(index + 1)")
                                .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                            }
                        }
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.bbCallout).foregroundStyle(Theme.Palette.gold)
                    }
                    PrimaryButton(title: "Add to shelf", systemImage: "plus", isLoading: isSaving) {
                        Task { await add() }
                    }
                    .disabled(isSaving)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(InkBackground())
            .navigationTitle("Add a book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task { library = (try? await services.books.allBooks()) ?? [] }
        }
        .presentationDragIndicator(.visible)
    }

    private func input(_ label: String, text: Binding<String>, limit: Int, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            DLEyebrow(text: label)
            TextField("", text: text, axis: axis)
                .lineLimit(axis == .vertical ? 3 : 1)
                .font(.bbBody)
                .foregroundStyle(Theme.Palette.parchment)
                .padding(Theme.Spacing.md)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
                .onChange(of: text.wrappedValue) {
                    if text.wrappedValue.count > limit { text.wrappedValue = String(text.wrappedValue.prefix(limit)) }
                }
                .accessibilityLabel(label)
        }
    }

    private func add() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            try await onAdd(title, author, note, colorIndex)
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? ShelfError.server.errorDescription
        }
    }
}

// MARK: - Public shelf (read-only)

struct PublicShelfView: View {
    let handle: String

    @Environment(\.services) private var services
    @State private var snapshot: ShelfSnapshot?
    @State private var isLoading = true
    @State private var failed = false

    var body: some View {
        ZStack {
            InkBackground()
            if isLoading {
                ProgressView().tint(Theme.Palette.parchment)
            } else if let snapshot {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            DLEyebrow(text: "@\(snapshot.shelf.handle)")
                            Text(verbatim: snapshot.shelf.displayName.isEmpty ? "@\(snapshot.shelf.handle)" : snapshot.shelf.displayName)
                                .font(.system(.largeTitle, design: .serif).italic())
                                .foregroundStyle(Theme.Palette.parchment)
                            if !snapshot.shelf.bio.isEmpty {
                                Text(verbatim: snapshot.shelf.bio)
                                    .font(.bbBody)
                                    .foregroundStyle(Theme.Palette.parchmentMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text("\(snapshot.entries.count) VOLUMES")
                                .font(.system(.caption, design: .monospaced).weight(.semibold))
                                .tracking(2)
                                .foregroundStyle(Theme.Palette.gold)
                        }
                        ShelfSpineRow(entries: snapshot.entries, scale: 0.55)
                        LazyVStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            ForEach(snapshot.entries) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(verbatim: entry.title)
                                        .font(.system(.title3, design: .serif).italic())
                                        .foregroundStyle(Theme.Palette.parchment)
                                    Text(verbatim: entry.author)
                                        .font(.bbCallout)
                                        .foregroundStyle(Theme.Palette.gold)
                                    if !entry.note.isEmpty {
                                        Text(verbatim: entry.note)
                                            .font(.bbCallout)
                                            .foregroundStyle(Theme.Palette.parchmentMuted)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .bbCard()
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            } else {
                EmptyStateView(
                    systemImage: "books.vertical",
                    title: "Shelf not found",
                    message: failed ? "Couldn't load this shelf. Try again in a moment." : "There's no public shelf at @\(handle)."
                )
            }
        }
        .navigationTitle("@\(handle)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            defer { isLoading = false }
            do {
                snapshot = try await services.shelves.publicShelf(handle: handle)
            } catch {
                failed = true
            }
        }
    }
}

// MARK: - Share card (rendered to an image)

/// A 9:16 story card: handle, spines on a ledge, and the app name. Rendered with ImageRenderer.
struct ShelfShareCard: View {
    let shelf: ReaderShelf
    let entries: [ShelfEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A PERSONAL ARCHIVE")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(Theme.Palette.parchmentMuted)
            Text(verbatim: shelf.displayName.isEmpty ? "@\(shelf.handle)" : shelf.displayName)
                .font(.system(size: 34, weight: .medium, design: .serif).italic())
                .foregroundStyle(Theme.Palette.parchment)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            Text("\(entries.count) BOOKS THAT SHAPED ME")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(Theme.Palette.gold)
            Spacer(minLength: 0)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(entries.prefix(9)) { entry in
                        DLSpineView(book: entry.spineBook, scale: 0.6)
                    }
                }
                .padding(.horizontal, 6)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(hex: "#5A4632"), Color(hex: "#3B2D20")], startPoint: .top, endPoint: .bottom))
                    .frame(height: 10)
            }
            Spacer(minLength: 0)
            HStack {
                Text(verbatim: "@\(shelf.handle)")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.Palette.parchment)
                Spacer()
                Text("Bookmark Buddy")
                    .font(.system(size: 15, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(Theme.Palette.gold)
            }
        }
        .padding(28)
        .frame(width: 360, height: 640)
        .background(
            LinearGradient(colors: [Theme.Palette.ink, Theme.Palette.inkRaised], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview("Share card") {
    ShelfShareCard(
        shelf: ReaderShelf(handle: "omari", displayName: "Omari Bell", bio: "", isPublic: true),
        entries: ["Atomic Habits", "Open", "The Alchemist", "Outliers", "It"].enumerated().map {
            ShelfEntry(id: UUID(), title: $1, author: "Author", note: "", colorIndex: $0, position: $0)
        }
    )
    .padding()
    .background(Color.black)
}
