// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import AppIntents
import Foundation

// MARK: - Open Current Book

struct OpenCurrentBookIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Current Book"
    static let description = IntentDescription("Opens your current book in Bookmark Buddy.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO(prod): Connect to the real BookRepository once authentication is in place.
        let currentBookTitle = DemoData.books
            .first(where: { book in DemoData.progress.first(where: { $0.bookID == book.id })?.state == .reading })
            .map(\.title)

        if let title = currentBookTitle {
            return .result(dialog: "Opening \(title) in Bookmark Buddy.")
        } else {
            return .result(dialog: "You don't have a book in progress. Head to your library to start one.")
        }
    }
}

// MARK: - Start Daily Memory Refresh

struct StartDailyMemoryRefreshIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Daily Memory Refresh"
    static let description = IntentDescription("Starts a quick memory refresh question in Bookmark Buddy.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO(prod): Connect to QuizService to pull a real spaced-repetition question.
        let finishedBook = DemoData.books
            .first(where: { book in DemoData.progress.first(where: { $0.bookID == book.id })?.state == .finished })
            .map(\.title)

        if let title = finishedBook {
            return .result(dialog: "Let's refresh your memory of \(title). Opening Bookmark Buddy now.")
        } else {
            return .result(dialog: "Finish a book first — then I'll quiz you on it every day!")
        }
    }
}

// MARK: - Open Upcoming Reading Event

struct OpenUpcomingReadingEventIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Upcoming Reading Event"
    static let description = IntentDescription("Shows your next reading event in Bookmark Buddy.")
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // TODO(prod): Fetch from EventService with the authenticated user's squad ID.
        if let event = DemoData.events.first {
            let timeString = event.startsAt.formatted(.relative(presentation: .named))
            return .result(dialog: "\(event.title) is \(timeString). Opening Bookmark Buddy.")
        } else {
            return .result(dialog: "No upcoming events right now. Create one in your squad!")
        }
    }
}

// MARK: - App Shortcuts

struct BookmarkBuddyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCurrentBookIntent(),
            phrases: ["Open my current book in \(.applicationName)", "Continue reading in \(.applicationName)"],
            shortTitle: "Current Book",
            systemImageName: "book.fill"
        )
        AppShortcut(
            intent: StartDailyMemoryRefreshIntent(),
            phrases: ["Start my memory refresh in \(.applicationName)", "Quiz me in \(.applicationName)"],
            shortTitle: "Memory Refresh",
            systemImageName: "brain.head.profile"
        )
        AppShortcut(
            intent: OpenUpcomingReadingEventIntent(),
            phrases: ["Show my next reading event in \(.applicationName)", "What's my next book event in \(.applicationName)"],
            shortTitle: "Upcoming Event",
            systemImageName: "calendar"
        )
    }
}
