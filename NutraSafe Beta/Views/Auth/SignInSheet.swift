import SwiftUI
import FirebaseAuth

struct SignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSignedIn: (() -> Void)?
    var onCancel: (() -> Void)?

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isBusy = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button(action: { Task { await signIn() } }) {
                        HStack {
                            if isBusy { ProgressView().scaleEffect(0.9) }
                            Text("Sign In")
                        }
                    }
                    .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                    Button(action: { Task { await signUp() } }) {
                        HStack {
                            if isBusy { ProgressView().scaleEffect(0.9) }
                            Text("Create Account")
                        }
                    }
                    .disabled(isBusy || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.count < 6)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
            }
        }
    }

    private func signIn() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try await FirebaseManager.shared.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            isBusy = false
            onSignedIn?()
            dismiss()
        } catch {
            isBusy = false
            let ns = error as NSError
            errorMessage = ns.localizedDescription
        }
    }

    private func signUp() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        do {
            try await FirebaseManager.shared.signUp(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
            isBusy = false
            onSignedIn?()
            dismiss()
        } catch {
            isBusy = false
            let ns = error as NSError
            errorMessage = ns.localizedDescription
        }
    }
}
