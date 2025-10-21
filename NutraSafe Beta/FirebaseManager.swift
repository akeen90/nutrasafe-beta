import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private lazy var db = Firestore.firestore()
    private lazy var auth = Auth.auth()

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
        
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            // Ensure @Published properties change on the main actor
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
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
    
    // MARK: - Authentication

    func signOut() throws {
        try auth.signOut()

        // Clear any residual UserDefaults data to prevent leakage between accounts
        UserDefaults.standard.removeObject(forKey: "userWeight")
        UserDefaults.standard.removeObject(forKey: "goalWeight")
        UserDefaults.standard.removeObject(forKey: "userHeight")
        UserDefaults.standard.removeObject(forKey: "weightHistory")
        print("🧹 Cleared local UserDefaults data on sign out")

        // Clear ReactionManager data to prevent leakage between accounts
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

        print("🗑️ Starting to delete all user data for user: \(userId)")

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
            print("   Deleting \(count) documents from \(collection)...")

            for document in snapshot.documents {
                try await document.reference.delete()
            }

            totalDeleted += count
            print("   ✅ Successfully deleted \(count) documents from \(collection)")
        }

        print("✅ All user data deleted successfully - Total: \(totalDeleted) documents deleted")

        // Notify observers that all data has been cleared
        await MainActor.run {
            self.objectWillChange.send()
        }
    }

    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String) async throws {
        initializeFirebaseServices()
        let result = try await auth.signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String) async throws {
        initializeFirebaseServices()
        let result = try await auth.createUser(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
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
        try await db.collection("users").document(userId)
            .collection("foodEntries").document(entry.id).setData(entryData)

        // Invalidate cache for this date
        invalidateFoodEntriesCache(for: entry.date, userId: userId)
    }

    /// Invalidate food entries cache for a specific date
    private func invalidateFoodEntriesCache(for date: Date, userId: String) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = "\(userId)_\(dateFormatter.string(from: startOfDay))"

        foodEntriesCache.removeValue(forKey: dateKey)
        print("🗑️ Invalidated food entries cache for \(dateFormatter.string(from: startOfDay))")
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

        // Create cache key from user ID and date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = "\(userId)_\(dateFormatter.string(from: startOfDay))"

        // Check cache first - instant results!
        if let cached = foodEntriesCache[dateKey] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < foodEntriesCacheExpirationSeconds {
                print("⚡️ Food Entries Cache HIT - instant load for \(dateFormatter.string(from: startOfDay)) (cached \(Int(age))s ago)")
                return cached.entries
            } else {
                // Cache expired, remove it
                foodEntriesCache.removeValue(forKey: dateKey)
                print("🔄 Food Entries Cache EXPIRED - refreshing for \(dateFormatter.string(from: startOfDay))")
            }
        }

        print("🔍 Food Entries Cache MISS - fetching from Firestore for \(dateFormatter.string(from: startOfDay))")

        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startOfDay))
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: endOfDay))
            .getDocuments()

        let entries = snapshot.documents.compactMap { doc in
            FoodEntry.fromDictionary(doc.data())
        }

        // Store in cache for next time
        foodEntriesCache[dateKey] = FoodEntriesCacheEntry(
            entries: entries,
            timestamp: Date()
        )
        print("💾 Cached \(entries.count) food entries for \(dateFormatter.string(from: startOfDay))")

        return entries
    }

    // Get food entries for the past N days for nutritional analysis
    func getFoodEntriesForPeriod(days: Int) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }

        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            FoodEntry.fromDictionary(doc.data())
        }
    }

    // Get food entries within a specific date range for calendar view
    func getFoodEntriesInRange(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }

        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: FirebaseFirestore.Timestamp(date: endDate))
            .order(by: "date", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            FoodEntry.fromDictionary(doc.data())
        }
    }

    // Delete all food entries older than today (for clearing test data)
    func deleteOldFoodEntries() async throws {
        guard let userId = currentUser?.uid else { return }

        // Get the start of today
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Query for all entries before today
        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: startOfToday))
            .getDocuments()

        print("🗑️ Deleting \(snapshot.documents.count) old food entries...")

        // Delete each old entry
        for document in snapshot.documents {
            try await document.reference.delete()
        }

        print("✅ Deleted \(snapshot.documents.count) old food entries")
    }

    func deleteFoodEntry(entryId: String) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId)
            .collection("foodEntries").document(entryId).delete()

        // Clear entire cache since we don't know which date this entry belongs to
        foodEntriesCache.removeAll()
        print("🗑️ Cleared all food entries cache after deletion")
    }
    
    // MARK: - Food Reactions

    func saveReaction(_ reaction: FoodReaction) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            print("⚠️ saveReaction: No user authenticated - cannot save reaction")
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save reactions"])
        }

        print("💾 Saving reaction to Firebase for user: \(userId)")
        let reactionData = reaction.toDictionary()
        try await db.collection("users").document(userId)
            .collection("reactions").document(reaction.id.uuidString).setData(reactionData)
        print("✅ Reaction saved successfully")
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

        // Handle nil values explicitly - Firebase merge doesn't delete fields when they're nil
        // If openedDate is nil, explicitly delete it from Firebase
        if item.openedDate == nil {
            dict["openedDate"] = FieldValue.delete()
        }
        if item.useWithinDaysOfOpening == nil {
            dict["useWithinDaysOfOpening"] = FieldValue.delete()
        }
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
        print("✅ updateUseByItem: Successfully updated item in Firebase \(item.id)")
    }

    func deleteUseByItem(itemId: String) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete use by items"])
        }

        try await db.collection("users").document(userId)
            .collection("useByInventory").document(itemId).delete()
        print("✅ deleteUseByItem: Successfully deleted item from Firebase \(itemId)")
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
                print("⚡️ Cache HIT - instant results for '\(query)' (cached \(Int(age))s ago)")
                return cached.results
            } else {
                // Cache expired, remove it
                searchCache.removeObject(forKey: cacheKey)
            }
        }

        print("🔍 Cache MISS - fetching '\(query)' from server...")

        // Search in both main database and user-added foods in parallel
        async let mainResults = searchMainDatabase(query: query)
        async let userAddedResults = try searchUserAddedFoods(query: query)

        // Wait for both searches to complete
        let (mainFoods, userFoods) = try await (mainResults, userAddedResults)

        // Merge results - user-added foods first, then main database
        var mergedResults = userFoods
        mergedResults.append(contentsOf: mainFoods)

        print("🔍 Search results for '\(query)': \(userFoods.count) user-added + \(mainFoods.count) main database = \(mergedResults.count) total")

        // Store in cache for next time (NSCache auto-manages memory)
        searchCache.setObject(
            SearchCacheEntry(results: mergedResults, timestamp: Date()),
            forKey: cacheKey
        )
        print("💾 Cached \(mergedResults.count) results for '\(query)'")

        return mergedResults
    }

    /// Search main food database via SQLite (optimized async)
    private func searchMainDatabase(query: String) async throws -> [FoodSearchResult] {
        // SQLite search runs off main thread via actor
        let localResults = await SQLiteFoodDatabase.shared.searchFoods(query: query, limit: 20)

        if !localResults.isEmpty {
            print("✅ Found \(localResults.count) results in local SQLite database (async!)")
        } else {
            print("⚠️ No results found in local database for '\(query)'")
        }

        return localResults
    }

    /// Clear the search cache (useful for testing or memory management)
    func clearSearchCache() {
        searchCache.removeAllObjects()
        print("🗑️ Search cache cleared")
    }

    /// Pre-warm cache with popular searches for instant results
    func prewarmSearchCache() async {
        let popularSearches = ["chicken", "milk", "bread", "cheese", "apple", "banana"]
        print("🔥 Pre-warming cache with popular searches...")

        for search in popularSearches {
            do {
                _ = try await searchFoods(query: search)
            } catch {
                print("⚠️ Failed to cache '\(search)': \(error)")
            }
        }
        print("✅ Cache pre-warming complete!")
    }

    func searchFoodsByBarcode(barcode: String) async throws -> [FoodSearchResult] {
        // SQLite barcode search runs off main thread via actor
        if let localResult = await SQLiteFoodDatabase.shared.searchByBarcode(barcode) {
            print("✅ Found barcode '\(barcode)' in local SQLite database (async!)")
            return [localResult]
        }

        print("⚠️ Barcode '\(barcode)' not found in local database")
        return []
    }

    func getReactions() async throws -> [FoodReaction] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            print("⚠️ getReactions: No user authenticated - returning empty array")
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view reactions"])
        }

        print("📥 Loading reactions from Firebase for user: \(userId)")
        let snapshot = try await db.collection("users").document(userId)
            .collection("reactions")
            .order(by: "date", descending: true)
            .getDocuments()

        let reactions = snapshot.documents.compactMap { doc in
            FoodReaction.fromDictionary(doc.data())
        }
        print("✅ Loaded \(reactions.count) reactions from Firebase")
        return reactions
    }

    func deleteReaction(reactionId: UUID) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            print("⚠️ deleteReaction: No user authenticated - cannot delete reaction")
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete reactions"])
        }

        print("🗑️ Deleting reaction from Firebase for user: \(userId)")
        try await db.collection("users").document(userId)
            .collection("reactions").document(reactionId.uuidString).delete()
        print("✅ Reaction deleted successfully")
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
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
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
                  let submittedAtTimestamp = data["submittedAt"] as? FirebaseFirestore.Timestamp,
                  let userId = data["userId"] as? String else { return nil }
            
            return PendingFoodVerification(
                id: id,
                foodName: foodName,
                brandName: data["brandName"] as? String,
                ingredients: data["ingredients"] as? String,
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
                    // Optimize image
                    guard let imageData = self.optimizeImage(image) else {
                        throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
                    }

                    // Create unique filename
                    let filename = "\(UUID().uuidString).jpg"
                    let storageRef = Storage.storage().reference()
                    let photoRef = storageRef.child("weightPhotos/\(userId)/\(filename)")

                    // Upload image
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"

                    _ = try await photoRef.putDataAsync(imageData, metadata: metadata)

                    // Get download URL
                    let downloadURL = try await photoRef.downloadURL()
                    print("✅ Weight photo uploaded successfully: \(downloadURL.absoluteString)")
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

        // Optimize image
        guard let imageData = optimizeImage(image) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
        let photoRef = storageRef.child("weightPhotos/\(userId)/\(filename)")

        // Upload image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await photoRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await photoRef.downloadURL()
        print("✅ Weight photo uploaded successfully: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    func downloadWeightPhoto(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid photo URL"])
        }

        // Download image data from URL
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
        }

        print("✅ Weight photo downloaded successfully")
        return image
    }

    // MARK: - Use By Item Photo Upload
    func uploadUseByItemPhoto(_ image: UIImage) async throws -> String {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to upload photos"])
        }

        // Optimize image
        guard let imageData = optimizeImage(image) else {
            throw NSError(domain: "NutraSafe", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference()
        let photoRef = storageRef.child("useByItemPhotos/\(userId)/\(filename)")

        // Upload image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await photoRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await photoRef.downloadURL()
        print("✅ Use By item photo uploaded successfully: \(downloadURL.absoluteString)")
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
        print("✅ Weight entry saved successfully")
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
            guard let data = doc.data() as? [String: Any],
                  let idString = data["id"] as? String,
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

        print("✅ Loaded \(entries.count) weight entries from Firebase")
        return entries
    }

    func deleteWeightEntry(id: UUID) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete weight entries"])
        }

        try await db.collection("users").document(userId)
            .collection("weightHistory").document(id.uuidString).delete()
        print("✅ Weight entry deleted successfully")
    }

    // MARK: - User Settings (Height, Goal Weight, Caloric Goal)

    func saveUserSettings(height: Double?, goalWeight: Double?, caloricGoal: Int? = nil) async throws {
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

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
        print("✅ User settings saved successfully")
    }

    func getUserSettings() async throws -> (height: Double?, goalWeight: Double?, caloricGoal: Int?, proteinPercent: Int?, carbsPercent: Int?, fatPercent: Int?, allergens: [Allergen]?) {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view settings"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data() else {
            return (nil, nil, nil, nil, nil, nil, nil)
        }

        let height = data["height"] as? Double
        let goalWeight = data["goalWeight"] as? Double
        let caloricGoal = data["caloricGoal"] as? Int
        let proteinPercent = data["proteinPercent"] as? Int
        let carbsPercent = data["carbsPercent"] as? Int
        let fatPercent = data["fatPercent"] as? Int
        let allergens = (data["allergens"] as? [String])?.compactMap { Allergen(rawValue: $0) }

        // Cache allergens for fast access
        if let allergens = allergens {
            await MainActor.run {
                self.cachedUserAllergens = allergens
                self.allergensLastFetched = Date()
            }
        }

        return (height, goalWeight, caloricGoal, proteinPercent, carbsPercent, fatPercent, allergens)
    }

    // MARK: - Fast Allergen Access
    /// Get user allergens from cache if available, otherwise fetch from Firebase
    func getUserAllergensWithCache() async -> [Allergen] {
        // Check if cache is still valid
        if let lastFetched = allergensLastFetched,
           Date().timeIntervalSince(lastFetched) < allergenCacheExpirationSeconds,
           !cachedUserAllergens.isEmpty {
            print("⚡ Using cached allergens: \(cachedUserAllergens.count) items")
            return cachedUserAllergens
        }

        // Cache expired or empty - fetch fresh
        do {
            print("🔄 Fetching fresh allergens from Firebase")
            let settings = try await getUserSettings()
            return settings.allergens ?? []
        } catch {
            print("❌ Failed to load allergens: \(error.localizedDescription)")
            // Return cached allergens even if expired, better than nothing
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
        print("✅ Macro percentages saved successfully")
    }

    func saveAllergens(_ allergens: [Allergen]) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save allergens"])
        }

        let allergenStrings = allergens.map { $0.rawValue }
        let data: [String: Any] = ["allergens": allergenStrings]

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
        print("✅ Allergens saved successfully")
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
        print("✅ Fasting state saved successfully")
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
        print("✅ User submitted food saved successfully")
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
        print("✅ User ingredients saved successfully")
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
        print("✅ Verified food saved successfully")
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

        print("✅ User enhanced product data saved: \(productId)")
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

        // Generate unique food ID
        let foodId = "userFood_\(UUID().uuidString)"

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
            .setData(foodData)

        print("✅ User added food saved: \(foodId)")
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
                ingredients: ingredients,
                confidence: nil,
                isVerified: false, // User-added foods are unverified by default
                additives: nil,
                processingScore: nil,
                processingGrade: nil,
                processingLabel: nil
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

    /// Notify team about incomplete food information via email
    func notifyIncompleteFood(foodName: String, brandName: String) async throws {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/notifyIncompleteFood") else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "data": [
                "foodName": foodName,
                "brandName": brandName,
                "userId": currentUser?.uid ?? "anonymous",
                "userEmail": currentUser?.email ?? "anonymous"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Server Error", code: -1)
        }

        // Parse response to ensure success
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let result = json["result"] as? [String: Any],
           let success = result["success"] as? Bool,
           success {
            print("✅ Team notified about incomplete food: \(foodName)")
        } else {
            throw NSError(domain: "Notification failed", code: -1)
        }
    }
}

extension Notification.Name {
    static let useByInventoryUpdated = Notification.Name("useByInventoryUpdated")
    static let navigateToUseBy = Notification.Name("navigateToUseBy")
}

// MARK: - Response Models for Food Search

struct FoodSearchResponse: Decodable {
    let foods: [FoodSearchResult]
}
