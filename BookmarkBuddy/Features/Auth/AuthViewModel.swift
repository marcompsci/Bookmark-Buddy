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
    /// Shown after sign-up when Supabase emailed a confirmation link.
    var infoMessage: String? = nil

    private let auth = SupabaseAuthService.shared

    // MARK: - Email / password

    func submit() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        defer { isLoading = false }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .signIn:
                try await auth.signIn(email: trimmedEmail, password: password)
            case .signUp:
                let signedIn = try await auth.signUp(email: trimmedEmail, password: password)
                if !signedIn {
                    infoMessage = "Check \(trimmedEmail) for a confirmation link. Open it on this iPhone and you'll be signed in."
                    mode = .signIn
                    confirmPassword = ""
                }
            }
        } catch {
            errorMessage = Self.friendly(error)
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
            // ASWebAuthenticationSessionError.canceledLogin = person closed the sheet — silent.
            if (error as NSError).domain == "com.apple.AuthenticationServices.WebAuthenticationSession",
               (error as NSError).code == 1 { return }
            errorMessage = Self.friendly(error)
        }
    }

    /// Turns Supabase's error text into plain language.
    private static func friendly(_ error: Error) -> String {
        let text = error.localizedDescription
        let lower = text.lowercased()
        if lower.contains("email not confirmed") {
            return "Confirm your email first — tap the link we sent you, then sign in."
        }
        if lower.contains("invalid login credentials") {
            return "That email and password don't match. Try again or reset your password."
        }
        if lower.contains("user already registered") {
            return "There's already an account with that email. Sign in instead."
        }
        if lower.contains("provider is not enabled") || lower.contains("unsupported provider") {
            return "Google sign-in isn't set up yet. Use email for now."
        }
        return text
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
