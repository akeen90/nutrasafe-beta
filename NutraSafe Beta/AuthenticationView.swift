//
//  AuthenticationView.swift
//  NutraSafe Beta
//
//  Email/password authentication flow - UNIFIED with onboarding design system.
//  NO legacy purple/blue gradients. Palette-aware throughout.
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @State private var showOnboardingFirst = !OnboardingManager.shared.hasCompletedOnboarding

    var body: some View {
        if firebaseManager.isAuthenticated {
            // Apple Sign In users skip email verification (Apple already verified)
            // Email/password users need to verify their email
            if firebaseManager.isAppleUser || firebaseManager.isEmailVerified {
                // Verified user, show main app
                ContentView()
            } else {
                // Email not verified, show verification screen
                EmailVerificationView()
            }
        } else {
            // User is not signed in
            // NEW FLOW: Show onboarding BEFORE sign-up (unless they tap "Already a member")
            if showOnboardingFirst && !OnboardingManager.shared.hasCompletedOnboarding {
                // Show onboarding with "Already a member" option
                PreAuthOnboardingView(
                    onComplete: {
                        // After onboarding completes, go to sign up
                        showOnboardingFirst = false
                        showingSignUp = true
                    },
                    onAlreadyMember: {
                        // Skip to sign in
                        showOnboardingFirst = false
                        showingSignIn = true
                    }
                )
                .environmentObject(healthKitManager)
            } else if showingSignIn {
                SignInView(showingSignUp: $showingSignUp)
            } else if showingSignUp {
                SignUpView(showingSignUp: $showingSignUp)
            } else {
                SignInView(showingSignUp: $showingSignUp)
            }
        }
    }
}

