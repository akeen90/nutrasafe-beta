//
//  AuthenticationView.swift
//  NutraSafe Beta
//
//  Email/password authentication flow
//

import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSignUp = false

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
            // User is not signed in, show auth screen
            if showingSignUp {
                SignUpView(showingSignUp: $showingSignUp)
            } else {
                SignInView(showingSignUp: $showingSignUp)
            }
        }
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @Binding var showingSignUp: Bool
    @StateObject private var firebaseManager = FirebaseManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingPasswordReset = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.8),
                    Color(red: 0.4, green: 0.5, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

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

                    Text("NutraSafe")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Know what you eat")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 10)

                // Sign In Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        SecureField("", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Sign In Button
                    Button(action: signIn) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.85))
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    .opacity(email.isEmpty || password.isEmpty || isLoading ? 0.6 : 1.0)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    Text("or")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

                // Apple Sign In - Custom Button with ASAuthorizationController
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
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                // Forgot Password Link
                Button(action: { showingPasswordReset = true }) {
                    Text("Forgot Password?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 4)

                // Sign Up Link
                Button(action: { showingSignUp = true }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .font(.system(size: 16))
                }
                .padding(.top, 8)

                Spacer()
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

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @StateObject private var appleSignInCoordinator = AppleSignInCoordinator()

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.3, blue: 0.8),
                    Color(red: 0.4, green: 0.5, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Back button
                HStack {
                    Button(action: { showingSignUp = false }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Title
                VStack(spacing: 12) {
                    Text("Create Account")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Know what you eat")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)

                // Sign Up Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        SecureField("", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        SecureField("", text: $confirmPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Sign Up Button
                    Button(action: signUp) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.85))
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid && !isLoading ? 1.0 : 0.6)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                    Text("or")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

                // Apple Sign In - Custom Button with ASAuthorizationController
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
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                Spacer()
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
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.6, green: 0.3, blue: 0.8),
                        Color(red: 0.4, green: 0.5, blue: 0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Icon and title
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Reset Password")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Enter your email address and we'll send you instructions to reset your password")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 20)

                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)

                    // Reset button
                    Button(action: resetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Email")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.85))
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity(email.isEmpty || isLoading ? 0.6 : 1.0)
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
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
                        .foregroundColor(.white)
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
    @State private var isChecking = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var canResend = true
    @State private var countdown = 0

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.3, green: 0.5, blue: 1.0),
                    Color(red: 0.5, green: 0.3, blue: 0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Email icon with animation
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
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
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 16) {
                        Text("Verify Your Email")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("We've sent a verification email to:")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        Text(firebaseManager.currentUser?.email ?? "")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )

                        Text("Click the link in the email to verify your account")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                    }

                    VStack(spacing: 14) {
                        // Check if verified button
                        Button(action: {
                            Task { await checkVerification() }
                        }) {
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
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
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
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                } else {
                                    Text("Resend Verification Email")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                }
                            }
                            .foregroundColor(.white.opacity(canResend ? 1.0 : 0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(canResend ? 0.15 : 0.08))
                            )
                        }
                        .disabled(!canResend)

                        // Sign out button
                        Button(action: {
                            try? firebaseManager.signOut()
                        }) {
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
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

                // Countdown timer - captures @State bindings which are value types (no retain cycle)
                // Timer self-invalidates when countdown reaches 0
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

        // Generate nonce
        let nonce = firebaseManager.startAppleSignIn()
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
