// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {

    enum Mode { case signIn, signUp }

    var mode: Mode = .signIn
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isLoading = false
    var errorMessage: String? = nil

    private let auth = SupabaseAuthService.shared

    // MARK: - Email / password

    func submit() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: email, password: password)
            case .signUp:
                try await auth.signUp(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email address first."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await auth.resetPassword(email: email)
            errorMessage = "Check your email for a reset link."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Social

    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await auth.signInWithApple()
        } catch {
            // ASAuthorizationError.canceled = user tapped Cancel — silent
            let code = (error as NSError).code
            if code != 1001 {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await auth.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Validation

    private func validate() -> Bool {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email."
            return false
        }
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        if mode == .signUp, password != confirmPassword {
            errorMessage = "Passwords don't match."
            return false
        }
        return true
    }
}
