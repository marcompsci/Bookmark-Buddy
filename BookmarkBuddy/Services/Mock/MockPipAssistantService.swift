// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Deterministic local command router for Pip's chat.
///
/// TODO(prod): Replace with a real AI provider. Before any request leaves the device:
/// - Send only the fields in `PipContext` (filtered by privacy settings).
/// - Require the notes/highlights consent gate for any request that includes notes.
/// - Apply rate limits and abuse monitoring server-side; never send analytics.
actor MockPipAssistantService: PipAssistantService {
    private var history: [PipMessage] = []
    private let latency: Duration

    init(latency: Duration = .milliseconds(500)) {
        self.latency = latency
    }

    func reply(to prompt: String, context: PipContext) async -> PipMessage {
        await DemoLatency.pause(latency)
        let message = route(prompt: prompt.lowercased(), context: context, raw: prompt)
        history.append(PipMessage(role: .user, text: prompt))
        history.append(message)
        return message
    }

    func resetMemory() async {
        history.removeAll()
    }

    // MARK: - Command router

    private func route(prompt: String, context: PipContext, raw: String) -> PipMessage {
        let name = context.profile?.firstName ?? "friend"

        // "What should I do next?"
        if prompt.contains("what should") || prompt.contains("do next") || prompt.contains("suggest") {
            return next(for: context, name: name)
        }

        // "Quiz me on The Glass Harbor."
        if prompt.contains("quiz") || prompt.contains("test me") {
            if let book = context.currentBook?.book ?? DemoData.books.first(where: { $0.title.localizedCaseInsensitiveContains("glass harbor") }) {
                return PipMessage(
                    role: .pip,
                    text: "Let's test your memory of \(book.title)! I'll give you three quick recall questions.",
                    action: .startQuiz(bookID: book.id)
                )
            }
            return PipMessage(role: .pip, text: "Open a book first and I'll quiz you on it!", action: .openTab(.library))
        }

        // "Summarize my current book."
        if prompt.contains("summar") || prompt.contains("recap") || prompt.contains("what's happening") {
            if let current = context.currentBook {
                return PipMessage(
                    role: .pip,
                    text: "You're on Chapter \(current.progress?.currentChapter ?? 1) of \(current.book.title). \(current.book.premise) — Demo AI summary, not a real AI response.",
                    action: .openBook(current.book.id)
                )
            }
            return PipMessage(role: .pip, text: "You don't have a book in progress yet. Head to your library and pick something!", action: .openTab(.library))
        }

        // "Show me how to create a trivia night." / "Walk me through it" → Guide Me
        let wantsWalkthrough = ["show me how", "walk me through", "guide me", "teach me", "step by step"].contains { prompt.contains($0) }
            || (prompt.contains("how do i") && (prompt.contains("event") || prompt.contains("trivia")))
        if wantsWalkthrough {
            return PipMessage(
                role: .pip,
                text: "Let's do it together. I'll highlight each step — tap Next whenever you're ready, or End guide to stop.",
                action: .startGuide(walkthroughID: DemoData.triviaNightWalkthrough.id)
            )
        }

        // "Help me create a trivia night." / "Create an event"
        if prompt.contains("trivia") || prompt.contains("create event") || prompt.contains("trivia night") {
            return PipMessage(
                role: .pip,
                text: "Trivia nights are the best! Let's set one up for \(context.squad?.name ?? "your squad").",
                action: .createEvent(.triviaNight)
            )
        }

        // "Take me to my squad."
        if prompt.contains("squad") || prompt.contains("group") {
            return PipMessage(
                role: .pip,
                text: "On your way to \(context.squad?.name ?? "your squad")!",
                action: .openTab(.squad)
            )
        }

        // "Show my upcoming event."
        if prompt.contains("event") || prompt.contains("upcoming") || prompt.contains("rsvp") {
            if let event = context.upcomingEvent {
                return PipMessage(
                    role: .pip,
                    text: "You have \"\(event.title)\" coming up \(event.startsAt.formatted(.relative(presentation: .named))).",
                    action: .showUpcomingEvent
                )
            }
            return PipMessage(role: .pip, text: "No upcoming events right now. Want to create one?", action: .createEvent(.triviaNight))
        }

        // "Start a buddy read."
        if prompt.contains("buddy read") || prompt.contains("read together") {
            return PipMessage(
                role: .pip,
                text: "A buddy read is a great way to stay motivated! Pick a book and I'll help you invite someone.",
                action: .startBuddyRead
            )
        }

        // "How do I use this app?" / "Help me navigate."
        if prompt.contains("how do i") || prompt.contains("navigate") || prompt.contains("help me") || prompt.contains("tutorial") {
            return PipMessage(
                role: .pip,
                text: "I've got you, \(name)! Here's the quick tour: Home has your current book and my daily nudge. Squad is your reading group. Play has quizzes and your memory garden. Library holds all your books. Explore lets you discover other readers. Want me to walk you through planning a trivia night?",
                action: .startGuide(walkthroughID: DemoData.triviaNightWalkthrough.id)
            )
        }

        // "What can you access?" / "What can you see?"
        if prompt.contains("access") || prompt.contains("can you see") || prompt.contains("data") || prompt.contains("privacy") {
            return PipMessage(
                role: .pip,
                text: "I can only see your reading progress, profile, squad activity, and notes if you've allowed it. I never access your camera, location, or other apps.",
                action: .showPrivacy
            )
        }

        // Fallback
        return PipMessage(
            role: .pip,
            text: "Hi \(name)! I'm not sure what you mean by that yet — try one of the quick commands, or ask me to quiz you, summarize your book, or help you navigate.",
            action: nil
        )
    }

    private func next(for context: PipContext, name: String) -> PipMessage {
        if let event = context.upcomingEvent, !event.isAttending(context.profile?.id ?? UUID()) {
            return PipMessage(
                role: .pip,
                text: "\(event.title) is coming up soon and you haven't RSVP'd yet. Want to let your squad know you're in?",
                action: .showUpcomingEvent
            )
        }
        if let current = context.currentBook {
            let chapter = current.progress?.currentChapter ?? 1
            return PipMessage(
                role: .pip,
                text: "You're on Chapter \(chapter) of \(current.book.title). Keep going — a chapter tonight keeps the streak alive!",
                action: .openBook(current.book.id)
            )
        }
        return PipMessage(
            role: .pip,
            text: "Why not pick a book from your Want to Read shelf and start the first chapter tonight?",
            action: .openTab(.library)
        )
    }
}
