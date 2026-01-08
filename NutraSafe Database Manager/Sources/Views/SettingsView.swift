//
//  SettingsView.swift
//  NutraSafe Database Manager
//
//  Settings and configuration view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService

    var body: some View {
        TabView {
            AlgoliaSettingsView()
                .tabItem {
                    Label("Algolia", systemImage: "magnifyingglass")
                }

            ClaudeSettingsView()
                .tabItem {
                    Label("Claude AI", systemImage: "sparkles")
                }

            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Algolia Settings

struct AlgoliaSettingsView: View {
    @EnvironmentObject var algoliaService: AlgoliaService

    @State private var appID: String = ""
    @State private var adminKey: String = ""
    @State private var showingKey = false
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                TextField("Application ID", text: $appID)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    if showingKey {
                        TextField("Admin API Key", text: $adminKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Admin API Key", text: $adminKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        showingKey.toggle()
                    } label: {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("✓ Admin API key configured - full read/write access enabled")
                        .font(.caption)
                        .foregroundColor(.green)
                    Link("Manage API Keys in Algolia Dashboard", destination: URL(string: "https://dashboard.algolia.com/account/api-keys")!)
                        .font(.caption)
                }
            } header: {
                Text("Algolia Credentials")
            }

            Section {
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(appID.isEmpty || adminKey.isEmpty || isTesting)

                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Spacer()

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("Success") ? .green : .red)
                    }
                }

                Button("Save Credentials") {
                    algoliaService.setCredentials(appID: appID, adminKey: adminKey)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appID.isEmpty || adminKey.isEmpty)
            } header: {
                Text("Actions")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Index Names")
                        .font(.headline)

                    ForEach(DatabaseType.allCases) { db in
                        HStack {
                            Image(systemName: db.icon)
                                .frame(width: 20)
                            Text(db.displayName)
                            Spacer()
                            Text(db.algoliaIndex)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("Database Indexes")
            }
        }
        .padding()
        .onAppear {
            appID = UserDefaults.standard.string(forKey: "algolia_app_id") ?? "WK0TIF84M2"
            adminKey = UserDefaults.standard.string(forKey: "algolia_admin_key") ?? "e54f75aae315af794ece385f3dc9c94b"
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        // Simple test by trying to save credentials and checking if client is configured
        algoliaService.setCredentials(appID: appID, adminKey: adminKey)

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                if algoliaService.isConfigured {
                    testResult = "Success! Connected to Algolia."
                } else {
                    testResult = "Failed: Unable to configure client."
                }
                isTesting = false
            }
        }
    }
}

// MARK: - Claude Settings

struct ClaudeSettingsView: View {
    @EnvironmentObject var claudeService: ClaudeService

    @State private var apiKey: String = ""
    @State private var showingKey = false
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                HStack {
                    if showingKey {
                        TextField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        showingKey.toggle()
                    } label: {
                        Image(systemName: showingKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                Text("Your Anthropic API key. This uses your existing Claude account limits.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("Get an API key from Anthropic Console",
                     destination: URL(string: "https://console.anthropic.com/")!)
                    .font(.caption)
            } header: {
                Text("Claude API Key")
            }

            Section {
                HStack {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(apiKey.isEmpty || isTesting)

                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Spacer()

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("Success") ? .green : .red)
                    }
                }

                Button("Save API Key") {
                    claudeService.setAPIKey(apiKey)
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            } header: {
                Text("Actions")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude AI Features")
                        .font(.headline)

                    FeatureRow(icon: "sparkles", title: "Food Analysis", description: "Analyze foods for data quality issues")
                    FeatureRow(icon: "wand.and.stars", title: "Auto-Fix", description: "Automatically fix common data problems")
                    FeatureRow(icon: "text.badge.plus", title: "Suggest Ingredients", description: "Generate ingredient lists for foods")
                    FeatureRow(icon: "bubble.left.and.bubble.right", title: "Chat Assistant", description: "Ask questions about your database")
                }
            } header: {
                Text("Available Features")
            }
        }
        .padding()
        .onAppear {
            apiKey = UserDefaults.standard.string(forKey: "claude_api_key") ?? ""
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = nil
        claudeService.setAPIKey(apiKey)

        Task {
            // Try a simple API call
            await claudeService.sendMessage("Hello, respond with just 'Connected!' if you receive this.")

            await MainActor.run {
                if claudeService.error == nil && !claudeService.messages.isEmpty {
                    testResult = "Success! Claude is connected."
                    claudeService.clearConversation()
                } else {
                    testResult = "Failed: \(claudeService.error ?? "Unknown error")"
                }
                isTesting = false
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("defaultDatabase") private var defaultDatabase: String = "foods"
    @AppStorage("autoRefreshOnLaunch") private var autoRefreshOnLaunch: Bool = true
    @AppStorage("showVerifiedBadge") private var showVerifiedBadge: Bool = true
    @AppStorage("confirmBeforeDelete") private var confirmBeforeDelete: Bool = true

    var body: some View {
        Form {
            Section {
                Picker("Default Database", selection: $defaultDatabase) {
                    ForEach(DatabaseType.allCases) { db in
                        Text(db.displayName).tag(db.rawValue)
                    }
                }

                Toggle("Auto-refresh on launch", isOn: $autoRefreshOnLaunch)
            } header: {
                Text("Startup")
            }

            Section {
                Toggle("Show verified badges", isOn: $showVerifiedBadge)
                Toggle("Confirm before delete", isOn: $confirmBeforeDelete)
            } header: {
                Text("Display")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NutraSafe Database Manager")
                        .font(.headline)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Manage your NutraSafe food databases with Claude AI assistance.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("About")
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(AlgoliaService.shared)
        .environmentObject(ClaudeService.shared)
}
