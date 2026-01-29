import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import AuthenticationServices
import CryptoKit

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var cachedWeightHistory: [WeightEntry] = []
    @Published var cachedUserHeight: Double?
    @Published var cachedGoalWeight: Double?

    private lazy var db: Firestore = {
        let firestore = Firestore.firestore()

        // Enable offline persistence with reasonable cache limit
        // Unlimited cache can grow to GBs and slow app startup
        // 100MB provides good offline experience without performance issues
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber) // 100 MB
        firestore.settings = settings

        return firestore
    }()
    private lazy var auth = Auth.auth()

    // Thread-safe cache using DispatchQueue (Swift 6 async-safe)
    private let cacheQueue = DispatchQueue(label: "com.nutrasafe.cacheQueue")
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    // Auth state generation counter - increments on each auth state change
    // Used by long-running operations to detect if auth changed mid-operation
    private let authGenerationLock = NSLock()
    private var _authGeneration: UInt64 = 0
    private var authGeneration: UInt64 {
        authGenerationLock.lock()
        defer { authGenerationLock.unlock() }
        return _authGeneration
    }
    private func incrementAuthGeneration() {
        authGenerationLock.lock()
        defer { authGenerationLock.unlock() }
        _authGeneration &+= 1 // Wrapping add to avoid overflow
    }

    /// Error thrown when auth state changes during an operation
    enum AuthStateError: LocalizedError {
        case authStateChanged
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .authStateChanged:
                return "Your authentication state changed. Please try again."
            case .notAuthenticated:
                return "You must be signed in to perform this action."
            }
        }
    }

    /// Captures the current auth generation for comparison during long-running operations.
    /// Call at the start of an operation, then use `checkAuthStateUnchanged` at checkpoints.
    private func captureAuthState() -> UInt64 {
        authGeneration
    }

    /// Throws if auth state has changed since the operation started.
    /// Use at checkpoints in long-running operations to abort early if user signed out.
    private func checkAuthStateUnchanged(since generation: UInt64) throws {
        guard authGeneration == generation else {
            throw AuthStateError.authStateChanged
        }
    }

    /// Guards that user is authenticated and returns the user ID.
    /// Use at the start of operations that require authentication.
    @MainActor
    private func requireAuthenticatedUserId() throws -> String {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }
        return userId
    }

    // Apple Sign In nonce storage - protected by dedicated queue to prevent race conditions
    private let nonceQueue = DispatchQueue(label: "com.nutrasafe.nonceQueue")
    private var _currentNonce: String?
    private var currentNonce: String? {
        get { nonceQueue.sync { _currentNonce } }
        set { nonceQueue.sync { _currentNonce = newValue } }
    }

    // MARK: - Search Cache (Optimized with NSCache)
    private class SearchCacheEntry {
        let results: [FoodSearchResult]
        let timestamp: Date

        init(results: [FoodSearchResult], timestamp: Date) {
            self.results = results
            self.timestamp = timestamp
        }
    }
    private let searchCache: NSCache<NSString, SearchCacheEntry> = {
        let cache = NSCache<NSString, SearchCacheEntry>()
        cache.countLimit = 100 // Maximum 100 cached searches
        cache.totalCostLimit = 10 * 1024 * 1024 // 10MB max
        return cache
    }()
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    // Thread-safe queue for search cache operations (NSCache is thread-safe for individual ops, but not for read-check-modify)
    private let searchCacheQueue = DispatchQueue(label: "com.nutrasafe.searchCacheQueue")
    // In-flight search request tracking to prevent duplicate fetches
    private var inFlightSearchRequests: [String: Task<[FoodSearchResult], Error>] = [:]

    // MARK: - Food Entries Cache (Performance Optimization)
    private struct FoodEntriesCacheEntry {
        let entries: [FoodEntry]
        let timestamp: Date
    }
    private var foodEntriesCache: [String: FoodEntriesCacheEntry] = [:]
    // PERFORMANCE: Separate LRU tracking for O(1) access time updates
    private var foodEntriesCacheAccessTime: [String: Date] = [:]
    private let foodEntriesCacheExpirationSeconds: TimeInterval = 600 // 10 minutes
    private let maxFoodEntriesCacheSize: Int = 100 // Maximum number of cached dates

    // In-flight request tracking to prevent duplicate fetches
    private var inFlightFoodEntriesRequests: [String: Task<[FoodEntry], Error>] = [:]

    // MARK: - Allergen Cache
    @Published var cachedUserAllergens: [Allergen] = []
    // allergensLastFetched is only accessed from MainActor contexts
    @MainActor private var allergensLastFetched: Date?
    private let allergenCacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    private init() {
        // Defer Firebase service initialization until first access
    }
    
    private func initializeFirebaseServices() {
        // Only initialize services when first accessed
        _ = db
        _ = auth
        
        // Guard against duplicate listener registration
        if authListenerHandle == nil {
            authListenerHandle = auth.addStateDidChangeListener { [weak self] _, user in
                // Ensure @Published properties change on the main actor
                // RACE CONDITION FIX: Check self before posting notification to prevent
                // orphaned observers receiving events for deallocated managers
                Task { @MainActor in
                    guard let self = self else { return }
                    // Increment auth generation to invalidate any in-flight operations
                    self.incrementAuthGeneration()
                    self.currentUser = user
                    self.isAuthenticated = user != nil
                    NotificationCenter.default.post(name: .authStateChanged, object: nil)
                }
            }
        }
    }

    /// Preload weight data into cache - awaitable to ensure data is ready before use
    @MainActor
    func preloadWeightData(history: [WeightEntry], height: Double?, goalWeight: Double?) {
        self.cachedWeightHistory = history
        self.cachedUserHeight = height
        self.cachedGoalWeight = goalWeight
    }

    /// Async version for non-MainActor contexts that need to ensure auth state is loaded
    /// This awaits MainActor to prevent race conditions where callers check currentUser
    /// immediately after calling this method
    private func ensureAuthStateLoadedAsync() async {
        initializeFirebaseServices()
        await MainActor.run {
            if self.currentUser == nil {
                let user = auth.currentUser
                self.currentUser = user
                self.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Network Retry Logic

    /// Retry failed network operations with exponential backoff and total timeout
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - totalTimeout: Maximum total time for all attempts combined (default: 15 seconds)
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    /// - Note: Total timeout prevents UI from appearing frozen during poor network conditions
    private func withRetry<T>(
        maxAttempts: Int = 3,
        totalTimeout: TimeInterval = 15.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let startTime = Date()
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            // STABILITY: Check total timeout before each attempt
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= totalTimeout {
                throw lastError ?? NSError(
                    domain: "NutraSafeRetry",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Operation timed out after \(Int(elapsed)) seconds"]
                )
            }

            do {
                return try await operation()
            } catch {
                lastError = error

                // Check if error is retryable
                if !isRetryableError(error) || attempt == maxAttempts - 1 {
                    throw error
                }

                // Exponential backoff: 1s, 2s, 4s
                let delay = pow(2.0, Double(attempt))

                // Don't sleep past the total timeout
                let remainingTime = totalTimeout - Date().timeIntervalSince(startTime)
                let actualDelay = min(delay, remainingTime)
                if actualDelay > 0 {
                    try await Task.sleep(nanoseconds: UInt64(actualDelay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? NSError(domain: "NutraSafeRetry", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation failed after \(maxAttempts) attempts"])
    }

    /// Determines if an error is retryable (network-related)
    /// - Parameter error: The error to check
    /// - Returns: True if the error is retryable
    private func isRetryableError(_ error: Error) -> Bool {
        // Check for URLError (network errors)
        if let urlError = error as? URLError {
            return [
                .notConnectedToInternet,
                .timedOut,
                .networkConnectionLost,
                .cannotFindHost,
                .cannotConnectToHost,
                .dnsLookupFailed
            ].contains(urlError.code)
        }

        // Check for NSError with network-related domains
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorDNSLookupFailed
            ].contains(nsError.code)
        }

        // Don't retry authentication errors, permission errors, or data validation errors
        if nsError.domain == "FIRFirestoreErrorDomain" {
            // Firestore error codes: 7 = permission denied, 5 = not found, 3 = invalid argument
            let nonRetryableCodes = [3, 5, 7, 16] // Invalid, NotFound, PermissionDenied, Unauthenticated
            return !nonRetryableCodes.contains(nsError.code)
        }

        // Default: don't retry unknown errors
        return false
    }

    // MARK: - Authentication

    /// Sign out the current user and clear all local state atomically
    /// - Throws: Firebase auth errors if sign out fails
    @MainActor
    func signOut() throws {
        // Increment auth generation FIRST to invalidate any in-flight operations immediately
        incrementAuthGeneration()

        // Clear auth state synchronously before signing out
        // This ensures no code can see an inconsistent state
        self.currentUser = nil
        self.isAuthenticated = false

        // Now sign out from Firebase
        try auth.signOut()

        // Clear any residual UserDefaults data to prevent leakage between accounts
        UserDefaults.standard.removeObject(forKey: "userWeight")
        UserDefaults.standard.removeObject(forKey: "goalWeight")
        UserDefaults.standard.removeObject(forKey: "userHeight")
        UserDefaults.standard.removeObject(forKey: "weightHistory")
        UserDefaults.standard.removeObject(forKey: "recentFoods")  // Clear recent foods to prevent data leak between users
        logInfo("Cleared local UserDefaults data on sign out", subsystem: .app, category: .security)

        // Clear ReactionManager data to prevent leakage between accounts
        ReactionManager.shared.clearData()

        // Cancel all Use By notifications to prevent cross-account notification leakage
        UseByNotificationManager.shared.cancelAllNotifications()

        // Clear all caches to prevent data leakage
        cacheQueue.sync {
            self.foodEntriesCache.removeAll()
            self.foodEntriesCacheAccessTime.removeAll()
            self.periodCache.removeAll()
            self.periodCacheAccessTime.removeAll()
            self.inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
            self.inFlightFoodEntriesRequests.removeAll()
            self.inFlightPeriodRequests.values.forEach { $0.cancel() }
            self.inFlightPeriodRequests.removeAll()
        }
        self.searchCache.removeAllObjects()
        self.cachedUserAllergens = []
        self.allergensLastFetched = nil
        self.cachedWeightHistory = []
        self.cachedUserHeight = nil
        self.cachedGoalWeight = nil
    }

    func deleteAllUserData() async throws {
        await ensureAuthStateLoadedAsync()

        // Capture auth state at start to detect mid-operation sign-out
        let startingAuthGeneration = captureAuthState()

        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        // Log data deletion (user ID is automatically redacted in production logs)
        PrivacyLogger.securityEvent("User data deletion initiated", severity: .info)

        // Delete all subcollections
        let collections = [
            "foodEntries",
            "reactions",
            "useByInventory",
            "useByItems",
            "exerciseEntries",
            "pendingVerifications",
            "weightHistory",
            "settings",
            "safeFoods",
            "submittedFoods",
            "customIngredients",
            "verifiedFoods"
        ]

        var totalDeleted = 0
        for collection in collections {
            // Check auth state before each collection deletion
            try checkAuthStateUnchanged(since: startingAuthGeneration)

            let snapshot = try await db.collection("users").document(userId)
                .collection(collection).getDocuments()

            let count = snapshot.documents.count
            logDebug("Deleting \(count) documents from \(collection)", subsystem: .firebase)

            // PERFORMANCE: Use batch operations instead of sequential deletes
            // Firestore batch limit is 500 operations, so chunk if needed
            let documents = snapshot.documents
            let chunkSize = 500

            for chunkStart in stride(from: 0, to: documents.count, by: chunkSize) {
                // Check auth state before each batch
                try checkAuthStateUnchanged(since: startingAuthGeneration)

                let chunkEnd = min(chunkStart + chunkSize, documents.count)
                let chunk = Array(documents[chunkStart..<chunkEnd])

                let batch = db.batch()
                for document in chunk {
                    batch.deleteDocument(document.reference)
                }
                try await batch.commit()
            }

            totalDeleted += count
            logDebug("Successfully deleted \(count) documents from \(collection)", subsystem: .firebase)
        }

        logInfo("All user data deleted successfully - Total: \(totalDeleted) documents", subsystem: .firebase, category: .security)

        // Clear caches and notify observers so the UI refreshes immediately
        // Invalidate internal caches - thread-safe, also cancel in-flight requests
        cacheQueue.sync {
            self.foodEntriesCache.removeAll()
            self.periodCache.removeAll()
            self.inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
            self.inFlightFoodEntriesRequests.removeAll()
            self.inFlightPeriodRequests.values.forEach { $0.cancel() }
            self.inFlightPeriodRequests.removeAll()
        }

        await MainActor.run {
            self.searchCache.removeAllObjects()
            self.cachedUserAllergens = []
            self.allergensLastFetched = nil

            // Broadcast updates to active views
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
            NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
            NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
            NotificationCenter.default.post(name: .goalWeightUpdated, object: nil, userInfo: ["goalWeight": 0])
            NotificationCenter.default.post(name: .userDataCleared, object: nil)

            // Notify SwiftUI observers
            self.objectWillChange.send()
        }
    }

    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String) async throws {
        initializeFirebaseServices()
        let result = try await auth.signIn(withEmail: email, password: password)

        // Reload user to get latest email verification status from Firebase servers
        try await result.user.reload()

        await MainActor.run {
            self.currentUser = auth.currentUser
            self.isAuthenticated = true
        }

        // Pull user data to local offline storage in background
        Task {
            await self.pullUserDataToOfflineStorage()
        }
    }
    
    func signUp(email: String, password: String) async throws {
        initializeFirebaseServices()
        let result = try await auth.createUser(withEmail: email, password: password)

        // Send email verification immediately after signup
        try await result.user.sendEmailVerification()

        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }

        // New user - no data to pull, but initialize offline storage
        // (will start syncing as they add data)
    }

    // Check if current user's email is verified
    var isEmailVerified: Bool {
        return currentUser?.isEmailVerified ?? false
    }

    // Reload user to get latest email verification status
    func reloadUser() async throws {
        try await auth.currentUser?.reload()
        await MainActor.run {
            self.currentUser = auth.currentUser
        }
    }

    // Resend verification email
    func resendVerificationEmail() async throws {
        guard let user = currentUser else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        try await user.sendEmailVerification()
    }

    // MARK: - Apple Sign In

    /// Start Apple Sign In flow and return the hashed nonce for the request
    /// Returns nil if secure nonce generation fails
    func startAppleSignIn() -> String? {
        // Initialize Firebase services to ensure auth listener is set up
        initializeFirebaseServices()

        guard let nonce = randomNonceString() else {
            print("⚠️ [FirebaseManager] Failed to generate secure nonce for Apple Sign In")
            return nil
        }
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Complete Apple Sign In with the authorization result
    func signInWithApple(authorization: ASAuthorization) async throws {
        logDebug("signInWithApple called", subsystem: .auth, category: .authentication)

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            logError("Invalid credential type", subsystem: .auth, category: .authentication)
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])
        }

        guard let nonce = currentNonce else {
            logError("Nonce not set - invalid state", subsystem: .auth, category: .authentication)
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: nonce not set"])
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            logError("Unable to fetch identity token", subsystem: .auth, category: .authentication)
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
        }

        logDebug("Apple credentials validated, initializing Firebase", subsystem: .auth, category: .authentication)

        initializeFirebaseServices()

        // Create Firebase credential with Apple ID token
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        logDebug("Attempting Firebase sign in with Apple credential", subsystem: .auth, category: .authentication)

        // Sign in with Firebase - automatically links if email matches existing account
        let result = try await auth.signIn(with: credential)

        // Use privacy-aware logging for user ID (automatically redacted in production)
        PrivacyLogger.authEvent("Apple Sign In Success", userId: result.user.uid, email: result.user.email)

        // Update display name if provided (Apple only sends name on first sign-in)
        if let fullName = appleIDCredential.fullName,
           let givenName = fullName.givenName {
            let displayName = [givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            if !displayName.isEmpty {
                PrivacyLogger.debugPrivate("Updating display name", privateData: displayName, subsystem: .auth, category: .authentication)
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }
        }

        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
            logInfo("Auth state updated - user authenticated", subsystem: .auth, category: .authentication)
        }

        // Pull user data to local offline storage in background
        Task {
            await self.pullUserDataToOfflineStorage()
        }
    }

    /// Check if current user authenticated via Apple Sign In
    var isAppleUser: Bool {
        currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }

    // Generate random nonce string for Apple Sign In security
    // Returns nil if secure random generation fails (should never happen, but safer than crashing)
    private func randomNonceString(length: Int = 32) -> String? {
        guard length > 0 else { return nil }
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            // Log error but don't crash - let caller handle gracefully
            print("⚠️ [FirebaseManager] SecRandomCopyBytes failed with OSStatus \(errorCode)")
            return nil
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    // SHA256 hash for nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - User Data
    
    func createUserProfile(userId: String, profile: UserProfile) async throws {
        try await db.collection("users").document(userId).setData(profile.toDictionary())
    }
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return nil }
        return UserProfile.fromDictionary(data)
    }

    // MARK: - Offline Data Sync

    /// Pull user data from Firebase to local offline storage
    /// Called after successful sign-in to enable offline-first functionality
    private func pullUserDataToOfflineStorage() async {
        do {
            try await OfflineSyncManager.shared.pullAllData()
            print("[FirebaseManager] Successfully pulled user data to offline storage")
        } catch {
            print("[FirebaseManager] Failed to pull user data to offline storage: \(error.localizedDescription)")
            // Non-fatal error - app will work with Firebase directly until next sync attempt
        }
    }

    // MARK: - Email Marketing Consent

    func updateEmailMarketingConsent(hasConsented: Bool) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"])
        }

        let consentData: [String: Any] = [
            "emailMarketingConsent": hasConsented,
            "emailMarketingConsentDate": hasConsented ? Timestamp(date: Date()) : NSNull(),
            "emailMarketingConsentWithdrawn": !hasConsented,
            "emailMarketingConsentWithdrawnDate": !hasConsented ? Timestamp(date: Date()) : NSNull(),
            "email": currentUser?.email ?? ""
        ]

        try await db.collection("users").document(userId).setData(consentData, merge: true)
    }

    func getEmailMarketingConsent() async throws -> Bool {
        guard let userId = currentUser?.uid else { return false }

        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data() else { return false }

        let isWithdrawn = data["emailMarketingConsentWithdrawn"] as? Bool ?? false
        if isWithdrawn { return false }

        return data["emailMarketingConsent"] as? Bool ?? false
    }

    // MARK: - Food Diary

    /// Error thrown when free user tries to exceed daily diary limit
    enum DiaryLimitError: LocalizedError {
        case dailyLimitReached(current: Int, limit: Int)

        var errorDescription: String? {
            switch self {
            case .dailyLimitReached(let current, let limit):
                return "Daily diary limit reached (\(current)/\(limit)). Upgrade to Pro for unlimited entries."
            }
        }
    }

    func saveFoodEntry(_ entry: FoodEntry, hasProAccess: Bool = false) async throws {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        // Check daily limit for free users BEFORE saving
        // Use local SQLite count to work offline (Firebase check would fail when offline)
        if !hasProAccess {
            let localEntries = OfflineDataManager.shared.getFoodEntries(for: entry.date, userId: userId)
            let currentCount = localEntries.count
            let limit = SubscriptionManager.freeDiaryEntriesPerDay
            if currentCount >= limit {
                throw DiaryLimitError.dailyLimitReached(current: currentCount, limit: limit)
            }
        }

        // Validate food entry before saving to prevent corrupt data
        // Validate entry before saving
        if ValidationConfig.strictMode {
            // Strict mode: throw error if validation fails
            try NutritionValidator.validateFoodEntry(entry)
        } else {
            // Non-strict mode: silently continue if validation fails
            do {
                try NutritionValidator.validateFoodEntry(entry)
            } catch {
                // Validation failed but non-strict mode allows continuing
            }
        }

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFoodEntry(entry)

        // Invalidate cache for this date only (granular invalidation for better performance)
        invalidateFoodEntriesCache(for: entry.date, userId: userId)

        // Note: Period cache NOT cleared here for performance
        // It has a 5-minute expiration and will refresh automatically
        // This prevents unnecessary refetches of 7-day data when adding one food item

        // Notify that food diary was updated
        await MainActor.run {
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        // Write dietary energy to Apple Health when enabled
        let ringsEnabled = UserDefaults.standard.bool(forKey: "healthKitRingsEnabled")
        if ringsEnabled {
            Task {
                // Add timeout to prevent hanging HealthKit operations
                let timeoutTask = Task {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                }

                await HealthKitManager.shared.requestAuthorization()
                do {
                    try await HealthKitManager.shared.writeDietaryEnergyConsumed(calories: entry.calories, date: entry.date)
                    timeoutTask.cancel()
                } catch {
                    // Retry once on HealthKit write failure
                    do {
                        try await Task.sleep(nanoseconds: 300_000_000)
                        try await HealthKitManager.shared.writeDietaryEnergyConsumed(calories: entry.calories, date: entry.date)
                        timeoutTask.cancel()
                    } catch {
                        timeoutTask.cancel()
                        // HealthKit sync failed - non-fatal, food entry is already saved
                        PrivacyLogger.warning(
                            "HealthKit sync failed after retry: \(error.localizedDescription)",
                            subsystem: .healthKit,
                            category: .dataSync
                        )
                    }
                }
            }
        }
    }

    /// Invalidate food entries cache for a specific date
    private func invalidateFoodEntriesCache(for date: Date, userId: String) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        let dateKey = "\(userId)_\(formatter.string(from: startOfDay))"

        // Thread-safe cache invalidation - also cancel any in-flight requests
        cacheQueue.sync {
            foodEntriesCache.removeValue(forKey: dateKey)
            inFlightFoodEntriesRequests.removeValue(forKey: dateKey)?.cancel()
        }
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        let dateKey = "\(userId)_\(formatter.string(from: startOfDay))"

        // OFFLINE-FIRST: Always try local SQLite database first for instant response
        let localEntries = OfflineDataManager.shared.getFoodEntries(for: date, userId: userId)
        if !localEntries.isEmpty {
            // Trigger background sync to pull latest from server
            OfflineSyncManager.shared.triggerSync()
            return localEntries
        }

        // Return cached entries if still valid (with async-safe synchronization)
        let cachedEntry = cacheQueue.sync { foodEntriesCache[dateKey] }

        if let cached = cachedEntry,
           Date().timeIntervalSince(cached.timestamp) < foodEntriesCacheExpirationSeconds {
            // PERFORMANCE: Update access time for LRU tracking - O(1) operation
            cacheQueue.sync { foodEntriesCacheAccessTime[dateKey] = Date() }
            return cached.entries
        }

        // RACE CONDITION FIX: Check for existing task first
        let existingTask = cacheQueue.sync { inFlightFoodEntriesRequests[dateKey] }
        if let task = existingTask {
            return try await task.value
        }

        // Create new fetch task - we'll register it atomically below
        let fetchTask = Task<[FoodEntry], Error> {
            // CRITICAL: Check for cancellation before starting work (prevents race condition)
            try Task.checkCancellation()

            // Query using local day boundaries (Firebase stores UTC timestamps but we query by local day)
            let queryStart = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: queryStart)?.addingTimeInterval(-0.001) else {
                throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
            }
            let queryEnd = endOfDay

            // Use defer to ensure in-flight request is always cleaned up, even on error/cancellation
            defer {
                _ = self.cacheQueue.sync {
                    self.inFlightFoodEntriesRequests.removeValue(forKey: dateKey)
                }
            }

            let snapshot = try await withRetry {
                // Check cancellation before each retry attempt
                try Task.checkCancellation()
                return try await self.db.collection("users").document(userId)
                    .collection("foodEntries")
                    .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: queryStart))
                    .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: queryEnd))
                    .getDocuments()
            }

            // CRITICAL: Check cancellation after network call - cache may have been invalidated
            try Task.checkCancellation()

            let entries = snapshot.documents.compactMap { doc -> FoodEntry? in
                // Use Firestore's native Codable decoder for safe, crash-proof parsing
                do {
                    return try doc.data(as: FoodEntry.self)
                } catch {
                    // Log parsing failure for debugging - helps identify corrupt entries
                    PrivacyLogger.warning(
                        "Failed to parse FoodEntry (doc: \(doc.documentID)): \(error.localizedDescription)",
                        subsystem: .firebase,
                        category: .dataSync
                    )
                    return nil
                }
            }

            // CRITICAL: Final cancellation check before writing to cache
            // This prevents a cancelled task from overwriting fresh data
            try Task.checkCancellation()

            // Store in cache (in-flight cleanup handled by defer above)
            self.cacheQueue.sync {
                self.foodEntriesCache[dateKey] = FoodEntriesCacheEntry(entries: entries, timestamp: Date())
                self.foodEntriesCacheAccessTime[dateKey] = Date() // O(1) LRU tracking

                // PERFORMANCE: Evict LRU entries - O(n) find min instead of O(n log n) sort
                while self.foodEntriesCache.count > self.maxFoodEntriesCacheSize {
                    // Find least recently accessed entry
                    if let oldestKey = self.foodEntriesCacheAccessTime.min(by: { $0.value < $1.value })?.key {
                        self.foodEntriesCache.removeValue(forKey: oldestKey)
                        self.foodEntriesCacheAccessTime.removeValue(forKey: oldestKey)
                    } else {
                        break
                    }
                }
            }

            // Import fetched entries to local SQLite for offline access
            for entry in entries {
                OfflineDataManager.shared.saveFoodEntry(entry)
            }

            return entries
        }

        // RACE CONDITION FIX: Atomically register the in-flight request, but check again
        // in case another request snuck in while we were creating the task
        let taskToAwait: Task<[FoodEntry], Error> = cacheQueue.sync {
            // Double-check: if another request registered while we were creating fetchTask, use that one
            if let existing = inFlightFoodEntriesRequests[dateKey] {
                // Cancel our task since we'll use the existing one
                fetchTask.cancel()
                return existing
            }
            // Register our task
            inFlightFoodEntriesRequests[dateKey] = fetchTask
            return fetchTask
        }

        return try await taskToAwait.value
    }

    /// Count food entries for a specific date (used for free tier limit checking)
    /// Note: Bypasses cache to get accurate count for limit enforcement
    /// Count food entries for a specific date (used for free tier limit checking)
    /// Uses cached data when available to prevent excessive network requests
    /// The cache is automatically invalidated when entries are added/deleted
    func countFoodEntries(for date: Date) async throws -> Int {
        // Use cached entries - the cache is already invalidated in saveFoodEntry/deleteFoodEntry
        // This prevents N network requests when user taps "Add" multiple times quickly
        let entries = try await getFoodEntries(for: date)
        return entries.count
    }

    /// Force a fresh count by bypassing cache (use sparingly - only when cache might be stale)
    func countFoodEntriesFresh(for date: Date) async throws -> Int {
        if let userId = currentUser?.uid {
            invalidateFoodEntriesCache(for: date, userId: userId)
        }
        let entries = try await getFoodEntries(for: date)
        return entries.count
    }

    /// Check if user can add more diary entries for today (free tier limit)
    func canAddDiaryEntry(for date: Date, hasAccess: Bool) async throws -> Bool {
        if hasAccess { return true }
        let count = try await countFoodEntries(for: date)
        return count < SubscriptionManager.freeDiaryEntriesPerDay
    }

    // MARK: - Period Cache (for Micronutrient Dashboard)
    // Key format: "userId_days" to prevent data leakage between users
    private var periodCache: [String: (entries: [FoodEntry], timestamp: Date)] = [:]
    // PERFORMANCE: Separate LRU tracking for O(1) access time updates
    private var periodCacheAccessTime: [String: Date] = [:]
    private let periodCacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    private let maxPeriodCacheSize: Int = 50 // Maximum number of cached periods

    // In-flight request tracking for period queries
    // Key format: "userId_days" to prevent data leakage between users
    private var inFlightPeriodRequests: [String: Task<[FoodEntry], Error>] = [:]

    // Get food entries for the past N days for nutritional analysis
    func getFoodEntriesForPeriod(days: Int) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        // Capture auth state at start for mid-operation validation
        let authGen = captureAuthState()

        // Cache key includes userId to prevent data leakage between users
        let cacheKey = "\(userId)_\(days)"

        // Check cache first (async-safe synchronization)
        let cachedPeriod = cacheQueue.sync { periodCache[cacheKey] }

        if let cached = cachedPeriod,
           Date().timeIntervalSince(cached.timestamp) < periodCacheExpirationSeconds {
            // PERFORMANCE: Update access time for LRU tracking - O(1) operation
            cacheQueue.sync { periodCacheAccessTime[cacheKey] = Date() }
            return cached.entries
        }

        // Check for in-flight request to prevent duplicate fetches
        let existingTask = cacheQueue.sync { inFlightPeriodRequests[cacheKey] }
        if let task = existingTask {
            return try await task.value
        }

        // Create new fetch task
        let fetchTask = Task<[FoodEntry], Error> {
            // CRITICAL: Check for cancellation before starting work (prevents race condition)
            try Task.checkCancellation()

            let calendar = Calendar.current
            let today = Date()
            let startOfToday = calendar.startOfDay(for: today)
            guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)?.addingTimeInterval(-0.001) else {
                throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day for period query"])
            }
            let endDate = endOfToday
            guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
                throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate start date for period query"])
            }
            let queryStart = calendar.startOfDay(for: startDate)

            // PERFORMANCE: Dynamic limit based on period - prevents fetching excessive documents
            // ~20 entries/day is generous: 7 days = 150, 30 days = 300, 90 days = 500
            let entryLimit = min(500, max(150, days * 20))

            // Use defer to ensure in-flight request is always cleaned up, even on error/cancellation
            defer {
                _ = self.cacheQueue.sync {
                    self.inFlightPeriodRequests.removeValue(forKey: cacheKey)
                }
            }

            let snapshot = try await withRetry {
                // Check cancellation before each retry attempt
                try Task.checkCancellation()
                return try await self.db.collection("users").document(userId)
                    .collection("foodEntries")
                    .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: queryStart))
                    .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
                    .order(by: "date", descending: true)
                    .limit(to: entryLimit)
                    .getDocuments()
            }

            // CRITICAL: Check cancellation after network call - cache may have been invalidated
            try Task.checkCancellation()

            // CRITICAL: Check auth state hasn't changed during network call
            try self.checkAuthStateUnchanged(since: authGen)

            let entries = snapshot.documents.compactMap { doc -> FoodEntry? in
                // Use Firestore's native Codable decoder for safe, crash-proof parsing
                do {
                    return try doc.data(as: FoodEntry.self)
                } catch {
                    // Log parsing failure for debugging - helps identify corrupt entries
                    PrivacyLogger.warning(
                        "Failed to parse FoodEntry in period query (doc: \(doc.documentID)): \(error.localizedDescription)",
                        subsystem: .firebase,
                        category: .dataSync
                    )
                    return nil
                }
            }

            // CRITICAL: Final cancellation check before writing to cache
            // This prevents a cancelled task from overwriting fresh data
            try Task.checkCancellation()

            // Store in cache (in-flight cleanup handled by defer above)
            self.cacheQueue.sync {
                self.periodCache[cacheKey] = (entries, Date())
                self.periodCacheAccessTime[cacheKey] = Date() // O(1) LRU tracking

                // PERFORMANCE: Evict LRU entries - O(n) find min instead of O(n log n) sort
                while self.periodCache.count > self.maxPeriodCacheSize {
                    // Find least recently accessed entry
                    if let oldestKey = self.periodCacheAccessTime.min(by: { $0.value < $1.value })?.key {
                        self.periodCache.removeValue(forKey: oldestKey)
                        self.periodCacheAccessTime.removeValue(forKey: oldestKey)
                    } else {
                        break
                    }
                }
            }

            return entries
        }

        // RACE CONDITION FIX: Atomically register the in-flight request, but check again
        // in case another request snuck in while we were creating the task
        let taskToAwait: Task<[FoodEntry], Error> = cacheQueue.sync {
            // Double-check: if another request registered while we were creating fetchTask, use that one
            if let existing = inFlightPeriodRequests[cacheKey] {
                // Cancel our task since we'll use the existing one
                fetchTask.cancel()
                return existing
            }
            // Register our task
            inFlightPeriodRequests[cacheKey] = fetchTask
            return fetchTask
        }

        return try await taskToAwait.value
    }

    // Get food entries for a period using fromDictionary for proper additives decoding
    func getFoodEntriesWithAdditivesForPeriod(days: Int) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)?.addingTimeInterval(-0.001) else {
            throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate end of day for additives period query"])
        }
        // For "days" period, we want today + (days-1) previous days
        // e.g., Week (7 days) = today + 6 previous days
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: startOfToday) else {
            throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate start date for additives period query"])
        }
        let queryStart = startDate  // Already at start of day

        // PERFORMANCE: Dynamic limit based on period - prevents fetching excessive documents
        let entryLimit = min(500, max(150, days * 20))

        let snapshot = try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("foodEntries")
                .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: queryStart))
                .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endOfToday))
                .order(by: "date", descending: true)
                .limit(to: entryLimit)
                .getDocuments()
        }

        // Use fromDictionary for proper additives decoding
        return snapshot.documents.compactMap { doc -> FoodEntry? in
            var data = doc.data()
            // Ensure id is set from document ID if not present
            if data["id"] == nil {
                data["id"] = doc.documentID
            }
            let entry = FoodEntry.fromDictionary(data)
            if entry == nil {
                // Log parsing failure for debugging - helps identify corrupt entries
                PrivacyLogger.warning(
                    "Failed to parse FoodEntry with additives (doc: \(doc.documentID))",
                    subsystem: .firebase,
                    category: .dataSync
                )
            }
            return entry
        }
    }

    // Get food entries within a specific date range (used by ReactionLogManager)
    // NOTE: Caller is responsible for passing correct date boundaries
    func getFoodEntriesInRange(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        // Query Firebase with the provided date range with retry logic
        // ReactionLogManager uses this for time-based reaction analysis
        let snapshot = try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("foodEntries")
                .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startDate))
                .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
                .order(by: "date", descending: false)
                .getDocuments()
        }

        return snapshot.documents.compactMap { doc -> FoodEntry? in
            // Use Firestore's native Codable decoder for safe, crash-proof parsing
            do {
                return try doc.data(as: FoodEntry.self)
            } catch {
                // Log parsing failure for debugging - helps identify corrupt entries
                PrivacyLogger.warning(
                    "Failed to parse FoodEntry in range query (doc: \(doc.documentID)): \(error.localizedDescription)",
                    subsystem: .firebase,
                    category: .dataSync
                )
                return nil
            }
        }
    }

    // Delete all food entries older than today (for clearing test data)
    /// Delete all food entries older than today (for clearing test data)
    /// Uses batch operations for efficiency (max 500 per batch)
    func deleteOldFoodEntries() async throws {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Query for all entries before today (in local timezone)
        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: startOfToday))
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        // PERFORMANCE: Use batch operations instead of sequential deletes
        // Firestore batch limit is 500 operations, so chunk if needed
        let documents = snapshot.documents
        let chunkSize = 500

        for chunkStart in stride(from: 0, to: documents.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, documents.count)
            let chunk = Array(documents[chunkStart..<chunkEnd])

            let batch = db.batch()
            for document in chunk {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
        }

        // Clear caches since we deleted potentially many entries
        cacheQueue.sync {
            foodEntriesCache.removeAll()
            foodEntriesCacheAccessTime.removeAll()
            periodCache.removeAll()
            periodCacheAccessTime.removeAll()
            inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
            inFlightFoodEntriesRequests.removeAll()
            inFlightPeriodRequests.values.forEach { $0.cancel() }
            inFlightPeriodRequests.removeAll()
        }

        // Notify UI
        await MainActor.run {
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }
    }

    /// Delete a food entry by ID
    /// - Parameters:
    ///   - entryId: The ID of the entry to delete
    ///   - date: Optional date of the entry - if provided, only invalidates cache for that date (more efficient)
    func deleteFoodEntry(entryId: String, date: Date? = nil) async throws {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteFoodEntry(entryId: entryId)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()

        // PERFORMANCE: Granular cache invalidation when date is known
        if let date = date {
            invalidateFoodEntriesCache(for: date, userId: userId)
            // Also need to invalidate period cache since aggregated data changed
            cacheQueue.sync {
                periodCache.removeAll()
                periodCacheAccessTime.removeAll()
                inFlightPeriodRequests.values.forEach { $0.cancel() }
                inFlightPeriodRequests.removeAll()
            }
        } else {
            // Fallback: Clear entire cache since we don't know which date this entry belongs to
            cacheQueue.sync {
                foodEntriesCache.removeAll()
                foodEntriesCacheAccessTime.removeAll()
                periodCache.removeAll()
                periodCacheAccessTime.removeAll()
                inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
                inFlightFoodEntriesRequests.removeAll()
                inFlightPeriodRequests.values.forEach { $0.cancel() }
                inFlightPeriodRequests.removeAll()
            }
        }

        // Notify that food diary was updated
        await MainActor.run {
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }
    }

    /// Delete multiple food entries atomically using Firestore batch writes
    /// More efficient than deleting one at a time for bulk operations
    /// - Parameters:
    ///   - entryIds: Array of entry IDs to delete
    ///   - dates: Optional set of dates for these entries - if provided, only invalidates cache for those dates (more efficient)
    func deleteFoodEntries(entryIds: [String], dates: Set<Date>? = nil) async throws {
        guard let userId = currentUser?.uid else {
            throw AuthStateError.notAuthenticated
        }
        guard !entryIds.isEmpty else { return }

        // Firestore batches support up to 500 operations
        let batches = stride(from: 0, to: entryIds.count, by: 500).map {
            Array(entryIds[$0..<min($0 + 500, entryIds.count)])
        }

        for batchIds in batches {
            let batch = db.batch()
            for entryId in batchIds {
                let docRef = db.collection("users").document(userId)
                    .collection("foodEntries").document(entryId)
                batch.deleteDocument(docRef)
            }
            try await batch.commit()
        }

        // PERFORMANCE: Granular cache invalidation when dates are known
        if let dates = dates, !dates.isEmpty {
            for date in dates {
                invalidateFoodEntriesCache(for: date, userId: userId)
            }
            // Period cache still needs full clear since aggregated data changed
            cacheQueue.sync {
                periodCache.removeAll()
                periodCacheAccessTime.removeAll()
                inFlightPeriodRequests.values.forEach { $0.cancel() }
                inFlightPeriodRequests.removeAll()
            }
        } else {
            // Fallback: Clear all caches
            cacheQueue.sync {
                foodEntriesCache.removeAll()
                foodEntriesCacheAccessTime.removeAll()
                periodCache.removeAll()
                periodCacheAccessTime.removeAll()
                inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
                inFlightFoodEntriesRequests.removeAll()
                inFlightPeriodRequests.values.forEach { $0.cancel() }
                inFlightPeriodRequests.removeAll()
            }
        }

        // Notify that food diary was updated
        await MainActor.run {
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }
    }

    /// Scan all food entries and delete corrupt ones that can't be decoded
    /// Returns the count of deleted corrupt entries
    func cleanupCorruptFoodEntries() async throws -> Int {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to cleanup entries"])
        }

                let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .getDocuments()

                var corruptEntries: [String] = []

        // Test each entry to see if it can be decoded
        for doc in snapshot.documents {
            do {
                _ = try doc.data(as: FoodEntry.self)
                // Successfully decoded - this entry is fine
            } catch {
                // Failed to decode - this entry is corrupt
                                corruptEntries.append(doc.documentID)
            }
        }

        if corruptEntries.isEmpty {
            return 0
        }

        for docId in corruptEntries {
            try await db.collection("users").document(userId)
                .collection("foodEntries").document(docId).delete()
        }

        // Clear caches and notify UI - thread-safe, also cancel in-flight requests
        cacheQueue.sync {
            foodEntriesCache.removeAll()
            periodCache.removeAll()
            inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
            inFlightFoodEntriesRequests.removeAll()
            inFlightPeriodRequests.values.forEach { $0.cancel() }
            inFlightPeriodRequests.removeAll()
        }
        await MainActor.run {
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }

        return corruptEntries.count
    }
    
    // MARK: - Food Reactions

    func saveReaction(_ reaction: FoodReaction) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save reactions"])
        }

        let reactionData = reaction.toDictionary()
        try await db.collection("users").document(userId)
            .collection("reactions").document(reaction.id.uuidString).setData(reactionData)
    }

    // MARK: - Reaction Log

    /// Get all reaction logs for a user
    func getReactionLogs(userId: String) async throws -> [ReactionLogEntry] {
        // OFFLINE-FIRST: Try local SQLite database first for instant response
        let localLogs = OfflineDataManager.shared.getReactionLogs()
        if !localLogs.isEmpty {
            // Trigger background sync to get latest from server
            OfflineSyncManager.shared.triggerSync()
            return localLogs
        }

        // If local is empty, fetch from Firebase (first launch or empty local)
        let snapshot = try await db.collection("users").document(userId)
            .collection("reactionLogs")
            .order(by: "reactionDate", descending: true)
            .getDocuments()

        let logs = try snapshot.documents.compactMap { doc in
            try doc.data(as: ReactionLogEntry.self)
        }

        // Import to local database for offline access
        for log in logs {
            OfflineDataManager.shared.saveReactionLog(log)
        }

        return logs
    }

    /// Save a new reaction log entry
    func saveReactionLog(_ entry: ReactionLogEntry) async throws -> ReactionLogEntry {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save reaction logs"])
        }

        // Generate an ID if not present
        var entryWithId = entry
        if entryWithId.id == nil {
            entryWithId.id = UUID().uuidString
        }

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveReactionLog(entryWithId)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        return entryWithId
    }

    /// Delete a reaction log entry
    func deleteReactionLog(entryId: String) async throws {
        guard currentUser?.uid != nil else {
            throw AuthStateError.notAuthenticated
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteReactionLog(id: entryId)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    /// Get food entries within a date range (for reaction analysis)
    func getFoodEntriesInRange(userId: String, startDate: Date, endDate: Date) async throws -> [FoodEntry] {
        let snapshot = try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("foodEntries")
                .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startDate))
                .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
                .order(by: "date", descending: false)
                .getDocuments()
        }

        let entries = snapshot.documents.compactMap { doc -> FoodEntry? in
            do {
                return try doc.data(as: FoodEntry.self)
            } catch {
                // Log parsing failure for debugging - helps identify corrupt entries
                PrivacyLogger.warning(
                    "Failed to parse FoodEntry for reaction analysis (doc: \(doc.documentID)): \(error.localizedDescription)",
                    subsystem: .firebase,
                    category: .dataSync
                )
                return nil
            }
        }

        return entries
    }

    // MARK: - Use By Inventory

    func addUseByItem(_ item: UseByInventoryItem) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add use by items"])
        }

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveUseByItem(item)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    // NOTE: Legacy UserDefaults storage for Use By items has been removed.
    // All Use By items are now stored in SQLite via OfflineDataManager for offline-first support.

    private func addUseByItemHelper(_ item: UseByInventoryItem, userId: String) async throws {
        var dict: [String: Any] = [
            "id": item.id,
            "name": item.name,
            "quantity": item.quantity,
            "expiryDate": Timestamp(date: item.expiryDate),
            "addedDate": Timestamp(date: item.addedDate)
        ]
        if let brand = item.brand { dict["brand"] = brand }
        if let barcode = item.barcode { dict["barcode"] = barcode }
        if let category = item.category { dict["category"] = category }
        if let imageURL = item.imageURL { dict["imageURL"] = imageURL }
        if let notes = item.notes { dict["notes"] = notes }

        try await db.collection("users").document(userId)
            .collection("useByInventory").document(item.id).setData(dict)
    }

    func getUseByItems() async throws -> [UseByInventoryItem] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view use by items"])
        }

        // OFFLINE-FIRST: Try local SQLite database first for instant response
        let localItems = OfflineDataManager.shared.getUseByItems()
        if !localItems.isEmpty {
            // Trigger background sync to get latest from server
            OfflineSyncManager.shared.triggerSync()
            return localItems
        }

        // If local is empty, fetch from Firebase (first launch or empty local)
        return try await getUseByItemsHelper(userId: userId)
    }

    private func getUseByItemsHelper(userId: String) async throws -> [UseByInventoryItem] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("useByInventory")
            .order(by: "expiryDate", descending: false)
            .getDocuments()

        // Use Firestore's direct Codable support (handles FIRTimestamp properly)
        let items = snapshot.documents.compactMap { doc in
            try? doc.data(as: UseByInventoryItem.self)
        }

        // Import to local database for offline access
        for item in items {
            OfflineDataManager.shared.saveUseByItem(item)
        }

        return items
    }

    func updateUseByItem(_ item: UseByInventoryItem) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update use by items"])
        }

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveUseByItem(item)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    func deleteUseByItem(itemId: String) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete use by items"])
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteUseByItem(itemId: itemId)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    func clearUseByInventory() async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to clear use by inventory"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("useByInventory").getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }

    // MARK: - Food Search Functions

    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        let cacheKeyString = query.lowercased().trimmingCharacters(in: .whitespaces)
        let cacheKey = cacheKeyString as NSString

        // Thread-safe cache check with atomic read-check-modify
        let cachedResult: [FoodSearchResult]? = searchCacheQueue.sync {
            if let cached = searchCache.object(forKey: cacheKey) {
                let age = Date().timeIntervalSince(cached.timestamp)
                if age < cacheExpirationSeconds {
                    // Check if cached results have ingredients - if not, invalidate and fetch fresh
                    let hasIngredients = cached.results.first?.ingredients?.isEmpty == false
                    if hasIngredients {
                        return cached.results
                    } else {
                        // Cache is stale (missing ingredients from Algolia) - force refresh
                        searchCache.removeObject(forKey: cacheKey)
                    }
                } else {
                    // Cache expired, remove it
                    searchCache.removeObject(forKey: cacheKey)
                }
            }
            return nil
        }

        if let results = cachedResult {
            return results
        }

        // Check for in-flight request to prevent duplicate fetches
        let existingTask: Task<[FoodSearchResult], Error>? = searchCacheQueue.sync {
            inFlightSearchRequests[cacheKeyString]
        }
        if let task = existingTask {
            return try await task.value
        }

        // Create new fetch task
        let fetchTask = Task<[FoodSearchResult], Error> {
            // Use defer to ensure in-flight request is always cleaned up, even on error/cancellation
            defer {
                _ = self.searchCacheQueue.sync {
                    self.inFlightSearchRequests.removeValue(forKey: cacheKeyString)
                }
            }

            // Use Algolia for all searches - it already searches all indices (user-added, AI-enhanced, AI-manual, foods)
            // This is MUCH faster than making 4 separate Firestore queries
            let results = try await AlgoliaSearchManager.shared.search(query: query, hitsPerPage: 100)

            // Store in cache for next time (NSCache auto-manages memory)
            self.searchCacheQueue.sync {
                self.searchCache.setObject(
                    SearchCacheEntry(results: results, timestamp: Date()),
                    forKey: cacheKey
                )
            }

            return results
        }

        // Atomically register the in-flight request
        let taskToAwait: Task<[FoodSearchResult], Error> = searchCacheQueue.sync {
            // Double-check: if another request registered while we were creating fetchTask, use that one
            if let existing = inFlightSearchRequests[cacheKeyString] {
                fetchTask.cancel()
                return existing
            }
            inFlightSearchRequests[cacheKeyString] = fetchTask
            return fetchTask
        }

        return try await taskToAwait.value
    }

    /// Search main food database via Direct Algolia SDK (instant search)
    /// Previously used Cloud Function which added 100-500ms latency
    private func searchMainDatabase(query: String) async throws -> [FoodSearchResult] {
        // Use direct Algolia SDK for instant results (~300ms faster than Cloud Function)
        // Request 100 results for better scrolling experience (was 20 default)
        return try await AlgoliaSearchManager.shared.search(query: query, hitsPerPage: 100)
    }

    /// Clear the search cache (useful for testing or memory management)
    func clearSearchCache() {
        searchCacheQueue.sync {
            searchCache.removeAllObjects()
            inFlightSearchRequests.values.forEach { $0.cancel() }
            inFlightSearchRequests.removeAll()
        }
        AlgoliaSearchManager.shared.clearCache()
    }

    /// Pre-warm cache with popular searches for instant results
    func prewarmSearchCache() async {
        let popularSearches = ["chicken", "milk", "bread", "cheese", "apple", "banana"]
        
        for search in popularSearches {
            do {
                _ = try await searchFoods(query: search)
            } catch {
                            }
        }
            }

    func searchFoodsByBarcode(barcode: String) async throws -> [FoodSearchResult] {
        // Use the parameter to avoid unused warning, or just ignore it
        _ = barcode
        
        // SQLite database has been deprecated and removed.
        // TODO: Implement Cloud/API barcode lookup if needed.
        return []
    }

    func getReactions() async throws -> [FoodReaction] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
                        throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view reactions"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("reactions")
            .order(by: "date", descending: true)
            .getDocuments()


        let reactions = snapshot.documents.compactMap { doc -> FoodReaction? in
            let data = doc.data()
            if let reaction = FoodReaction.fromDictionary(data) {
                return reaction
            } else {
                                return nil
            }
        }
                return reactions
    }

    func deleteReaction(reactionId: UUID) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
                        throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete reactions"])
        }

        try await db.collection("users").document(userId)
            .collection("reactions").document(reactionId.uuidString).delete()
            }
    
    // MARK: - Safe Foods
    
    func saveSafeFood(_ food: SafeFood) async throws {
        guard let userId = currentUser?.uid else { return }
        let foodData = food.toDictionary()
        try await db.collection("users").document(userId)
            .collection("safeFoods").document(food.id.uuidString).setData(foodData)
    }
    
    
    // MARK: - Use By Items

    func saveUseByItem(_ item: UseByItem) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save items"])
        }
        let itemData = item.toDictionary()
        try await withRetry(maxAttempts: 3, totalTimeout: 10.0) {
            try await self.db.collection("users").document(userId)
                .collection("useByItems").document(item.id.uuidString).setData(itemData)
        }
    }

    /// Get legacy UseByItem records (distinct from UseByInventoryItem)
    /// Note: This uses the "useByItems" collection, while getUseByItems() uses "useByInventory"
    func getLegacyUseByItems() async throws -> [UseByItem] {
        guard let userId = currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(userId)
            .collection("useByItems")
            .order(by: "expiryDate")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            UseByItem.fromDictionary(doc.data())
        }
    }

    // MARK: - Pending Food Verifications
    
    func savePendingVerification(_ verification: PendingFoodVerification) async throws {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to submit verifications"])
        }
        let verificationData = [
            "id": verification.id,
            "foodName": verification.foodName,
            "brandName": verification.brandName ?? "",
            "ingredients": verification.ingredients ?? "",
            "submittedAt": FirebaseFirestore.Timestamp(date: verification.submittedAt),
            "status": verification.status.rawValue,
            "userId": verification.userId
        ] as [String: Any]

        try await withRetry(maxAttempts: 3, totalTimeout: 10.0) {
            try await self.db.collection("users").document(userId)
                .collection("pendingVerifications").document(verification.id).setData(verificationData)
        }
    }
    
    func getPendingVerifications() async throws -> [PendingFoodVerification] {
        guard let userId = currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(userId)
            .collection("pendingVerifications")
            .order(by: "submittedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let foodName = data["foodName"] as? String,
                  let statusString = data["status"] as? String,
                  let status = PendingFoodVerification.VerificationStatus(rawValue: statusString),
                  let submittedAtTs = data["submittedAt"] as? FirebaseFirestore.Timestamp,
                  let userId = data["userId"] as? String else { return nil }
            
            return PendingFoodVerification(
                id: id,
                foodName: foodName,
                brandName: data["brandName"] as? String,
                ingredients: data["ingredients"] as? String,
                submittedAt: submittedAtTs.dateValue(),
                status: status,
                userId: userId
            )
        }
    }
    
    func updateVerificationStatus(verificationId: String, status: PendingFoodVerification.VerificationStatus) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId)
            .collection("pendingVerifications").document(verificationId)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Weight Tracking

    // Resize and compress image for faster uploads (runs on background thread)
    private func optimizeImage(_ image: UIImage) async -> Data? {
        return await Task.detached {
            let maxDimension: CGFloat = 1200
            var newSize = image.size

            // Resize if too large
            if image.size.width > maxDimension || image.size.height > maxDimension {
                let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
                newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
            }

            // Use UIGraphicsImageRenderer for thread-safe image processing
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = false

            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            let resizedImage = renderer.image { context in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }

            // Compress to JPEG at 50% quality for smaller file size
            return resizedImage.jpegData(compressionQuality: 0.5)
        }.value
    }

    // Upload multiple photos in parallel for better performance
    func uploadWeightPhotos(_ images: [UIImage]) async throws -> [String] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to upload photos"])
        }

        return try await withThrowingTaskGroup(of: String.self) { group in
            for image in images {
                group.addTask {
                    // Optimize image (must run on main actor for UIGraphics)
                    guard let imageData = await self.optimizeImage(image) else {
                        throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
                    }

                    // Create unique filename
                    let filename = "\(UUID().uuidString).jpg"
                    let storageRef = Storage.storage().reference()
                    let photoRef = storageRef.child("weightPhotos/\(userId)/\(filename)")

                    // Upload image with retry logic
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"

                    _ = try await self.withRetry {
                        try await photoRef.putDataAsync(imageData, metadata: metadata)
                    }

                    // Get download URL with retry logic
                    let downloadURL = try await self.withRetry {
                        try await photoRef.downloadURL()
                    }

                                        return downloadURL.absoluteString
                }
            }

            var urls: [String] = []
            for try await url in group {
                urls.append(url)
            }
            return urls
        }
    }

    // Legacy single photo upload (using optimized version)
    func uploadWeightPhoto(_ image: UIImage) async throws -> String {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to upload photos"])
        }

        // Optimize image (must run on main actor for UIGraphics)
        guard let imageData = await optimizeImage(image) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
        let photoRef = storageRef.child("weightPhotos/\(userId)/\(filename)")

        // Upload image with retry logic
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await withRetry {
            try await photoRef.putDataAsync(imageData, metadata: metadata)
        }

        // Get download URL with retry logic
        let downloadURL = try await withRetry {
            try await photoRef.downloadURL()
        }

                return downloadURL.absoluteString
    }

    func downloadWeightPhoto(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid photo URL"])
        }

        // Download image data from URL with retry logic
        let (data, _) = try await withRetry {
            try await URLSession.shared.data(from: url)
        }

        guard let image = UIImage(data: data) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
        }

                return image
    }

    // MARK: - Use By Item Photo Upload
    func uploadUseByItemPhoto(_ image: UIImage) async throws -> String {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to upload photos"])
        }

        // Optimize image (must run on main actor for UIGraphics)
        guard let imageData = await optimizeImage(image) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
        let photoRef = storageRef.child("useByItemPhotos/\(userId)/\(filename)")

        // Upload image with retry logic
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await withRetry {
            try await photoRef.putDataAsync(imageData, metadata: metadata)
        }

        // Get download URL with retry logic
        let downloadURL = try await withRetry {
            try await photoRef.downloadURL()
        }

                return downloadURL.absoluteString
    }

    func saveWeightEntry(_ entry: WeightEntry) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save weight entries"])
        }

        // Validate weight entry before saving
        try NutritionValidator.validateWeightEntry(weight: entry.weight, date: entry.date)

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveWeightEntry(entry)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        // Update cached weight history immediately after successful save
        // This ensures the cache is always in sync and prevents stale data issues
        await MainActor.run {
            // Check if entry already exists (editing existing entry)
            if let existingIndex = self.cachedWeightHistory.firstIndex(where: { $0.id == entry.id }) {
                self.cachedWeightHistory[existingIndex] = entry
            } else {
                // Insert new entry at beginning (most recent first)
                self.cachedWeightHistory.insert(entry, at: 0)
            }
            // Re-sort by date to maintain correct order
            self.cachedWeightHistory.sort { $0.date > $1.date }

            NotificationCenter.default.post(name: .weightHistoryUpdated, object: nil, userInfo: ["entry": entry])
        }
    }

    func getWeightHistory() async throws -> [WeightEntry] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view weight history"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("weightHistory")
            .order(by: "date", descending: true)
            .getDocuments()

        let entries = snapshot.documents.compactMap { doc -> WeightEntry? in
            let data = doc.data()
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let weight = data["weight"] as? Double,
                  let timestamp = data["date"] as? FirebaseFirestore.Timestamp else {
                return nil
            }

            let bmi = data["bmi"] as? Double
            let note = data["note"] as? String
            let photoURL = data["photoURL"] as? String
            let photoURLs = data["photoURLs"] as? [String]
            let waistSize = data["waistSize"] as? Double
            let dressSize = data["dressSize"] as? String

            return WeightEntry(id: id, weight: weight, date: timestamp.dateValue(), bmi: bmi, note: note, photoURL: photoURL, photoURLs: photoURLs, waistSize: waistSize, dressSize: dressSize)
        }

                return entries
    }

    func deleteWeightEntry(id: UUID) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete weight entries"])
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteWeightEntry(id: id)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()

        // Update cached weight history after successful delete
        await MainActor.run {
            self.cachedWeightHistory.removeAll { $0.id == id }
        }
    }

    // MARK: - Favorite Foods

    /// Saves a food to user's favorites
    func saveFavoriteFood(_ food: FoodSearchResult) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save favorites"])
        }

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFavoriteFood(food)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    /// Removes a food from user's favorites
    /// Uses offline-first pattern for network resilience
    func removeFavoriteFood(foodId: String) async throws {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to remove favorites"])
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteFavoriteFood(id: foodId)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    /// Gets user's favorite foods
    func getFavoriteFoods() async throws -> [FoodSearchResult] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view favorites"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("favoriteFoods")
            .order(by: "addedAt", descending: true)
            .limit(to: 20)  // Limit to recent 20 favorites
            .getDocuments()

        let favorites = snapshot.documents.compactMap { doc -> FoodSearchResult? in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let calories = data["calories"] as? Double,
                  let protein = data["protein"] as? Double,
                  let carbs = data["carbs"] as? Double,
                  let fat = data["fat"] as? Double else {
                return nil
            }

            // Decode additives from JSON array
            var additives: [NutritionAdditiveInfo]?
            if let additivesArray = data["additives"] as? [[String: Any]] {
                let decoder = JSONDecoder()
                if let additivesData = try? JSONSerialization.data(withJSONObject: additivesArray),
                   let decoded = try? decoder.decode([NutritionAdditiveInfo].self, from: additivesData) {
                    additives = decoded
                }
            }

            // Decode micronutrientProfile from JSON
            var micronutrientProfile: MicronutrientProfile?
            if let microDict = data["micronutrientProfile"] as? [String: Any] {
                let decoder = JSONDecoder()
                if let microData = try? JSONSerialization.data(withJSONObject: microDict),
                   let decoded = try? decoder.decode(MicronutrientProfile.self, from: microData) {
                    micronutrientProfile = decoded
                }
            }

            // Decode portions from JSON array
            var portions: [PortionOption]?
            if let portionsArray = data["portions"] as? [[String: Any]] {
                let decoder = JSONDecoder()
                if let portionsData = try? JSONSerialization.data(withJSONObject: portionsArray),
                   let decoded = try? decoder.decode([PortionOption].self, from: portionsData) {
                    portions = decoded
                }
            }

            return FoodSearchResult(
                id: id,
                name: name,
                brand: data["brand"] as? String,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                saturatedFat: data["saturatedFat"] as? Double,
                fiber: data["fiber"] as? Double ?? 0,
                sugar: data["sugar"] as? Double ?? 0,
                sodium: data["sodium"] as? Double ?? 0,
                servingDescription: data["servingDescription"] as? String,
                servingSizeG: data["servingSizeG"] as? Double,
                isPerUnit: data["isPerUnit"] as? Bool,
                ingredients: data["ingredients"] as? [String],
                isVerified: data["isVerified"] as? Bool ?? false,
                additives: additives,
                processingScore: data["processingScore"] as? Int,
                processingGrade: data["processingGrade"] as? String,
                processingLabel: data["processingLabel"] as? String,
                barcode: data["barcode"] as? String,
                micronutrientProfile: micronutrientProfile,
                portions: portions
            )
        }

                return favorites
    }

    /// Checks if a food is in user's favorites
    /// Uses offline-first pattern - checks local database first
    func isFavoriteFood(foodId: String) async throws -> Bool {
        await ensureAuthStateLoadedAsync()

        guard currentUser?.uid != nil else {
            return false
        }

        // OFFLINE-FIRST: Check local database first for instant response
        return OfflineDataManager.shared.isFavoriteFood(id: foodId)
    }

    // MARK: - User Settings (Height, Goal Weight, Caloric Goal)

    func saveUserSettings(height: Double?, goalWeight: Double?, caloricGoal: Int? = nil, exerciseGoal: Int? = nil, stepGoal: Int? = nil) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save settings"])
        }

        var data: [String: Any] = [:]
        if let height = height {
            data["height"] = height
        }
        if let goalWeight = goalWeight {
            data["goalWeight"] = goalWeight
        }
        if let caloricGoal = caloricGoal {
            data["caloricGoal"] = caloricGoal
        }
        if let exerciseGoal = exerciseGoal {
            data["exerciseGoal"] = exerciseGoal
        }
        if let stepGoal = stepGoal {
            data["stepGoal"] = stepGoal
        }

        // Use transaction with version check to prevent concurrent update conflicts
        let settingsRef = db.collection("users").document(userId)
            .collection("settings").document("preferences")

        try await FirestoreTransactionHelper.updateWithVersionCheck(
            documentRef: settingsRef,
            updateData: data,
            db: db
        )
                await MainActor.run {
            // Broadcast granular updates to refresh live UI
            if let goalWeight = goalWeight {
                NotificationCenter.default.post(name: .goalWeightUpdated, object: nil, userInfo: ["goalWeight": goalWeight])
            }
            if caloricGoal != nil || exerciseGoal != nil || stepGoal != nil {
                NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
            }
            NotificationCenter.default.post(name: .userSettingsUpdated, object: nil)
        }
    }

    func getUserSettings() async throws -> (height: Double?, goalWeight: Double?, caloricGoal: Int?, proteinPercent: Int?, carbsPercent: Int?, fatPercent: Int?, allergens: [Allergen]?, exerciseGoal: Int?, stepGoal: Int?) {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view settings"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data() else {
            return (nil, nil, nil, nil, nil, nil, nil, nil, nil)
        }

        let height = data["height"] as? Double
        let goalWeight = data["goalWeight"] as? Double
        let caloricGoal = data["caloricGoal"] as? Int
        let proteinPercent = data["proteinPercent"] as? Int
        let carbsPercent = data["carbsPercent"] as? Int
        let fatPercent = data["fatPercent"] as? Int
        let allergens = (data["allergens"] as? [String])?.compactMap { Allergen(rawValue: $0) }
        let exerciseGoal = data["exerciseGoal"] as? Int
        let stepGoal = data["stepGoal"] as? Int

        // Cache allergens for fast access
        if let allergens = allergens {
            await MainActor.run {
                self.cachedUserAllergens = allergens
                self.allergensLastFetched = Date()
            }
        }

        return (height, goalWeight, caloricGoal, proteinPercent, carbsPercent, fatPercent, allergens, exerciseGoal, stepGoal)
    }

    // MARK: - Fast Allergen Access
    /// Get user allergens from cache if available, otherwise fetch from Firebase
    /// Uses MainActor for thread-safe access to allergensLastFetched and cachedUserAllergens
    @MainActor
    func getUserAllergensWithCache() async -> [Allergen] {
        // Check if cache is still valid (thread-safe on MainActor)
        if let lastFetched = allergensLastFetched,
           Date().timeIntervalSince(lastFetched) < allergenCacheExpirationSeconds,
           !cachedUserAllergens.isEmpty {
            return cachedUserAllergens
        }

        // Cache expired or empty - fetch fresh
        do {
            let settings = try await getUserSettings()
            return settings.allergens ?? []
        } catch {
            return cachedUserAllergens
        }
    }

    func saveMacroPercentages(protein: Int, carbs: Int, fat: Int) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save macro settings"])
        }

        let data: [String: Any] = [
            "proteinPercent": protein,
            "carbsPercent": carbs,
            "fatPercent": fat
        ]

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
            }

    // MARK: - Macro Management (Customizable Macros)

    func saveMacroGoals(_ macroGoals: [MacroGoal], dietType: DietType?) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save macro goals"])
        }

        // Convert MacroGoal array to dictionary for Firebase
        let macroGoalsData = macroGoals.map { goal -> [String: Any] in
            var data: [String: Any] = ["macroType": goal.macroType.rawValue]

            if let percentage = goal.percentage {
                data["percentage"] = percentage
            }
            if let directTarget = goal.directTarget {
                data["directTarget"] = directTarget
            }

            return data
        }

        var data: [String: Any] = [
            "macroGoals": macroGoalsData
        ]

        // Save diet type (nil = custom)
        if let diet = dietType {
            data["dietType"] = diet.rawValue
        } else {
            data["dietType"] = "custom"
        }

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
    }

    func getMacroGoals() async throws -> [MacroGoal] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view macro goals"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data() else {
            // No settings found, return defaults
                        return MacroGoal.defaultMacros
        }

        // Try to load new macro goals structure
        if let macroGoalsData = data["macroGoals"] as? [[String: Any]] {
            let macroGoals = macroGoalsData.compactMap { goalData -> MacroGoal? in
                guard let macroTypeString = goalData["macroType"] as? String,
                      let macroType = MacroType(rawValue: macroTypeString) else {
                    return nil
                }

                // Check if it has a percentage (core macro) or direct target (extra macro)
                if let percentage = goalData["percentage"] as? Int {
                    return MacroGoal(macroType: macroType, percentage: percentage)
                } else if let directTarget = goalData["directTarget"] as? Double {
                    return MacroGoal(macroType: macroType, directTarget: directTarget)
                }

                return nil
            }

            if !macroGoals.isEmpty {
                // Ensure we always have 4 macros (P, C, F + extra)
                // Pad with defaults if any are missing
                var paddedMacros = macroGoals

                // Check for core macros and add if missing
                if !paddedMacros.contains(where: { $0.macroType == .protein }) {
                    paddedMacros.append(MacroGoal(macroType: .protein, percentage: 30))
                }
                if !paddedMacros.contains(where: { $0.macroType == .carbs }) {
                    paddedMacros.append(MacroGoal(macroType: .carbs, percentage: 40))
                }
                if !paddedMacros.contains(where: { $0.macroType == .fat }) {
                    paddedMacros.append(MacroGoal(macroType: .fat, percentage: 30))
                }

                // Ensure there's a 4th macro (extra) - default to Fiber if none
                let hasExtraMacro = paddedMacros.contains(where: { !$0.macroType.isCoreMacro })
                if !hasExtraMacro {
                    paddedMacros.append(MacroGoal(macroType: .fiber, directTarget: 30.0))
                }

                return paddedMacros
            }
        }

        // Backwards compatibility: Try to load old protein/carbs/fat percentages only
        if let proteinPercent = data["proteinPercent"] as? Int,
           let carbsPercent = data["carbsPercent"] as? Int,
           let fatPercent = data["fatPercent"] as? Int {
                        let migratedMacros = [
                MacroGoal(macroType: .protein, percentage: proteinPercent),
                MacroGoal(macroType: .carbs, percentage: carbsPercent),
                MacroGoal(macroType: .fat, percentage: fatPercent),
                MacroGoal(macroType: .fiber, directTarget: 30.0) // Add default fibre
            ]

            // Automatically migrate to new structure
            do {
                try await saveMacroGoals(migratedMacros, dietType: nil)
            } catch {
                PrivacyLogger.warning(
                    "Macro goals migration failed: \(error.localizedDescription)",
                    subsystem: .firebase,
                    category: .dataSync
                )
                // Continue with migration - non-fatal, user still gets their macros
            }

            return migratedMacros
        }

        // No data found at all, return defaults
                return MacroGoal.defaultMacros
    }

    func getDietType() async throws -> DietType? {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            return nil
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data(),
              let dietTypeString = data["dietType"] as? String else {
            return nil
        }

        // "custom" means user chose custom macros
        if dietTypeString == "custom" {
            return nil
        }

        return DietType(rawValue: dietTypeString)
    }

    func cacheNutritionGoals(caloric: Int?, exercise: Int?, steps: Int?) {
        if let caloric = caloric { UserDefaults.standard.set(caloric, forKey: "cachedCaloricGoal") }
        if let exercise = exercise { UserDefaults.standard.set(exercise, forKey: "cachedExerciseGoal") }
        if let steps = steps { UserDefaults.standard.set(steps, forKey: "cachedStepGoal") }
    }

    func saveAllergens(_ allergens: [Allergen]) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save allergens"])
        }

        let allergenStrings = allergens.map { $0.rawValue }
        let data: [String: Any] = ["allergens": allergenStrings]

        try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("settings").document("preferences").setData(data, merge: true)
        }

            }

    // MARK: - Fasting Tracking

    func saveFastingState(isFasting: Bool, startTime: Date?, goal: Int, notificationsEnabled: Bool, reminderInterval: Int) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting state"])
        }

        var data: [String: Any] = [
            "isFasting": isFasting,
            "goal": goal,
            "notificationsEnabled": notificationsEnabled,
            "reminderInterval": reminderInterval
        ]

        if let startTime = startTime {
            data["startTime"] = FirebaseFirestore.Timestamp(date: startTime)
        }

        try await db.collection("users").document(userId)
            .collection("settings").document("fasting").setData(data, merge: true)
            }

    func getFastingState() async throws -> (isFasting: Bool, startTime: Date?, goal: Int, notificationsEnabled: Bool, reminderInterval: Int) {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting state"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("fasting").getDocument()

        guard let data = document.data() else {
            return (false, nil, 16, false, 4) // Defaults
        }

        let isFasting = data["isFasting"] as? Bool ?? false
        let startTime = (data["startTime"] as? FirebaseFirestore.Timestamp)?.dateValue()
        let goal = data["goal"] as? Int ?? 16
        let notificationsEnabled = data["notificationsEnabled"] as? Bool ?? false
        let reminderInterval = data["reminderInterval"] as? Int ?? 4

        return (isFasting, startTime, goal, notificationsEnabled, reminderInterval)
    }

    // MARK: - User-Submitted Food Data

    func saveUserSubmittedFood(_ food: [String: Any]) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to submit foods"])
        }

        let foodId = food["id"] as? String ?? UUID().uuidString
        try await db.collection("users").document(userId)
            .collection("submittedFoods").document(foodId).setData(food, merge: true)
            }

    func getUserSubmittedFoods() async throws -> [[String: Any]] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view submitted foods"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("submittedFoods").getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    func saveUserIngredients(foodKey: String, ingredients: String) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save ingredients"])
        }

        let data: [String: Any] = [
            "ingredients": ingredients,
            "timestamp": FirebaseFirestore.Timestamp(date: Date())
        ]

        try await db.collection("users").document(userId)
            .collection("customIngredients").document(foodKey).setData(data, merge: true)
            }

    func getUserIngredients(foodKey: String) async throws -> String? {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view ingredients"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("customIngredients").document(foodKey).getDocument()

        return document.data()?["ingredients"] as? String
    }

    func saveVerifiedFood(foodKey: String) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to verify foods"])
        }

        let data: [String: Any] = [
            "foodKey": foodKey,
            "timestamp": FirebaseFirestore.Timestamp(date: Date())
        ]

        try await db.collection("users").document(userId)
            .collection("verifiedFoods").document(foodKey).setData(data)
            }

    func getVerifiedFoods() async throws -> [String] {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view verified foods"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("verifiedFoods").getDocuments()

        return snapshot.documents.compactMap { $0.data()["foodKey"] as? String }
    }

    // MARK: - User Enhanced Product Data

    func saveUserEnhancedProduct(data: [String: Any]) async throws {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save enhanced product data"])
        }

        guard let barcode = data["barcode"] as? String else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Barcode is required for enhanced product data"])
        }

        // Save to global userEnhancedProductData collection for all users to access
        let productId = "product_\(barcode)_\(UUID().uuidString)"
        var enhancedData = data
        enhancedData["userId"] = userId
        enhancedData["timestamp"] = FirebaseFirestore.Timestamp(date: Date())
        enhancedData["status"] = "pending_review" // Admin can review before making it public

        try await db.collection("userEnhancedProductData")
            .document(productId)
            .setData(enhancedData)

            }

    func getUserEnhancedProduct(barcode: String) async throws -> [String: Any]? {
        // Search for user-enhanced product data by barcode
        let snapshot = try await db.collection("userEnhancedProductData")
            .whereField("barcode", isEqualTo: barcode)
            .whereField("status", isEqualTo: "approved") // Only return approved data
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first?.data()
    }

    // MARK: - User Added Foods (Manual Entry)

    /// Save a manually added food to the global userAdded collection (accessible by all users)
    func saveUserAddedFood(_ food: [String: Any]) async throws -> String {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add foods"])
        }

        guard let foodName = food["foodName"] as? String else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name is required"])
        }

        // Use sanitized food name as document ID for easier identification
        let sanitizedName = foodName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "_")
            .prefix(100)
        let foodId = "userFood_\(sanitizedName)"

        // Prepare food data
        var foodData = food
        foodData["id"] = foodId
        foodData["userId"] = userId
        foodData["timestamp"] = FirebaseFirestore.Timestamp(date: Date())
        foodData["source"] = "manual_entry"
        foodData["isUserAdded"] = true

        // Add lowercase version of foodName for case-insensitive search
        foodData["foodNameLower"] = foodName.lowercased()

        // Save to global userAdded collection (accessible by all users)
        try await db.collection("userAdded")
            .document(foodId)
            .setData(foodData, merge: true)

                return foodId
    }

    /// Save an AI-enhanced food to the global aiManuallyAdded collection (accessible by all users)
    /// This is used when a user uses the "Find with AI" feature to auto-fill ingredient data from trusted UK sources
    func saveAIEnhancedFood(_ food: [String: Any], sourceURL: String?, aiProductName: String?) async throws -> String {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add foods"])
        }

        guard let foodName = food["foodName"] as? String else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name is required"])
        }

        // Use sanitized food name as document ID for easier identification
        let sanitizedName = foodName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "_")
            .prefix(100)
        let foodId = "aiFood_\(sanitizedName)"

        // Prepare food data with AI-specific fields
        var foodData = food
        foodData["id"] = foodId
        foodData["userId"] = userId
        foodData["timestamp"] = FirebaseFirestore.Timestamp(date: Date())
        foodData["source"] = "ai_ingredient_finder"
        foodData["isAIEnhanced"] = true

        // Add AI metadata if available
        if let sourceURL = sourceURL {
            foodData["source_url"] = sourceURL
        }
        if let aiProductName = aiProductName {
            foodData["ai_product_name"] = aiProductName
        }

        // Add lowercase version of foodName for case-insensitive search
        foodData["foodNameLower"] = foodName.lowercased()

        // Save to global aiManuallyAdded collection (accessible by all users)
        try await db.collection("aiManuallyAdded")
            .document(foodId)
            .setData(foodData, merge: true)

                return foodId
    }

    /// Search user-added foods by name and convert to FoodSearchResult
    func searchUserAddedFoods(query: String) async throws -> [FoodSearchResult] {
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespaces)

        // Search in userAdded collection using lowercase field for case-insensitive search
        let snapshot = try await db.collection("userAdded")
            .whereField("foodNameLower", isGreaterThanOrEqualTo: searchTerm)
            .whereField("foodNameLower", isLessThan: searchTerm + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()

        // Convert to FoodSearchResult
        return snapshot.documents.compactMap { doc -> FoodSearchResult? in
            let data = doc.data()

            guard let foodName = data["foodName"] as? String else { return nil }

            let id = data["id"] as? String ?? doc.documentID
            let brandName = data["brandName"] as? String
            let calories = data["calories"] as? Double ?? 0
            let protein = data["protein"] as? Double ?? 0
            let carbohydrates = data["carbohydrates"] as? Double ?? 0
            let fat = data["fat"] as? Double ?? 0
            let fiber = data["fiber"] as? Double ?? 0
            let sugars = data["sugars"] as? Double ?? 0
            let sodium = data["sodium"] as? Double ?? 0
            let servingSize = data["servingSize"] as? Double ?? 100
            let servingUnit = data["servingUnit"] as? String ?? "g"
            let ingredientsString = data["ingredients"] as? String

            // Convert ingredients string to array
            let ingredients: [String]? = ingredientsString?.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            // Read processing/grade information from Firestore
            let processingScore = data["processingScore"] as? Int
            let processingGrade = data["processingGrade"] as? String
            let processingLabel = data["processingLabel"] as? String
            let isPerUnit = data["per_unit_nutrition"] as? Bool

            return FoodSearchResult(
                id: id,
                name: foodName,
                brand: brandName,
                calories: calories,
                protein: protein,
                carbs: carbohydrates,
                fat: fat,
                fiber: fiber,
                sugar: sugars,
                sodium: sodium,
                servingDescription: "\(servingSize)\(servingUnit)",
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                confidence: nil,
                isVerified: false, // User-added foods are unverified by default
                additives: nil,
                processingScore: processingScore,
                processingGrade: processingGrade,
                processingLabel: processingLabel
            )
        }
    }

    /// Get a specific user-added food by ID
    func getUserAddedFood(foodId: String) async throws -> [String: Any]? {
        let document = try await db.collection("userAdded")
            .document(foodId)
            .getDocument()

        return document.data()
    }

    /// Search AI-enhanced foods collection (foods enhanced from detail page)
    func searchAIEnhancedFoods(query: String) async throws -> [FoodSearchResult] {
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespaces)

        // Search in aiEnhanced collection for approved foods
        let snapshot = try await db.collection("aiEnhanced")
            .whereField("status", isEqualTo: "approved")
            .limit(to: 20)
            .getDocuments()

        // Filter by name match and convert to FoodSearchResult
        return snapshot.documents.compactMap { doc -> FoodSearchResult? in
            let data = doc.data()

            // Get original food name and match against query
            guard let originalFoodName = data["originalFoodName"] as? String else { return nil }
            let foodNameLower = originalFoodName.lowercased()

            // Simple contains match for now
            guard foodNameLower.contains(searchTerm) else { return nil }

            let id = data["originalFoodId"] as? String ?? doc.documentID
            let brandName = data["originalBrand"] as? String ?? data["brand"] as? String

            // Use enhanced nutrition data
            let calories = data["calories"] as? Double ?? 0
            let protein = data["protein"] as? Double ?? 0
            let carbs = data["carbs"] as? Double ?? 0
            let fat = data["fat"] as? Double ?? 0
            let fiber = data["fiber"] as? Double ?? 0
            let sugar = data["sugar"] as? Double ?? 0
            let salt = data["salt"] as? Double ?? 0
            let sodium = salt * 400 // Convert salt (g) to sodium (mg)

            // Use enhanced ingredients
            let ingredientsText = data["ingredientsText"] as? String
            let ingredients: [String]? = ingredientsText?.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            // Get serving size from enhanced data, fallback to "100g"
            let servingSize = data["servingSize"] as? String ?? "100g"

            // Read processing/grade information from Firestore
            let processingScore = data["processingScore"] as? Int
            let processingGrade = data["processingGrade"] as? String
            let processingLabel = data["processingLabel"] as? String
            let isPerUnit = data["per_unit_nutrition"] as? Bool

            return FoodSearchResult(
                id: id,
                name: originalFoodName,
                brand: brandName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                servingDescription: servingSize,
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                confidence: nil,
                isVerified: true, // AI-enhanced foods are verified
                additives: nil,
                processingScore: processingScore,
                processingGrade: processingGrade,
                processingLabel: processingLabel
            )
        }
    }

    /// Search AI manually added foods collection (from "Find with AI" feature)
    func searchAIManuallyAddedFoods(query: String) async throws -> [FoodSearchResult] {
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespaces)

        // Search in aiManuallyAdded collection
        let snapshot = try await db.collection("aiManuallyAdded")
            .limit(to: 20)
            .getDocuments()

        // Filter by name match and convert to FoodSearchResult
        return snapshot.documents.compactMap { doc -> FoodSearchResult? in
            let data = doc.data()

            guard let foodName = data["foodName"] as? String else { return nil }
            let foodNameLower = foodName.lowercased()

            // Simple contains match
            guard foodNameLower.contains(searchTerm) else { return nil }

            let id = data["id"] as? String ?? doc.documentID
            let brandName = data["brand"] as? String
            let calories = data["calories"] as? Double ?? 0
            let protein = data["protein"] as? Double ?? 0
            let carbs = data["carbs"] as? Double ?? 0
            let fat = data["fat"] as? Double ?? 0
            let fiber = data["fiber"] as? Double ?? 0
            let sugar = data["sugar"] as? Double ?? 0
            let salt = data["salt"] as? Double ?? 0
            let sodium = salt * 400 // Convert salt (g) to sodium (mg)

            let ingredientsText = data["ingredientsText"] as? String
            let ingredients: [String]? = ingredientsText?.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            // Get serving size from data (servingSize + servingUnit), fallback to "100g"
            let servingSizeValue = data["servingSize"] as? Double ?? 100
            let servingUnit = data["servingUnit"] as? String ?? "g"
            let servingDescription = "\(Int(servingSizeValue))\(servingUnit)"

            // Read processing/grade information from Firestore
            let processingScore = data["processingScore"] as? Int
            let processingGrade = data["processingGrade"] as? String
            let processingLabel = data["processingLabel"] as? String
            let isPerUnit = data["per_unit_nutrition"] as? Bool

            return FoodSearchResult(
                id: id,
                name: foodName,
                brand: brandName,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                servingDescription: servingDescription,
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                confidence: nil,
                isVerified: true, // AI-found foods are verified
                additives: nil,
                processingScore: processingScore,
                processingGrade: processingGrade,
                processingLabel: processingLabel
            )
        }
    }

    /// Search foods via Cloud Function (includes OpenFoodFacts fallback)
    private func searchFoodsViaCloudFunction(query: String) async throws -> [FoodSearchResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoods?q=\(encodedQuery)"

        guard let url = URL(string: urlString) else {
                        throw NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                        return []
        }

        // Parse the JSON response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]] else {
                        return []
        }

        // Convert to FoodSearchResult objects
        return foods.compactMap { foodDict -> FoodSearchResult? in
            guard let id = foodDict["id"] as? String,
                  let name = foodDict["name"] as? String else {
                return nil
            }

            let brand = foodDict["brand"] as? String
            let barcode = foodDict["barcode"] as? String

            // Extract nutrition values (may be wrapped in objects like {kcal: 100})
            let calories = extractNutritionValue(foodDict["calories"])
            let protein = extractNutritionValue(foodDict["protein"])
            let carbs = extractNutritionValue(foodDict["carbs"])
            let fat = extractNutritionValue(foodDict["fat"])
            let fiber = extractNutritionValue(foodDict["fiber"])
            let sugar = extractNutritionValue(foodDict["sugar"])
            let sodium = extractNutritionValue(foodDict["sodium"])

            let servingDescription = foodDict["servingDescription"] as? String ?? "100g"

            // Get ingredients string
            let ingredientsString = foodDict["ingredients"] as? String
            let ingredients: [String]? = ingredientsString?.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }

            let isPerUnit = foodDict["per_unit_nutrition"] as? Bool

            // Extract unit override fields (for admin panel Reports feature)
            let suggestedServingUnit = foodDict["suggestedServingUnit"] as? String
            let unitOverrideLocked = foodDict["unitOverrideLocked"] as? Bool

            return FoodSearchResult(
                id: id,
                name: name,
                brand: brand,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: fiber,
                sugar: sugar,
                sodium: sodium,
                servingDescription: servingDescription,
                servingSizeG: nil,
                isPerUnit: isPerUnit,
                ingredients: ingredients,
                confidence: nil,
                isVerified: false,
                additives: nil,
                additivesDatabaseVersion: nil,
                processingScore: nil,
                processingGrade: nil,
                processingLabel: nil,
                barcode: barcode,
                micronutrientProfile: nil,
                portions: nil,
                source: nil,
                imageUrl: nil,
                foodCategory: nil,
                suggestedServingSize: nil,
                suggestedServingUnit: suggestedServingUnit,
                suggestedServingDescription: nil,
                unitOverrideLocked: unitOverrideLocked
            )
        }
    }

    /// Helper to extract nutrition values from either plain numbers or objects like {kcal: 100, per100g: 100}
    private func extractNutritionValue(_ value: Any?) -> Double {
        if let number = value as? Double {
            return number
        }
        if let dict = value as? [String: Any] {
            // Try different keys
            if let kcal = dict["kcal"] as? Double {
                return kcal
            }
            if let per100g = dict["per100g"] as? Double {
                return per100g
            }
        }
        return 0.0
    }

    // MARK: - Firebase Search Fallback (when Algolia unavailable)

    /// Fallback search method that queries Firebase directly when Algolia is unavailable
    /// This is slower than Algolia but ensures the app remains functional
    /// - Parameters:
    ///   - query: Search query string
    ///   - limit: Maximum results per collection (default 10)
    /// - Returns: Array of FoodSearchResult from Firebase collections
    func searchFoodsFirebaseFallback(query: String, limit: Int = 10) async throws -> [FoodSearchResult] {
        let searchTerm = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !searchTerm.isEmpty else { return [] }

        // Collections to search (in priority order matching Algolia tiers)
        // Note: Firestore doesn't support full-text search, so we use prefix matching
        let collections = [
            ("verifiedFoods", "name"),           // Admin-verified foods
            ("consumer_foods", "searchableName"), // Consumer-friendly generic foods
            ("uk_foods_cleaned", "name"),        // UK Foods
            ("tesco_products", "name"),          // Tesco products
            ("foods", "name"),                   // Original foods database
            ("fast_foods_database", "name"),     // Fast food
        ]

        var allResults: [FoodSearchResult] = []
        var seenIds = Set<String>()

        // PERFORMANCE: Limit concurrent requests to avoid overwhelming Firestore
        // Search in batches of 2 collections at a time to balance speed vs resource usage
        let batchSize = 2
        for batchStart in stride(from: 0, to: collections.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, collections.count)
            let batch = Array(collections[batchStart..<batchEnd])

            await withTaskGroup(of: [FoodSearchResult].self) { group in
                for (collectionName, nameField) in batch {
                    group.addTask {
                        do {
                            return try await self.searchFirebaseCollection(
                                collectionName: collectionName,
                                nameField: nameField,
                                searchTerm: searchTerm,
                                limit: limit
                            )
                        } catch {
                            PrivacyLogger.warning(
                                "Firebase fallback search failed for \(collectionName): \(error.localizedDescription)",
                                subsystem: .firebase,
                                category: .dataSync
                            )
                            return []
                        }
                    }
                }

                for await results in group {
                    for result in results where !seenIds.contains(result.id) {
                        seenIds.insert(result.id)
                        allResults.append(result)
                    }
                }
            }

            // If we have enough results, stop early to save network calls
            if allResults.count >= 20 {
                break
            }
        }

        // Sort by relevance (exact matches first, then prefix matches, then contains)
        let sorted = allResults.sorted { a, b in
            let aName = a.name.lowercased()
            let bName = b.name.lowercased()

            // Exact match
            if aName == searchTerm && bName != searchTerm { return true }
            if bName == searchTerm && aName != searchTerm { return false }

            // Starts with query
            if aName.hasPrefix(searchTerm) && !bName.hasPrefix(searchTerm) { return true }
            if bName.hasPrefix(searchTerm) && !aName.hasPrefix(searchTerm) { return false }

            // Shorter names first (more likely to be canonical)
            return a.name.count < b.name.count
        }

        return Array(sorted.prefix(20))
    }

    /// Search a single Firebase collection with prefix matching
    /// Combines capitalized and lowercase searches for better coverage
    private func searchFirebaseCollection(
        collectionName: String,
        nameField: String,
        searchTerm: String,
        limit: Int
    ) async throws -> [FoodSearchResult] {
        // PERFORMANCE: Run both case variants in parallel instead of sequentially
        async let capitalizedTask = db.collection(collectionName)
            .whereField(nameField, isGreaterThanOrEqualTo: searchTerm.capitalized)
            .whereField(nameField, isLessThan: searchTerm.capitalized + "\u{f8ff}")
            .limit(to: limit)
            .getDocuments()

        async let lowercaseTask = db.collection(collectionName)
            .whereField(nameField, isGreaterThanOrEqualTo: searchTerm)
            .whereField(nameField, isLessThan: searchTerm + "\u{f8ff}")
            .limit(to: limit)
            .getDocuments()

        // Await both in parallel
        let (capitalizedSnapshot, lowercaseSnapshot) = try await (capitalizedTask, lowercaseTask)

        // Combine results, removing duplicates
        var allDocs = capitalizedSnapshot.documents
        let existingIds = Set(allDocs.map { $0.documentID })
        for doc in lowercaseSnapshot.documents where !existingIds.contains(doc.documentID) {
            allDocs.append(doc)
        }

        return allDocs.compactMap { doc -> FoodSearchResult? in
            let data = doc.data()
            return parseFirestoreDocToFoodSearchResult(docId: doc.documentID, data: data, source: collectionName)
        }
    }

    /// Parse a Firestore document into FoodSearchResult
    private func parseFirestoreDocToFoodSearchResult(docId: String, data: [String: Any], source: String) -> FoodSearchResult? {
        // Get name from various possible fields
        guard let name = (data["name"] as? String)
            ?? (data["foodName"] as? String)
            ?? (data["product_name"] as? String) else {
            return nil
        }

        let id = (data["id"] as? String) ?? docId
        let brand = (data["brandName"] as? String) ?? (data["brand"] as? String)
        let barcode = data["barcode"] as? String

        // Extract nutrition values
        let calories = (data["calories"] as? Double) ?? (data["energy_kcal"] as? Double) ?? 0
        let protein = (data["protein"] as? Double) ?? (data["proteins"] as? Double) ?? 0
        let carbs = (data["carbs"] as? Double) ?? (data["carbohydrates"] as? Double) ?? 0
        let fat = (data["fat"] as? Double) ?? (data["fats"] as? Double) ?? 0
        let saturatedFat = (data["saturatedFat"] as? Double) ?? (data["saturated_fat"] as? Double)
        let fiber = (data["fiber"] as? Double) ?? (data["fibre"] as? Double) ?? 0
        let sugar = (data["sugar"] as? Double) ?? (data["sugars"] as? Double) ?? 0
        let sodium = (data["sodium"] as? Double) ?? ((data["salt"] as? Double).map { $0 * 400 }) ?? 0

        // Serving info
        let servingSizeG = (data["servingSizeG"] as? Double) ?? (data["serving_size_g"] as? Double) ?? 100
        let servingDescription = (data["servingSize"] as? String) ?? (data["serving_description"] as? String) ?? "\(Int(servingSizeG))g"

        // Ingredients
        var ingredients: [String]? = nil
        if let ingredientsList = data["ingredients"] as? [String] {
            ingredients = ingredientsList
        } else if let ingredientsString = data["ingredients"] as? String, !ingredientsString.isEmpty {
            ingredients = ingredientsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        // Verification status
        let isVerified = (data["isVerified"] as? Bool) ?? (data["verified"] as? Bool) ?? false
        let isPerUnit = data["per_unit_nutrition"] as? Bool

        // Micronutrient profile
        var micronutrientProfile: MicronutrientProfile? = nil
        if let profileData = data["micronutrientProfile"] as? [String: Any] {
            micronutrientProfile = parseMicronutrientProfileFromFirestore(profileData)
        }

        return FoodSearchResult(
            id: id,
            name: name,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            saturatedFat: saturatedFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingDescription: servingDescription,
            servingSizeG: servingSizeG,
            isPerUnit: isPerUnit,
            ingredients: ingredients,
            isVerified: isVerified,
            barcode: barcode,
            micronutrientProfile: micronutrientProfile,
            source: source
        )
    }

    /// Parse micronutrient profile from Firestore data
    private func parseMicronutrientProfileFromFirestore(_ data: [String: Any]) -> MicronutrientProfile? {
        var vitamins: [String: Double] = [:]
        var minerals: [String: Double] = [:]

        if let vitaminsData = data["vitamins"] as? [String: Any] {
            for (key, value) in vitaminsData {
                if let doubleValue = value as? Double {
                    vitamins[key] = doubleValue
                } else if let intValue = value as? Int {
                    vitamins[key] = Double(intValue)
                }
            }
        }

        if let mineralsData = data["minerals"] as? [String: Any] {
            for (key, value) in mineralsData {
                if let doubleValue = value as? Double {
                    minerals[key] = doubleValue
                } else if let intValue = value as? Int {
                    minerals[key] = Double(intValue)
                }
            }
        }

        guard !vitamins.isEmpty || !minerals.isEmpty else { return nil }

        let dailyValues: [String: Double] = [
            "vitaminA": 900, "vitaminC": 90, "vitaminD": 20, "vitaminE": 15, "vitaminK": 120,
            "thiamine": 1.2, "riboflavin": 1.3, "niacin": 16, "pantothenicAcid": 5,
            "vitaminB6": 1.7, "biotin": 30, "folate": 400, "vitaminB12": 2.4, "choline": 550,
            "calcium": 1000, "iron": 18, "magnesium": 420, "phosphorus": 1250, "potassium": 4700,
            "sodium": 2300, "zinc": 11, "copper": 0.9, "manganese": 2.3, "selenium": 55,
            "chromium": 35, "molybdenum": 45, "iodine": 150
        ]

        let recommendedIntakes = RecommendedIntakes(age: 30, gender: .other, dailyValues: dailyValues)

        let confidenceScore: MicronutrientConfidence
        if let confidenceString = data["confidenceScore"] as? String {
            switch confidenceString.lowercased() {
            case "high": confidenceScore = .high
            case "low": confidenceScore = .low
            case "estimated": confidenceScore = .estimated
            default: confidenceScore = .medium
            }
        } else {
            confidenceScore = .medium
        }

        return MicronutrientProfile(
            vitamins: vitamins,
            minerals: minerals,
            recommendedIntakes: recommendedIntakes,
            confidenceScore: confidenceScore
        )
    }

    // MARK: - AI-Improved Foods

    /// Save AI-improved food data to Firebase
    func saveAIImprovedFood(originalFood: FoodSearchResult, enhancedData: [String: Any]) async throws -> String {
        await ensureAuthStateLoadedAsync()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save AI-improved foods"])
        }

        let timestamp = Timestamp(date: Date())

        // Use sanitized original food name as document ID for easier identification
        let sanitizedName = originalFood.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "_")
            .prefix(100)
        let foodId = "aiEnhanced_\(sanitizedName)"

        var aiImprovedData: [String: Any] = [
            "id": foodId,
            "originalFoodId": originalFood.id,
            "originalFoodName": originalFood.name,
            "originalBrand": originalFood.brand ?? "",
            "improvedBy": userId,
            "improvedAt": timestamp,
            "status": "pending_review"  // Can be: pending_review, approved, rejected
        ]

        // Merge enhanced data
        aiImprovedData.merge(enhancedData) { (_, new) in new }

        // Save to aiEnhanced collection (global, accessible by all users)
        try await db.collection("aiEnhanced").document(foodId).setData(aiImprovedData, merge: true)
                return foodId
    }

    /// Get AI-enhanced version of a food by original food ID
    func getAIImprovedFood(originalFoodId: String) async throws -> [String: Any]? {
        let snapshot = try await db.collection("aiEnhanced")
            .whereField("originalFoodId", isEqualTo: originalFoodId)
            .whereField("status", isEqualTo: "approved")
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first?.data()
    }

    /// Check if a food has been AI-improved
    func hasAIImprovedVersion(originalFoodId: String) async throws -> Bool {
        let improved = try await getAIImprovedFood(originalFoodId: originalFoodId)
        return improved != nil
    }

    // MARK: - Incomplete Food Notification

    /// Notify team about incomplete food information via Cloud Function
    func notifyIncompleteFood(food: FoodSearchResult) async throws {
        // Call the Cloud Function which handles both Firestore save and email notification
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/notifyIncompleteFood") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build full food data for the report
        var foodData: [String: Any] = [
            "id": food.id,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "fiber": food.fiber,
            "sugar": food.sugar,
            "sodium": food.sodium,
            "isVerified": food.isVerified
        ]

        // Add optional fields if present
        if let brand = food.brand { foodData["brand"] = brand }
        if let barcode = food.barcode { foodData["barcode"] = barcode }
        if let servingDescription = food.servingDescription { foodData["servingDescription"] = servingDescription }
        if let servingSizeG = food.servingSizeG { foodData["servingSizeG"] = servingSizeG }
        if let ingredients = food.ingredients { foodData["ingredients"] = ingredients }
        if let processingScore = food.processingScore { foodData["processingScore"] = processingScore }
        if let processingGrade = food.processingGrade { foodData["processingGrade"] = processingGrade }
        if let processingLabel = food.processingLabel { foodData["processingLabel"] = processingLabel }

        let requestBody: [String: Any] = [
            "data": [
                "foodName": food.name,
                "brandName": food.brand ?? "",
                "foodId": food.id,
                "barcode": food.barcode ?? "",
                "userId": currentUser?.uid ?? "anonymous",
                "userEmail": currentUser?.email ?? "anonymous",
                "recipientEmail": "contact@nutrasafe.co.uk",
                "fullFoodData": foodData
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "Invalid Response", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "Server Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error code \(httpResponse.statusCode)"])
        }

        // Parse response to ensure success
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: Any],
           let success = result["success"] as? Bool,
           success {
                    } else {
            throw NSError(domain: "Notification failed", code: -1)
        }
    }

    /// Save incomplete food data to Firestore for team review
    private func saveIncompleteFoodToFirestore(food: FoodSearchResult) async throws {
        let db = Firestore.firestore()
        let timestamp = Timestamp(date: Date())

        // Create document data with all available food information
        var foodData: [String: Any] = [
            "foodId": food.id,
            "name": food.name,
            "brand": food.brand ?? "",
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat,
            "fiber": food.fiber,
            "sugar": food.sugar,
            "sodium": food.sodium,
            "reportedBy": currentUser?.uid ?? "anonymous",
            "reportedByEmail": currentUser?.email ?? "anonymous",
            "reportedAt": timestamp,
            "status": "pending", // pending, in_progress, resolved
            "resolved": false
        ]

        // Add optional values if available
        if let servingDescription = food.servingDescription {
            foodData["servingDescription"] = servingDescription
        }
        if let servingSizeG = food.servingSizeG {
            foodData["servingSizeG"] = servingSizeG
        }
        if let ingredients = food.ingredients {
            foodData["ingredients"] = ingredients
        }
        if let barcode = food.barcode {
            foodData["barcode"] = barcode
        }
        if let source = food.source {
            foodData["source"] = source
            // Map Algolia index to Firestore collection for editing
            let indexToCollection: [String: String] = [
                "tesco_products": "tesco_products",
                "verified_foods": "verifiedFoods",
                "foods": "foods",
                "user_added": "userAdded",
                "ai_enhanced": "aiEnhanced",
                "ai_manually_added": "aiManuallyAdded"
            ]
            foodData["collection"] = indexToCollection[source] ?? "verifiedFoods"
        }

        // Add to incomplete_foods collection
        // Use sanitized food name as document ID for easier identification
        let sanitizedName = food.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "_")
            .prefix(100) // Firestore doc ID max length is 1500 chars, but keep it readable
        let docRef = db.collection("incomplete_foods").document(String(sanitizedName))
        try await docRef.setData(foodData, merge: true) // Use merge to avoid overwriting if name collision

            }
    func saveFastingStreakSettings(_ settings: [String: Any]) async throws {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting settings"])
        }
        let data: [String: Any] = [
            "daysPerWeekGoal": settings["daysPerWeekGoal"] as? Int ?? 3,
            "targetMinHours": settings["targetMinHours"] as? Int ?? 14,
            "targetMaxHours": settings["targetMaxHours"] as? Int ?? 18
        ]
        try await db.collection("users").document(userId)
            .collection("settings").document("fasting_streak").setData(data, merge: true)
        await MainActor.run {
            NotificationCenter.default.post(name: .fastingSettingsUpdated, object: nil)
        }
    }

    func getFastingStreakSettings() async throws -> [String: Any] {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting settings"])
        }
        let document = try await db.collection("users").document(userId)
            .collection("settings").document("fasting_streak").getDocument()
        guard let data = document.data() else { 
            return [
                "daysPerWeekGoal": 3,
                "targetMinHours": 14,
                "targetMaxHours": 18
            ]
        }
        let daysPerWeekGoal = data["daysPerWeekGoal"] as? Int ?? 3
        let targetMinHours = data["targetMinHours"] as? Int ?? 14
        let targetMaxHours = data["targetMaxHours"] as? Int ?? 18
        return [
            "daysPerWeekGoal": daysPerWeekGoal,
            "targetMinHours": targetMinHours,
            "targetMaxHours": targetMaxHours
        ]
    }

    // MARK: - New Fasting System Methods

    func saveFastingPlan(_ plan: FastingPlan) async throws -> String {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting plans"])
        }

        let planId = plan.id ?? UUID().uuidString
        var planWithId = plan
        planWithId.id = planId

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFastingPlan(planWithId)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        return planId
    }

    func getFastingPlans() async throws -> [FastingPlan] {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting plans"])
        }

        // First try to get from local database for instant response
        let localPlans = OfflineDataManager.shared.getFastingPlans()
        if !localPlans.isEmpty {
            // Trigger background sync to get latest from server
            OfflineSyncManager.shared.triggerSync()
            return localPlans
        }

        // If local is empty, fetch from Firebase (first launch or empty local)
        let snapshot = try await db.collection("users").document(userId)
            .collection("fastingPlans").order(by: "created_at", descending: true).getDocuments()

        var plans: [FastingPlan] = []
        for doc in snapshot.documents {
            do {
                let plan = try doc.data(as: FastingPlan.self)
                plans.append(plan)
                // Import to local database
                OfflineDataManager.shared.saveFastingPlan(plan)
            } catch {
                // Skip malformed documents
            }
        }

        return plans
    }

    func updateFastingPlan(_ plan: FastingPlan) async throws {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update fasting plans"])
        }
        guard plan.id != nil else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Plan ID is required for updates"])
        }

        // OFFLINE-FIRST: Update in local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFastingPlan(plan)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    func deleteFastingPlan(id: String) async throws {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete fasting plans"])
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteFastingPlan(id: id)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()
    }

    /// Clean up corrupted fasting plans that failed to decode
    /// Uses batch operations for efficient deletion (max 500 per batch)
    func cleanupCorruptedFastingPlans() async throws -> Int {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to cleanup fasting plans"])
        }

        
        let snapshot = try await db.collection("users").document(userId)
            .collection("fastingPlans").getDocuments()

        // Identify corrupted plans
        var corruptedDocIDs: [String] = []
        for doc in snapshot.documents {
            do {
                _ = try doc.data(as: FastingPlan.self)
            } catch {
                corruptedDocIDs.append(doc.documentID)
            }
        }

        guard !corruptedDocIDs.isEmpty else {
                        return 0
        }

        
        // PERFORMANCE: Use batch operations to delete efficiently
        // Firestore batch limit is 500 operations
        let chunkSize = 500
        for chunkStart in stride(from: 0, to: corruptedDocIDs.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, corruptedDocIDs.count)
            let chunk = Array(corruptedDocIDs[chunkStart..<chunkEnd])

            let batch = db.batch()
            for docID in chunk {
                let docRef = db.collection("users").document(userId)
                    .collection("fastingPlans").document(docID)
                batch.deleteDocument(docRef)
            }
            try await batch.commit()
                    }

                return corruptedDocIDs.count
    }

    func saveFastingSession(_ session: FastingSession) async throws -> String {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting sessions"])
        }

        let sessionId = session.id ?? UUID().uuidString
        var sessionWithId = session
        sessionWithId.id = sessionId

        // OFFLINE-FIRST: Save to local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFastingSession(sessionWithId)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        await MainActor.run {
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        }

        return sessionId
    }

    func getFastingSessions() async throws -> [FastingSession] {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting sessions"])
        }

        // OFFLINE-FIRST: Try local database first for instant response
        let localSessions = OfflineDataManager.shared.getFastingSessions()
        if !localSessions.isEmpty {
            // Trigger background sync to get latest from server
            OfflineSyncManager.shared.triggerSync()
            return localSessions
        }

        // If local is empty, fetch from Firebase (first launch or empty local)
        let snapshot = try await db.collection("users").document(userId)
            .collection("fastingSessions").order(by: "start_time", descending: true).getDocuments()

        var sessions: [FastingSession] = []
        for doc in snapshot.documents {
            if let session = try? doc.data(as: FastingSession.self) {
                sessions.append(session)
                // Import to local database
                OfflineDataManager.shared.saveFastingSession(session)
            }
        }

        return sessions
    }

    func updateFastingSession(_ session: FastingSession) async throws {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update fasting sessions"])
        }
        guard session.id != nil else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session ID is required for updates"])
        }

        // OFFLINE-FIRST: Update in local SQLite database first
        // OfflineSyncManager will push to Firebase in the background
        OfflineDataManager.shared.saveFastingSession(session)

        // Trigger background sync to push to Firebase
        OfflineSyncManager.shared.triggerSync()

        await MainActor.run {
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        }
    }

    func deleteFastingSession(id: String) async throws {
        await ensureAuthStateLoadedAsync()
        guard currentUser?.uid != nil else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete fasting sessions"])
        }

        // OFFLINE-FIRST: Mark as deleted in local SQLite database
        // OfflineSyncManager will push delete to Firebase in the background
        OfflineDataManager.shared.deleteFastingSession(id: id)

        // Trigger background sync to push delete to Firebase
        OfflineSyncManager.shared.triggerSync()

        await MainActor.run {
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        }
    }
}

