// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Runs a `PendingAction` after the person has approved it in `ConfirmationSheet`.
/// This is the only place consequential actions execute, which keeps the confirmation
/// gate easy to audit: nothing here is reachable without passing through the sheet.
@MainActor
struct ActionPerformer {
    let services: AppServices
    let appState: AppState
    let router: AppRouter

    func perform(_ action: PendingAction) async {
        do {
            switch action {
            case .sendInvites(let names, _):
                // TODO(prod): Send invites server-side with rate limits and recipient consent.
                router.showToast("Invite sent to \(ListFormatter.localizedString(byJoining: names))", systemImage: "paperplane.fill")

            case .postToSquad(let message):
                try await postActivity(kind: .reaction, message: message)
                router.showToast("Posted to your squad")

            case .createEvent(let event):
                let created = try await services.events.create(event)
                try await postActivity(kind: .eventCreated, message: "created \(created.title)")
                router.showToast("\(created.title) is on the calendar", systemImage: "calendar.badge.checkmark")

            case .startBuddyRead(let buddyRead, let names):
                _ = try await services.events.startBuddyRead(buddyRead)
                let title = (try? await services.books.book(id: buddyRead.bookID))?.title ?? "a book"
                try await postActivity(kind: .buddyReadStarted, message: "started a buddy read of \(title)")
                router.showToast("Buddy read started with \(ListFormatter.localizedString(byJoining: names))", systemImage: "person.2.fill")

            case .challengeSquad(let result):
                try await postActivity(kind: .quizWin, message: "scored \(result.correctCount)/\(result.totalCount) — can you beat it?")
                router.showToast("Challenge sent to your squad", systemImage: "flag.checkered")

            case .deleteNote(let note):
                try await services.books.deleteNote(id: note.id)
                router.showToast("Note deleted", systemImage: "trash")

            case .resetPipMemory:
                await services.pip.resetMemory()
                await appState.updatePipPermissions { $0.notesConsent = .notAsked }
                router.showToast("\(PipIdentity.name)'s memory was reset", systemImage: "arrow.counterclockwise")

            case .deleteAllLocalData:
                await appState.deleteAllData()
                UserDefaults.standard.set(false, forKey: StorageKeys.hasCompletedOnboarding)
                router.reset()

            case .reportContent(let item, let note):
                _ = try await services.moderation.report(item: item, note: note)
                router.showToast("Thanks — we'll review it", systemImage: "exclamationmark.bubble.fill")

            case .blockMember(let member):
                try await services.moderation.block(memberID: member.id)
                router.showToast("\(member.displayName) is blocked", systemImage: "hand.raised.fill")
            }
            router.dataChanged()
        } catch {
            router.showToast("That didn't work. Please try again.", systemImage: "exclamationmark.triangle.fill")
        }
    }

    private func postActivity(kind: ActivityKind, message: String) async throws {
        guard let profile = appState.profile else { return }
        let item = ActivityFeedItem(memberID: profile.id, kind: kind, message: message, timestamp: .now)
        try await services.squads.post(item, squadID: DemoData.IDs.midnightMargins)
    }
}
