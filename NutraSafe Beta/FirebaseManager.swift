import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private lazy var db = Firestore.firestore()
    private lazy var auth = Auth.auth()

    // MARK: - Search Cache
    private struct SearchCacheEntry {
        let results: [FoodSearchResult]
        let timestamp: Date
    }
    private var searchCache: [String: SearchCacheEntry] = [:]
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes

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
        Task { @MainActor in
            self.currentUser = nil
            self.isAuthenticated = false
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
    }
    
    func getFoodEntries(for date: Date) async throws -> [FoodEntry] {
        guard let userId = currentUser?.uid else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("foodEntries")
            .whereField("date", isGreaterThanOrEqualTo: FirebaseFirestore.Timestamp(date: startOfDay))
            .whereField("date", isLessThan: FirebaseFirestore.Timestamp(date: endOfDay))
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            FoodEntry.fromDictionary(doc.data())
        }
    }
    
    func deleteFoodEntry(entryId: String) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId)
            .collection("foodEntries").document(entryId).delete()
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

    // MARK: - Kitchen Inventory

    func addKitchenItem(_ item: KitchenInventoryItem) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to add kitchen items"])
        }

        try await addKitchenItemHelper(item, userId: userId)
    }

    // Local storage helpers
    private func saveKitchenItemLocally(_ item: KitchenInventoryItem) {
        var localItems = getLocalKitchenItems()
        localItems.append(item)
        if let encoded = try? JSONEncoder().encode(localItems) {
            UserDefaults.standard.set(encoded, forKey: "localKitchenItems")
        }
    }

    private func getLocalKitchenItems() -> [KitchenInventoryItem] {
        guard let data = UserDefaults.standard.data(forKey: "localKitchenItems"),
              let items = try? JSONDecoder().decode([KitchenInventoryItem].self, from: data) else {
            return []
        }
        return items
    }

    private func addKitchenItemHelper(_ item: KitchenInventoryItem, userId: String) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(item.id).setData(dict)
    }

    func getKitchenItems() async throws -> [KitchenInventoryItem] {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view kitchen items"])
        }

        return try await getKitchenItemsHelper(userId: userId)
    }

    private func getKitchenItemsHelper(userId: String) async throws -> [KitchenInventoryItem] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("kitchenInventory")
            .order(by: "expiryDate", descending: false)
            .getDocuments()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return snapshot.documents.compactMap { doc in
            guard let data = try? JSONSerialization.data(withJSONObject: doc.data(), options: []) else { return nil }
            return try? decoder.decode(KitchenInventoryItem.self, from: data)
        }
    }

    func updateKitchenItem(_ item: KitchenInventoryItem) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to update kitchen items"])
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(item.id).setData(dict, merge: true)
        print("✅ updateKitchenItem: Successfully updated item in Firebase \(item.id)")
    }

    func deleteKitchenItem(itemId: String) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to delete kitchen items"])
        }

        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(itemId).delete()
        print("✅ deleteKitchenItem: Successfully deleted item from Firebase \(itemId)")
    }

    func clearKitchenInventory() async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to clear kitchen inventory"])
        }

        let snapshot = try await db.collection("users").document(userId)
            .collection("kitchenInventory").getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.delete()
        }
    }

    // MARK: - Food Search Functions

    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        let cacheKey = query.lowercased().trimmingCharacters(in: .whitespaces)

        // Check cache first - instant results!
        if let cached = searchCache[cacheKey] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpirationSeconds {
                print("⚡️ Cache HIT - instant results for '\(query)' (cached \(Int(age))s ago)")
                return cached.results
            } else {
                // Cache expired, remove it
                searchCache.removeValue(forKey: cacheKey)
            }
        }

        print("🔍 Cache MISS - fetching '\(query)' from server...")

        // Search in Firebase Cloud Functions
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoods") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let startTime = Date()
        let (data, _) = try await URLSession.shared.data(for: request)
        let elapsed = Date().timeIntervalSince(startTime)

        let decoder = JSONDecoder()
        let response = try decoder.decode(FoodSearchResponse.self, from: data)

        // Store in cache for next time
        searchCache[cacheKey] = SearchCacheEntry(
            results: response.foods,
            timestamp: Date()
        )
        print("💾 Cached \(response.foods.count) results for '\(query)' (took \(Int(elapsed * 1000))ms)")

        return response.foods
    }

    /// Clear the search cache (useful for testing or memory management)
    func clearSearchCache() {
        searchCache.removeAll()
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
        // Search in Firebase Cloud Functions by barcode (internal DB first)
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoodByBarcode") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["barcode": barcode]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        let barcodeResponse = try decoder.decode(BarcodeSearchResponse.self, from: data)

        if let result = barcodeResponse.toFoodSearchResult() {
            return [result]
        }
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
    
    
    // MARK: - Kitchen Items
    
    func saveKitchenItem(_ item: KitchenItem) async throws {
        guard let userId = currentUser?.uid else { return }
        let itemData = item.toDictionary()
        try await db.collection("users").document(userId)
            .collection("kitchenItems").document(item.id.uuidString).setData(itemData)
    }
    
    func getKitchenItems() async throws -> [KitchenItem] {
        guard let userId = currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(userId)
            .collection("kitchenItems")
            .order(by: "expiryDate")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            KitchenItem.fromDictionary(doc.data())
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

    func saveWeightEntry(_ entry: WeightEntry) async throws {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to save weight entries"])
        }

        let entryData: [String: Any] = [
            "id": entry.id.uuidString,
            "weight": entry.weight,
            "date": FirebaseFirestore.Timestamp(date: entry.date),
            "bmi": entry.bmi as Any,
            "note": entry.note as Any
        ]

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

            return WeightEntry(id: id, weight: weight, date: timestamp.dateValue(), bmi: bmi, note: note)
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

    // MARK: - User Settings (Height, Goal Weight)

    func saveUserSettings(height: Double?, goalWeight: Double?) async throws {
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

        try await db.collection("users").document(userId)
            .collection("settings").document("preferences").setData(data, merge: true)
        print("✅ User settings saved successfully")
    }

    func getUserSettings() async throws -> (height: Double?, goalWeight: Double?) {
        ensureAuthStateLoaded()

        guard let userId = currentUser?.uid else {
            throw NSError(domain: "NutraSafeAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "You must be signed in to view settings"])
        }

        let document = try await db.collection("users").document(userId)
            .collection("settings").document("preferences").getDocument()

        guard let data = document.data() else {
            return (nil, nil)
        }

        let height = data["height"] as? Double
        let goalWeight = data["goalWeight"] as? Double

        return (height, goalWeight)
    }
}

extension Notification.Name {
    static let kitchenInventoryUpdated = Notification.Name("kitchenInventoryUpdated")
    static let navigateToKitchen = Notification.Name("navigateToKitchen")
}

// MARK: - Response Models for Food Search

struct FoodSearchResponse: Decodable {
    let foods: [FoodSearchResult]
}
