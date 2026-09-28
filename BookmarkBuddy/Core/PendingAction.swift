// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Every consequential action in the app is described by a `PendingAction` and must be
/// approved in `ConfirmationSheet` before it runs. Keeping them in one enum means there is
/// exactly one gate to audit.
enum PendingAction: Identifiable, Hashable, Sendable {
    case sendInvites(memberNames: [String], context: String)
    case postToSquad(message: String)
    case createEvent(ReadingEvent)
    case startBuddyRead(BuddyRead, inviteeNames: [String])
    case challengeSquad(QuizResult)
    case deleteNote(BookNote)
    case resetPipMemory
    case deleteAllLocalData
    case reportContent(ActivityFeedItem, reporterNote: String)
    case blockMember(SquadMember)

    var id: String {
        switch self {
        case .sendInvites(let names, let context): "invite-\(names.joined(separator: ","))-\(context)"
        case .postToSquad(let message): "post-\(message.hashValue)"
        case .createEvent(let event): "event-\(event.id)"
        case .startBuddyRead(let read, _): "buddy-\(read.id)"
        case .challengeSquad(let result): "challenge-\(result.id)"
        case .deleteNote(let note): "delete-note-\(note.id)"
        case .resetPipMemory: "reset-pip"
        case .deleteAllLocalData: "delete-all"
        case .reportContent(let item, _): "report-\(item.id)"
        case .blockMember(let member): "block-\(member.id)"
        }
    }

    var title: String {
        switch self {
        case .sendInvites: "Send invites?"
        case .postToSquad: "Post to your squad?"
        case .createEvent(let event): "Create \(event.type.displayName)?"
        case .startBuddyRead: "Start this buddy read?"
        case .challengeSquad: "Challenge your squad?"
        case .deleteNote: "Delete this note?"
        case .resetPipMemory: "Reset Pip's memory?"
        case .deleteAllLocalData: "Delete all your data?"
        case .reportContent: "Report this activity?"
        case .blockMember(let member): "Block \(member.displayName)?"
        }
    }

    var message: String {
        switch self {
        case .sendInvites(let names, let context):
            "\(ListFormatter.localizedString(byJoining: names)) will get an invite to \(context)."
        case .postToSquad(let message):
            "Everyone in your squad will see: “\(message)”"
        case .createEvent(let event):
            "“\(event.title)” will appear on your squad's calendar and members will be notified."
        case .startBuddyRead(_, let names):
            "\(ListFormatter.localizedString(byJoining: names)) will be invited to read with you."
        case .challengeSquad(let result):
            "Your squad will see your score (\(result.correctCount)/\(result.totalCount)) and an invite to beat it."
        case .deleteNote:
            "This note will be removed from this device. This can't be undone."
        case .resetPipMemory:
            "Pip will forget your chat history and any notes consent. Your books, notes and squad stay as they are."
        case .deleteAllLocalData:
            "Your profile, notes, saved moments and settings will be erased from this device, and onboarding will restart."
        case .reportContent:
            "Our team will review this activity. The member won't be told who reported it."
        case .blockMember(let member):
            "You won't see \(member.displayName)'s activity, and they won't be able to invite you."
        }
    }

    var confirmTitle: String {
        switch self {
        case .sendInvites: "Send invites"
        case .postToSquad: "Post"
        case .createEvent: "Create event"
        case .startBuddyRead: "Start & invite"
        case .challengeSquad: "Send challenge"
        case .deleteNote: "Delete note"
        case .resetPipMemory: "Reset Pip"
        case .deleteAllLocalData: "Delete everything"
        case .reportContent: "Report"
        case .blockMember: "Block"
        }
    }

    var systemImage: String {
        switch self {
        case .sendInvites: "paperplane.fill"
        case .postToSquad: "text.bubble.fill"
        case .createEvent: "calendar.badge.plus"
        case .startBuddyRead: "person.2.fill"
        case .challengeSquad: "flag.checkered"
        case .deleteNote: "trash.fill"
        case .resetPipMemory: "arrow.counterclockwise"
        case .deleteAllLocalData: "trash.fill"
        case .reportContent: "exclamationmark.bubble.fill"
        case .blockMember: "hand.raised.fill"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .deleteNote, .resetPipMemory, .deleteAllLocalData, .blockMember: true
        default: false
        }
    }

    /// Short note explaining that this is a local demo action.
    var demoFootnote: String {
        "Demo: this only updates data on this device. Nothing is sent anywhere."
    }
}