extension Notification.Name {
    static let useByInventoryUpdated = Notification.Name("useByInventoryUpdated")
    static let navigateToUseBy = Notification.Name("navigateToUseBy")
    static let navigateToFasting = Notification.Name("navigateToFasting")
    static let restartOnboarding = Notification.Name("restartOnboarding")
    static let authStateChanged = Notification.Name("authStateChanged")
    static let foodDiaryUpdated = Notification.Name("foodDiaryUpdated")
    static let nutritionGoalsUpdated = Notification.Name("nutritionGoalsUpdated")
    // New notifications for live settings updates
    static let goalWeightUpdated = Notification.Name("goalWeightUpdated")
    static let weightHistoryUpdated = Notification.Name("weightHistoryUpdated")
    static let userSettingsUpdated = Notification.Name("userSettingsUpdated")
    static let userDataCleared = Notification.Name("userDataCleared")
    // Fasting-related updates
    static let fastHistoryUpdated = Notification.Name("fastHistoryUpdated")
    static let fastingSettingsUpdated = Notification.Name("fastingSettingsUpdated")
    static let diaryFoodDetailOpened = Notification.Name("diaryFoodDetailOpened")
    // Fasting confirmation flow - triggered from notification tap with context
    static let fastingConfirmationRequired = Notification.Name("fastingConfirmationRequired")
}

