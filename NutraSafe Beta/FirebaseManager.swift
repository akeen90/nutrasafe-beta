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
    
    private init() {
        // Defer Firebase service initialization until first access
    }
    
    private func initializeFirebaseServices() {
        // Only initialize services when first accessed
        _ = db
        _ = auth
        
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }
    
    // MARK: - Authentication
    
    func signInAnonymously() async throws {
        initializeFirebaseServices()
        let result = try await auth.signInAnonymously()
        await MainActor.run {
            self.currentUser = result.user
            self.isAuthenticated = true
        }
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
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
        guard let userId = currentUser?.uid else { return }
        let reactionData = reaction.toDictionary()
        try await db.collection("users").document(userId)
            .collection("reactions").document(reaction.id.uuidString).setData(reactionData)
    }

    // MARK: - Kitchen Inventory

    func addKitchenItem(_ item: KitchenInventoryItem) async throws {
        guard let userId = currentUser?.uid else {
            // Try anonymous sign in
            try await signInAnonymously()
            guard let userId = currentUser?.uid else { return }
            try await addKitchenItemHelper(item, userId: userId)
            return
        }
        try await addKitchenItemHelper(item, userId: userId)
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
        guard let userId = currentUser?.uid else {
            // Try anonymous sign in
            try await signInAnonymously()
            guard let userId = currentUser?.uid else { return [] }
            return try await getKitchenItemsHelper(userId: userId)
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
        guard let userId = currentUser?.uid else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(item.id).setData(dict, merge: true)
    }

    func deleteKitchenItem(itemId: String) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(itemId).delete()
    }
    
    func getReactions() async throws -> [FoodReaction] {
        guard let userId = currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(userId)
            .collection("reactions")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            FoodReaction.fromDictionary(doc.data())
        }
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
}