// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

// MARK: - Row types

private struct SupabaseEventRow: Codable, Sendable {
    let id: UUID
    let squadId: UUID
    let eventType: String
    let title: String
    let startsAt: Date
    let durationMinutes: Int
    let hostMemberId: UUID
    let rsvpMemberIds: [UUID]
    let bookId: UUID?
    let notes: String
    enum CodingKeys: String, CodingKey {
        case id, title, notes
        case squadId        = "squad_id"
        case eventType      = "event_type"
        case startsAt       = "starts_at"
        case durationMinutes = "duration_minutes"
        case hostMemberId   = "host_member_id"
        case rsvpMemberIds  = "rsvp_member_ids"
        case bookId         = "book_id"
    }
    var toEvent: ReadingEvent {
        ReadingEvent(
            id: id, squadID: squadId,
            type: EventType(rawValue: eventType) ?? .readTogether,
            title: title, startsAt: startsAt,
            durationMinutes: durationMinutes,
            hostMemberID: hostMemberId,
            rsvpMemberIDs: rsvpMemberIds,
            bookID: bookId, notes: notes
        )
    }
}

private struct BuddyReadRow: Codable, Sendable {
    let id: UUID
    let bookId: UUID
    let invitedMemberIds: [UUID]
    let goalDate: Date
    let spoilerLevel: String
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id
        case bookId            = "book_id"
        case invitedMemberIds  = "invited_member_ids"
        case goalDate          = "goal_date"
        case spoilerLevel      = "spoiler_level"
        case createdAt         = "created_at"
    }
    var toBuddyRead: BuddyRead {
        BuddyRead(
            id: id, bookID: bookId,
            invitedMemberIDs: invitedMemberIds,
            goalDate: goalDate,
            spoilerLevel: SpoilerLevel(rawValue: spoilerLevel) ?? .currentChapter,
            createdAt: createdAt
        )
    }
}

// MARK: - Service

struct SupabaseEventService: EventService {

    private let db = SupabaseManager.shared.client

    func upcomingEvents(squadID: UUID) async throws -> [ReadingEvent] {
        let rows: [SupabaseEventRow] = try await db.from("reading_events")
            .select()
            .eq("squad_id", value: squadID.uuidString)
            .gte("starts_at", value: ISO8601DateFormatter().string(from: .now))
            .order("starts_at", ascending: true)
            .execute()
            .value
        return rows.map { $0.toEvent }
    }

    func event(id: UUID) async throws -> ReadingEvent {
        let rows: [SupabaseEventRow] = try await db.from("reading_events")
            .select()
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { throw RepositoryError.notFound }
        return row.toEvent
    }

    func create(_ event: ReadingEvent) async throws -> ReadingEvent {
        struct Insert: Encodable {
            let id: UUID; let squadId: UUID; let eventType: String
            let title: String; let startsAt: Date; let durationMinutes: Int
            let hostMemberId: UUID; let rsvpMemberIds: [UUID]; let bookId: UUID?; let notes: String
            enum CodingKeys: String, CodingKey {
                case id, title, notes
                case squadId         = "squad_id"
                case eventType       = "event_type"
                case startsAt        = "starts_at"
                case durationMinutes = "duration_minutes"
                case hostMemberId    = "host_member_id"
                case rsvpMemberIds   = "rsvp_member_ids"
                case bookId          = "book_id"
            }
        }
        let insert = Insert(
            id: event.id, squadId: event.squadID, eventType: event.type.rawValue,
            title: event.title, startsAt: event.startsAt, durationMinutes: event.durationMinutes,
            hostMemberId: event.hostMemberID, rsvpMemberIds: event.rsvpMemberIDs,
            bookId: event.bookID, notes: event.notes
        )
        try await db.from("reading_events").insert(insert).execute()
        return event
    }

    func setRSVP(eventID: UUID, memberID: UUID, attending: Bool) async throws -> ReadingEvent {
        struct Args: Encodable { let event_id: UUID; let member_id: UUID; let attending: Bool }
        let rows: [SupabaseEventRow] = try await db.rpc("set_event_rsvp",
            params: Args(event_id: eventID, member_id: memberID, attending: attending))
            .execute()
            .value
        guard let row = rows.first else { throw RepositoryError.notFound }
        return row.toEvent
    }

    func startBuddyRead(_ buddyRead: BuddyRead) async throws -> BuddyRead {
        struct Insert: Encodable {
            let id: UUID; let bookId: UUID; let invitedMemberIds: [UUID]
            let goalDate: Date; let spoilerLevel: String; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id
                case bookId           = "book_id"
                case invitedMemberIds = "invited_member_ids"
                case goalDate         = "goal_date"
                case spoilerLevel     = "spoiler_level"
                case createdAt        = "created_at"
            }
        }
        try await db.from("buddy_reads").insert(Insert(
            id: buddyRead.id, bookId: buddyRead.bookID,
            invitedMemberIds: buddyRead.invitedMemberIDs, goalDate: buddyRead.goalDate,
            spoilerLevel: buddyRead.spoilerLevel.rawValue, createdAt: buddyRead.createdAt
        )).execute()
        return buddyRead
    }

    func buddyReads() async throws -> [BuddyRead] {
        guard let uid = await SupabaseAuthService.shared.currentUserID else {
            throw RepositoryError.notAuthenticated
        }
        let rows: [BuddyReadRow] = try await db.from("buddy_reads")
            .select()
            .contains("invited_member_ids", value: [uid.uuidString])
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map { $0.toBuddyRead }
    }
}
