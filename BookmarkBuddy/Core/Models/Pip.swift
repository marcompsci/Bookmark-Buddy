// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Things Pip is allowed to do. Every case is an in-app action; Pip never acts outside this app.
/// Consequential actions (sending invites, posting, creating events) still pass through a confirmation sheet.
enum PipAction: Codable, Hashable, Sendable {
    case openTab(AppTab)
    case openBook(UUID)
    case startQuiz(bookID: UUID)
    case createEvent(EventType)
    case startBuddyRead
    case showUpcomingEvent
    case startGuide(walkthroughID: String)
    case showPrivacy

    var buttonTitle: String {
        switch self {
        case .openTab(let tab): "Go to \(tab.title)"
        case .openBook: "Open book"
        case .startQuiz: "Start quiz"
        case .createEvent(let type): "Set up \(type.displayName)"
        case .startBuddyRead: "Start a buddy read"
        case .showUpcomingEvent: "Show event"
        case .startGuide: "Guide me"
        case .showPrivacy: "What Pip can see"
        }
    }
}

enum PipRole: String, Codable, Hashable, Sendable {
    case user, pip
}

struct PipMessage: Codable, Identifiable, Hashable, Sendable {
    var id: UUID = UUID()
    var role: PipRole
    var text: String
    var action: PipAction?
    var createdAt: Date = .now
}

enum NotesConsent: String, Codable, CaseIterable, Hashable, Sendable {
    /// The consent gate has not been shown yet.
    case notAsked
    /// "Always Allow".
    case always
    /// "Not Now" — Pip won't use notes until the person turns it on in Profile.
    case denied
}

struct PipPermissionSettings: Codable, Hashable, Sendable {
    var activityVisibility: ActivityVisibility = .squad
    var allowReadingProgress: Bool = true
    var notesConsent: NotesConsent = .notAsked

    var allowsNotes: Bool { notesConsent == .always }

    static let `default` = PipPermissionSettings()
}

/// Everything Pip may consider when replying. Built fresh for each request from local data,
/// filtered by the person's privacy settings. Nothing here leaves the device in the MVP.
struct PipContext: Sendable {
    var profile: UserProfile?
    var currentBook: BookWithProgress?
    var squad: ReadingSquad?
    var upcomingEvent: ReadingEvent?
    /// Present only when the person has allowed Pip to use notes (always, or once for this request).
    var notes: [BookNote]?
    var moments: [SavedMoment]?

    static let empty = PipContext()
}
