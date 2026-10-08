// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI

/// "Recommend a book" — readers suggest what Omari should read next.
/// The pick lands on the floating shelf for everyone to see.
struct DLRecommendView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.services) private var services
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var title = ""
    @State private var author = ""
    @State private var from = ""
    @State private var note = ""
    @State private var colorIndex = 1
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var saved: DLRecommendation?
    @State private var dropped = false

    private typealias Limits = DLRecommendation.Limits

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        DLEyebrow(text: "Page three")
                        DLTypewriterText(text: "Recommend a book")
                        Text("Tell me what I should read next. Your pick goes on the floating shelf under my library, spine out, for everyone to see.")
                            .font(.bbBody)
                            .foregroundStyle(Theme.Palette.parchmentMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let saved { success(saved) } else { form }
                }
                .padding(Theme.Spacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Recommend a book")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Form

    private var form: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            field("Book title", text: $title, limit: Limits.title, required: true)
            field("Author", text: $author, limit: Limits.author, required: true)
            field("Your name (optional)", text: $from, limit: Limits.from)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    DLEyebrow(text: "Why should I read it? (optional)")
                    Spacer()
                    Text("\(note.count) / \(Limits.note)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(note.count >= Limits.note ? Theme.Palette.gold : Theme.Palette.parchmentMuted)
                        .accessibilityLabel("\(note.count) of \(Limits.note) characters")
                }
                TextField("", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .modifier(DLFieldStyle())
                    .onChange(of: note) { if note.count > Limits.note { note = String(note.prefix(Limits.note)) } }
                    .accessibilityLabel("Why should I read it")
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                DLEyebrow(text: "Spine color")
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(DLRecommendation.palette.indices, id: \.self) { index in
                        Button {
                            colorIndex = index
                        } label: {
                            Circle()
                                .fill(Color(hex: DLRecommendation.palette[index].background))
                                .frame(width: 30, height: 30)
                                .overlay(Circle().strokeBorder(Theme.Palette.parchment, lineWidth: colorIndex == index ? 3 : 0.5))
                                .frame(width: 38, height: Theme.minTapTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Color \(index + 1) of \(DLRecommendation.palette.count)")
                        .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                    }
                }
            }

            preview

            if let errorMessage {
                Text(errorMessage)
                    .font(.bbCallout)
                    .foregroundStyle(Theme.Palette.gold)
                    .accessibilityAddTraits(.updatesFrequently)
            }

            PrimaryButton(title: "Add it to the shelf", systemImage: "books.vertical", isLoading: isSaving) {
                Task { await submit() }
            }
            .disabled(isSaving)

            Text("Recommendations are visible to everyone who uses the app.")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
        }
    }

    /// Live preview of the flat book on a mini plank.
    private var preview: some View {
        VStack(spacing: 0) {
            DLFlatBookView(recommendation: draft, width: 220)
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [Color(hex: "#6B5440"), Color(hex: "#43331F")], startPoint: .top, endPoint: .bottom))
                .frame(width: 250, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview: \(draft.title) by \(draft.author)")
    }

    private var draft: DLRecommendation {
        DLRecommendation(
            id: "draft",
            title: title.isEmpty ? "Book title" : title,
            author: author.isEmpty ? "Author" : author,
            from: from, note: note, colorIndex: colorIndex, createdAt: .now
        )
    }

    private func field(_ label: String, text: Binding<String>, limit: Int, required: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            DLEyebrow(text: label)
            TextField("", text: text)
                .modifier(DLFieldStyle())
                .onChange(of: text.wrappedValue) {
                    if text.wrappedValue.count > limit { text.wrappedValue = String(text.wrappedValue.prefix(limit)) }
                }
                .accessibilityLabel(label)
                .accessibilityHint(required ? "Required, up to \(limit) characters" : "Up to \(limit) characters")
        }
    }

    // MARK: Success

    private func success(_ rec: DLRecommendation) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: 0) {
                DLFlatBookView(recommendation: rec, width: 220)
                    .offset(y: dropped ? 0 : -120)
                    .opacity(dropped ? 1 : 0)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [Color(hex: "#6B5440"), Color(hex: "#43331F")], startPoint: .top, endPoint: .bottom))
                    .frame(width: 250, height: 8)
            }
            .onAppear {
                if reduceMotion { dropped = true } else {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.5)) { dropped = true }
                }
            }
            Text("It's on the shelf.")
                .font(.system(.title2, design: .serif).italic())
                .foregroundStyle(Theme.Palette.parchment)
            HStack(spacing: Theme.Spacing.sm) {
                DLPillButton(title: "See it on the shelf") {
                    dismiss()
                }
                DLPillButton(title: "Recommend another", filled: false) {
                    title = ""; author = ""; note = ""; errorMessage = nil
                    dropped = false
                    saved = nil
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }

    // MARK: Submit

    private func submit() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            let rec = try await services.shelfRecommendations.add(
                title: title, author: author, from: from, note: note, colorIndex: colorIndex
            )
            saved = rec
            router.dataChanged()
            router.showToast("Added to Omari's shelf")
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't save that right now. Try again in a moment."
        }
    }
}

private struct DLFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.bbBody)
            .foregroundStyle(Theme.Palette.parchment)
            .padding(Theme.Spacing.md)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm).fill(Theme.Palette.inkHighlight))
    }
}

#Preview {
    NavigationStack { DLRecommendView() }
        .withPreviewEnvironment()
}
