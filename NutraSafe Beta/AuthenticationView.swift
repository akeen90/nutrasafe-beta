//
//  AuthenticationView.swift
//  NutraSafe Beta
//
//  Email/password authentication flow
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingSignUp = false

    var body: some View {
        if authManager.isAuthenticated {
            // User is signed in, show main app
            ContentView()
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
    @StateObject private var authManager = AuthenticationManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingPasswordReset = false

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

                // Logo/Title
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text("NutraSafe")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Know what you eat")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)

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
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
    }

    private func signIn() {
        isLoading = true

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
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

// MARK: - Sign Up View
struct SignUpView: View {
    @Binding var showingSignUp: Bool
    @StateObject private var authManager = AuthenticationManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

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

                Spacer()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword && password.count >= 6
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
                try await authManager.signUp(email: email, password: password)
                await MainActor.run {
                    showingSignUp = false
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

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private init() {
        // Check if user is already signed in
        if let user = Auth.auth().currentUser {
            self.isAuthenticated = true
            self.currentUser = user
        }

        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        // Use default Firebase password reset without custom action code settings
        // This uses Firebase's built-in handler which should work out of the box
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared

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
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    showingSuccess = true
                }
            } catch let error as NSError {
                await MainActor.run {
                    // Handle specific Firebase Auth error codes
                    switch error.code {
                    case 17011: // User not found
                        errorMessage = "No account found with this email address. Please check the email or create a new account."
                    case 17008: // Invalid email
                        errorMessage = "Invalid email address format. Please check and try again."
                    case 17010: // Too many requests
                        errorMessage = "Too many reset attempts. Please try again later."
                    default:
                        errorMessage = "Unable to send reset email. Please check your email address and try again."
                    }
                    showingError = true
                    isLoading = false
                }
            }
        }
    }
}
