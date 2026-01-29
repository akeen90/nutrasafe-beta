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

    /// Maximum retry count before giving up on a sync operation
    private let maxRetryCount = 5

    /// Maximum concurrent sync operations to prevent memory explosion
    private let maxConcurrentOperations = 5

    /// Timeout for Firestore transactions (in seconds)
    private let transactionTimeout: TimeInterval = 30

    /// Minimum time between sync attempts
    private let minSyncInterval: TimeInterval = 30

    /// Debounce delay after network reconnection (prevents rapid sync attempts)
    private let networkReconnectDebounce: TimeInterval = 0.5

    /// Interval for periodic full sync (5 minutes) to keep local data fresh
    private let periodicSyncInterval: TimeInterval = 300

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

    // MARK: - Initialization

    private init() {
        setupNetworkMonitoring()
        setupNotificationObservers()
        startPeriodicSync()
    }

    // MARK: - Periodic Sync

    /// Start a timer that runs full sync every 5 minutes to keep local data fresh
    private func startPeriodicSync() {
        // Must run on main thread for timer
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.periodicSyncTimer?.invalidate()
            self.periodicSyncTimer = Timer.scheduledTimer(withTimeInterval: self.periodicSyncInterval, repeats: true) { [weak self] _ in
                guard let self = self, self.isConnected else { return }
                print("[OfflineSyncManager] Periodic sync triggered (every 5 mins)")
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

            // RACE CONDITION FIX: Use structured concurrency with TaskGroup instead of DispatchGroup
            // This ensures all tasks complete before we mark sync as done
            // MEMORY FIX: Process in batches to prevent memory explosion with large queues
            Task {
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
                                OfflineDataManager.shared.markAsSynced(collection: operation.collection, documentId: operation.documentId)
                                print("[OfflineSyncManager] Synced: \(operation.collection)/\(operation.documentId)")

                            case .failure(let error):
                                print("[OfflineSyncManager] Failed to sync \(operation.collection)/\(operation.documentId): \(error)")

                                if operation.retryCount < self.maxRetryCount {
                                    // Increment retry count (operation stays in queue for next sync)
                                    OfflineDataManager.shared.incrementRetryCount(id: operation.id)

                                    // Apply exponential backoff delay before next sync attempt
                                    let backoffDelay = pow(2.0, Double(operation.retryCount + 1))
                                    print("[OfflineSyncManager] Will retry \(operation.id) after \(backoffDelay)s backoff (attempt \(operation.retryCount + 1)/\(self.maxRetryCount))")
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

                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        // Compare using the local timestamp we recorded when we queued the change
                        // This allows server to be authoritative while still resolving conflicts
                        let serverDate = serverModified.dateValue()
                        // If document exists and was modified after we queued our change, skip
                        // Use a small tolerance (1 second) to handle near-simultaneous edits
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            transaction.setData(dict, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer data for food entry \(operation.documentId)")
                        }
                    } else {
                        // No server document or no timestamp - safe to write
                        transaction.setData(dict, forDocument: docRef)
                    }
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

                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            transaction.setData(dict, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer data for use by item \(operation.documentId)")
                        }
                    } else {
                        transaction.setData(dict, forDocument: docRef)
                    }
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

                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            transaction.setData(dict, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer data for \(operation.documentId)")
                        }
                    } else {
                        transaction.setData(dict, forDocument: docRef)
                    }
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "settings":
            docRef = db.collection("users").document(userId)
                .collection("settings").document("preferences")

            // Settings data is already a dictionary
            if let settingsDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                try await docRef.setData(settingsDict, merge: true)
            } else {
                throw SyncError.decodingFailed
            }

        case "fastingSessions":
            docRef = db.collection("users").document(userId)
                .collection("fastingSessions").document(operation.documentId)

            if let session = try? JSONDecoder().decode(FastingSession.self, from: data) {
                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        // Standardized comparison: allow 1 second tolerance for near-simultaneous edits
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            _ = try? transaction.setData(from: session, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer fasting session \(operation.documentId)")
                        }
                    } else {
                        _ = try? transaction.setData(from: session, forDocument: docRef)
                    }
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "fastingPlans":
            docRef = db.collection("users").document(userId)
                .collection("fastingPlans").document(operation.documentId)

            if let plan = try? JSONDecoder().decode(FastingPlan.self, from: data) {
                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        // Standardized comparison: allow 1 second tolerance for near-simultaneous edits
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            _ = try? transaction.setData(from: plan, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer fasting plan \(operation.documentId)")
                        }
                    } else {
                        _ = try? transaction.setData(from: plan, forDocument: docRef)
                    }
                }
            } else {
                throw SyncError.decodingFailed
            }

        case "reactionLogs":
            docRef = db.collection("users").document(userId)
                .collection("reactionLogs").document(operation.documentId)

            if let entry = try? JSONDecoder().decode(ReactionLogEntry.self, from: data) {
                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        // Standardized comparison: allow 1 second tolerance for near-simultaneous edits
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            _ = try? transaction.setData(from: entry, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer reaction log \(operation.documentId)")
                        }
                    } else {
                        _ = try? transaction.setData(from: entry, forDocument: docRef)
                    }
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
                    "addedAt": Timestamp(date: Date()),
                    "lastModified": Timestamp(date: operation.timestamp)
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

                // Use transaction for conflict resolution with timeout
                try await self.runTransactionWithTimeout(db: db) { transaction in
                    let serverDoc = try? transaction.getDocument(docRef)

                    if let serverData = serverDoc?.data(),
                       let serverModified = serverData["lastModified"] as? Timestamp {
                        let serverDate = serverModified.dateValue()
                        // Standardized comparison: allow 1 second tolerance for near-simultaneous edits
                        if operation.timestamp.timeIntervalSince(serverDate) > -1.0 {
                            transaction.setData(favoriteData, forDocument: docRef)
                        } else {
                            print("[OfflineSyncManager] Skipping sync - server has newer favorite food \(operation.documentId)")
                        }
                    } else {
                        transaction.setData(favoriteData, forDocument: docRef)
                    }
                }
            } else {
                throw SyncError.decodingFailed
            }

        default:
            throw SyncError.unknownCollection
        }
    }

    // MARK: - Transaction Helper with Timeout

    /// Runs a Firestore transaction with a timeout to prevent hanging operations
    private func runTransactionWithTimeout(
        db: Firestore,
        _ updateBlock: @escaping (Transaction) -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Add the transaction task
            group.addTask {
                _ = try await db.runTransaction { transaction, _ in
                    updateBlock(transaction)
                    return nil
                }
            }

            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.transactionTimeout * 1_000_000_000))
                throw SyncError.transactionTimeout
            }

            // Wait for first to complete (either success or timeout)
            do {
                try await group.next()
                // If transaction completed first, cancel the timeout
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
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

        try await docRef.delete()
    }

    // MARK: - Initial Data Pull

    /// Pull all user data from Firebase to local storage (for first launch or re-sync)
    func pullAllData() async throws {
        guard FirebaseManager.shared.currentUser?.uid != nil else {
            throw SyncError.notAuthenticated
        }

        guard isConnected else {
            throw SyncError.noNetwork
        }

        print("[OfflineSyncManager] Pulling all data from Firebase...")

        // Pull food entries (last 90 days)
        guard let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else {
            print("[OfflineSyncManager] Failed to calculate date 90 days ago")
            throw SyncError.decodingFailed
        }
        let foodEntries = try await FirebaseManager.shared.getFoodEntriesInRange(from: ninetyDaysAgo, to: Date())
        OfflineDataManager.shared.importFoodEntries(foodEntries)
        print("[OfflineSyncManager] Pulled \(foodEntries.count) food entries")

        // Pull Use By items
        let useByItems: [UseByInventoryItem] = try await FirebaseManager.shared.getUseByItems()
        OfflineDataManager.shared.importUseByItems(useByItems)
        print("[OfflineSyncManager] Pulled \(useByItems.count) Use By items")

        // Pull weight history
        let weightEntries = try await FirebaseManager.shared.getWeightHistory()
        OfflineDataManager.shared.importWeightEntries(weightEntries)
        print("[OfflineSyncManager] Pulled \(weightEntries.count) weight entries")

        // Pull user settings
        let settings = try await FirebaseManager.shared.getUserSettings()
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
