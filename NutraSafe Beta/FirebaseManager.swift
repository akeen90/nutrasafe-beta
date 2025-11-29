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

    private lazy var db = Firestore.firestore()
    private lazy var auth = Auth.auth()

    // Thread-safe cache using DispatchQueue (Swift 6 async-safe)
    private let cacheQueue = DispatchQueue(label: "com.nutrasafe.cacheQueue")
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    // Apple Sign In nonce storage
    private var currentNonce: String?

    // MARK: - Search Cache (Optimized with NSCache)
    private class SearchCacheEntry {
        let results: [FoodSearchResult]
        let timestamp: Date

        init(results: [FoodSearchResult], timestamp: Date) {
            self.results = results
            self.timestamp = timestamp
        }
    }
    private let searchCache = NSCache<NSString, SearchCacheEntry>()
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

    // MARK: - Food Entries Cache (Performance Optimization)
    private struct FoodEntriesCacheEntry {
        let entries: [FoodEntry]
        let timestamp: Date
    }
    private var foodEntriesCache: [String: FoodEntriesCacheEntry] = [:]
    private let foodEntriesCacheExpirationSeconds: TimeInterval = 600 // 10 minutes
    private let maxFoodEntriesCacheSize: Int = 100 // Maximum number of cached dates

    // In-flight request tracking to prevent duplicate fetches
    private var inFlightFoodEntriesRequests: [String: Task<[FoodEntry], Error>] = [:]

    // MARK: - Allergen Cache
    @Published var cachedUserAllergens: [Allergen] = []
    private var allergensLastFetched: Date?
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
                Task { @MainActor in
                    self?.currentUser = user
                    self?.isAuthenticated = user != nil
                    NotificationCenter.default.post(name: .authStateChanged, object: nil)
                }
            }
        }
    }

    func preloadWeightData(history: [WeightEntry], height: Double?, goalWeight: Double?) {
        Task { @MainActor in
            self.cachedWeightHistory = history
            self.cachedUserHeight = height
            self.cachedGoalWeight = goalWeight
        }
    }
    
    // Ensure our cached auth state is populated even if the listener hasn't fired yet
    private func ensureAuthStateLoaded() {
        initializeFirebaseServices()
        if self.currentUser == nil {
            let user = auth.currentUser
            Task { @MainActor in
                self.currentUser = user
                self.isAuthenticated = user != nil
            }
        }
    }

    // MARK: - Network Retry Logic

    /// Retry failed network operations with exponential backoff
    /// - Parameters:
    ///   - maxAttempts: Maximum number of retry attempts (default: 3)
    ///   - operation: The async operation to retry
    /// - Returns: The result of the operation
    private func withRetry<T>(
        maxAttempts: Int = 3,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
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

                #if DEBUG
                print("⚠️ [Retry \(attempt + 1)/\(maxAttempts)] Network error: \(error.localizedDescription)")
                print("   Retrying in \(delay)s...")
                #endif

                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
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

    func signOut() throws {
        try auth.signOut()

        // Clear any residual UserDefaults data to prevent leakage between accounts
        UserDefaults.standard.removeObject(forKey: "userWeight")
        UserDefaults.standard.removeObject(forKey: "goalWeight")
        UserDefaults.standard.removeObject(forKey: "userHeight")
        UserDefaults.standard.removeObject(forKey: "weightHistory")
        #if DEBUG
        print("🧹 Cleared local UserDefaults data on sign out")

        // Clear ReactionManager data to prevent leakage between accounts
        #endif
        Task { @MainActor in
            ReactionManager.shared.clearData()
        }

        Task { @MainActor in
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }

    func deleteAllUserData() async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete data"])
        }

        // DEBUG LOG: print("🗑️ Starting to delete all user data for user: \(userId)")

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
            let snapshot = try await db.collection("users").document(userId)
                .collection(collection).getDocuments()

            let count = snapshot.documents.count
            #if DEBUG
            print("   Deleting \(count) documents from \(collection)...")

            #endif
            for document in snapshot.documents {
                try await document.reference.delete()
            }

            totalDeleted += count
            #if DEBUG
            print("   ✅ Successfully deleted \(count) documents from \(collection)")
            #endif
        }

        #if DEBUG
        print("✅ All user data deleted successfully - Total: \(totalDeleted) documents deleted")

        // Clear caches and notify observers so the UI refreshes immediately
        #endif
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
    func startAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Complete Apple Sign In with the authorization result
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"])
        }

        guard let nonce = currentNonce else {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: nonce not set"])
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
        }

        initializeFirebaseServices()

        // Create Firebase credential with Apple ID token
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        // Sign in with Firebase - automatically links if email matches existing account
        let result = try await auth.signIn(with: credential)

        // Update display name if provided (Apple only sends name on first sign-in)
        if let fullName = appleIDCredential.fullName,
           let givenName = fullName.givenName {
            let displayName = [givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
            if !displayName.isEmpty {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }
        }

        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }

    /// Check if current user authenticated via Apple Sign In
    var isAppleUser: Bool {
        currentUser?.providerData.contains { $0.providerID == "apple.com" } ?? false
    }

    // Generate random nonce string for Apple Sign In security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
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
    
    // MARK: - Food Diary
    
    func saveFoodEntry(_ entry: FoodEntry) async throws {
        guard let userId = currentUser?.uid else { return }
        let entryData = entry.toDictionary()

        // Wrap with retry for network resilience
        try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("foodEntries").document(entry.id).setData(entryData)
        }

        // Invalidate cache for this date
        invalidateFoodEntriesCache(for: entry.date, userId: userId)

        // Invalidate period cache (7-day queries) - thread-safe, also cancel in-flight requests
        cacheQueue.sync {
            periodCache.removeAll()
            inFlightPeriodRequests.values.forEach { $0.cancel() }
            inFlightPeriodRequests.removeAll()
        }
        // DEBUG LOG: print("🗑️ Cleared period cache after saving food entry")

        // Notify that food diary was updated
        await MainActor.run {
        // DEBUG LOG: print("📢 Posting foodDiaryUpdated notification...")
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }

        // Write dietary energy to Apple Health when enabled
        let ringsEnabled = UserDefaults.standard.bool(forKey: "healthKitRingsEnabled")
        if ringsEnabled {
            Task {
                await HealthKitManager.shared.requestAuthorization()
                do {
                    try await HealthKitManager.shared.writeDietaryEnergyConsumed(calories: entry.calories, date: entry.date)
                } catch {
                    #if DEBUG
                    print("⚠️ Failed to write dietary energy to HealthKit: \(error)")
                    #endif
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
        // DEBUG LOG: print("🗑️ Invalidated food entries cache for \(formatter.string(from: startOfDay))")
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        let dateKey = "\(userId)_\(formatter.string(from: startOfDay))"

        // Return cached entries if still valid (with async-safe synchronization)
        let cachedEntry = cacheQueue.sync { foodEntriesCache[dateKey] }

        if let cached = cachedEntry,
           Date().timeIntervalSince(cached.timestamp) < foodEntriesCacheExpirationSeconds {
            // DEBUG LOG: print("✅ [Cache HIT] Returning cached entries for \(dateKey)")
            return cached.entries
        }

        // Check for in-flight request to prevent duplicate fetches
        let existingTask = cacheQueue.sync { inFlightFoodEntriesRequests[dateKey] }
        if let task = existingTask {
            // DEBUG LOG: print("⏳ [In-flight Request] Waiting for existing fetch for \(dateKey)")
            return try await task.value
        }

        // Create new fetch task
        let fetchTask = Task<[FoodEntry], Error> {
            // Query using local day boundaries (Firebase stores UTC timestamps but we query by local day)
            let queryStart = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: queryStart)?.addingTimeInterval(-0.001) else {
                #if DEBUG
                print("❌ Failed to calculate end of day for date: \(date)")
                #endif
                throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
            }
            let queryEnd = endOfDay

            let snapshot = try await withRetry {
                try await self.db.collection("users").document(userId)
                    .collection("foodEntries")
                    .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: queryStart))
                    .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: queryEnd))
                    .getDocuments()
            }

            let entries = snapshot.documents.compactMap { doc -> FoodEntry? in
                // Use Firestore's native Codable decoder for safe, crash-proof parsing
                do {
                    return try doc.data(as: FoodEntry.self)
                } catch {
                    #if DEBUG
                    print("⚠️ Skipping corrupt entry \(doc.documentID): \(error.localizedDescription)")
                    #endif
                    return nil
                }
            }

            // Store in cache and remove from in-flight (async-safe with DispatchQueue)
            self.cacheQueue.sync {
                self.foodEntriesCache[dateKey] = FoodEntriesCacheEntry(entries: entries, timestamp: Date())

                // Evict oldest entries if cache exceeds size limit
                if self.foodEntriesCache.count > self.maxFoodEntriesCacheSize {
                    // Sort by timestamp and remove oldest entries
                    let sortedEntries = self.foodEntriesCache.sorted { $0.value.timestamp < $1.value.timestamp }
                    let entriesToRemove = sortedEntries.prefix(self.foodEntriesCache.count - self.maxFoodEntriesCacheSize)
                    for (key, _) in entriesToRemove {
                        self.foodEntriesCache.removeValue(forKey: key)
                    }
                }

                self.inFlightFoodEntriesRequests.removeValue(forKey: dateKey)
            }

            return entries
        }

        // Register the in-flight request
        cacheQueue.sync {
            inFlightFoodEntriesRequests[dateKey] = fetchTask
        }

        return try await fetchTask.value
    }

    // MARK: - Period Cache (for Micronutrient Dashboard)
    private var periodCache: [Int: (entries: [FoodEntry], timestamp: Date)] = [:]
    private let periodCacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    private let maxPeriodCacheSize: Int = 50 // Maximum number of cached periods

    // In-flight request tracking for period queries
    private var inFlightPeriodRequests: [Int: Task<[FoodEntry], Error>] = [:]

    // Get food entries for the past N days for nutritional analysis
    func getFoodEntriesForPeriod(days: Int) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

        // Check cache first (async-safe synchronization)
        let cachedPeriod = cacheQueue.sync { periodCache[days] }

        if let cached = cachedPeriod,
           Date().timeIntervalSince(cached.timestamp) < periodCacheExpirationSeconds {
            // DEBUG LOG: print("✅ [Period Cache HIT] Returning cached entries for \(days) days")
            return cached.entries
        }

        // Check for in-flight request to prevent duplicate fetches
        let existingTask = cacheQueue.sync { inFlightPeriodRequests[days] }
        if let task = existingTask {
            // DEBUG LOG: print("⏳ [In-flight Request] Waiting for existing period fetch for \(days) days")
            return try await task.value
        }

        // Create new fetch task
        let fetchTask = Task<[FoodEntry], Error> {
            let calendar = Calendar.current
            let today = Date()
            let startOfToday = calendar.startOfDay(for: today)
            guard let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)?.addingTimeInterval(-0.001) else {
                #if DEBUG
                print("❌ Failed to calculate end of today")
                #endif
                return []
            }
            let endDate = endOfToday
            guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else {
                #if DEBUG
                print("❌ Failed to calculate start date for \(days) days ago")
                #endif
                return []
            }
            let queryStart = calendar.startOfDay(for: startDate)

            let snapshot = try await withRetry {
                try await self.db.collection("users").document(userId)
                    .collection("foodEntries")
                    .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: queryStart))
                    .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
                    .order(by: "date", descending: true)
                    .getDocuments()
            }

            let entries = snapshot.documents.compactMap { doc -> FoodEntry? in
                // Use Firestore's native Codable decoder for safe, crash-proof parsing
                do {
                    return try doc.data(as: FoodEntry.self)
                } catch {
                    #if DEBUG
                    print("⚠️ Skipping corrupt entry \(doc.documentID): \(error.localizedDescription)")
                    #endif
                    return nil
                }
            }

            // Store in cache and remove from in-flight (async-safe with DispatchQueue)
            self.cacheQueue.sync {
                self.periodCache[days] = (entries, Date())

                // Evict oldest entries if cache exceeds size limit
                if self.periodCache.count > self.maxPeriodCacheSize {
                    // Sort by timestamp and remove oldest entries
                    let sortedEntries = self.periodCache.sorted { $0.value.timestamp < $1.value.timestamp }
                    let entriesToRemove = sortedEntries.prefix(self.periodCache.count - self.maxPeriodCacheSize)
                    for (key, _) in entriesToRemove {
                        self.periodCache.removeValue(forKey: key)
                    }
                }

                self.inFlightPeriodRequests.removeValue(forKey: days)
            }

            return entries
        }

        // Register the in-flight request
        cacheQueue.sync {
            inFlightPeriodRequests[days] = fetchTask
        }

        return try await fetchTask.value
    }

    // Get food entries within a specific date range (used by ReactionLogManager)
    // NOTE: Caller is responsible for passing correct date boundaries
    func getFoodEntriesInRange(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

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
                #if DEBUG
                print("⚠️ Skipping corrupt entry \(doc.documentID): \(error.localizedDescription)")
                #endif
                return nil
            }
        }
    }

    // Delete all food entries older than today (for clearing test data)
    func deleteOldFoodEntries() async throws {
        guard let userId = currentUser?.uid else { return }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Query for all entries before today (in local timezone)
        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: startOfToday))
            .getDocuments()

        // DEBUG LOG: print("🗑️ Deleting \(snapshot.documents.count) old food entries...")

        // Delete each old entry
        for document in snapshot.documents {
            try await document.reference.delete()
        }

        #if DEBUG
        print("✅ Deleted \(snapshot.documents.count) old food entries")
        #endif
    }

    func deleteFoodEntry(entryId: String) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId)
            .collection("foodEntries").document(entryId).delete()

        // Clear entire cache since we don't know which date this entry belongs to - thread-safe
        // Also cancel all in-flight requests
        cacheQueue.sync {
            foodEntriesCache.removeAll()
            periodCache.removeAll()
            inFlightFoodEntriesRequests.values.forEach { $0.cancel() }
            inFlightFoodEntriesRequests.removeAll()
            inFlightPeriodRequests.values.forEach { $0.cancel() }
            inFlightPeriodRequests.removeAll()
        }
        // DEBUG LOG: print("🗑️ Cleared all food entries cache after deletion")
        // DEBUG LOG: print("🗑️ Cleared period cache after deletion")

        // Notify that food diary was updated
        await MainActor.run {
        // DEBUG LOG: print("📢 Posting foodDiaryUpdated notification after deletion...")
            NotificationCenter.default.post(name: .foodDiaryUpdated, object: nil)
        }
    }

    /// Scan all food entries and delete corrupt ones that can't be decoded
    /// Returns the count of deleted corrupt entries
    func cleanupCorruptFoodEntries() async throws -> Int {
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to cleanup entries"])
        }

        #if DEBUG
        print("🔍 Scanning all food entries for corrupt data...")

        // Get ALL food entries (no date filter)
        #endif
        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .getDocuments()

        #if DEBUG
        print("📄 Found \(snapshot.documents.count) total food entries")

        #endif
        var corruptEntries: [String] = []

        // Test each entry to see if it can be decoded
        for doc in snapshot.documents {
            do {
                _ = try doc.data(as: FoodEntry.self)
                // Successfully decoded - this entry is fine
            } catch {
                // Failed to decode - this entry is corrupt
                #if DEBUG
                print("❌ Corrupt entry found: \(doc.documentID)")
                print("   Error: \(error.localizedDescription)")
                #endif
                corruptEntries.append(doc.documentID)
            }
        }

        if corruptEntries.isEmpty {
            #if DEBUG
            print("✅ No corrupt entries found!")
            #endif
            return 0
        }

        #if DEBUG
        print("🗑️ Deleting \(corruptEntries.count) corrupt entries...")

        // Delete all corrupt entries
        #endif
        for docId in corruptEntries {
            try await db.collection("users").document(userId)
                .collection("foodEntries").document(docId).delete()
            #if DEBUG
            print("   ✓ Deleted: \(docId)")
            #endif
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

        #if DEBUG
        print("✅ Cleanup complete! Deleted \(corruptEntries.count) corrupt entries")
        #endif
        return corruptEntries.count
    }
    
    // MARK: - Food Reactions

    func saveReaction(_ reaction: FoodReaction) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            #if DEBUG
            print("⚠️ saveReaction: No user authenticated - cannot save reaction")
            #endif
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save reactions"])
        }

        // DEBUG LOG: print("💾 Saving reaction to Firebase for user: \(userId)")
        let reactionData = reaction.toDictionary()
        try await db.collection("users").document(userId)
            .collection("reactions").document(reaction.id.uuidString).setData(reactionData)
        #if DEBUG
        print("✅ Reaction saved successfully")
        #endif
    }

    // MARK: - Reaction Log

    /// Get all reaction logs for a user
    func getReactionLogs(userId: String) async throws -> [ReactionLogEntry] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("reactionLogs")
            .order(by: "reactionDate", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { doc in
            try doc.data(as: ReactionLogEntry.self)
        }
    }

    /// Save a new reaction log entry
    func saveReactionLog(_ entry: ReactionLogEntry) async throws -> ReactionLogEntry {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save reaction logs"])
        }

        // Create a new document reference to get an ID
        let docRef = db.collection("users").document(userId)
            .collection("reactionLogs").document()

        // Create entry with the Firebase-generated ID
        var entryWithId = entry
        entryWithId.id = docRef.documentID

        // Save to Firestore with retry logic
        try await withRetry {
            try docRef.setData(from: entryWithId)
        }

        #if DEBUG
        print("✅ Reaction log saved successfully with ID: \(docRef.documentID)")
        #endif
        return entryWithId
    }

    /// Delete a reaction log entry
    func deleteReactionLog(entryId: String) async throws {
        guard let userId = currentUser?.uid else { return }

        try await db.collection("users").document(userId)
            .collection("reactionLogs").document(entryId).delete()

        #if DEBUG
        print("✅ Reaction log deleted successfully")
        #endif
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

        let entries = try snapshot.documents.compactMap { doc in
            try doc.data(as: FoodEntry.self)
        }

        #if DEBUG
        print("📊 Found \(entries.count) food entries between \(startDate) and \(endDate)")
        #endif
        return entries
    }

    // MARK: - Use By Inventory

    func addUseByItem(_ item: UseByInventoryItem) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add use by items"])
        }

        try await addUseByItemHelper(item, userId: userId)
    }

    // Local storage helpers
    private func saveUseByItemLocally(_ item: UseByInventoryItem) {
        var localItems = getLocalUseByItems()
        localItems.append(item)
        if let encoded = try? JSONEncoder().encode(localItems) {
            UserDefaults.standard.set(encoded, forKey: "localUseByItems")
        }
    }

    private func getLocalUseByItems() -> [UseByInventoryItem] {
        guard let data = UserDefaults.standard.data(forKey: "localUseByItems"),
              let items = try? JSONDecoder().decode([UseByInventoryItem].self, from: data) else {
            return []
        }
        return items
    }

    private func addUseByItemHelper(_ item: UseByInventoryItem, userId: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

        try await db.collection("users").document(userId)
            .collection("useByInventory").document(item.id).setData(dict)
    }

    func getUseByItems() async throws -> [UseByInventoryItem] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view use by items"])
        }

        return try await getUseByItemsHelper(userId: userId)
    }

    private func getUseByItemsHelper(userId: String) async throws -> [UseByInventoryItem] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("useByInventory")
            .order(by: "expiryDate", descending: false)
            .getDocuments()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return snapshot.documents.compactMap { doc in
            guard let data = try? JSONSerialization.data(withJSONObject: doc.data(), options: []) else { return nil }
            return try? decoder.decode(UseByInventoryItem.self, from: data)
        }
    }

    func updateUseByItem(_ item: UseByInventoryItem) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update use by items"])
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        var dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]


        if item.notes == nil {
            dict["notes"] = FieldValue.delete()
        }
        if item.brand == nil {
            dict["brand"] = FieldValue.delete()
        }
        if item.imageURL == nil {
            dict["imageURL"] = FieldValue.delete()
        }

        try await db.collection("users").document(userId)
            .collection("useByInventory").document(item.id).setData(dict, merge: true)
        #if DEBUG
        print("✅ updateUseByItem: Successfully updated item in Firebase \(item.id)")
        #endif
    }

    func deleteUseByItem(itemId: String) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete use by items"])
        }

        try await db.collection("users").document(userId)
            .collection("useByInventory").document(itemId).delete()
        #if DEBUG
        print("✅ deleteUseByItem: Successfully deleted item from Firebase \(itemId)")
        #endif
    }

    func clearUseByInventory() async throws {
        ensureAuthStateLoaded()

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
        let cacheKey = query.lowercased().trimmingCharacters(in: .whitespaces) as NSString

        // Check cache first - instant results!
        if let cached = searchCache.object(forKey: cacheKey) {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpirationSeconds {
        // DEBUG LOG: print("⚡️ Cache HIT - instant results for '\(query)' (cached \(Int(age))s ago)")
                return cached.results
            } else {
                // Cache expired, remove it
                searchCache.removeObject(forKey: cacheKey)
            }
        }

        // DEBUG LOG: print("🔍 Cache MISS - fetching '\(query)' from server...")

        // Use Algolia for all searches - it already searches all indices (user-added, AI-enhanced, AI-manual, foods)
        // This is MUCH faster than making 4 separate Firestore queries
        let limitedResults = try await searchMainDatabase(query: query)

        // Store in cache for next time (NSCache auto-manages memory)
        searchCache.setObject(
            SearchCacheEntry(results: limitedResults, timestamp: Date()),
            forKey: cacheKey
        )
        // DEBUG LOG: print("💾 Cached \(limitedResults.count) results for '\(query)'")

        return limitedResults
    }

    /// Search main food database via Direct Algolia SDK (instant search)
    /// Previously used Cloud Function which added 100-500ms latency
    private func searchMainDatabase(query: String) async throws -> [FoodSearchResult] {
        // Use direct Algolia SDK for instant results (~300ms faster than Cloud Function)
        return try await AlgoliaSearchManager.shared.search(query: query)
    }

    /// Clear the search cache (useful for testing or memory management)
    func clearSearchCache() {
        searchCache.removeAllObjects()
        AlgoliaSearchManager.shared.clearCache()
        // DEBUG LOG: print("🗑️ Search cache cleared")
    }

    /// Pre-warm cache with popular searches for instant results
    func prewarmSearchCache() async {
        let popularSearches = ["chicken", "milk", "bread", "cheese", "apple", "banana"]
        #if DEBUG
        print("🔥 Pre-warming cache with popular searches...")
        #endif

        for search in popularSearches {
            do {
                _ = try await searchFoods(query: search)
            } catch {
                #if DEBUG
                print("⚠️ Failed to cache '\(search)': \(error)")
                #endif
            }
        }
        #if DEBUG
        print("✅ Cache pre-warming complete!")
        #endif
    }

    func searchFoodsByBarcode(barcode: String) async throws -> [FoodSearchResult] {
        // SQLite barcode search runs off main thread via actor
        if let localResult = await SQLiteFoodDatabase.shared.searchByBarcode(barcode) {
            #if DEBUG
            print("✅ Found barcode '\(barcode)' in local SQLite database (async!)")
            #endif
            return [localResult]
        }

        #if DEBUG
        print("⚠️ Barcode '\(barcode)' not found in local database")
        #endif
        return []
    }

    func getReactions() async throws -> [FoodReaction] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            #if DEBUG
            print("⚠️ getReactions: No user authenticated - returning empty array")
            #endif
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view reactions"])
        }

        // DEBUG LOG: print("📥 Loading reactions from Firebase for user: \(userId)")
        let snapshot = try await db.collection("users").document(userId)
            .collection("reactions")
            .order(by: "date", descending: true)
            .getDocuments()

        // DEBUG LOG: print("📄 Found \(snapshot.documents.count) reaction documents in Firebase")

        let reactions = snapshot.documents.compactMap { doc -> FoodReaction? in
            let data = doc.data()
        // DEBUG LOG: print("🔍 Parsing reaction document: \(doc.documentID)")
            if let reaction = FoodReaction.fromDictionary(data) {
                return reaction
            } else {
                #if DEBUG
                print("⚠️ Failed to parse reaction document \(doc.documentID)")
                print("   Data keys: \(data.keys.joined(separator: ", "))")
                #endif
                return nil
            }
        }
        #if DEBUG
        print("✅ Successfully loaded \(reactions.count) reactions from Firebase")
        #endif
        return reactions
    }

    func deleteReaction(reactionId: UUID) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            #if DEBUG
            print("⚠️ deleteReaction: No user authenticated - cannot delete reaction")
            #endif
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete reactions"])
        }

        // DEBUG LOG: print("🗑️ Deleting reaction from Firebase for user: \(userId)")
        try await db.collection("users").document(userId)
            .collection("reactions").document(reactionId.uuidString).delete()
        #if DEBUG
        print("✅ Reaction deleted successfully")
        #endif
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
        guard let userId = currentUser?.uid else { return }
        let itemData = item.toDictionary()
        try await db.collection("users").document(userId)
            .collection("useByItems").document(item.id.uuidString).setData(itemData)
    }

    func getUseByItems() async throws -> [UseByItem] {
        guard let userId = currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(userId)
            .collection("useByItems")
            .order(by: "expiryDate")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            UseByItem.fromDictionary(doc.data())
        }
    }

    // MARK: - Exercise Entries
    
    func saveExerciseEntry(_ entry: ExerciseEntry) async throws {
        guard let userId = currentUser?.uid else { return }
        let entryData = entry.toDictionary()
        try await db.collection("users").document(userId)
            .collection("exerciseEntries").document(entry.id.uuidString).setData(entryData)
    }
    
    func getExerciseEntries(for date: Date) async throws -> [ExerciseEntry] {
        guard let userId = currentUser?.uid else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            #if DEBUG
            print("❌ Failed to calculate end of day for exercise entries")
            #endif
            throw NSError(domain: "FirebaseManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])
        }
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("exerciseEntries")
            .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startOfDay))
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: endOfDay))
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            ExerciseEntry.fromDictionary(doc.data())
        }
    }
    
    // MARK: - Pending Food Verifications
    
    func savePendingVerification(_ verification: PendingFoodVerification) async throws {
        guard let userId = currentUser?.uid else { return }
        let verificationData = [
            "id": verification.id,
            "foodName": verification.foodName,
            "brandName": verification.brandName ?? "",
            "ingredients": verification.ingredients ?? "",
            "submittedAt": FirebaseFirestore.Timestamp(date: verification.submittedAt),
            "status": verification.status.rawValue,
            "userId": verification.userId
        ] as [String: Any]
        
        try await db.collection("users").document(userId)
            .collection("pendingVerifications").document(verification.id).setData(verificationData)
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

    // Resize and compress image for faster uploads
    @MainActor
    private func optimizeImage(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1200
        var newSize = image.size

        // Resize if too large
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let ratio = min(maxDimension / image.size.width, maxDimension / image.size.height)
            newSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Compress to JPEG at 50% quality for smaller file size
        return resizedImage?.jpegData(compressionQuality: 0.5)
    }

    // Upload multiple photos in parallel for better performance
    func uploadWeightPhotos(_ images: [UIImage]) async throws -> [String] {
        ensureAuthStateLoaded()

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

                    #if DEBUG
                    print("✅ Weight photo uploaded successfully: \(downloadURL.absoluteString)")
                    #endif
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
        ensureAuthStateLoaded()

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

        #if DEBUG
        print("✅ Weight photo uploaded successfully: \(downloadURL.absoluteString)")
        #endif
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

        #if DEBUG
        print("✅ Weight photo downloaded successfully")
        #endif
        return image
    }

    // MARK: - Use By Item Photo Upload
    func uploadUseByItemPhoto(_ image: UIImage) async throws -> String {
        ensureAuthStateLoaded()

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

        #if DEBUG
        print("✅ Use By item photo uploaded successfully: \(downloadURL.absoluteString)")
        #endif
        return downloadURL.absoluteString
    }

    func saveWeightEntry(_ entry: WeightEntry) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save weight entries"])
        }

        var entryData: [String: Any] = [
            "id": entry.id.uuidString,
            "weight": entry.weight,
            "date": FirebaseFirestore.Timestamp(date: entry.date),
            "bmi": entry.bmi as Any,
            "note": entry.note as Any
        ]

        // Add optional fields
        if let photoURL = entry.photoURL {
            entryData["photoURL"] = photoURL
        }
        if let photoURLs = entry.photoURLs {
            entryData["photoURLs"] = photoURLs
        }
        if let waistSize = entry.waistSize {
            entryData["waistSize"] = waistSize
        }
        if let dressSize = entry.dressSize {
            entryData["dressSize"] = dressSize
        }

        try await db.collection("users").document(userId)
            .collection("weightHistory").document(entry.id.uuidString).setData(entryData)
        #if DEBUG
        print("✅ Weight entry saved successfully")
        // Notify listeners that weight history changed
        #endif
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .weightHistoryUpdated, object: nil, userInfo: ["entry": entry])
        }
    }

    func getWeightHistory() async throws -> [WeightEntry] {
        ensureAuthStateLoaded()

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

        #if DEBUG
        print("✅ Loaded \(entries.count) weight entries from Firebase")
        #endif
        return entries
    }

    func deleteWeightEntry(id: UUID) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete weight entries"])
        }

        try await db.collection("users").document(userId)
            .collection("weightHistory").document(id.uuidString).delete()
        #if DEBUG
        print("✅ Weight entry deleted successfully")
        #endif
    }

    // MARK: - User Settings (Height, Goal Weight, Caloric Goal)

    func saveUserSettings(height: Double?, goalWeight: Double?, caloricGoal: Int? = nil, exerciseGoal: Int? = nil, stepGoal: Int? = nil) async throws {
        ensureAuthStateLoaded()

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

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
        #if DEBUG
        print("✅ User settings saved successfully")

        #endif
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
        ensureAuthStateLoaded()

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
    func getUserAllergensWithCache() async -> [Allergen] {
        // Check if cache is still valid
        if let lastFetched = allergensLastFetched,
           Date().timeIntervalSince(lastFetched) < allergenCacheExpirationSeconds,
           !cachedUserAllergens.isEmpty {
        // DEBUG LOG: print("⚡ Using cached allergens: \(cachedUserAllergens.count) items")
            return cachedUserAllergens
        }

        // Cache expired or empty - fetch fresh
        do {
        // DEBUG LOG: print("🔄 Fetching fresh allergens from Firebase")
            let settings = try await getUserSettings()
            return settings.allergens ?? []
        } catch {
            #if DEBUG
            print("❌ Failed to load allergens: \(error.localizedDescription)")
            // Return cached allergens even if expired, better than nothing
            #endif
            return cachedUserAllergens
        }
    }

    func saveMacroPercentages(protein: Int, carbs: Int, fat: Int) async throws {
        ensureAuthStateLoaded()

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
        #if DEBUG
        print("✅ Macro percentages saved successfully")
        #endif
    }

    // MARK: - Macro Management (Customizable Macros)

    func saveMacroGoals(_ macroGoals: [MacroGoal]) async throws {
        ensureAuthStateLoaded()

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

        let data: [String: Any] = [
            "macroGoals": macroGoalsData
        ]

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)

        let descriptions = macroGoals.map { goal in
            if let percentage = goal.percentage {
                return "\(goal.macroType.displayName): \(percentage)%"
            } else if let directTarget = goal.directTarget {
                return "\(goal.macroType.displayName): \(Int(directTarget))g"
            } else {
                return "\(goal.macroType.displayName)"
            }
        }
        #if DEBUG
        print("✅ Macro goals saved successfully: \(descriptions)")
        #endif
    }

    func getMacroGoals() async throws -> [MacroGoal] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view macro goals"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data() else {
            // No settings found, return defaults
            #if DEBUG
            print("ℹ️ No macro goals found, returning defaults (P 30%, C 40%, F 30%, Fibre 30g)")
            #endif
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
                #if DEBUG
                print("ℹ️ Loaded \(macroGoals.count) macro goals from Firebase")
                #endif
                return macroGoals
            }
        }

        // Backwards compatibility: Try to load old protein/carbs/fat percentages only
        if let proteinPercent = data["proteinPercent"] as? Int,
           let carbsPercent = data["carbsPercent"] as? Int,
           let fatPercent = data["fatPercent"] as? Int {
            #if DEBUG
            print("ℹ️ Migrating old macro percentages to new 4-macro structure (P:\(proteinPercent)%, C:\(carbsPercent)%, F:\(fatPercent)% + Fibre 30g)")
            #endif
            let migratedMacros = [
                MacroGoal(macroType: .protein, percentage: proteinPercent),
                MacroGoal(macroType: .carbs, percentage: carbsPercent),
                MacroGoal(macroType: .fat, percentage: fatPercent),
                MacroGoal(macroType: .fiber, directTarget: 30.0) // Add default fibre
            ]

            // Automatically migrate to new structure
            try? await saveMacroGoals(migratedMacros)

            return migratedMacros
        }

        // No data found at all, return defaults
        #if DEBUG
        print("ℹ️ No macro data found, returning defaults (P 30%, C 40%, F 30%, Fibre 30g)")
        #endif
        return MacroGoal.defaultMacros
    }

    func saveAllergens(_ allergens: [Allergen]) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save allergens"])
        }

        let allergenStrings = allergens.map { $0.rawValue }
        let data: [String: Any] = ["allergens": allergenStrings]

        try await withRetry {
            try await self.db.collection("users").document(userId)
                .collection("settings").document("preferences").setData(data, merge: true)
        }

        #if DEBUG
        print("✅ Allergens saved successfully")
        #endif
    }

    // MARK: - Fasting Tracking

    func saveFastingState(isFasting: Bool, startTime: Date?, goal: Int, notificationsEnabled: Bool, reminderInterval: Int) async throws {
        ensureAuthStateLoaded()

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
        #if DEBUG
        print("✅ Fasting state saved successfully")
        #endif
    }

    func getFastingState() async throws -> (isFasting: Bool, startTime: Date?, goal: Int, notificationsEnabled: Bool, reminderInterval: Int) {
        ensureAuthStateLoaded()

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
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to submit foods"])
        }

        let foodId = food["id"] as? String ?? UUID().uuidString
        try await db.collection("users").document(userId)
            .collection("submittedFoods").document(foodId).setData(food, merge: true)
        #if DEBUG
        print("✅ User submitted food saved successfully")
        #endif
    }

    func getUserSubmittedFoods() async throws -> [[String: Any]] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view submitted foods"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("submittedFoods").getDocuments()

        return snapshot.documents.map { $0.data() }
    }

    func saveUserIngredients(foodKey: String, ingredients: String) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save ingredients"])
        }

        let data: [String: Any] = [
            "ingredients": ingredients,
            "timestamp": FirebaseFirestore.Timestamp(date: Date())
        ]

        try await db.collection("users").document(userId)
            .collection("customIngredients").document(foodKey).setData(data, merge: true)
        #if DEBUG
        print("✅ User ingredients saved successfully")
        #endif
    }

    func getUserIngredients(foodKey: String) async throws -> String? {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view ingredients"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("customIngredients").document(foodKey).getDocument()

        return document.data()?["ingredients"] as? String
    }

    func saveVerifiedFood(foodKey: String) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to verify foods"])
        }

        let data: [String: Any] = [
            "foodKey": foodKey,
            "timestamp": FirebaseFirestore.Timestamp(date: Date())
        ]

        try await db.collection("users").document(userId)
            .collection("verifiedFoods").document(foodKey).setData(data)
        #if DEBUG
        print("✅ Verified food saved successfully")
        #endif
    }

    func getVerifiedFoods() async throws -> [String] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view verified foods"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("verifiedFoods").getDocuments()

        return snapshot.documents.compactMap { $0.data()["foodKey"] as? String }
    }

    // MARK: - User Enhanced Product Data

    func saveUserEnhancedProduct(data: [String: Any]) async throws {
        ensureAuthStateLoaded()

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

        #if DEBUG
        print("✅ User enhanced product data saved: \(productId)")
        #endif
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
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add foods"])
        }

        guard let foodName = food["foodName"] as? String else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name is required"])
        }

        // Check for profanity
        if containsProfanity(foodName) {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name contains inappropriate language. Please use appropriate terms."])
        }

        // Also check brand name if present
        if let brandName = food["brandName"] as? String, containsProfanity(brandName) {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Brand name contains inappropriate language. Please use appropriate terms."])
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

        #if DEBUG
        print("✅ User added food saved: \(foodId)")
        #endif
        return foodId
    }

    /// Save an AI-enhanced food to the global aiManuallyAdded collection (accessible by all users)
    /// This is used when a user uses the "Find with AI" feature to auto-fill ingredient data from trusted UK sources
    func saveAIEnhancedFood(_ food: [String: Any], sourceURL: String?, aiProductName: String?) async throws -> String {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add foods"])
        }

        guard let foodName = food["foodName"] as? String else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name is required"])
        }

        // Check for profanity
        if containsProfanity(foodName) {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Food name contains inappropriate language. Please use appropriate terms."])
        }

        // Also check brand name if present
        if let brandName = food["brandName"] as? String, containsProfanity(brandName) {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Brand name contains inappropriate language. Please use appropriate terms."])
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

        #if DEBUG
        print("✅ AI enhanced food saved: \(foodId)")
        #endif
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
            #if DEBUG
            print("❌ Invalid URL for Cloud Function search: \(urlString)")
            #endif
            throw NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            #if DEBUG
            print("❌ Cloud Function search failed")
            #endif
            return []
        }

        // Parse the JSON response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]] else {
            #if DEBUG
            print("❌ Failed to parse Cloud Function response")
            #endif
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
                micronutrientProfile: nil
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

    // MARK: - AI-Improved Foods

    /// Save AI-improved food data to Firebase
    func saveAIImprovedFood(originalFood: FoodSearchResult, enhancedData: [String: Any]) async throws -> String {
        ensureAuthStateLoaded()

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
        #if DEBUG
        print("✅ AI-enhanced food saved to Firebase: \(foodId)")

        #endif
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

    /// Profanity filter - basic implementation
    private func containsProfanity(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Common profanity list (basic implementation)
        let profanityList = [
            "fuck", "shit", "damn", "bitch", "ass", "bastard", "cunt",
            "dick", "piss", "cock", "whore", "slut", "wanker", "bollocks",
            "arse", "bugger", "bloody", "crap", "twat", "prick", "tosser"
        ]

        // Check for exact matches or words containing profanity
        for profanity in profanityList {
            if lowercased.contains(profanity) {
                return true
            }
        }

        return false
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

        let requestBody: [String: Any] = [
            "data": [
                "foodName": food.name,
                "brandName": food.brand ?? "",
                "foodId": food.id,
                "barcode": food.barcode ?? "",
                "userId": currentUser?.uid ?? "anonymous",
                "userEmail": currentUser?.email ?? "anonymous",
                "recipientEmail": "contact@nutrasafe.co.uk"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            #if DEBUG
            print("❌ Invalid response from server")
            #endif
            throw NSError(domain: "Invalid Response", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        guard httpResponse.statusCode == 200 else {
            #if DEBUG
            print("❌ Server returned status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            #endif
            throw NSError(domain: "Server Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned error code \(httpResponse.statusCode)"])
        }

        // Parse response to ensure success
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: Any],
           let success = result["success"] as? Bool,
           success {
            #if DEBUG
            print("✅ Team notified about incomplete food: \(food.name)")
            #endif
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

        // Add to incomplete_foods collection
        // Use sanitized food name as document ID for easier identification
        let sanitizedName = food.name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ".", with: "_")
            .prefix(100) // Firestore doc ID max length is 1500 chars, but keep it readable
        let docRef = db.collection("incomplete_foods").document(String(sanitizedName))
        try await docRef.setData(foodData, merge: true) // Use merge to avoid overwriting if name collision

        #if DEBUG
        print("✅ Incomplete food saved to Firestore: \(food.name) (ID: \(docRef.documentID))")
        #endif
    }
 

    // MARK: - Legacy Fasting Methods (Replaced by New Session-Based System)
    
    @available(*, deprecated, message: "Use saveFastingSession instead")
    func saveFastRecord(_ record: [String: Any]) async throws -> String {
        // Convert old FastRecord format to new FastingSession
        guard let _ = record["id"] as? String,
              let startTime = record["startTime"] as? Date,
              let endTime = record["endTime"] as? Date,
              let _ = record["durationHours"] as? Double,
              let goalHours = record["goalHours"] as? Double else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid FastRecord format"])
        }
        
        let session = FastingSession(
            userId: "", // Will be set by saveFastingSession
            planId: nil,
            startTime: startTime,
            endTime: endTime,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .completed,
            targetDurationHours: Int(goalHours),
            notes: record["notes"] as? String,
            createdAt: Date(),
            archived: false
        )
        return try await saveFastingSession(session)
    }

    @available(*, deprecated, message: "Use getFastingSessions instead")
    func getFastHistory() async throws -> [[String: Any]] {
        let sessions = try await getFastingSessions()
        return sessions.map { session in
            [
                "id": session.id ?? UUID().uuidString,
                "startTime": session.startTime,
                "endTime": session.endTime ?? Date(),
                "durationHours": session.actualDurationHours,
                "goalHours": Double(session.targetDurationHours),
                "withinTarget": session.completionStatus == .completed && session.actualDurationHours >= Double(session.targetDurationHours),
                "notes": session.notes ?? ""
            ]
        }
    }

    @available(*, deprecated, message: "Use deleteFastingSession instead")
    func deleteFastRecord(id: String) async throws {
        try await deleteFastingSession(id: id)
    }

    func saveFastingStreakSettings(_ settings: [String: Any]) async throws {
        ensureAuthStateLoaded()
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
        ensureAuthStateLoaded()
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
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting plans"])
        }
        print("      🔥 FirebaseManager.saveFastingPlan")
        print("         UserID: \(userId)")
        print("         Plan ID: \(plan.id ?? "nil - will generate new UUID")")
        print("         Plan name: '\(plan.name)'")
        print("         Active: \(plan.active)")

        let docRef = db.collection("users").document(userId)
            .collection("fastingPlans").document(plan.id ?? UUID().uuidString)

        let path = "users/\(userId)/fastingPlans/\(docRef.documentID)"
        print("         Saving to path: \(path)")

        try docRef.setData(from: plan, merge: true)
        print("         ✅ Successfully saved to Firebase")
        return docRef.documentID
    }

    func getFastingPlans() async throws -> [FastingPlan] {
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting plans"])
        }
        print("      🔥 FirebaseManager.getFastingPlans")
        print("         UserID: \(userId)")
        let path = "users/\(userId)/fastingPlans"
        print("         Fetching from path: \(path)")

        let snapshot = try await db.collection("users").document(userId)
            .collection("fastingPlans").order(by: "created_at", descending: true).getDocuments()

        print("         Raw document count: \(snapshot.documents.count)")

        var plans: [FastingPlan] = []
        for (index, doc) in snapshot.documents.enumerated() {
            do {
                let plan = try doc.data(as: FastingPlan.self)
                print("         ✅ Decoded plan \(index + 1): '\(plan.name)' (ID: \(plan.id ?? "nil"))")
                plans.append(plan)
            } catch {
                print("         ❌ Failed to decode plan \(index + 1) (docID: \(doc.documentID)): \(error.localizedDescription)")
            }
        }

        print("         Returning \(plans.count) successfully decoded plans")
        return plans
    }

    func updateFastingPlan(_ plan: FastingPlan) async throws {
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update fasting plans"])
        }
        guard let planId = plan.id else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Plan ID is required for updates"])
        }
        let docRef = db.collection("users").document(userId)
            .collection("fastingPlans").document(planId)
        try docRef.setData(from: plan, merge: true)
    }

    func deleteFastingPlan(id: String) async throws {
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete fasting plans"])
        }
        try await db.collection("users").document(userId)
            .collection("fastingPlans").document(id).delete()
    }

    func saveFastingSession(_ session: FastingSession) async throws -> String {
        print("🔥 FirebaseManager.saveFastingSession() called")
        print("   📋 Session data - userId: '\(session.userId)', planId: '\(session.planId ?? "nil")', target: \(session.targetDurationHours)h")

        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            print("   ❌ currentUser?.uid is nil - user not authenticated!")
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save fasting sessions"])
        }

        print("   ✅ Current authenticated userId: '\(userId)'")

        let docRef = db.collection("users").document(userId)
            .collection("fastingSessions").document(session.id ?? UUID().uuidString)

        print("   📍 Firestore path: users/\(userId)/fastingSessions/\(docRef.documentID)")
        print("   💾 Writing to Firestore...")

        try docRef.setData(from: session, merge: true)

        print("   ✅ Firestore write successful!")

        await MainActor.run {
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        }

        print("   📢 Posted .fastHistoryUpdated notification")

        return docRef.documentID
    }

    func getFastingSessions() async throws -> [FastingSession] {
        print("📥 getFastingSessions() called")
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            print("   ❌ No authenticated user")
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view fasting sessions"])
        }

        print("   👤 Fetching sessions for userId: '\(userId)'")
        print("   📍 Path: users/\(userId)/fastingSessions")

        let snapshot = try await db.collection("users").document(userId)
            .collection("fastingSessions").order(by: "start_time", descending: true).getDocuments()

        print("   📊 Raw documents retrieved: \(snapshot.documents.count)")

        let sessions = snapshot.documents.compactMap { try? $0.data(as: FastingSession.self) }

        print("   ✅ Successfully decoded \(sessions.count) sessions")
        for (index, session) in sessions.enumerated() {
            print("      Session \(index + 1): ID=\(session.id ?? "nil"), userId=\(session.userId), status=\(session.completionStatus)")
        }

        return sessions
    }

    func updateFastingSession(_ session: FastingSession) async throws {
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update fasting sessions"])
        }
        guard let sessionId = session.id else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session ID is required for updates"])
        }
        let docRef = db.collection("users").document(userId)
            .collection("fastingSessions").document(sessionId)
        try docRef.setData(from: session, merge: true)
        await MainActor.run {
            NotificationCenter.default.post(name: .fastHistoryUpdated, object: nil)
        }
    }

    func deleteFastingSession(id: String) async throws {
        ensureAuthStateLoaded()
        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete fasting sessions"])
        }
        try await db.collection("users").document(userId)
            .collection("fastingSessions").document(id).delete()
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
}

// MARK: - Response Models for Food Search

struct FoodSearchResponse: Decodable {
    let foods: [FoodSearchResult]
}

extension FirebaseManager {
    func getPremiumOverride() async throws -> Bool {
        ensureAuthStateLoaded()
        // Domain-based override for staff/users with nutrasafe.co.uk emails
        if let email = currentUser?.email?.lowercased(),
           let domain = email.split(separator: "@").last,
           domain == "nutrasafe.co.uk" {
            return true
        }
        guard let userId = currentUser?.uid else { return false }
        let doc = try await Firestore.firestore()
            .collection("users").document(userId)
            .collection("settings").document("preferences")
            .getDocument()
        let value = doc.data()? ["premiumOverride"] as? Bool ?? false
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
        ensureAuthStateLoaded()
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
        ensureAuthStateLoaded()
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
