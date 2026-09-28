// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

/// Stores the profile on device. Pass `store: nil` for an in-memory store (previews/tests).
actor LocalUserProfileStore: UserProfileStore {
    private let store: LocalStore?
    private var cached: UserProfile?
    private static let key = "profile"

    init(store: LocalStore?, seed: UserProfile? = nil) {
        self.store = store
        self.cached = seed
    }

    func load() async -> UserProfile? {
        if let cached { return cached }
        let loaded = store?.load(UserProfile.self, key: Self.key)
        cached = loaded
        return loaded
    }

    func save(_ profile: UserProfile) async throws {
        try store?.save(profile, key: Self.key)
        cached = profile
    }

    func delete() async {
        store?.remove(key: Self.key)
        cached = nil
    }
}

/// Stores Pip permissions on device. Pass `store: nil` for an in-memory store.
actor LocalPrivacySettingsStore: PrivacySettingsStore {
    private let store: LocalStore?
    private var cached: PipPermissionSettings?
    private static let key = "pip-permissions"

    init(store: LocalStore?) {
        self.store = store
    }

    func load() async -> PipPermissionSettings {
        if let cached { return cached }
        let loaded = store?.load(PipPermissionSettings.self, key: Self.key) ?? .default
        cached = loaded
        return loaded
    }

    func save(_ settings: PipPermissionSettings) async {
        try? store?.save(settings, key: Self.key)
        cached = settings
    }

    func reset() async {
        store?.remove(key: Self.key)
        cached = .default
    }
}
