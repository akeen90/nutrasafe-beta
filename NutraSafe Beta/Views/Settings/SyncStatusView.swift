//
//  SyncStatusView.swift
//  NutraSafe Beta
//
//  Displays sync status and allows manual sync operations
//  Shows pending operations, failed operations, and last sync time
//

import SwiftUI

/// View showing current sync status with manual sync controls
struct SyncStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SyncStatusViewModel()

    var body: some View {
        NavigationView {
            List {
                // Current Status Section
                Section {
                    StatusRow(
                        title: "Connection",
                        value: viewModel.isConnected ? "Online" : "Offline",
                        valueColor: viewModel.isConnected ? .green : .red,
                        icon: viewModel.isConnected ? "wifi" : "wifi.slash"
                    )

                    StatusRow(
                        title: "Sync Status",
                        value: viewModel.syncStatusDescription,
                        valueColor: viewModel.isSyncing ? .orange : .primary,
                        icon: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "checkmark.circle"
                    )

                    if let lastSync = viewModel.lastSyncTime {
                        StatusRow(
                            title: "Last Sync",
                            value: lastSync,
                            valueColor: .secondary,
                            icon: "clock"
                        )
                    }
                } header: {
                    Text("Current Status")
                }

                // Pending Operations Section
                Section {
                    HStack {
                        Label("Pending Changes", systemImage: "tray.full")
                        Spacer()
                        Text("\(viewModel.pendingCount)")
                            .foregroundColor(viewModel.pendingCount > 0 ? .orange : .secondary)
                            .fontWeight(viewModel.pendingCount > 0 ? .semibold : .regular)
                    }

                    if viewModel.pendingCount > 0 && viewModel.isConnected {
                        Button(action: {
                            viewModel.triggerManualSync()
                        }) {
                            HStack {
                                if viewModel.isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                            }
                        }
                        .disabled(viewModel.isSyncing)
                    }
                } header: {
                    Text("Pending Operations")
                } footer: {
                    if viewModel.pendingCount > 0 {
                        Text("These changes will sync automatically when online.")
                    }
                }

                // Failed Operations Section (if any)
                if viewModel.failedCount > 0 {
                    Section {
                        HStack {
                            Label("Failed Syncs", systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Spacer()
                            Text("\(viewModel.failedCount)")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }

                        ForEach(viewModel.failedOperations) { operation in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(operation.description)
                                    .font(.subheadline)
                                if let error = operation.errorMessage {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("Failed \(operation.failedAt.formatted(.relative(presentation: .named)))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Discard", role: .destructive) {
                                    viewModel.discardFailedOperation(operation.id)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button("Retry") {
                                    viewModel.retryFailedOperation(operation.id)
                                }
                                .tint(.blue)
                            }
                        }

                        if viewModel.failedCount > 1 {
                            Button("Retry All Failed", action: viewModel.retryAllFailed)
                                .foregroundColor(.blue)

                            Button("Discard All Failed", role: .destructive, action: viewModel.discardAllFailed)
                        }
                    } header: {
                        Text("Failed Operations")
                    } footer: {
                        Text("Swipe left to discard, right to retry individual items.")
                    }
                }

                // Actions Section
                Section {
                    Button(action: {
                        viewModel.pullAllDataFromServer()
                    }) {
                        HStack {
                            Label("Refresh from Server", systemImage: "arrow.down.circle")
                            Spacer()
                            if viewModel.isPulling {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(viewModel.isPulling || !viewModel.isConnected)
                } header: {
                    Text("Actions")
                } footer: {
                    Text("Download the latest data from the server. Local changes will not be overwritten.")
                }
            }
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.startObserving()
        }
        .onDisappear {
            viewModel.stopObserving()
        }
    }
}

// MARK: - Status Row

private struct StatusRow: View {
    let title: String
    let value: String
    let valueColor: Color
    let icon: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - View Model

@MainActor
class SyncStatusViewModel: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var isSyncing: Bool = false
    @Published var isPulling: Bool = false
    @Published var pendingCount: Int = 0
    @Published var failedCount: Int = 0
    @Published var failedOperations: [FailedSyncOperation] = []
    @Published var lastSyncTime: String?

    private var syncObserver: NSObjectProtocol?
    private var failedObserver: NSObjectProtocol?

    func startObserving() {
        refresh()

        // Observe sync completion
        syncObserver = NotificationCenter.default.addObserver(
            forName: .offlineSyncCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        // Observe failed operations
        failedObserver = NotificationCenter.default.addObserver(
            forName: .offlineSyncOperationsFailed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let count = notification.userInfo?["count"] as? Int, count > 0 {
                Task { @MainActor in
                    self?.refresh()
                }
            }
        }
    }

    func stopObserving() {
        if let observer = syncObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = failedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func refresh() {
        let status = OfflineSyncManager.shared.getSyncStatus()
        isConnected = status.isConnected
        isSyncing = status.isSyncing
        pendingCount = status.pendingOperations

        if let lastAttempt = status.lastSyncAttempt {
            lastSyncTime = lastAttempt.formatted(.relative(presentation: .named))
        }

        failedOperations = OfflineDataManager.shared.getFailedOperations()
        failedCount = failedOperations.count
    }

    var syncStatusDescription: String {
        if isSyncing {
            return "Syncing..."
        } else if failedCount > 0 {
            // LOW-9 FIX: Prioritize showing failed count over pending
            // Failed operations need user attention, pending will auto-resolve
            return "\(failedCount) failed - needs attention"
        } else if pendingCount > 0 {
            return "\(pendingCount) pending"
        } else if unresolvedConflictCount > 0 {
            // HIGH-4: Show conflict count if any unresolved
            return "\(unresolvedConflictCount) conflict(s) detected"
        } else {
            return "Up to date"
        }
    }

    /// HIGH-4: Count of unresolved multi-device conflicts
    var unresolvedConflictCount: Int {
        OfflineDataManager.shared.getUnresolvedConflictCount()
    }

    func triggerManualSync() {
        guard isConnected else { return }

        // Force sync bypassing the minimum interval for manual user action
        Task {
            await OfflineSyncManager.shared.forceSync()
            await MainActor.run {
                self.refresh()
            }
        }
    }

    func pullAllDataFromServer() {
        guard isConnected else { return }
        isPulling = true

        Task {
            do {
                try await OfflineSyncManager.shared.pullAllData()
            } catch {
                print("[SyncStatus] Failed to pull data: \(error)")
            }
            await MainActor.run {
                self.isPulling = false
                self.refresh()
            }
        }
    }

    func retryFailedOperation(_ id: String) {
        OfflineDataManager.shared.retryFailedOperation(id: id)
        // Brief delay then refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
            if self.isConnected {
                OfflineSyncManager.shared.triggerSync()
            }
        }
    }

    func discardFailedOperation(_ id: String) {
        OfflineDataManager.shared.discardFailedOperation(id: id)
        refresh()
    }

    func retryAllFailed() {
        for operation in failedOperations {
            OfflineDataManager.shared.retryFailedOperation(id: operation.id)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
            if self.isConnected {
                OfflineSyncManager.shared.triggerSync()
            }
        }
    }

    func discardAllFailed() {
        OfflineDataManager.shared.clearAllFailedOperations()
        refresh()
    }
}

#Preview {
    SyncStatusView()
}