// MARK: - Pre-Auth Onboarding View
// Wraps PremiumOnboardingView but shows BEFORE authentication
// Has "Already joined" button in top-right using ZStack for stable z-ordering
struct PreAuthOnboardingView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let onComplete: () -> Void
    let onAlreadyMember: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // The actual onboarding flow (but without permission screens - those come after sign-up)
            PreAuthPremiumOnboardingView(onComplete: { _ in
                onComplete()
            })
            .environmentObject(healthKitManager)

            // "Already joined?" button - ZStack ensures stable rendering with animations
            Button(action: onAlreadyMember) {
                HStack(spacing: 6) {
                    Text("Already joined?")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppPalette.standard.accent)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                )
                .overlay(
                    Capsule()
                        .stroke(AppPalette.standard.accent.opacity(0.25), lineWidth: 1)
                )
            }
            .padding(.trailing, 20)
            .padding(.top, 52) // Adjusted: closer to status bar
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @Binding var showingSignUp: Bool
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingPasswordReset = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Onboarding-style animated background - NO purple/blue gradients
            AppAnimatedBackground()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 50)

                    // Logo/Title
                    VStack(spacing: 12) {
                        // App Icon
                        Image("SignInIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: palette.accent.opacity(0.3), radius: 20, y: 8)

                        Text("NutraSafe")
                            .font(.system(size: 42, weight: .bold, design: .serif))
                            .foregroundColor(palette.textPrimary)

                        Text("Know what you eat")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding(.bottom, 10)

                    // Sign In Form - Glassmorphic styling
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            SecureField("", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }

                        // Sign In Button - Unified palette button
                        Button(action: signIn) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        (email.isEmpty || password.isEmpty || isLoading)
                                            ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(
                                                colors: [palette.accent, palette.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .shadow(
                                        color: (email.isEmpty || password.isEmpty || isLoading) ? Color.clear : palette.accent.opacity(0.3),
                                        radius: 15,
                                        y: 5
                                    )

                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 56)
                        }
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.textTertiary.opacity(0.3))
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(palette.textTertiary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.textTertiary.opacity(0.3))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)

                    // Apple Sign In - Palette-aware
                    Button(action: {
                        appleSignInCoordinator.startSignInWithApple(firebaseManager: firebaseManager) { result in
                            handleAppleSignIn(result: result)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20, weight: .medium))
                            Text("Sign in with Apple")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                        )
                    }
                    .padding(.horizontal, 32)

                    // Forgot Password Link
                    Button(action: { showingPasswordReset = true }) {
                        Text("Forgot Password?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(palette.accent)
                    }
                    .padding(.top, 4)

                    // Sign Up Link
                    Button(action: { showingSignUp = true }) {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(palette.textSecondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(palette.accent)
                        }
                        .font(.system(size: 16))
                    }
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
        .trackScreen("Sign In")
    }

    private func signIn() {
        isLoading = true

        Task {
            do {
                try await firebaseManager.signIn(email: email, password: password)
                AnalyticsManager.shared.trackSignIn(method: "email")
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                    AnalyticsManager.shared.trackError(errorType: "sign_in", errorMessage: error.localizedDescription)
                }
            }
        }
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            Task {
                do {
                    try await firebaseManager.signInWithApple(authorization: authorization)
                    AnalyticsManager.shared.trackSignIn(method: "apple")
                } catch {
                    await MainActor.run {
                        errorMessage = "Sign in failed: \(error.localizedDescription)"
                        showingError = true
                        isLoading = false
                        AnalyticsManager.shared.trackError(errorType: "apple_sign_in", errorMessage: error.localizedDescription)
                    }
                }
            }
        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Binding var showingSignUp: Bool
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Onboarding-style animated background
            AppAnimatedBackground()

            ScrollView {
                VStack(spacing: 30) {
                    // Back button
                    HStack {
                        Button(action: { showingSignUp = false }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(palette.accent)
                            .font(.system(size: 16, weight: .medium))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()
                        .frame(height: 20)

                    // Title
                    VStack(spacing: 12) {
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundColor(palette.textPrimary)

                        Text("Know what you eat")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }
                    .padding(.bottom, 20)

                    // Sign Up Form - Glassmorphic styling
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            SecureField("", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }

                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            SecureField("", text: $confirmPassword)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }

                        // Sign Up Button - Unified palette button
                        Button(action: signUp) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        (!isFormValid || isLoading)
                                            ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(
                                                colors: [palette.accent, palette.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .shadow(
                                        color: (!isFormValid || isLoading) ? Color.clear : palette.accent.opacity(0.3),
                                        radius: 15,
                                        y: 5
                                    )

                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 56)
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)

                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.textTertiary.opacity(0.3))
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(palette.textTertiary)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.textTertiary.opacity(0.3))
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)

                    // Apple Sign In
                    Button(action: {
                        appleSignInCoordinator.startSignInWithApple(firebaseManager: firebaseManager) { result in
                            handleAppleSignIn(result: result)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20, weight: .medium))
                            Text("Sign up with Apple")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                        .frame(height: 50)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .trackScreen("Sign Up")
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword && password.count >= 6
    }

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            Task {
                do {
                    try await firebaseManager.signInWithApple(authorization: authorization)
                    AnalyticsManager.shared.trackSignUp(method: "apple")
                } catch {
                    await MainActor.run {
                        errorMessage = "Sign up failed: \(error.localizedDescription)"
                        showingError = true
                        isLoading = false
                        AnalyticsManager.shared.trackError(errorType: "apple_sign_up", errorMessage: error.localizedDescription)
                    }
                }
            }
        case .failure(let error):
            // Don't show error for user cancellation
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Apple Sign Up failed: \(error.localizedDescription)"
                showingError = true
                AnalyticsManager.shared.trackError(errorType: "apple_sign_up", errorMessage: error.localizedDescription)
            }
        }
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showingError = true
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showingError = true
            return
        }

        isLoading = true

        Task {
            do {
                try await firebaseManager.signUp(email: email, password: password)
                AnalyticsManager.shared.trackSignUp(method: "email")
                await MainActor.run {
                    showingSignUp = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                    AnalyticsManager.shared.trackError(errorType: "sign_up", errorMessage: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Onboarding-style animated background
                AppAnimatedBackground()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                            .frame(height: 40)

                        // Icon and title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(palette.accent.opacity(0.15))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 44, weight: .light))
                                    .foregroundColor(palette.accent)
                            }

                            Text("Reset Password")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundColor(palette.textPrimary)

                            Text("Enter your email address and we'll send you instructions to reset your password")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(palette.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 20)

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            TextField("", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(palette.textPrimary)
                        }
                        .padding(.horizontal, 32)

                        // Reset button
                        Button(action: resetPassword) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        (email.isEmpty || isLoading)
                                            ? LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                            : LinearGradient(
                                                colors: [palette.accent, palette.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                    )
                                    .shadow(
                                        color: (email.isEmpty || isLoading) ? Color.clear : palette.accent.opacity(0.3),
                                        radius: 15,
                                        y: 5
                                    )

                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Send Reset Email")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 56)
                        }
                        .disabled(email.isEmpty || isLoading)
                        .padding(.horizontal, 32)

                        Spacer()
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(palette.accent)
                        .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset instructions have been sent to your email address")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func resetPassword() {
        // Validate email format
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            showingError = true
            return
        }

        isLoading = true

        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Email Verification View

struct EmailVerificationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var isChecking = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var canResend = true
    @State private var countdown = 0

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Onboarding-style animated background
            AppAnimatedBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Email icon with glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [palette.accent.opacity(0.25), palette.accent.opacity(0.05)],
                                    center: .center,
                                    startRadius: 40,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 180, height: 180)

                        Image(systemName: "envelope.fill")
                            .font(.system(size: 70, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [palette.accent, palette.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 16) {
                        Text("Verify Your Email")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(palette.textPrimary)

                        Text("We've sent a verification email to:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(palette.textSecondary)

                        Text(firebaseManager.currentUser?.email ?? "")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                        Text("Click the link in the email to verify your account")
                            .font(.system(size: 15))
                            .foregroundColor(palette.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 14) {
                        // Check if verified button
                        Button(action: {
                            Task { await checkVerification() }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent, palette.primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: palette.accent.opacity(0.3), radius: 15, y: 5)

                                HStack(spacing: 10) {
                                    if isChecking {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                    }

                                    Text(isChecking ? "Checking..." : "I've Verified My Email")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                            }
                            .frame(height: 56)
                        }
                        .disabled(isChecking)

                        // Resend email button
                        Button(action: {
                            Task { await resendVerification() }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .semibold))

                                if countdown > 0 {
                                    Text("Resend in \(countdown)s")
                                        .font(.system(size: 15, weight: .medium))
                                } else {
                                    Text("Resend Verification Email")
                                        .font(.system(size: 15, weight: .medium))
                                }
                            }
                            .foregroundColor(canResend ? palette.accent : palette.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(palette.accent.opacity(canResend ? 0.1 : 0.05))
                            )
                        }
                        .disabled(!canResend)

                        // Sign out button
                        Button(action: {
                            try? firebaseManager.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(palette.textTertiary)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Email Sent!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Verification email has been sent. Please check your inbox.")
        }
    }

    private func checkVerification() async {
        await MainActor.run { isChecking = true }

        do {
            try await firebaseManager.reloadUser()

            await MainActor.run {
                isChecking = false
                if !firebaseManager.isEmailVerified {
                    errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                    showingError = true
                }
            }
        } catch {
            await MainActor.run {
                isChecking = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }

    private func resendVerification() async {
        guard canResend else { return }

        do {
            try await firebaseManager.resendVerificationEmail()

            await MainActor.run {
                canResend = false
                countdown = 60
                showingSuccess = true

                // Countdown timer
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    countdown -= 1
                    if countdown <= 0 {
                        timer.invalidate()
                        canResend = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Apple Sign In Coordinator

/// Coordinator to handle Apple Sign In with ASAuthorizationController
class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    private var completionHandler: ((Result<ASAuthorization, Error>) -> Void)?
    private var currentNonce: String?

    func startSignInWithApple(firebaseManager: FirebaseManager, completion: @escaping (Result<ASAuthorization, Error>) -> Void) {

        self.completionHandler = completion

        // Generate nonce - handle rare failure gracefully
        guard let nonce = firebaseManager.startAppleSignIn() else {
            let error = NSError(domain: "AppleSignIn", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to generate secure authentication token. Please try again."])
            completion(.failure(error))
            return
        }
        self.currentNonce = nonce


        // Create Apple ID request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = nonce

        // Create authorization controller
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self


        // Perform request
        authorizationController.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completionHandler?(.success(authorization))
        completionHandler = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completionHandler?(.failure(error))
        completionHandler = nil
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the window to present the authorization UI
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }

        return window
    }
}
