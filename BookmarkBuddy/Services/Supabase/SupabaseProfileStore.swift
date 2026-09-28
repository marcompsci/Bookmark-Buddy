// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase

// MARK: - Row types

private struct ProfileRow: Codable, Sendable {
    let id: UUID
    let displayName: String
    let favoriteGenres: [String]
    let booksPerMonth: Int
    let pace: String
    let spoilerLevel: String
    let currentStreakDays: Int
    let squadPoints: Int
    let joinedSquadIds: [UUID]
    let createdAt: Date
    enum CodingKeys: String, CodingKey {
        case id
        case displayName       = "display_name"
        case favoriteGenres    = "favorite_genres"
        case booksPerMonth     = "books_per_month"
        case pace
        case spoilerLevel      = "spoiler_level"
        case currentStreakDays  = "current_streak_days"
        case squadPoints       = "squad_points"
        case joinedSquadIds    = "joined_squad_ids"
        case createdAt         = "created_at"
    }

    var toProfile: UserProfile {
        UserProfile(
            id: id,
            displayName: displayName,
            favoriteGenres: favoriteGenres.compactMap { Genre(rawValue: $0) },
            booksPerMonth: booksPerMonth,
            pace: ReadingPace(rawValue: pace) ?? .steady,
            spoilerLevel: SpoilerLevel(rawValue: spoilerLevel) ?? .currentChapter,
            currentStreakDays: currentStreakDays,
            squadPoints: squadPoints,
            joinedSquadIDs: joinedSquadIds,
            createdAt: createdAt
        )
    }
}

private struct PrivacyRow: Codable, Sendable {
    let userId: UUID
    let notesConsent: String
    let readingProgressVisible: Bool
    let notesVisible: Bool
    enum CodingKeys: String, CodingKey {
        case userId                 = "user_id"
        case notesConsent           = "notes_consent"
        case readingProgressVisible = "reading_progress_visible"
        case notesVisible           = "notes_visible"
    }
}

// MARK: - Profile store

struct SupabaseUserProfileStore: UserProfileStore {

    private let db = SupabaseManager.shared.client

    func load() async -> UserProfile? {
        guard let uid = await SupabaseAuthService.shared.currentUserID else { return nil }
        let rows: [ProfileRow]? = try? await db.from("profiles")
            .select()
            .eq("id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        return rows?.first?.toProfile
    }

    func save(_ profile: UserProfile) async throws {
        guard let uid = await SupabaseAuthService.shared.currentUserID else {
            throw RepositoryError.notAuthenticated
        }
        struct Upsert: Encodable {
            let id: UUID; let displayName: String; let favoriteGenres: [String]
            let booksPerMonth: Int; let pace: String; let spoilerLevel: String
            let currentStreakDays: Int; let squadPoints: Int; let joinedSquadIds: [UUID]; let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id
                case displayName       = "display_name"
                case favoriteGenres    = "favorite_genres"
                case booksPerMonth     = "books_per_month"
                case pace; case spoilerLevel = "spoiler_level"
                case currentStreakDays  = "current_streak_days"
                case squadPoints       = "squad_points"
                case joinedSquadIds    = "joined_squad_ids"
                case createdAt         = "created_at"
            }
        }
        try await db.from("profiles").upsert(Upsert(
            id: uid,
            displayName: profile.displayName,
            favoriteGenres: profile.favoriteGenres.map { $0.rawValue },
            booksPerMonth: profile.booksPerMonth,
            pace: profile.pace.rawValue,
            spoilerLevel: profile.spoilerLevel.rawValue,
            currentStreakDays: profile.currentStreakDays,
            squadPoints: profile.squadPoints,
            joinedSquadIds: profile.joinedSquadIDs,
            createdAt: profile.createdAt
        ), onConflict: "id").execute()
    }

    func delete() async {
        guard let uid = await SupabaseAuthService.shared.currentUserID else { return }
        try? await db.from("profiles").delete().eq("id", value: uid.uuidString).execute()
        try? await SupabaseAuthService.shared.signOut()
    }
}

// MARK: - Privacy settings store

struct SupabasePrivacyStore: PrivacySettingsStore {

    private let db = SupabaseManager.shared.client

    func load() async -> PipPermissionSettings {
        guard let uid = await SupabaseAuthService.shared.currentUserID else {
            return .default
        }
        let rows: [PrivacyRow]? = try? await db.from("privacy_settings")
            .select()
            .eq("user_id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        guard let row = rows?.first else { return .default }
        var settings = PipPermissionSettings()
        settings.notesConsent = NotesConsent(rawValue: row.notesConsent) ?? .notAsked
        settings.allowReadingProgress = row.readingProgressVisible
        return settings
    }

    func save(_ settings: PipPermissionSettings) async {
        guard let uid = await SupabaseAuthService.shared.currentUserID else { return }
        struct Upsert: Encodable {
            let userId: UUID; let notesConsent: String
            let readingProgressVisible: Bool; let notesVisible: Bool
            enum CodingKeys: String, CodingKey {
                case userId                 = "user_id"
                case notesConsent           = "notes_consent"
                case readingProgressVisible = "reading_progress_visible"
                case notesVisible           = "notes_visible"
            }
        }
        try? await db.from("privacy_settings").upsert(Upsert(
            userId: uid,
            notesConsent: settings.notesConsent.rawValue,
            readingProgressVisible: settings.allowReadingProgress,
            notesVisible: settings.allowsNotes
        ), onConflict: "user_id").execute()
    }

    func reset() async {
        guard let uid = await SupabaseAuthService.shared.currentUserID else { return }
        try? await db.from("privacy_settings").delete().eq("user_id", value: uid.uuidString).execute()
    }
}
