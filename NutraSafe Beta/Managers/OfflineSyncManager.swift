//
//  OfflineSyncManager.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Processes the offline sync queue and pushes changes to Firebase
//

import Foundation
import Network
import FirebaseFirestore

/// Manages synchronization between local offline storage and Firebase
final class OfflineSyncManager {

    // MARK: - Singleton

    static let shared = OfflineSyncManager()

    // MARK: - Properties

    private let syncQueue = DispatchQueue(label: "com.nutrasafe.offlineSync", qos: .utility)
    /// Thread-safe sync state using os_unfair_lock for atomic check-and-set
    private let syncStateLock = NSLock()
    private var _isSyncing = false
    private var isSyncing: Bool {
        get {
            syncStateLock.lock()
            defer { syncStateLock.unlock() }
            return _isSyncing
        }
        set {
            syncStateLock.lock()
            defer { syncStateLock.unlock() }
            _isSyncing = newValue
        }
    }

    /// Atomically try to start syncing - returns true if we successfully started, false if already syncing
    private func tryStartSync() -> Bool {
        syncStateLock.lock()
        defer { syncStateLock.unlock() }
        if _isSyncing {
            return false
        }
        _isSyncing = true
        return true
    }

    private let networkMonitor = NWPathMonitor()

    /// CRIT-4 FIX: Increased from 5 to 10 retries to handle transient network issues
    /// With exponential backoff (1, 2, 4, 8, 16, 32, 64, 128, 256, 300s capped),
    /// this allows ~14 minutes of retries before giving up
    private let maxRetryCount = 10

    /// Maximum concurrent sync operations to prevent memory explosion
    private let maxConcurrentOperations = 5

    /// Timeout for Firestore transactions (in seconds)
    private let transactionTimeout: TimeInterval = 30

    /// Minimum time between sync attempts
    private let minSyncInterval: TimeInterval = 30

    /// HIGH-2 FIX: Increased from 0.5s to 3.0s to handle network flapping
    /// Mobile networks can reconnect/disconnect multiple times per second during transitions
    /// 3 seconds provides stability while still being responsive enough for user experience
    private let networkReconnectDebounce: TimeInterval = 3.0

    /// Interval for periodic full sync (30 minutes) to balance freshness vs battery
    /// Changed from 5 min to reduce battery drain (288 → 48 syncs/day)
    private let periodicSyncInterval: TimeInterval = 1800

    /// Timer for periodic sync
    private var periodicSyncTimer: Timer?

    /// Thread-safe last sync attempt timestamp using NSLock
    private let lastSyncAttemptLock = NSLock()
    private var _lastSyncAttempt: Date?
    private var lastSyncAttempt: Date? {
        get {
            lastSyncAttemptLock.lock()
            defer { lastSyncAttemptLock.unlock() }
            return _lastSyncAttempt
        }
        set {
            lastSyncAttemptLock.lock()
            defer { lastSyncAttemptLock.unlock() }
            _lastSyncAttempt = newValue
        }
    }

    /// Thread-safe pending reconnection sync task (for debouncing)
    private let reconnectTaskLock = NSLock()
    private var _pendingReconnectTask: Task<Void, Never>?
    private var pendingReconnectTask: Task<Void, Never>? {
        get {
            reconnectTaskLock.lock()
            defer { reconnectTaskLock.unlock() }
            return _pendingReconnectTask
        }
        set {
            reconnectTaskLock.lock()
            defer { reconnectTaskLock.unlock() }
            _pendingReconnectTask = newValue
        }
    }

    /// Thread-safe network connection state
    private let connectionLock = NSLock()
    private var _isConnected: Bool = true
    /// Whether the device is currently connected to the network
    var isConnected: Bool {
        get {
            connectionLock.lock()
            defer { connectionLock.unlock() }
            return _isConnected
        }
        set {
            connectionLock.lock()
            defer { connectionLock.unlock() }
            _isConnected = newValue
        }
    }

    /// Track failed operations that exceeded max retries (for user notification)
    /// Using actor-isolated state to avoid NSLock in async contexts (Swift 6 compatibility)
    private let failedOpsQueue = DispatchQueue(label: "com.nutrasafe.failedOps")
    private var _failedOperationsCount = 0

