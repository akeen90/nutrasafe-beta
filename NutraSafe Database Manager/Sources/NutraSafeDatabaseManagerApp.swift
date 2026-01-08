//
//  NutraSafeDatabaseManagerApp.swift
//  NutraSafe Database Manager
//
//  Main entry point for the macOS database management app
//

import SwiftUI

@main
struct NutraSafeDatabaseManagerApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var algoliaService = AlgoliaService.shared
    @StateObject private var claudeService = ClaudeService.shared
    @StateObject private var reviewManager = ReviewManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(algoliaService)
                .environmentObject(claudeService)
                .environmentObject(reviewManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Food Item") {
                    appState.showingNewFoodSheet = true
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Import Foods...") {
                    appState.showingImportSheet = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export Selected...") {
                    appState.showingExportSheet = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(appState.selectedFoodIDs.isEmpty)
            }

            CommandGroup(after: .pasteboard) {
                Divider()

                Button("Select All") {
                    appState.selectAllFoods()
                }
                .keyboardShortcut("a", modifiers: .command)

                Button("Deselect All") {
                    appState.deselectAllFoods()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }

            CommandMenu("Database") {
                Button("Refresh") {
                    Task {
                        await algoliaService.refreshCurrentIndex()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)

                Divider()

                Button("Bulk Edit Selected...") {
                    appState.showingBulkEditSheet = true
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(appState.selectedFoodIDs.isEmpty)

                Button("Delete Selected...") {
                    appState.showingDeleteConfirmation = true
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appState.selectedFoodIDs.isEmpty)
            }

            CommandMenu("AI Assistant") {
                Button("Ask Claude...") {
                    appState.showingClaudeSheet = true
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Auto-Fix Selected Foods") {
                    Task {
                        await claudeService.autoFixSelectedFoods(appState.selectedFoodIDs)
                    }
                }
                .disabled(appState.selectedFoodIDs.isEmpty)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(algoliaService)
                .environmentObject(claudeService)
                .environmentObject(reviewManager)
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var selectedDatabase: DatabaseType = .foods
    @Published var selectedFoodIDs: Set<String> = []
    @Published var searchQuery: String = ""
    @Published var currentFood: FoodItem?
    @Published var currentFoodID: String?
    @Published var reviewFilter: ReviewFilter = .all

    // Navigation state
    @Published var sidebarSelection: SidebarItem = .foodsDatabase

    // Sheet states
    @Published var showingNewFoodSheet = false
    @Published var showingImportSheet = false
    @Published var showingExportSheet = false
    @Published var showingBulkEditSheet = false
    @Published var showingDeleteConfirmation = false
    @Published var showingClaudeSheet = false
    @Published var showingClaudeReviewSheet = false
    @Published var showingValidationSheet = false
    @Published var showingFoodDetail = false

    // All loaded foods for selection
    @Published var loadedFoods: [FoodItem] = []

    func selectAllFoods() {
        selectedFoodIDs = Set(loadedFoods.map { $0.objectID })
    }

    func deselectAllFoods() {
        selectedFoodIDs.removeAll()
    }

    func toggleSelection(for id: String) {
        if selectedFoodIDs.contains(id) {
            selectedFoodIDs.remove(id)
        } else {
            selectedFoodIDs.insert(id)
        }
    }
}

enum DatabaseType: String, CaseIterable, Identifiable {
    case foods = "foods"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foods: return "Foods Database"
        }
    }

    var icon: String {
        switch self {
        case .foods: return "fork.knife"
        }
    }

    var algoliaIndex: String {
        switch self {
        case .foods: return "foods"
        }
    }
}

// MARK: - Sidebar Navigation Item

enum SidebarItem: String, Identifiable, Hashable {
    case foodsDatabase
    case userReports

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .foodsDatabase: return "Foods Database"
        case .userReports: return "User Reports"
        }
    }

    var icon: String {
        switch self {
        case .foodsDatabase: return "fork.knife"
        case .userReports: return "exclamationmark.bubble"
        }
    }
}