// MARK: - Response Models for Food Search

struct FoodSearchResponse: Decodable {
    let foods: [FoodSearchResult]
}

extension FirebaseManager {
    // Whitelisted emails that get premium access
    private static let premiumWhitelistedEmails: Set<String> = [
        "aaronmkeen@gmail.com"
    ]

    func getPremiumOverride() async throws -> Bool {
        await ensureAuthStateLoadedAsync()

        if let email = currentUser?.email?.lowercased() {
            // Domain-based override for staff/users with nutrasafe.co.uk emails
            if let domain = email.split(separator: "@").last,
               domain == "nutrasafe.co.uk" {
                return true
            }

            // Specific whitelisted emails
            if Self.premiumWhitelistedEmails.contains(email) {
                return true
            }
        }

        guard let userId = currentUser?.uid else { return false }
        let doc = try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("settings").document("preferences")
            .getDocument()
        let value = doc.data()?["premiumOverride"] as? Bool ?? false
        return value
    }
}

// MARK: - Ingredient Cache

struct IngredientCacheEntry: Codable {
    let productName: String
    let brand: String?
    let ingredientsText: String
    let sourceUrl: String?
    let createdAt: FirebaseFirestore.Timestamp
}

extension FirebaseManager {
    func getIngredientCache(productName: String, brand: String?) async throws -> IngredientResult? {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else { return nil }
        let key = cacheKey(productName: productName, brand: brand)
        let doc = try await db.collection("users").document(userId)
            .collection("ingredientCache").document(key).getDocument()
        guard let data = doc.data() else { return nil }
        let text = data["ingredientsText"] as? String ?? ""
        let source = data["sourceUrl"] as? String
        if text.isEmpty { return nil }
        return IngredientResult(ingredients_found: true, ingredients_text: text, source_url: source)
    }

    func setIngredientCache(productName: String, brand: String?, ingredientsText: String, sourceUrl: String?) async throws {
        await ensureAuthStateLoadedAsync()
        guard let userId = currentUser?.uid else { return }
        let key = cacheKey(productName: productName, brand: brand)
        let payload: [String: Any] = [
            "productName": productName,
            "brand": brand ?? "",
            "ingredientsText": ingredientsText,
            "sourceUrl": sourceUrl ?? "",
            "createdAt": FirebaseFirestore.Timestamp(date: Date())
        ]
        try await db.collection("users").document(userId)
            .collection("ingredientCache").document(key).setData(payload, merge: true)
    }

    private func cacheKey(productName: String, brand: String?) -> String {
        let pn = productName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let br = (brand ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return br.isEmpty ? pn : "\(pn)__\(br)"
    }
}

// Fallback model for Ingredient Finder to satisfy compilation when model file is missing from target
struct IngredientResult: Codable {
    let ingredients_found: Bool
    let ingredients_text: String?
    let source_url: String?
}
