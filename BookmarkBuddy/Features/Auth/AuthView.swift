// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var model = AuthViewModel()
    @FocusState private var focused: Field?

    enum Field: Hashable { case email, password, confirm }

    var body: some View {
        ZStack {
            InkBackground()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    formCard
                        .padding(.top, Theme.Spacing.xl)
                    divider
                        .padding(.vertical, Theme.Spacing.lg)
                    socialButtons
                    modeToggle
                        .padding(.top, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, 60)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.Spacing.md) {
            PipAvatar(size: 72, mood: .happy)
            Text("Bookmark Buddy")
                .font(.bbDisplay)
                .foregroundStyle(Theme.Palette.parchment)
            Text(model.mode == .signIn ? "Welcome back, reader." : "Create your reading world.")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Error message
            if let error = model.errorMessage {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Theme.Palette.danger)
                    Text(error)
                        .font(.bbCallout)
                        .foregroundStyle(Theme.Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Palette.danger.opacity(0.12))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Email
            AuthField(
                label: "Email",
                text: $model.email,
                systemImage: "envelope",
                keyboardType: .emailAddress,
                contentType: .emailAddress,
                focused: $focused,
                field: .email
            )

            // Password
            AuthField(
                label: "Password",
                text: $model.password,
                systemImage: "lock",
                isSecure: true,
                contentType: model.mode == .signIn ? .password : .newPassword,
                focused: $focused,
                field: .password
            )

            // Confirm password (sign-up only)
            if model.mode == .signUp {
                AuthField(
                    label: "Confirm Password",
                    text: $model.confirmPassword,
                    systemImage: "lock.fill",
                    isSecure: true,
                    contentType: .newPassword,
                    focused: $focused,
                    field: .confirm
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Submit
            PrimaryButton(
                title: model.mode == .signIn ? "Sign In" : "Create Account",
                systemImage: model.mode == .signIn ? "arrow.right.circle.fill" : "person.badge.plus",
                isLoading: model.isLoading
            ) {
                focused = nil
                Task { await model.submit() }
            }
            .padding(.top, Theme.Spacing.xs)

            // Forgot password
            if model.mode == .signIn {
                Button("Forgot password?") {
                    Task { await model.resetPassword() }
                }
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.lavender)
                .frame(minHeight: Theme.minTapTarget)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Palette.inkRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.mode)
        .animation(.spring(response: 0.3), value: model.errorMessage)
    }

    // MARK: - Social buttons

    private var divider: some View {
        HStack(spacing: Theme.Spacing.md) {
            Rectangle().fill(Theme.Palette.hairline).frame(height: 1)
            Text("or continue with")
                .font(.bbCaption)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .fixedSize()
            Rectangle().fill(Theme.Palette.hairline).frame(height: 1)
        }
    }

    private var socialButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Sign in with Apple — uses system button for App Store compliance
            SignInWithAppleButton(
                model.mode == .signIn ? .signIn : .signUp,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { _ in
                    // Supabase handles the token via SupabaseAuthService.signInWithApple()
                    Task { await model.signInWithApple() }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(Theme.Radius.sm)

            // Google
            Button {
                Task { await model.signInWithGoogle() }
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "globe")
                        .font(.headline)
                    Text("Continue with Google")
                        .font(.bbHeadline)
                }
                .foregroundStyle(Theme.Palette.parchment)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .fill(Theme.Palette.inkHighlight)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(model.isLoading)
        }
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(model.mode == .signIn ? "New to Bookmark Buddy?" : "Already have an account?")
                .font(.bbCallout)
                .foregroundStyle(Theme.Palette.parchmentMuted)
            Button(model.mode == .signIn ? "Sign Up" : "Sign In") {
                withAnimation {
                    model.mode = model.mode == .signIn ? .signUp : .signIn
                    model.errorMessage = nil
                    model.password = ""
                    model.confirmPassword = ""
                }
            }
            .font(.bbHeadline)
            .foregroundStyle(Theme.Palette.gold)
        }
    }
}

// MARK: - Auth text field

private struct AuthField: View {
    let label: String
    @Binding var text: String
    var systemImage: String
    var keyboardType: UIKeyboardType = .default
    var isSecure = false
    var contentType: UITextContentType? = nil
    @FocusState.Binding var focused: AuthView.Field?
    let field: AuthView.Field

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(Theme.Palette.parchmentMuted)
                .frame(width: 20)
                .accessibilityHidden(true)
            Group {
                if isSecure {
                    SecureField(label, text: $text)
                } else {
                    TextField(label, text: $text)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .textContentType(contentType)
            .focused($focused, equals: field)
            .foregroundStyle(Theme.Palette.parchment)
            .font(.bbBody)
            .submitLabel(field == .confirm ? .done : .next)
            .onSubmit {
                switch field {
                case .email:   focused = .password
                case .password: focused = .confirm
                case .confirm:  focused = nil
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .fill(Theme.Palette.ink)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .strokeBorder(
                            focused == field ? Theme.Palette.gold : Theme.Palette.hairline,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.18), value: focused == field)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environment(LibraryCustomization())
}
