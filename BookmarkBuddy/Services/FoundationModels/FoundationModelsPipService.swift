// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import FoundationModels

/// Pip powered by Apple Intelligence for open-ended questions.
/// Navigation and action commands are still handled by the rule-based router
/// so that in-app actions (quiz, open squad, create event) keep working.
/// Falls back gracefully to the router when the model is unavailable.
@available(iOS 26, *)
actor FoundationModelsPipService: PipAssistantService {

    private let router = MockPipAssistantService(latency: .zero)
    private var session: LanguageModelSession?

    func reply(to prompt: String, context: PipContext) async -> PipMessage {
        if isActionableCommand(prompt.lowercased()) {
            return await router.reply(to: prompt, context: context)
        }
        guard SystemLanguageModel.default.availability == .available else {
            return await router.reply(to: prompt, context: context)
        }
        do {
            let response = try await currentSession(context: context)
                .respond(to: buildPrompt(from: prompt, context: context))
            return PipMessage(role: .pip, text: response.content)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Context full — reset and retry with just the bare prompt.
            session = nil
            do {
                let response = try await currentSession(context: context).respond(to: prompt)
                return PipMessage(role: .pip, text: response.content)
            } catch {
                return await router.reply(to: prompt, context: context)
            }
        } catch {
            return await router.reply(to: prompt, context: context)
        }
    }

    func resetMemory() async {
        session = nil
        await router.resetMemory()
    }

    // MARK: - Helpers

    /// Returns true for prompts that map to in-app navigation actions so the
    /// rule-based router handles them and returns a PipMessage with an action attached.
    private func isActionableCommand(_ lower: String) -> Bool {
        let triggers = [
            "quiz", "test me", "squad", "group", "buddy read", "read together",
            "event", "rsvp", "upcoming", "navigate", "go to", "guide me",
            "walk me through", "show me how", "step by step", "tutorial",
            "summarize", "recap", "what's happening", "what should", "do next",
            "suggest", "what can you", "can you see", "privacy", "access", "help me"
        ]
        return triggers.contains { lower.contains($0) }
    }

    private func currentSession(context: PipContext) -> LanguageModelSession {
        if let s = session { return s }
        let name = context.profile?.firstName ?? "friend"
        let s = LanguageModelSession(instructions: """
            You are Pip, a warm and knowledgeable reading companion inside BookmarkBuddy. \
            You are helping \(name) with their reading life. \
            Keep every response to 2–3 sentences — concise, encouraging, and specific. \
            You only discuss books, reading habits, authors, themes, and the BookmarkBuddy app. \
            Politely decline anything unrelated to reading.
            """)
        session = s
        return s
    }

    private func buildPrompt(from userMessage: String, context: PipContext) -> String {
        var parts: [String] = []
        if let book = context.currentBook {
            let ch = book.progress?.currentChapter ?? 1
            parts.append("Currently reading: \"\(book.book.title)\" by \(book.book.author), Chapter \(ch).")
        }
        if let squad = context.squad {
            parts.append("Reading squad: \(squad.name).")
        }
        if let event = context.upcomingEvent {
            parts.append("Upcoming event: \(event.title).")
        }
        guard !parts.isEmpty else { return userMessage }
        return "[Context: \(parts.joined(separator: " "))]\n\(userMessage)"
    }
}
