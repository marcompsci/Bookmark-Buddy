// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

// MARK: - Auth service

/// Handles all Supabase authentication: email/password, Sign in with Apple, Google OAuth.
final class SupabaseAuthService: NSObject, @unchecked Sendable {

    static let shared = SupabaseAuthService()

    private let client: SupabaseClient = SupabaseManager.shared.client

    // MARK: - Session

    /// Current authenticated user ID, if a valid session exists.
    var currentUserID: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    func hasActiveSession() async -> Bool {
        (try? await client.auth.session) != nil
    }

    // MARK: - Email / Password

    /// Creates the account. Returns `true` when the person is signed in right away, or `false`
    /// when Supabase sent a confirmation email first (the link opens the app via bookmarkbuddy://).
    @discardableResult
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            redirectTo: URL(string: SupabaseConfig.oauthRedirectURL)
        )
        return response.session != nil
    }

    /// Finishes sign-in from a bookmarkbuddy:// link (email confirmation, magic link, OAuth).
    func handleOpenURL(_ url: URL) async throws {
        try await client.auth.session(from: url)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        // Store a session marker in the Keychain so SecurityGuard can check it quickly.
        if let token = try? await client.auth.session.accessToken {
            KeychainHelper.saveString(token, forKey: KeychainHelper.Keys.sessionToken)
        }
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email, redirectTo: URL(string: SupabaseConfig.oauthRedirectURL))
    }

    func signOut() async throws {
        try await client.auth.signOut()
        KeychainHelper.delete(forKey: KeychainHelper.Keys.sessionToken)
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async throws {
        let nonce = randomNonce()
        let hashedNonce = sha256(nonce)

        let result: ASAuthorization = try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = hashedNonce

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let handler = AppleSignInHandler(continuation: continuation)
            controller.delegate = handler
            controller.presentationContextProvider = handler
            controller.performRequests()
            // Keep the handler alive for the duration of the async operation.
            objc_setAssociatedObject(controller, "handler", handler, .OBJC_ASSOCIATION_RETAIN)
        }

        guard
            let credential = result.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthError.invalidAppleResponse
        }

        try await client.auth.signInWithIdToken(credentials: .init(
            provider: .apple,
            idToken: idToken,
            nonce: nonce
        ))
    }

    // MARK: - Google (OAuth via ASWebAuthenticationSession)

    func signInWithGoogle() async throws {
        guard let redirectURL = URL(string: SupabaseConfig.oauthRedirectURL) else {
            throw AuthError.badConfiguration
        }

        let oauthURL = try await client.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: redirectURL
        )

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let session = ASWebAuthenticationSession(
                    url: oauthURL,
                    callbackURLScheme: "bookmarkbuddy"
                ) { url, error in
                    if let error { continuation.resume(throwing: error); return }
                    guard let url else { continuation.resume(throwing: AuthError.invalidGoogleCallback); return }
                    continuation.resume(returning: url)
                }
                session.prefersEphemeralWebBrowserSession = true
                session.presentationContextProvider = WebContextProvider.shared
                session.start()
            }
        }

        try await client.auth.session(from: callbackURL)
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case invalidAppleResponse
        case invalidGoogleCallback
        case badConfiguration

        var errorDescription: String? {
            switch self {
            case .invalidAppleResponse:  return "Sign in with Apple returned an invalid response."
            case .invalidGoogleCallback: return "Google sign-in did not return a valid callback URL."
            case .badConfiguration:      return "OAuth redirect URL is not configured correctly."
            }
        }
    }

    // MARK: - Nonce helpers

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var block = [UInt8](repeating: 0, count: 16)
            guard SecRandomCopyBytes(kSecRandomDefault, block.count, &block) == errSecSuccess else {
                fatalError("Unable to generate secure random bytes")
            }
            block.forEach { byte in
                guard remaining > 0, byte < charset.count else { return }
                result.append(charset[Int(byte)])
                remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - ASAuthorization delegate (Apple)

private final class AppleSignInHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private let continuation: CheckedContinuation<ASAuthorization, Error>

    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        WebContextProvider.shared.window ?? UIWindow()
    }
}

// MARK: - ASWebAuthentication context (Google)

private final class WebContextProvider: NSObject,
    ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {

    static let shared = WebContextProvider()

    var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows.first(where: { $0.isKeyWindow })
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        window ?? UIWindow()
    }
}
