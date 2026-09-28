// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

/// App-wide session state: who the reader is and their privacy settings.
/// Feature view models own their own screen state and read from here.
@Observable
@MainActor
final class AppState {
    enum ProfileStatus: Equatable {
        case loading          // checking Supabase session
        case unauthenticated  // no active session → show AuthView
        case missing          // authenticated but no profile → show Onboarding
        case ready            // authenticated + profile loaded → show main app
    }

    let services: AppServices
    private(set) var profile: UserProfile?
    private(set) var status: ProfileStatus = .loading
    private(set) var pipPermissions: PipPermissionSettings = .default

    init(services: AppServices) {
        self.services = services
    }

    /// Preview/test initializer with a profile already in place.
    init(services: AppServices, profile: UserProfile?) {
        self.services = services
        self.profile = profile
        self.status = profile == nil ? .missing : .ready
    }

    func loadProfile() async {
        guard status == .loading else { return }

        // Check Supabase session first (skipped in preview where auth is not wired).
        if SupabaseConfig.isConfigured {
            let hasSession = await SupabaseAuthService.shared.hasActiveSession()
            guard hasSession else {
                status = .unauthenticated
                return
            }
        }

        pipPermissions = await services.privacy.load()
        if let stored = await services.profiles.load() {
            profile = stored
            status = .ready
        } else {
            status = .missing
        }
    }

    /// Called after a successful Supabase sign-in to load the profile.
    func handleSignIn() async {
        status = .loading
        await loadProfile()
    }

    /// Saves the new profile and seeds the reader into the demo squad.
    func completeOnboarding(with newProfile: UserProfile) async throws {
        var updated = newProfile
        // Squad join is best-effort — the demo squad may not be seeded in this environment.
        if let squad = try? await services.squads.join(squadID: DemoData.IDs.midnightMargins, as: updated) {
            if !updated.joinedSquadIDs.contains(squad.id) {
                updated.joinedSquadIDs.append(squad.id)
            }
        }
        try await services.profiles.save(updated)
        profile = updated
        status = .ready
    }

    func updateProfile(_ transform: (inout UserProfile) -> Void) async {
        guard var current = profile else { return }
        transform(&current)
        profile = current
        try? await services.profiles.save(current)
    }

    func updatePipPermissions(_ transform: (inout PipPermissionSettings) -> Void) async {
        var current = pipPermissions
        transform(&current)
        pipPermissions = current
        await services.privacy.save(current)
    }

    /// Signs the user out of Supabase and clears local state.
    func signOut() async {
        try? await SupabaseAuthService.shared.signOut()
        profile = nil
        pipPermissions = .default
        status = .unauthenticated
    }

    /// Permanently deletes the account and all associated data.
    func deleteAllData() async {
        await services.profiles.delete()
        await services.privacy.reset()
        await services.pip.resetMemory()
        LocalStore().removeAll()
        profile = nil
        pipPermissions = .default
        status = .unauthenticated
    }
}
