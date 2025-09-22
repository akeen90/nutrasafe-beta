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
            // Ensure @Published properties change on the main actor
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    // Ensure our cached auth state is populated even if the listener hasn’t fired yet
    private func ensureAuthStateLoaded() {
        initializeFirebaseServices()
        if self.currentUser == nil {
            let user = auth.currentUser
            Task { @MainActor in
                self.currentUser = user
                self.isAuthenticated = user != nil
            }
            
            // If still no user and dev flag allows, attempt anonymous sign-in
            if user == nil && AppConfig.Features.allowAnonymousAuth {
                Task {
                    do { try await self.signInAnonymously() } catch { /* ignore; will require explicit sign-in */ }
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signInAnonymously() async throws {
        initializeFirebaseServices()
        do {
            let result = try await auth.signInAnonymously()
            await MainActor.run {
                self.currentUser = result.user
                self.isAuthenticated = true
            }
        } catch {
            let ns = error as NSError
            // Map common configuration errors to clearer messages
            if ns.domain == AuthErrorDomain {
                if ns.code == AuthErrorCode.operationNotAllowed.rawValue {
                    throw NSError(domain: "NutraSafeAuth", code: ns.code, userInfo: [NSLocalizedDescriptionKey: "Anonymous sign-in is disabled in your Firebase project. Enable it in Firebase Console > Authentication > Sign-in method > Anonymous."])
                }
            }
            throw error
        }
    }

    // Ensure we have a signed-in user (anonymous is fine)
    func ensureSignedIn() async throws {
        if currentUser == nil { try await signInAnonymously() }
    }
    
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
        guard let userId = currentUser?.uid else { return }
        let reactionData = reaction.toDictionary()
        try await db.collection("users").document(userId)
            .collection("reactions").document(reaction.id.uuidString).setData(reactionData)
    }

    // MARK: - Kitchen Inventory

    func addKitchenItem(_ item: KitchenInventoryItem) async throws {
        ensureAuthStateLoaded()
        // If dev flag allows, try anonymous sign-in just-in-time
        if currentUser == nil && AppConfig.Features.allowAnonymousAuth {
            do {
                try await signInAnonymously()
            } catch {
                print("Anonymous sign-in failed: \(error)")
                // Continue anyway - we'll store locally
            }
        }

        // Try to get userId after auth attempt
        if let userId = currentUser?.uid ?? auth.currentUser?.uid {
            do {
                try await addKitchenItemHelper(item, userId: userId)
            } catch {
                // If Firebase fails, store locally
                saveKitchenItemLocally(item)
            }
        } else {
            // No user - store locally
            print("No user available - storing kitchen item locally")
            saveKitchenItemLocally(item)
        }
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
        if AppConfig.Features.allowAnonymousAuth && auth.currentUser == nil { try? await signInAnonymously() }

        var allItems: [KitchenInventoryItem] = []

        // Get Firebase items if user is authenticated
        if let userId = currentUser?.uid ?? auth.currentUser?.uid {
            do {
                let firebaseItems = try await getKitchenItemsHelper(userId: userId)
                allItems.append(contentsOf: firebaseItems)
            } catch {
                print("Failed to get Firebase items: \(error)")
            }
        }

        // Always include local items
        let localItems = getLocalKitchenItems()
        allItems.append(contentsOf: localItems)

        // Remove duplicates based on ID
        let uniqueItems = Array(Dictionary(grouping: allItems, by: { $0.id })
            .compactMapValues { $0.first }.values)

        // Sort by expiry date
        return uniqueItems.sorted { $0.expiryDate < $1.expiryDate }
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
        if AppConfig.Features.allowAnonymousAuth && auth.currentUser == nil { try? await signInAnonymously() }
        let userId = currentUser?.uid ?? auth.currentUser?.uid ?? "local_user"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(item)
        let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

        try await db.collection("users").document(userId)
            .collection("kitchenInventory").document(item.id).setData(dict, merge: true)
    }

    func deleteKitchenItem(itemId: String) async throws {
        ensureAuthStateLoaded()
        if AppConfig.Features.allowAnonymousAuth && auth.currentUser == nil { try? await signInAnonymously() }

        // Try to delete from Firebase if user is authenticated
        if let userId = currentUser?.uid ?? auth.currentUser?.uid {
            do {
                try await db.collection("users").document(userId)
                    .collection("kitchenInventory").document(itemId).delete()
            } catch {
                print("Failed to delete from Firebase: \(error)")
            }
        }

        // Also delete from local storage
        var localItems = getLocalKitchenItems()
        localItems.removeAll { $0.id == itemId }
        if let encoded = try? JSONEncoder().encode(localItems) {
            UserDefaults.standard.set(encoded, forKey: "localKitchenItems")
        }
    }

    func clearKitchenInventory() async throws {
        ensureAuthStateLoaded()
        if AppConfig.Features.allowAnonymousAuth && auth.currentUser == nil { try? await signInAnonymously() }

        // Clear Firebase items if user is authenticated
        if let userId = currentUser?.uid ?? auth.currentUser?.uid {
            do {
                let snapshot = try await db.collection("users").document(userId)
                    .collection("kitchenInventory").getDocuments()
                for doc in snapshot.documents {
                    try await doc.reference.delete()
                }
            } catch {
                print("Failed to clear Firebase items: \(error)")
            }
        }

        // Clear local storage
        UserDefaults.standard.removeObject(forKey: "localKitchenItems")
    }

    // MARK: - Food Search Functions

    func searchFoods(query: String) async throws -> [FoodSearchResult] {
        // Search in Firebase Cloud Functions
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoods") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        let response = try decoder.decode(FoodSearchResponse.self, from: data)

        return response.foods
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

extension Notification.Name {
    static let kitchenInventoryUpdated = Notification.Name("kitchenInventoryUpdated")
    static let navigateToKitchen = Notification.Name("navigateToKitchen")
}

// MARK: - Response Models for Food Search

struct FoodSearchResponse: Decodable {
    let foods: [FoodSearchResult]
}