    // MARK: - Circuit Breaker
    /// Circuit breaker to prevent retry storms when Firebase is down
    /// Trips after 90% failure rate in a batch, resets after successful sync
    private var circuitBreakerTripped = false
    private var circuitBreakerResetTime: Date?
    private let circuitBreakerResetInterval: TimeInterval = 300 // 5 minutes cooldown

    // MARK: - Initialization

    private init() {
        setupNetworkMonitoring()
        setupNotificationObservers()
        startPeriodicSync()
    }

    // MARK: - Periodic Sync

    /// Start a timer that runs full sync every 30 minutes to keep local data fresh
    /// BATTERY FIX: Only runs when app is in foreground (stopped on background)
    private func startPeriodicSync() {
        // Must run on main thread for timer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // BATTERY FIX: Don't start timer if app is in background
            let appState = UIApplication.shared.applicationState
            guard appState == .active else {
                #if DEBUG
                print("[OfflineSyncManager] Not starting periodic sync - app is not active (state: \(appState.rawValue))")
                #endif
                return
            }

            self.periodicSyncTimer?.invalidate()
            self.periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: self.periodicSyncInterval, repeats: true) { [weak self] _ in
                guard let self = self, self.isConnected else { return }
                #if DEBUG
                print("[OfflineSyncManager] Periodic sync triggered (every 30 mins)")
                #endif
                Task {
                    do {
                        try await self.pullAllData()
                    } catch {
                        print("[OfflineSyncManager] Periodic sync failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Stop the periodic sync timer
    func stopPeriodicSync() {
        DispatchQueue.main.async { [weak self] in
            self?.periodicSyncTimer?.invalidate()
            self?.periodicSyncTimer = nil
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            let wasConnected = self.isConnected
            self.isConnected = path.status == .satisfied

            print("[OfflineSyncManager] Network status: \(path.status == .satisfied ? "connected" : "disconnected")")

            // Trigger sync when network becomes available (with debounce to handle network flapping)
            if !wasConnected && path.status == .satisfied {
                print("[OfflineSyncManager] Network reconnected - scheduling sync with debounce")

                // Cancel any pending reconnect task
                self.pendingReconnectTask?.cancel()

                // Schedule sync after debounce period
                self.pendingReconnectTask = Task {
                    do {
                        try await Task.sleep(nanoseconds: UInt64(self.networkReconnectDebounce * 1_000_000_000))

                        // Check we're still connected after debounce
                        guard !Task.isCancelled && self.isConnected else { return }

                        print("[OfflineSyncManager] Debounce complete - triggering sync")
                        self.triggerSync()
                    } catch {
                        // Task was cancelled (network dropped again) - ignore
                    }
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    private func setupNotificationObservers() {
        // Listen for pending sync notifications
        NotificationCenter.default.addObserver(
            forName: .offlineDataPendingSync,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerSync()
        }

        // Listen for app becoming active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerSync()
            // BATTERY FIX: Restart periodic sync timer when app comes to foreground
            self?.startPeriodicSync()
        }

        // BATTERY FIX: Stop periodic sync timer when app backgrounds to prevent battery drain
        // This prevents the timer from firing every 30 minutes while the app is in background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            #if DEBUG
            print("[OfflineSyncManager] App backgrounded - stopping periodic sync timer to save battery")
            #endif
            self?.stopPeriodicSync()
        }
    }

    // MARK: - Sync Trigger

    /// Trigger a sync if conditions are met
    func triggerSync() {
        // Check if we're connected
        guard isConnected else {
            print("[OfflineSyncManager] No network connection - skipping sync")
            return
        }

        // Check minimum interval
        if let lastAttempt = lastSyncAttempt,
           Date().timeIntervalSince(lastAttempt) < minSyncInterval {
            print("[OfflineSyncManager] Too soon since last sync - skipping")
            return
        }

        // Start sync
        performSync()
    }

    /// Force a sync regardless of timing constraints
    func forceSync() async {
        guard isConnected else {
            print("[OfflineSyncManager] No network connection - cannot force sync")
            return
        }

        await withCheckedContinuation { continuation in
            performSync {
                continuation.resume()
            }
        }
    }

    // MARK: - Sync Execution

    private func performSync(completion: (() -> Void)? = nil) {
        syncQueue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }

            // RACE CONDITION FIX: Use atomic tryStartSync() instead of check-then-set
            guard self.tryStartSync() else {
                print("[OfflineSyncManager] Sync already in progress")
                completion?()
                return
            }

            self.lastSyncAttempt = Date()

            print("[OfflineSyncManager] Starting sync...")

            // Get pending operations
            let operations = OfflineDataManager.shared.getPendingSyncOperations()

            if operations.isEmpty {
                print("[OfflineSyncManager] No pending operations")
                self.isSyncing = false
                completion?()
                return
            }

            print("[OfflineSyncManager] Found \(operations.count) pending operations")

            // CIRCUIT BREAKER: Check if we should skip sync due to recent high failure rate
            if self.circuitBreakerTripped {
                if let resetTime = self.circuitBreakerResetTime,
                   Date() > resetTime {
                    // Reset the circuit breaker after cooldown period
                    self.circuitBreakerTripped = false
                    self.circuitBreakerResetTime = nil
                    print("[OfflineSyncManager] Circuit breaker reset after cooldown")
                } else {
                    print("[OfflineSyncManager] Circuit breaker tripped - skipping sync to prevent retry storm")
                    self.isSyncing = false
                    completion?()
                    return
                }
            }

            // RACE CONDITION FIX: Use structured concurrency with TaskGroup instead of DispatchGroup
            // This ensures all tasks complete before we mark sync as done
            // MEMORY FIX: Process in batches to prevent memory explosion with large queues
            // THREAD FIX: Run on MainActor to prevent "Publishing from background thread" warnings
            Task { @MainActor in
                // Track batch success/failure for circuit breaker
                var batchSuccessCount = 0
                var batchFailureCount = 0

                // Process operations in batches to limit concurrent Firebase calls
                let batches = operations.chunked(into: self.maxConcurrentOperations)

                for batch in batches {
                    await withTaskGroup(of: (PendingSyncOperation, Result<Void, Error>).self) { group in
                        for operation in batch {
                            group.addTask {
                                do {
                                    try await self.processOperation(operation)
                                    return (operation, .success(()))
                                } catch {
                                    return (operation, .failure(error))
                                }
                            }
                        }

                        // Process results - only remove from queue AFTER Firebase confirms success
                        for await (operation, result) in group {
                            switch result {
                            case .success:
                                // SUCCESS: Now safe to remove from sync queue
                                OfflineDataManager.shared.removeSyncOperation(id: operation.id)

                                // CRITICAL FIX: Handle DELETE operations differently!
                                // If we mark a deleted entry as 'synced', the deletion check
                                // (isDocumentDeletedInternal) returns false and imports resurrect it.
                                // For deletes: Hard-delete the SQLite row immediately to prevent resurrection.
                                if operation.type == .delete {
                                    // IMMEDIATE hard-delete prevents any race condition where
                                    // an import could resurrect the entry before cleanup runs
                                    OfflineDataManager.shared.hardDeleteRecord(collection: operation.collection, documentId: operation.documentId)
                                } else {
                                    OfflineDataManager.shared.markAsSynced(collection: operation.collection, documentId: operation.documentId)
                                }
                                print("[OfflineSyncManager] Synced: \(operation.collection)/\(operation.documentId) (\(operation.type.rawValue))")
                                batchSuccessCount += 1

                            case .failure(let error):
                                print("[OfflineSyncManager] Failed to sync \(operation.collection)/\(operation.documentId): \(error)")
                                batchFailureCount += 1

                                if operation.retryCount < self.maxRetryCount {
                                    // HIGH-9 FIX: Increment retry count and set next_retry_time
                                    // Backoff is now tracked in the database and checked before processing
                                    // This prevents blocking the task group with inline sleeps
                                    let backoffDelay = min(pow(2.0, Double(operation.retryCount + 1)), 300.0)
                                    OfflineDataManager.shared.incrementRetryCount(id: operation.id, backoffSeconds: backoffDelay)
                                    print("[OfflineSyncManager] HIGH-9: Scheduled retry for \(operation.id) in \(Int(backoffDelay))s (attempt \(operation.retryCount + 1)/\(self.maxRetryCount))")
                                } else {
                                    // Max retries exceeded - move to failed operations table and notify user
                                    print("[OfflineSyncManager] Max retries exceeded for \(operation.id) - marking as permanently failed")
                                    OfflineDataManager.shared.markOperationAsFailed(operation: operation, error: error.localizedDescription)
                                    OfflineDataManager.shared.removeSyncOperation(id: operation.id)

                                    // Track failed operations for user notification (thread-safe)
                                    self.failedOpsQueue.sync {
                                        self._failedOperationsCount += 1
                                    }
                                }
                            }
                        }
                    }
                }

                // Clean up deleted records that have been synced
                OfflineDataManager.shared.cleanupDeletedRecords()

                // HIGH-6 FIX: Improved circuit breaker with better thresholds
                // - Require at least 5 operations (was 3) to avoid false positives from small batches
                // - Use 80% threshold (was 90%) to trip earlier when Firebase is struggling
                // - Require at least 2 successes (was 1) to reset, preventing flapping
                let totalOperations = batchSuccessCount + batchFailureCount
                if totalOperations > 0 {
                    let failureRate = Double(batchFailureCount) / Double(totalOperations)
                    if failureRate >= 0.8 && totalOperations >= 5 {
                        // Trip the circuit breaker
                        self.circuitBreakerTripped = true
                        self.circuitBreakerResetTime = Date().addingTimeInterval(self.circuitBreakerResetInterval)
                        print("[OfflineSyncManager] ⚠️ Circuit breaker TRIPPED - \(Int(failureRate * 100))% failure rate (\(batchFailureCount)/\(totalOperations)). Cooling down for \(Int(self.circuitBreakerResetInterval))s")
                    } else if batchSuccessCount >= 2 && self.circuitBreakerTripped {
                        // Reset circuit breaker only after 2+ successes to prevent flapping
                        self.circuitBreakerTripped = false
                        self.circuitBreakerResetTime = nil
                        print("[OfflineSyncManager] Circuit breaker reset due to \(batchSuccessCount) successful operations")
                    }
                }

                self.isSyncing = false

                // Check for failed operations and notify user (thread-safe)
                let failedCount = self.failedOpsQueue.sync {
                    let count = self._failedOperationsCount
                    self._failedOperationsCount = 0
                    return count
                }

                let totalFailedCount = OfflineDataManager.shared.getFailedOperationsCount()

                print("[OfflineSyncManager] Sync completed. \(failedCount) new failures, \(totalFailedCount) total failed operations.")

                // Notify observers
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .offlineSyncCompleted,
                        object: nil,
                        userInfo: [
                            "newFailures": failedCount,
                            "totalFailures": totalFailedCount
                        ]
                    )

                    // Post separate notification if there are failed operations requiring user attention
                    if failedCount > 0 {
                        NotificationCenter.default.post(
                            name: .offlineSyncOperationsFailed,
                            object: nil,
                            userInfo: ["count": failedCount]
                        )
                    }
                }

                completion?()
            }
        }
    }

    // MARK: - Operation Processing

    private func processOperation(_ operation: PendingSyncOperation) async throws {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw SyncError.notAuthenticated
        }

        let db = Firestore.firestore()

        switch operation.type {
        case .add, .update:
            // CRIT-6 FIX: Skip add/update if document was deleted OR has a delete pending
            // This prevents stale edits from resurrecting deleted records via INSERT OR REPLACE
            // Check both: (1) sync_status = 'deleted' in table, and (2) pending delete in sync queue
            if OfflineDataManager.shared.isDocumentDeleted(collection: operation.collection, documentId: operation.documentId) {
                print("[OfflineSyncManager] CRIT-6: Skipping stale \(operation.type) - document marked deleted: \(operation.documentId)")
                return // Skip this operation - document was deleted
            }
            if OfflineDataManager.shared.hasDeletePending(collection: operation.collection, documentId: operation.documentId) {
                print("[OfflineSyncManager] CRIT-6: Skipping stale \(operation.type) - delete pending in queue: \(operation.documentId)")
                return // Skip this operation - delete is pending
            }
            try await processAddOrUpdate(operation: operation, userId: userId, db: db)
        case .delete:
            try await processDelete(operation: operation, userId: userId, db: db)
        }
    }

    private func processAddOrUpdate(operation: PendingSyncOperation, userId: String, db: Firestore) async throws {
        guard let data = operation.data else {
            throw SyncError.missingData
        }

        let docRef: DocumentReference

        switch operation.collection {
        case "foodEntries":
            docRef = db.collection("users").document(userId)
                .collection("foodEntries").document(operation.documentId)

            // Decode FoodEntry and convert to dictionary
            if let entry = try? JSONDecoder().decode(FoodEntry.self, from: data) {
                var dict = entry.toDictionary()
                // Use server timestamp for authoritative conflict resolution (fixes clock skew issues)
                dict["lastModified"] = FieldValue.serverTimestamp()
                // Store local timestamp as reference for debugging
                dict["localTimestamp"] = Timestamp(date: operation.timestamp)

                // CRIT-1 FIX: Use server-authoritative conflict resolution
                // Instead of comparing client timestamps (which are unreliable due to clock skew),
                // we use a version counter approach. If server has data, increment version.
                // Last-write-wins using server timestamp as the arbiter.
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data() {
                        // Server has existing data - check version for optimistic concurrency
                        let serverVersion = serverData["_version"] as? Int ?? 0
                        let localVersion = dict["_version"] as? Int ?? 0

                        // If server has higher version, this is a conflict
                        // In offline-first, we prefer local changes (user's intent) but log the conflict
                        if serverVersion > localVersion {
                            print("[OfflineSyncManager] CRIT-1: Conflict detected for food entry \(operation.documentId) - server v\(serverVersion), local v\(localVersion). Applying local changes (last-write-wins).")
                        }

                        // Always write with incremented version (last-write-wins)
                        dict["_version"] = max(serverVersion, localVersion) + 1
                    } else {
                        // No server document - this is a new record
                        dict["_version"] = 1
                    }
                    transaction.setData(dict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "useByInventory":
            docRef = db.collection("users").document(userId)
                .collection("useByInventory").document(operation.documentId)

            if let item = try? JSONDecoder().decode(UseByInventoryItem.self, from: data) {
                var dict: [String: Any] = [
                    "id": item.id,
                    "name": item.name,
                    "quantity": item.quantity,
                    "expiryDate": Timestamp(date: item.expiryDate),
                    "addedDate": Timestamp(date: item.addedDate),
                    "lastModified": FieldValue.serverTimestamp(),
                    "localTimestamp": Timestamp(date: operation.timestamp)
                ]
                if let brand = item.brand { dict["brand"] = brand }
                if let barcode = item.barcode { dict["barcode"] = barcode }
                if let category = item.category { dict["category"] = category }
                if let imageURL = item.imageURL { dict["imageURL"] = imageURL }
                if let notes = item.notes { dict["notes"] = notes }

                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data() {
                        let serverVersion = serverData["_version"] as? Int ?? 0
                        if serverVersion > (dict["_version"] as? Int ?? 0) {
                            print("[OfflineSyncManager] CRIT-1: Conflict on use-by item \(operation.documentId) - applying local (last-write-wins)")
                        }
                        dict["_version"] = serverVersion + 1
                    } else {
                        dict["_version"] = 1
                    }
                    transaction.setData(dict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "weightHistory":
            docRef = db.collection("users").document(userId)
                .collection("weightHistory").document(operation.documentId)

            if let entry = try? JSONDecoder().decode(WeightEntry.self, from: data) {
                var dict: [String: Any] = [
                    "id": entry.id.uuidString,
                    "weight": entry.weight,
                    "date": Timestamp(date: entry.date),
                    "lastModified": FieldValue.serverTimestamp(),
                    "localTimestamp": Timestamp(date: operation.timestamp)
                ]
                if let bmi = entry.bmi { dict["bmi"] = bmi }
                if let note = entry.note { dict["note"] = note }
                if let photoURL = entry.photoURL { dict["photoURL"] = photoURL }
                if let photoURLs = entry.photoURLs { dict["photoURLs"] = photoURLs }
                if let waistSize = entry.waistSize { dict["waistSize"] = waistSize }
                if let dressSize = entry.dressSize { dict["dressSize"] = dressSize }

                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data() {
                        let serverVersion = serverData["_version"] as? Int ?? 0
                        if serverVersion > (dict["_version"] as? Int ?? 0) {
                            print("[OfflineSyncManager] CRIT-1: Conflict on weight entry \(operation.documentId) - applying local (last-write-wins)")
                        }
                        dict["_version"] = serverVersion + 1
                    } else {
                        dict["_version"] = 1
                    }
                    transaction.setData(dict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "settings":
            docRef = db.collection("users").document(userId)
                .collection("settings").document("preferences")

            // Settings data is already a dictionary
            if var settingsDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data() {
                        let serverVersion = serverData["_version"] as? Int ?? 0
                        if serverVersion > (settingsDict["_version"] as? Int ?? 0) {
                            print("[OfflineSyncManager] CRIT-1: Conflict on settings - applying local (last-write-wins)")
                        }
                        settingsDict["_version"] = serverVersion + 1
                    } else {
                        settingsDict["_version"] = 1
                    }
                    settingsDict["lastModified"] = FieldValue.serverTimestamp()
                    transaction.setData(settingsDict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "fastingSessions":
            docRef = db.collection("users").document(userId)
                .collection("fastingSessions").document(operation.documentId)

            if let session = try? JSONDecoder().decode(FastingSession.self, from: data) {
                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)
                    let serverVersion = serverDoc?.data()?["_version"] as? Int ?? 0

                    // Always write with incremented version (last-write-wins for offline-first)
                    var sessionDict: [String: Any] = [
                        "_version": serverVersion + 1,
                        "lastModified": FieldValue.serverTimestamp()
                    ]
                    // Merge with encoded session data
                    if let encodedData = try? Firestore.Encoder().encode(session) {
                        sessionDict.merge(encodedData) { _, new in new }
                    }
                    transaction.setData(sessionDict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "fastingPlans":
            docRef = db.collection("users").document(userId)
                .collection("fastingPlans").document(operation.documentId)

            if let plan = try? JSONDecoder().decode(FastingPlan.self, from: data) {
                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)
                    let serverVersion = serverDoc?.data()?["_version"] as? Int ?? 0

                    // Always write with incremented version (last-write-wins for offline-first)
                    var planDict: [String: Any] = [
                        "_version": serverVersion + 1,
                        "lastModified": FieldValue.serverTimestamp()
                    ]
                    // Merge with encoded plan data
                    if let encodedData = try? Firestore.Encoder().encode(plan) {
                        planDict.merge(encodedData) { _, new in new }
                    }
                    transaction.setData(planDict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "reactionLogs":
            docRef = db.collection("users").document(userId)
                .collection("reactionLogs").document(operation.documentId)

            if let entry = try? JSONDecoder().decode(ReactionLogEntry.self, from: data) {
                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)
                    let serverVersion = serverDoc?.data()?["_version"] as? Int ?? 0

                    // Always write with incremented version (last-write-wins for offline-first)
                    var entryDict: [String: Any] = [
                        "_version": serverVersion + 1,
                        "lastModified": FieldValue.serverTimestamp()
                    ]
                    // Merge with encoded entry data
                    if let encodedData = try? Firestore.Encoder().encode(entry) {
                        entryDict.merge(encodedData) { _, new in new }
                    }
                    transaction.setData(entryDict, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "favoriteFoods":
            docRef = db.collection("users").document(userId)
                .collection("favoriteFoods").document(operation.documentId)

            if let food = try? JSONDecoder().decode(FoodSearchResult.self, from: data) {
                // Convert to dictionary for Firestore (FoodSearchResult may have complex nested types)
                var favoriteData: [String: Any] = [
                    "id": food.id,
                    "name": food.name,
                    "calories": food.calories,
                    "protein": food.protein,
                    "carbs": food.carbs,
                    "fat": food.fat,
                    "fiber": food.fiber,
                    "sugar": food.sugar,
                    "sodium": food.sodium,
                    "isVerified": food.isVerified,
                    "addedAt": Timestamp(date: Date())
                ]
                if let brand = food.brand { favoriteData["brand"] = brand }
                if let saturatedFat = food.saturatedFat { favoriteData["saturatedFat"] = saturatedFat }
                if let servingDescription = food.servingDescription { favoriteData["servingDescription"] = servingDescription }
                if let servingSizeG = food.servingSizeG { favoriteData["servingSizeG"] = servingSizeG }
                if let isPerUnit = food.isPerUnit { favoriteData["isPerUnit"] = isPerUnit }
                if let barcode = food.barcode { favoriteData["barcode"] = barcode }
                if let ingredients = food.ingredients { favoriteData["ingredients"] = ingredients }
                if let processingScore = food.processingScore { favoriteData["processingScore"] = processingScore }
                if let processingGrade = food.processingGrade { favoriteData["processingGrade"] = processingGrade }
                if let processingLabel = food.processingLabel { favoriteData["processingLabel"] = processingLabel }

                // Encode additives and micronutrients as JSON
                if let additives = food.additives, let additivesData = try? JSONEncoder().encode(additives),
                   let additivesArray = try? JSONSerialization.jsonObject(with: additivesData) as? [[String: Any]] {
                    favoriteData["additives"] = additivesArray
                }
                if let micronutrients = food.micronutrientProfile, let microData = try? JSONEncoder().encode(micronutrients),
                   let microDict = try? JSONSerialization.jsonObject(with: microData) as? [String: Any] {
                    favoriteData["micronutrientProfile"] = microDict
                }
                if let portions = food.portions, let portionsData = try? JSONEncoder().encode(portions),
                   let portionsArray = try? JSONSerialization.jsonObject(with: portionsData) as? [[String: Any]] {
                    favoriteData["portions"] = portionsArray
                }

                // CRIT-1 FIX: Use server-authoritative conflict resolution with version counter
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)
                    let serverVersion = serverDoc?.data()?["_version"] as? Int ?? 0

                    // Always write with incremented version (last-write-wins for offline-first)
                    favoriteData["_version"] = serverVersion + 1
                    favoriteData["lastModified"] = FieldValue.serverTimestamp()
                    transaction.setData(favoriteData, forDocument: docRef)
                }
            } else {
                throw SyncError.decodingFailed
            }

        default:
            throw SyncError.unknownCollection
        }
    }

    // MARK: - Transaction Helper with Timeout

    /// HIGH-3 FIX: Rewritten to avoid UnsafeMutablePointer which isn't safe across async contexts
    /// Uses Swift's built-in Task cancellation mechanism instead
    private func runTransactionWithTimeout(
        db: Firestore,
        _ updateBlock: @escaping (Transaction) -> Void
    ) async throws {
        // Create a task that will race: transaction vs timeout
        // The first to complete wins, the other is cancelled
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Track if transaction succeeded (using atomic actor-isolated state isn't needed
            // because TaskGroup handles the race internally - first completion cancels others)

            // Add the main transaction task
            group.addTask {
                try await db.runTransaction { transaction, _ in
                    updateBlock(transaction)
                    return nil
                }
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.transactionTimeout * 1_000_000_000))
                // If we get here, timeout elapsed before transaction completed
                throw SyncError.transactionTimeout
            }

            // Wait for first result - either transaction succeeds, or timeout throws
            // TaskGroup semantics: first successful completion or first error
            do {
                // Wait for first task to complete (transaction or timeout)
                _ = try await group.next()
                // If we get here without error, transaction completed successfully
                group.cancelAll() // Cancel the other task (timeout)
            } catch {
                group.cancelAll() // Cancel remaining tasks
                throw error // Re-throw (either transaction error or timeout)
            }
        }
    }

    private func processDelete(operation: PendingSyncOperation, userId: String, db: Firestore) async throws {
        let docRef: DocumentReference

        switch operation.collection {
        case "foodEntries":
            docRef = db.collection("users").document(userId)
                .collection("foodEntries").document(operation.documentId)

        case "useByInventory":
            docRef = db.collection("users").document(userId)
                .collection("useByInventory").document(operation.documentId)

        case "weightHistory":
            docRef = db.collection("users").document(userId)
                .collection("weightHistory").document(operation.documentId)

        case "fastingSessions":
            docRef = db.collection("users").document(userId)
                .collection("fastingSessions").document(operation.documentId)

        case "fastingPlans":
            docRef = db.collection("users").document(userId)
                .collection("fastingPlans").document(operation.documentId)

        case "reactionLogs":
            docRef = db.collection("users").document(userId)
                .collection("reactionLogs").document(operation.documentId)

        case "favoriteFoods":
            docRef = db.collection("users").document(userId)
                .collection("favoriteFoods").document(operation.documentId)

        default:
            throw SyncError.unknownCollection
        }

        // HIGH-5 FIX: Verify document exists before deleting to provide better logging
        // Note: Firestore delete() is idempotent (doesn't fail if doc doesn't exist),
        // but this helps debug sync issues where delete was already processed
        do {
            let snapshot = try await docRef.getDocument()
            if !snapshot.exists {
                print("[OfflineSyncManager] HIGH-5: Document \(operation.documentId) already deleted on server - marking sync complete")
                // Document doesn't exist - this is success (already deleted)
                return
            }
            try await docRef.delete()
        } catch {
            // Log and re-throw - permission errors will surface here
            print("[OfflineSyncManager] HIGH-5: Delete failed for \(operation.documentId): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Initial Data Pull

    /// Pull all user data from Firebase to local storage (for first launch or re-sync)
    /// CRIT-2 FIX: Captures auth generation at start and checks after each network call
    /// to prevent data leakage if user signs out/in mid-operation
    func pullAllData() async throws {
        guard FirebaseManager.shared.currentUser?.uid != nil else {
            throw SyncError.notAuthenticated
        }

        guard isConnected else {
            throw SyncError.noNetwork
        }

        // CRIT-2 FIX: Capture auth generation to detect mid-operation auth changes
        let authGeneration = FirebaseManager.shared.captureAuthState()

        print("[OfflineSyncManager] Pulling all data from Firebase...")

        // Pull food entries (last 90 days)
        guard let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else {
            print("[OfflineSyncManager] Failed to calculate date 90 days ago")
            throw SyncError.decodingFailed
        }
        let foodEntries = try await FirebaseManager.shared.getFoodEntriesInRange(from: ninetyDaysAgo, to: Date())
        // CRIT-2 FIX: Check auth state before importing to local storage
        try FirebaseManager.shared.checkAuthStateUnchanged(since: authGeneration)
        OfflineDataManager.shared.importFoodEntries(foodEntries)
        print("[OfflineSyncManager] Pulled \(foodEntries.count) food entries")

        // Pull Use By items
        let useByItems: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
        // CRIT-2 FIX: Check auth state before importing
        try FirebaseManager.shared.checkAuthStateUnchanged(since: authGeneration)
        OfflineDataManager.shared.importUseByItems(useByItems)
        print("[OfflineSyncManager] Pulled \(useByItems.count) Use By items")

        // Pull weight history
        let weightEntries = try await FirebaseManager.shared.getWeightHistory()
        // CRIT-2 FIX: Check auth state before importing
        try FirebaseManager.shared.checkAuthStateUnchanged(since: authGeneration)
        OfflineDataManager.shared.importWeightEntries(weightEntries)
        print("[OfflineSyncManager] Pulled \(weightEntries.count) weight entries")

        // Pull user settings
        let settings = try await FirebaseManager.shared.getUserSettings()
        // CRIT-2 FIX: Check auth state before importing
        try FirebaseManager.shared.checkAuthStateUnchanged(since: authGeneration)
        OfflineDataManager.shared.saveUserSettings(
            height: settings.height,
            goalWeight: settings.goalWeight,
            caloricGoal: settings.caloricGoal,
            exerciseGoal: settings.exerciseGoal,
            stepGoal: settings.stepGoal,
            proteinPercent: settings.proteinPercent,
            carbsPercent: settings.carbsPercent,
            fatPercent: settings.fatPercent,
            allergens: settings.allergens
        )
        // Mark as synced since we just pulled from server
        OfflineDataManager.shared.markAsSynced(collection: "settings", documentId: "preferences")

        print("[OfflineSyncManager] Initial data pull complete")
    }

    // MARK: - Sync Status

    /// Get the current sync status
    func getSyncStatus() -> SyncStatusInfo {
        let pendingCount = OfflineDataManager.shared.getPendingSyncCount()
        return SyncStatusInfo(
            pendingOperations: pendingCount,
            isConnected: isConnected,
            isSyncing: isSyncing,
            lastSyncAttempt: lastSyncAttempt
        )
    }
}

// MARK: - Sync Status Info

struct SyncStatusInfo {
    let pendingOperations: Int
    let isConnected: Bool
    let isSyncing: Bool
    let lastSyncAttempt: Date?

    var description: String {
        if !isConnected {
            return "Offline - \(pendingOperations) changes pending"
        } else if isSyncing {
            return "Syncing..."
        } else if pendingOperations > 0 {
            return "\(pendingOperations) changes pending"
        } else {
            return "Synced"
        }
    }
}

// MARK: - Sync Errors

enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case noNetwork
    case missingData
    case decodingFailed
    case unknownCollection
    case transactionTimeout

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .noNetwork:
            return "No network connection"
        case .missingData:
            return "Missing data for sync operation"
        case .decodingFailed:
            return "Failed to decode data"
        case .unknownCollection:
            return "Unknown collection type"
        case .transactionTimeout:
            return "Transaction timed out"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineSyncCompleted = Notification.Name("offlineSyncCompleted")
    static let offlineSyncOperationsFailed = Notification.Name("offlineSyncOperationsFailed")
}

// MARK: - Array Chunking Extension

private extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
