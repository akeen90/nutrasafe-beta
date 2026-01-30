import SwiftUI
import Foundation
import HealthKit
import Vision
import UserNotifications
import ActivityKit
import UIKit

// MARK: - Ingredient Submission Service
class IngredientSubmissionService: ObservableObject {
    static let shared = IngredientSubmissionService()
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"
    
    private init() {}
    
    // Submit ingredients immediately and create pending verification
    func submitIngredientSubmission(foodName: String, brandName: String?, 
                                  ingredientsImage: UIImage?, nutritionImage: UIImage?, 
                                  barcodeImage: UIImage?) async throws -> String {
        // First, process the ingredient image to extract text if available
        var extractedIngredients: String = ""
        
        if let ingredientsImage = ingredientsImage {
            extractedIngredients = try await processIngredientImage(ingredientsImage)
        }
        
        // Create immediate pending verification record
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let pendingVerification = PendingFoodVerification(
            id: UUID().uuidString,
            foodName: foodName,
            brandName: brandName,
            ingredients: extractedIngredients.isEmpty ? "Processing ingredient image..." : extractedIngredients,
            submittedAt: Date(),
            status: .pending,
            userId: userId
        )
        
        // Save immediately to local collection for instant display
        try await FirebaseManager.shared.savePendingVerification(pendingVerification)
        
        // Submit to backend for full processing (asynchronous)
        Task {
            try await submitToBackendForFullProcessing(
                foodName: foodName,
                brandName: brandName,
                ingredientsImage: ingredientsImage,
                nutritionImage: nutritionImage,
                barcodeImage: barcodeImage,
                pendingId: pendingVerification.id
            )
        }
        
        return pendingVerification.id
    }
    
    // Extract ingredients text from image using Vision framework
    private func processIngredientImage(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                continuation.resume(returning: recognizedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Submit to backend Firebase function for complete processing
    private func submitToBackendForFullProcessing(foodName: String, brandName: String?,
                                                ingredientsImage: UIImage?, nutritionImage: UIImage?,
                                                barcodeImage: UIImage?, pendingId: String) async throws {
        guard let userId = FirebaseManager.shared.currentUser?.uid else {
                        return
        }

        let urlString = "\(functionsBaseURL)/submitFoodVerification"
        guard let url = URL(string: urlString) else {
                        throw NSError(domain: "ContentView", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid submission URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var images: [String: String] = [:]
        
        // Convert images to base64 if available
        if let ingredientsImage = ingredientsImage,
           let imageData = ingredientsImage.jpegData(compressionQuality: 0.8) {
            images["ingredients"] = imageData.base64EncodedString()
        }
        
        if let nutritionImage = nutritionImage,
           let imageData = nutritionImage.jpegData(compressionQuality: 0.8) {
            images["nutrition"] = imageData.base64EncodedString()
        }
        
        if let barcodeImage = barcodeImage,
           let imageData = barcodeImage.jpegData(compressionQuality: 0.8) {
            images["barcode"] = imageData.base64EncodedString()
        }
        
        let requestData: [String: Any] = [
            "userId": userId,
            "verificationId": pendingId,
            "foodName": foodName,
            "brandName": brandName ?? "",
            "images": images
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
                        return
        }
    }
}

// MARK: - FatSecret API Service via Firebase Functions
class FatSecretService: ObservableObject {
    static let shared = FatSecretService()
    
    // Firebase Functions URL for NutraSafe project
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"
    
    private init() {}
    
    func searchFoods(query: String) async throws -> [FoodSearchResult] {
                let results = try await performFatSecretSearch(query: query)
                return results
    }
    
    private func performFatSecretSearch(query: String) async throws -> [FoodSearchResult] {
        let urlString = "\(functionsBaseURL)/searchFoods"
        guard let url = URL(string: urlString) else {
                        throw NSError(domain: "FatSecretService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["query": query, "maxResults": "50"]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct FirebaseFoodSearchResponse: Codable {
            let foods: [FirebaseFoodItem]
            
            struct FirebaseFoodItem: Codable {
                let id: String
                let name: String
                let brand: String?
                let calories: CalorieInfo?
                let protein: NutrientInfo?
                let carbs: NutrientInfo?
                let fat: NutrientInfo?
                let fiber: NutrientInfo?
                let sugar: NutrientInfo?
                let sodium: NutrientInfo?
                let servingDescription: String?
                let ingredients: String?
                let additives: [FirebaseAdditiveInfo]?
                let processingScore: Int?
                let processingGrade: String?
                let processingLabel: String?
                
                struct CalorieInfo: Codable {
                    let kcal: Double
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            kcal = 0
                        } else if let directValue = try? container.decode(Double.self) {
                            // Handle direct number: "calories": 442
                            kcal = directValue
                        } else {
                            // Handle nested object: "calories": {"kcal": 442}
                            let calorieContainer = try decoder.container(keyedBy: CodingKeys.self)
                            kcal = try calorieContainer.decode(Double.self, forKey: .kcal)
                        }
                    }
                    
                    private enum CodingKeys: String, CodingKey {
                        case kcal
                    }
                }
                
                struct NutrientInfo: Codable {
                    let per100g: Double
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.singleValueContainer()
                        if container.decodeNil() {
                            per100g = 0
                        } else if let directValue = try? container.decode(Double.self) {
                            // Handle direct number: "protein": 4.5
                            per100g = directValue
                        } else {
                            // Handle nested object: "protein": {"per100g": 4.5}
                            let nutrientContainer = try decoder.container(keyedBy: CodingKeys.self)
                            per100g = try nutrientContainer.decode(Double.self, forKey: .per100g)
                        }
                    }
                    
                    private enum CodingKeys: String, CodingKey {
                        case per100g
                    }
                }
                
                struct FirebaseAdditiveInfo: Codable {
                    let id: String
                    let code: String
                    let name: String
                    let category: String
                    let permittedGB: Bool
                    let permittedNI: Bool
                    let permittedEU: Bool
                    let statusNotes: String?
                    let childWarning: Bool
                    let pkuWarning: Bool
                    let polyolsWarning: Bool
                    let sulphitesAllergenLabel: Bool
                    let origin: String
                    let consumerGuide: String?
                    let effectsVerdict: String
                    let synonyms: [String]
                    let matches: [String]
                    let sources: [AdditiveSource]?
                    let consumerInfo: String?
                    
                    private enum CodingKeys: String, CodingKey {
                        case id, code, name, category, origin, synonyms, matches, sources
                        case permittedGB = "permitted_GB"
                        case permittedNI = "permitted_NI"
                        case permittedEU = "permitted_EU"
                        case statusNotes = "status_notes"
                        case childWarning = "child_warning"
                        case pkuWarning = "PKU_warning"
                        case polyolsWarning = "polyols_warning"
                        case sulphitesAllergenLabel = "sulphites_allergen_label"
                        case consumerGuide = "consumer_guide"
                        case effectsVerdict = "effects_verdict"
                        case consumerInfo
                    }
                }
                
                struct AdditiveSource: Codable {
                    let name: String
                    let url: String?
                }
            }
        }
        
        let searchResponse: FirebaseFoodSearchResponse
        do {
            searchResponse = try JSONDecoder().decode(FirebaseFoodSearchResponse.self, from: data)
        } catch {
            throw error
        }

        return searchResponse.foods.map { food in
            // Convert Firebase additives to NutritionAdditiveInfo format
            let convertedAdditives = food.additives?.map { firebaseAdditive in
                // Calculate health score based on warnings (simplified scoring)
                var healthScore = 70 // Base score
                if firebaseAdditive.childWarning { healthScore -= 20 }
                if firebaseAdditive.pkuWarning { healthScore -= 15 }
                if firebaseAdditive.polyolsWarning { healthScore -= 10 }
                if firebaseAdditive.effectsVerdict.lowercased().contains("caution") { healthScore -= 15 }
                healthScore = max(0, min(100, healthScore))

                return NutritionAdditiveInfo(
                    code: firebaseAdditive.code,
                    name: firebaseAdditive.name,
                    category: firebaseAdditive.category,
                    healthScore: healthScore,
                    childWarning: firebaseAdditive.childWarning,
                    effectsVerdict: firebaseAdditive.effectsVerdict
                )
            }
            
            return FoodSearchResult(
                id: food.id,
                name: food.name,
                brand: food.brand,
                calories: food.calories?.kcal ?? 0,
                protein: food.protein?.per100g ?? 0,
                carbs: food.carbs?.per100g ?? 0,
                fat: food.fat?.per100g ?? 0,
                fiber: food.fiber?.per100g ?? 0,
                sugar: food.sugar?.per100g ?? 0,
                sodium: food.sodium?.per100g ?? 0,
                servingDescription: food.servingDescription,
                ingredients: food.ingredients?.components(separatedBy: ", "),
                additives: convertedAdditives,
                processingScore: food.processingScore,
                processingGrade: food.processingGrade,
                processingLabel: food.processingLabel
            )
        }
    }
    
    func getFoodDetails(foodId: String) async throws -> FoodSearchResult? {
        let urlString = "\(functionsBaseURL)/getFoodDetails"
        guard let url = URL(string: urlString) else {
                        throw NSError(domain: "FatSecretService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid details URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["foodId": foodId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        struct FirebaseFoodDetailsResponse: Codable {
            let id: String
            let name: String
            let brand: String?
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
            let fiber: Double
            let sugar: Double
            let sodium: Double
            let servingDescription: String?
            let ingredients: String?
        }
        
        let detailResponse = try JSONDecoder().decode(FirebaseFoodDetailsResponse.self, from: data)
        
        return FoodSearchResult(
            id: detailResponse.id,
            name: detailResponse.name,
            brand: detailResponse.brand,
            calories: detailResponse.calories,
            protein: detailResponse.protein,
            carbs: detailResponse.carbs,
            fat: detailResponse.fat,
            fiber: detailResponse.fiber,
            sugar: detailResponse.sugar,
            sodium: detailResponse.sodium,
            servingDescription: detailResponse.servingDescription,
            ingredients: detailResponse.ingredients?.components(separatedBy: ", ")
        )
    }
    
}

// MARK: - Data Models for UI

struct NutritionValue {
    let current: Double
    let target: Double
    
    var percentage: Double {
        return min(current / target, 1.0)
    }
    
    var remaining: Double {
        return max(target - current, 0)
    }
}







// MARK: - Professional Nutrition App UI Following Research Standards
// Based on analysis of MyFitnessPal, Lose It!, Cronometer, and Lifesum

struct ContentView: View {
    @StateObject private var diaryDataManager = DiaryDataManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: TabItem = .diary
    @State private var showingSettings = false
    @State private var selectedFoodItems: Set<String> = []
    @State private var showingMoveMenu = false
    @State private var editTrigger = false
    @State private var moveTrigger = false
    @State private var copyTrigger = false
    @State private var deleteTrigger = false
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showOnboarding = !OnboardingManager.shared.hasCompletedOnboarding
    // Post-auth permissions: Show if user completed pre-auth onboarding but not permissions
    @State private var showPostAuthPermissions = OnboardingManager.shared.hasCompletedPreAuthOnboarding && !OnboardingManager.shared.hasCompletedPermissions
    @State private var showWelcomeScreen = false
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var showingPaywall = false
    @State private var showingAddMenu = false
    @State private var showingDiaryAdd = false
    @State private var diaryAddInitialOption: AddFoodMainView.AddOption? = nil
    @State private var showingReactionLog = false
    @State private var showingWeightAdd = false
    @State private var showingMealScan = false
    @State private var showingBarcodeScan = false
    @State private var prefilledBarcodeForManual: String? = nil
    @State private var useBySelectedFood: FoodSearchResult? = nil
    @State private var previousTabBeforeAdd: TabItem = .diary

    // Weight tracking state for AddWeightView
    @State private var currentWeight: Double = 0
    @State private var weightHistory: [WeightEntry] = []
    @State private var userHeight: Double = 0
    @State private var goalWeightMain: Double = 0

    // Track notification-triggered navigation to bypass subscription gate
    @State private var isNavigatingFromNotification = false

    // Shared FastingViewModel for diary-fasting integration
    @StateObject private var sharedFastingViewModelWrapper = FastingViewModelWrapper()

    // MARK: - Persistent Tab Views (Performance Fix)
    // Keep tabs alive to preserve state and prevent redundant loading
    // Only the selected tab is visible, but all maintain their loaded data
    @State private var visitedTabs: Set<TabItem> = [.diary] // Diary pre-loaded

    // PERFORMANCE: Pre-render all tabs in background for instant switching
    private func preloadAllTabsInBackground() {
        // Stagger tab loading to prevent memory spike and reduce UI jank
        Task(priority: .utility) {
            // First tab (.diary) is already loaded on launch

            // Load .progress tab after 500ms
            try? await Task.sleep(nanoseconds: 500_000_000)
            _ = await MainActor.run { visitedTabs.insert(.weight) }

            // Load .food (health) tab after 800ms total
            try? await Task.sleep(nanoseconds: 300_000_000)
            _ = await MainActor.run { visitedTabs.insert(.food) }

            // Load .useBy tab after 1.1s total
            try? await Task.sleep(nanoseconds: 300_000_000)
            _ = await MainActor.run { visitedTabs.insert(.useBy) }

            // .add tab is modal-only, never preload
        }
    }

    private var persistentTabViews: some View {
        ZStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if visitedTabs.contains(tab) {
                    // PERFORMANCE: Use .id() to stabilize view identity and prevent re-creation
                    // This ensures that once a tab is created, it stays alive and isn't recreated
                    // on every state change, reducing excessive re-rendering
                    tabContent(for: tab)
                        .id(tab) // Stable identity prevents view re-creation
                        .opacity(selectedTab == tab ? 1 : 0)
                        // PERFORMANCE: Remove animation delay for instant tab switching
                        // Users perceive <100ms as instant; animation was adding 150ms latency
                        .allowsHitTesting(selectedTab == tab)
                        .accessibilityHidden(selectedTab != tab)
                }
            }
        }
    }

    // Keep each tab alive once visited so data/models are not re-created on every switch
    @ViewBuilder
    private func tabContent(for tab: TabItem) -> some View {
        switch tab {
        case .diary:
            DiaryTabView(
                selectedFoodItems: $selectedFoodItems,
                showingSettings: $showingSettings,
                selectedTab: $selectedTab,
                editTrigger: $editTrigger,
                moveTrigger: $moveTrigger,
                copyTrigger: $copyTrigger,
                deleteTrigger: $deleteTrigger,
                onEditFood: editSelectedFood,
                onDeleteFoods: deleteSelectedFoods,
                onBlockedNutrientsAttempt: { showingPaywall = true }
            )
            .environmentObject(diaryDataManager)
            .environmentObject(healthKitManager)
            .environmentObject(subscriptionManager)
            .environmentObject(sharedFastingViewModelWrapper)

        case .weight:
            WeightTrackingView(showingSettings: $showingSettings, selectedTab: $selectedTab)
                .environmentObject(healthKitManager)
                .environmentObject(subscriptionManager)

        case .food:
            FoodTabView(showingSettings: $showingSettings, selectedTab: $selectedTab)
                .environmentObject(subscriptionManager)
                .environmentObject(sharedFastingViewModelWrapper)

        case .useBy:
            UseByTabView(showingSettings: $showingSettings, selectedTab: $selectedTab)
                .environmentObject(subscriptionManager)

        case .add:
            AddTabView(
                selectedTab: $selectedTab,
                isPresented: Binding(
                    get: { selectedTab == .add },
                    set: { if !$0 { selectedTab = previousTabBeforeAdd } }
                )
            )
            .environmentObject(diaryDataManager)
            .environmentObject(sharedFastingViewModelWrapper)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    var body: some View {
        navigationContainer {
            ZStack {
                // Midnight blue background for entire app
                Color.adaptiveBackground
                    .ignoresSafeArea()

                // Main Content with padding for tab bar and potential workout progress bar
                VStack {
                    persistentTabViews
                        .onAppear {
                            visitedTabs.insert(selectedTab)
                            // PERFORMANCE: Pre-load all tabs in background for instant switching
                            preloadAllTabsInBackground()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar positioned at bottom
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab, showingAddMenu: $showingAddMenu)
                    .offset(y: 34) // Lower the tab bar to bottom edge
            }

            // Add Action Menu - always rendered but controls its own visibility
            AddActionMenu(
                isPresented: $showingAddMenu,
                onSelectDiary: {
                    previousTabBeforeAdd = selectedTab
                    diaryAddInitialOption = .search
                    showingDiaryAdd = true
                },
                onSelectUseBy: {
                    // Navigate directly to Use By tab instead of showing redundant sheet
                    selectedTab = .useBy
                },
                onSelectReaction: {
                    previousTabBeforeAdd = selectedTab
                    showingReactionLog = true
                },
                onSelectWeighIn: {
                    previousTabBeforeAdd = selectedTab
                    showingWeightAdd = true
                },
                onSelectBarcodeScan: {
                    previousTabBeforeAdd = selectedTab
                    showingBarcodeScan = true
                },
                onSelectMealScan: {
                    previousTabBeforeAdd = selectedTab
                    showingMealScan = true
                },
                onSelectWater: {
                    addWaterForToday()
                }
            )
            .zIndex(1000)
            
            // Persistent bottom menu when food items are selected - properly overlays tab bar
            if selectedTab == .diary && !selectedFoodItems.isEmpty {
                VStack {
                    Spacer()
                    PersistentBottomMenu(
                        selectedCount: selectedFoodItems.count,
                        onEdit: editSelectedFood,
                        onMove: {
                            moveTrigger = true
                        },
                        onCopy: {
                            copyTrigger = true
                        },
                        onDelete: deleteSelectedFoods,
                        onCancel: {
                            selectedFoodItems.removeAll() // Clear selection
                        }
                    )
                    .offset(y: 34) // Same offset as tab bar to replace it
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: selectedFoodItems.isEmpty)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(selectedTab: $selectedTab)
                .environmentObject(firebaseManager)
                .environmentObject(subscriptionManager)
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            // Show onboarding ONLY if user hasn't completed pre-auth onboarding
            // (If they did pre-auth, showPostAuthPermissions handles the rest)
            if !OnboardingManager.shared.hasCompletedPreAuthOnboarding {
                // Full premium onboarding for users who sign in without doing pre-auth onboarding
                // (e.g., returning users who tapped "Already a member")
                PremiumOnboardingView(onComplete: { emailMarketingConsent in
                    // Save email consent to Firestore
                    Task {
                        do {
                            try await firebaseManager.updateEmailMarketingConsent(hasConsented: emailMarketingConsent)
                        } catch {
                            // Save to UserDefaults as fallback
                            UserDefaults.standard.set(emailMarketingConsent, forKey: "emailMarketingConsent")
                            if emailMarketingConsent {
                                UserDefaults.standard.set(Date(), forKey: "emailMarketingConsentDate")
                            }
                        }
                    }

                    showOnboarding = false
                    OnboardingManager.shared.completeWelcome()
                })
                .environmentObject(healthKitManager)
            } else {
                // User already did pre-auth onboarding, just close this
                // (showPostAuthPermissions will handle permissions)
                Color.clear
                    .onAppear {
                        showOnboarding = false
                    }
            }
        }
        .fullScreenCover(isPresented: $showPostAuthPermissions) {
            // Post-auth permissions flow for users who completed pre-auth onboarding
            PostAuthPermissionsView(onComplete: {
                showPostAuthPermissions = false
                OnboardingManager.shared.completeWelcome()
            })
            .environmentObject(healthKitManager)
        }
        .fullScreenCover(isPresented: $showWelcomeScreen) {
            WelcomeScreenView(onContinue: {
                OnboardingManager.shared.completeWelcome()
                showWelcomeScreen = false
            })
        }
        .fullScreenCover(isPresented: $showingDiaryAdd) {
            AddFoodMainView(
                selectedTab: $selectedTab,
                isPresented: $showingDiaryAdd,
                initialOption: diaryAddInitialOption,
                prefilledBarcode: prefilledBarcodeForManual,
                onDismiss: {
                    showingDiaryAdd = false
                    diaryAddInitialOption = nil
                    prefilledBarcodeForManual = nil
                },
                onComplete: { tab in
                    // Dismiss keyboard before closing fullscreen and switching tabs
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showingDiaryAdd = false
                    diaryAddInitialOption = nil
                    prefilledBarcodeForManual = nil
                    selectedTab = tab
                }
            )
            // Force view recreation when initial option or prefilled barcode changes
            .id("\(String(describing: diaryAddInitialOption))-\(prefilledBarcodeForManual ?? "")")
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(sharedFastingViewModelWrapper)
            .keyboardDismissButton()
        }
        .fullScreenCover(isPresented: $showingReactionLog) {
            LogReactionSheet(selectedDayRange: .threeDays)
        }
        .fullScreenCover(isPresented: $showingWeightAdd) {
            LogWeightView(
                currentWeight: $currentWeight,
                weightHistory: $weightHistory,
                userHeight: $userHeight,
                goalWeight: $goalWeightMain,
                onInstantDismiss: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingWeightAdd = false
                    }
                },
                // Note: Don't call refreshMainViewWeightData() here - the .weightHistoryUpdated
                // notification already updates weightHistory optimistically.
                onSave: nil
            )
                .environmentObject(FirebaseManager.shared)
                .onDisappear {
                    // Switch to weight tab after adding weight
                    selectedTab = .weight
                }
        }
        .fullScreenCover(isPresented: $showingMealScan) {
            NavigationView {
                AddFoodAIView(selectedTab: $selectedTab)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingMealScan = false
                            }
                        }
                    }
            }
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(firebaseManager)
            .environmentObject(sharedFastingViewModelWrapper)
            .onDisappear {
                showingMealScan = false
            }
        }
        .fullScreenCover(isPresented: $showingBarcodeScan) {
            NavigationView {
                AddFoodBarcodeView(selectedTab: $selectedTab, onSwitchToManual: { barcode in
                    // Store barcode, close scanner, and open AddFoodMainView with manual entry
                    prefilledBarcodeForManual = barcode
                    showingBarcodeScan = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        diaryAddInitialOption = .manual
                        showingDiaryAdd = true
                    }
                })
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingBarcodeScan = false
                        }
                    }
                }
            }
            .environmentObject(diaryDataManager)
            .environmentObject(subscriptionManager)
            .environmentObject(firebaseManager)
            .environmentObject(sharedFastingViewModelWrapper)
            .onDisappear {
                showingBarcodeScan = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToUseBy)) { _ in
                        isNavigatingFromNotification = true
            selectedTab = .useBy
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFasting)) { _ in
                        isNavigatingFromNotification = true
            selectedTab = .food
        }
        .onReceive(NotificationCenter.default.publisher(for: .restartOnboarding)) { _ in
            // First dismiss Settings if it's showing
            showingSettings = false
            // Wait for Settings dismiss animation to complete, then show onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightHistoryUpdated)) { notification in
            // Update ContentView's weight state when a weight entry is saved
            // This keeps the main view in sync with weight changes from LogWeightView
            if let entry = notification.userInfo?["entry"] as? WeightEntry {
                if let existingIndex = weightHistory.firstIndex(where: { $0.id == entry.id }) {
                    weightHistory[existingIndex] = entry
                } else {
                    weightHistory.insert(entry, at: 0)
                }
                weightHistory.sort { $0.date > $1.date }
                currentWeight = entry.weight
            }
        }

        .onChange(of: selectedTab) { _, newTab in
            // Track visited tabs for pre-loading optimization
            visitedTabs.insert(newTab)

            // Track tab changes in analytics
            trackTabChange(newTab)

            // Track the last non-add tab for proper return behavior when dismissing
            if newTab != .add {
                previousTabBeforeAdd = newTab
            }

            // Reset the notification flag after navigation is handled
            if isNavigatingFromNotification {
                isNavigatingFromNotification = false
            }
        }
        .onAppear {
            // PERFORMANCE OPTIMIZATION: Parallel preloading for instant app responsiveness

            // PRIORITY 1: Load critical Diary tab data IMMEDIATELY (user-facing)
            Task(priority: .userInitiated) {
                let today = Date()
                _ = diaryDataManager.getFoodData(for: today)
                            }

            // PRIORITY 2: Background preload other tabs IN PARALLEL (non-blocking)
            Task(priority: .utility) {
                // All requests run in parallel using async let (single settings fetch)
                async let weightsTask = FirebaseManager.shared.getWeightHistory()
                async let useByTask: [UseByInventoryItem] = FirebaseManager.shared.getUseByItems()
                async let reactionsTask = FirebaseManager.shared.getReactions()
                async let settingsTask = FirebaseManager.shared.getUserSettings()
                async let nutrientsTask = MicronutrientTrackingManager.shared.getAllNutrientSummaries()

                // Wait for all to complete (runs in ~1.2s instead of 3.4s sequential)
                do {
                    let weights = try await weightsTask
                    _ = try await useByTask
                    let reactions = try await reactionsTask
                    let settings = try await settingsTask
                    _ = await nutrientsTask
                    await MainActor.run {
                        // Set user height from settings
                        if let height = settings.height {
                            userHeight = height
                        }

                        if let uid = FirebaseManager.shared.currentUser?.uid {
                            ReactionManager.shared.preload(reactions, for: uid)
                            // Start nutrient tracking with user-scoped caching
                            NutrientTrackingManager.shared.startTracking(for: uid)
                        }
                        FirebaseManager.shared.preloadWeightData(history: weights, height: settings.height, goalWeight: settings.goalWeight)
                    }
                } catch {
                    // Silent failure for background preload
                }
            }

            // Initialize shared FastingViewModel for diary-fasting integration
            if sharedFastingViewModelWrapper.viewModel == nil, let userId = firebaseManager.currentUser?.uid {
                sharedFastingViewModelWrapper.viewModel = FastingViewModel(firebaseManager: firebaseManager, userId: userId)
            }
        }

        }
    }
    
    private func editSelectedFood() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        editTrigger.toggle()
    }
    
    private func deleteSelectedFoods() {
        guard selectedTab == .diary && !selectedFoodItems.isEmpty else { return }
        deleteTrigger = true
    }

    // MARK: - Weight Data Refresh (for main ContentView)
    private func refreshMainViewWeightData() {
        Task {
            do {
                let history = try await firebaseManager.getWeightHistory()
                await MainActor.run {
                    weightHistory = history
                    if let latest = history.first {
                        currentWeight = latest.weight
                    }
                }
            } catch {
                // Silent failure - notification should have already updated state
            }
        }
    }

    // MARK: - Water Tracking Quick Add
    private func addWaterForToday() {
        let dateKey = DateHelper.isoDateFormatter.string(from: Date())
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        let currentCount = hydrationData[dateKey] ?? 0
        hydrationData[dateKey] = currentCount + 1
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")

        // Notify views to update
        NotificationCenter.default.post(name: .waterUpdated, object: nil)

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    // MARK: - Analytics Tracking
    private func trackTabChange(_ tab: TabItem) {
        let screenName: String
        switch tab {
        case .diary: screenName = "Diary"
        case .weight: screenName = "Progress"
        case .add: return // Add menu is a modal, not a screen
        case .food: screenName = "Search"
        case .useBy: screenName = "Use By Tracker"
        }
        AnalyticsManager.shared.trackScreen(screenName, screenClass: "ContentView")
    }
}

// MARK: - Tab Items
enum TabItem: String, CaseIterable {
    case diary = "diary"
    case weight = "progress"
    case add = "add"
    case food = "food"
    case useBy = "fridge"

    var title: String {
        switch self {
        case .diary: return "Diary"
        case .weight: return "Progress"
        case .add: return ""
        case .food: return "Health"
        case .useBy: return "Use By"
        }
    }

    var icon: String {
        switch self {
        case .diary: return "fork.knife.circle"
        case .weight: return "figure.run.treadmill.circle"
        case .add: return "plus"
        case .food: return "heart.circle"
        case .useBy: return "calendar.circle"
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    func apply<V: View>(@ViewBuilder _ transform: (Self) -> V) -> V {
        transform(self)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Tab Views


// MARK: - Progress Sub-Tabs
enum ProgressSubTab: String, CaseIterable {
    case weight = "Weight"
    case diet = "Diet"
}

// MARK: - Journey Time Range
enum JourneyTimeRange: String, CaseIterable {
    case thirtyDays = "30 Days"
    case ninetyDays = "90 Days"
    case allTime = "All Time"

    var entryLimit: Int? {
        switch self {
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return nil
        }
    }
}

// MARK: - Weight Tracking View
struct WeightTrackingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    var isPresentedAsModal: Bool = false
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @AppStorage("weightUnit") private var selectedWeightUnit: WeightUnit = .kg
    @AppStorage("cachedCurrentWeight") private var cachedCurrentWeight: Double = 0

    @State private var currentWeight: Double = 0
    @State private var goalWeight: Double = 0
    @State private var userHeight: Double = 0
    @State private var showingAddWeight = false
    @State private var weightHistory: [WeightEntry] = []
    @State private var showingHeightSetup = false
    @State private var isLoadingData = false
    @State private var hasCheckedHeight = false
    @State private var hasLoadedOnce = false

    @State private var progressSubTab: ProgressSubTab = .weight

    // MARK: - Scroll Reset Trigger
    // Combines main tab and subtab to reset scroll when returning to this tab
    private var scrollResetTrigger: String {
        "\(selectedTab)-\(progressSubTab)"
    }
    @State private var editingEntry: WeightEntry?
    @State private var entryToDelete: WeightEntry?
    @State private var showingDeleteConfirmation = false
    @State private var showAllWeightEntries = false
    @State private var showingGoalWeightEditor = false
    @State private var journeyTimeRange: JourneyTimeRange = .thirtyDays

    @State private var showingProgressTip = false
    @State private var showingPaywall = false

    // MARK: - Palette Integration
    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    /// Free users can see limited entries
    private var hasFullAccess: Bool {
        subscriptionManager.hasAccess
    }

    private var visibleEntryCount: Int {
        hasFullAccess ? weightHistory.count : min(weightHistory.count, SubscriptionManager.freeWeightHistoryLimit)
    }

    private var needsHeightSetup: Bool {
        userHeight == 0 && hasCheckedHeight // Only prompt if height is truly not set
    }

    private var currentBMI: Double {
        guard currentWeight > 0, userHeight > 0 else { return 0 }
        let heightInMeters = userHeight / 100
        return currentWeight / (heightInMeters * heightInMeters)
    }

    private var bmiCategory: (String, Color) {
        let bmi = currentBMI
        // Use palette accent instead of semantic colors
        if bmi < 18.5 {
            return ("Underweight", palette.textSecondary)
        } else if bmi < 25 {
            return ("Healthy", palette.accent)
        } else if bmi < 30 {
            return ("Overweight", palette.textSecondary)
        } else {
            return ("Obese", palette.textTertiary)
        }
    }

    private var totalProgress: Double {
        guard goalWeight > 0, let firstEntry = weightHistory.last else { return 0 }
        let startWeight = firstEntry.weight
        let totalToLose = startWeight - goalWeight
        let lostSoFar = startWeight - currentWeight
        return totalToLose != 0 ? (lostSoFar / totalToLose) * 100 : 0
    }

    // Helper methods for unit conversion
    private func formatWeight(_ kg: Double) -> String {
        let converted = selectedWeightUnit.fromKg(kg)
        switch selectedWeightUnit {
        case .kg:
            return String(format: "%.1f", converted.primary)
        case .lbs:
            return String(format: "%.1f", converted.primary)
        case .stones:
            let st = Int(converted.primary)
            let lbs = converted.secondary ?? 0
            return "\(st)st \(String(format: "%.0f", lbs))lb"
        }
    }

    private var weightUnit: String {
        switch selectedWeightUnit {
        case .kg: return "kg"
        case .lbs: return "lbs"
        case .stones: return ""  // Already included in formatted string
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Modern tab header with segmented control
                TabHeaderView(
                    tabs: ProgressSubTab.allCases,
                    selectedTab: $progressSubTab,
                    onSettingsTapped: {
                        if isPresentedAsModal {
                            showingSettings = false  // Dismiss modal
                        } else {
                            showingSettings = true   // Open settings
                        }
                    },
                    actionIcon: isPresentedAsModal ? "xmark" : "gearshape.fill"
                )

                // Loading overlay
                if isLoadingData {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: palette.accent))

                        Text("Loading your progress...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ZStack {
                        // MARK: Weight Tab Content
                        if progressSubTab == .weight {
                        ScrollViewWithTopReset(resetOn: scrollResetTrigger) {
                            // PERFORMANCE: LazyVStack defers rendering of off-screen content
                            LazyVStack(spacing: 24) {

                            // Stats Grid - NOW AT TOP
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Summary")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        HStack(spacing: 12) {
                            // Current Weight
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(palette.textSecondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(currentWeight))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [palette.accent, palette.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    Text(weightUnit)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(palette.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(Color.nutraSafeCard)
                                    .shadow(color: DesignTokens.Shadow.subtle.color,
                                            radius: DesignTokens.Shadow.subtle.radius,
                                            y: DesignTokens.Shadow.subtle.y)
                            )

                            // Goal Weight - Tappable to edit
                            Button(action: { showingGoalWeightEditor = true }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Goal")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(palette.textSecondary)
                                        Spacer()
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(palette.accent.opacity(0.6))
                                    }
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(goalWeight > 0 ? formatWeight(goalWeight) : "--")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(palette.accent)
                                        Text(weightUnit)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(palette.textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .fill(Color.nutraSafeCard)
                                        .shadow(color: DesignTokens.Shadow.subtle.color,
                                                radius: DesignTokens.Shadow.subtle.radius,
                                                y: DesignTokens.Shadow.subtle.y)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)

                        HStack(spacing: 12) {
                            // Progress
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Progress")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(palette.textSecondary)
                                let startWeight = weightHistory.last?.weight ?? currentWeight
                                let lost = max(startWeight - currentWeight, 0)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(lost))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(palette.accent)
                                    Text(weightUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(palette.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(Color.nutraSafeCard)
                                    .shadow(color: DesignTokens.Shadow.subtle.color,
                                            radius: DesignTokens.Shadow.subtle.radius,
                                            y: DesignTokens.Shadow.subtle.y)
                            )

                            // Remaining
                            VStack(alignment: .leading, spacing: 8) {
                                Text("To Go")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(palette.textSecondary)
                                let remaining = goalWeight > 0 ? max(currentWeight - goalWeight, 0) : 0
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(formatWeight(remaining))
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(palette.textTertiary)
                                    Text(weightUnit)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(palette.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(Color.nutraSafeCard)
                                    .shadow(color: DesignTokens.Shadow.subtle.color,
                                            radius: DesignTokens.Shadow.subtle.radius,
                                            y: DesignTokens.Shadow.subtle.y)
                            )
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)

                    // Progress Graph Section
                    if weightHistory.count >= 2 {
                        let journeyEntries: [WeightEntry] = {
                            if let limit = journeyTimeRange.entryLimit {
                                return Array(weightHistory.prefix(limit).reversed())
                            } else {
                                return Array(weightHistory.reversed())
                            }
                        }()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Your Journey")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)

                                Spacer()

                                // Time range picker
                                Picker("Time Range", selection: $journeyTimeRange) {
                                    ForEach(JourneyTimeRange.allCases, id: \.self) { range in
                                        Text(range.rawValue).tag(range)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                            }
                            .padding(.horizontal, 16)

                            // Weight trend line graph
                            WeightLineChart(
                                entries: journeyEntries,
                                goalWeight: goalWeight,
                                startWeight: weightHistory.last?.weight ?? currentWeight,
                                weightUnit: selectedWeightUnit
                            )
                            .frame(height: 160)
                            .padding(.horizontal, 12)

                            // Progress summary stats
                            if let firstEntry = weightHistory.last {
                                let totalChange = currentWeight - firstEntry.weight
                                let toGoal = goalWeight > 0 ? currentWeight - goalWeight : 0

                                HStack(spacing: 12) {
                                    // Change since start
                                    HStack(spacing: 6) {
                                        Image(systemName: totalChange <= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(totalChange <= 0 ? palette.accent : palette.textTertiary)

                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(totalChange <= 0 ? "Down" : "Up")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(palette.textSecondary)
                                            Text("\(formatWeight(abs(totalChange))) \(weightUnit)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(totalChange <= 0 ? palette.accent : palette.textTertiary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                            .fill(palette.accent.opacity(0.08))
                                    )

                                    // To goal
                                    if goalWeight > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: "target")
                                                .font(.system(size: 16))
                                                .foregroundColor(toGoal <= 0 ? palette.accent : palette.textSecondary)

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(toGoal <= 0 ? "Goal reached!" : "To goal")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(palette.textSecondary)
                                                Text(toGoal <= 0 ? "🎉" : "\(formatWeight(toGoal)) \(weightUnit)")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(toGoal <= 0 ? palette.accent : palette.textSecondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                                .fill(palette.primary.opacity(0.08))
                                        )
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(Color.nutraSafeCard)
                                .shadow(color: DesignTokens.Shadow.subtle.color,
                                        radius: DesignTokens.Shadow.subtle.radius,
                                        y: DesignTokens.Shadow.subtle.y)
                        )
                        .padding(.horizontal, 16)
                    }

                    // Update Weight button - STAYS IN MIDDLE
                    Button(action: { showingAddWeight = true }) {
                        HStack {
                            Text("Update Weight")
                                .font(.system(size: 20, weight: .semibold))
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: palette.accent.opacity(0.3), radius: 10, y: 4)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // Weight History or Empty State - NOW AT BOTTOM
                    if !weightHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("History")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)

                                    Text("\(weightHistory.count) entries")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Mini trend indicator
                                if weightHistory.count > 1 {
                                    let latest = weightHistory.first?.weight ?? currentWeight
                                    let previous = weightHistory[safe: 1]?.weight ?? latest
                                    let change = latest - previous

                                    HStack(spacing: 4) {
                                        Image(systemName: change < 0 ? "arrow.down.right" : change > 0 ? "arrow.up.right" : "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("\(formatWeight(abs(change))) \(weightUnit)")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(change < 0 ? palette.accent : change > 0 ? palette.textTertiary : palette.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                            .fill(palette.accent.opacity(0.08))
                                    )
                                }
                            }
                            .padding(.horizontal, 20)

                            // Weight entries list
                            List {
                                // Show entries based on access level
                                let displayCount = hasFullAccess
                                    ? (showAllWeightEntries ? weightHistory.count : min(5, weightHistory.count))
                                    : min(SubscriptionManager.freeWeightHistoryLimit, weightHistory.count)

                                ForEach(Array(weightHistory.prefix(displayCount).enumerated()), id: \.element.id) { index, entry in
                                    WeightEntryRow(
                                        entry: entry,
                                        previousEntry: weightHistory[safe: index + 1],
                                        isLatest: index == 0
                                    )
                                    .onTapGesture {
                                                                                editingEntry = entry
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            editingEntry = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }

                                        Button(role: .destructive) {
                                            entryToDelete = entry
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }

                                // Show upgrade prompt for free users with more history
                                if !hasFullAccess && weightHistory.count > SubscriptionManager.freeWeightHistoryLimit {
                                    Button(action: { showingPaywall = true }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(palette.accent)

                                            Text("+\(weightHistory.count - SubscriptionManager.freeWeightHistoryLimit) more entries")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(palette.textPrimary)

                                            Spacer()

                                            Text("Unlock")
                                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(palette.accent))
                                        }
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                                .fill(palette.accent.opacity(0.08))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }

                                // Show "View all" only for premium users with lots of entries
                                if hasFullAccess && weightHistory.count > 5 {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showAllWeightEntries.toggle()
                                        }
                                    }) {
                                        Text(showAllWeightEntries ? "Show less" : "View all \(weightHistory.count) entries")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(palette.accent)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat({
                                let baseCount = hasFullAccess
                                    ? (showAllWeightEntries ? weightHistory.count : min(weightHistory.count, 5))
                                    : min(weightHistory.count, SubscriptionManager.freeWeightHistoryLimit)
                                let hasExtraRow = (!hasFullAccess && weightHistory.count > SubscriptionManager.freeWeightHistoryLimit)
                                    || (hasFullAccess && weightHistory.count > 5)
                                return baseCount * 85 + (hasExtraRow ? 60 : 0)
                            }()))
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 12)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                                .fill(Color.nutraSafeCard)
                                .shadow(color: DesignTokens.Shadow.subtle.color,
                                        radius: DesignTokens.Shadow.subtle.radius,
                                        y: DesignTokens.Shadow.subtle.y)
                        )
                            .padding(.horizontal, 0)
                    } else {
                        // Empty State
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [palette.accent.opacity(0.1), palette.primary.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)

                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [palette.accent, palette.primary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 20)

                            VStack(spacing: 8) {
                                Text("Track Your Weight Journey")
                                    .font(.system(size: 20, weight: .semibold, design: .serif))
                                    .foregroundColor(palette.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text("Tap 'Update Weight' above to log your first entry and see your progress over time")
                                    .font(.system(size: 15))
                                    .foregroundColor(palette.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                        }
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }

                    }
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
                } // End of Weight tab if

                        // MARK: Diet Tab Content
                        if progressSubTab == .diet {
                            ScrollViewWithTopReset(resetOn: scrollResetTrigger) {
                                DietManagementTabContent()
                                    .environmentObject(firebaseManager)
                            }
                            .scrollDismissesKeyboard(.interactively)
                        }
                    } // End of ZStack
                } // End of loading else block
            }
            .background(AppAnimatedBackground())
        .fullScreenCover(isPresented: $showingAddWeight) {
            LogWeightView(
                currentWeight: $currentWeight,
                weightHistory: $weightHistory,
                userHeight: $userHeight,
                goalWeight: $goalWeight,
                onInstantDismiss: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        showingAddWeight = false
                    }
                },
                // Note: Don't call loadWeightHistory() here - the .weightHistoryUpdated
                // notification already updates weightHistory optimistically. Reloading from
                // Firestore may overwrite with stale data before sync completes.
                onSave: nil
            )
                .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingHeightSetup) {
            HeightSetupView(userHeight: $userHeight)
                .environmentObject(firebaseManager)
        }
        .fullScreenCover(item: $editingEntry) { entry in
            LogWeightView(
                currentWeight: $currentWeight,
                weightHistory: $weightHistory,
                userHeight: $userHeight,
                goalWeight: $goalWeight,
                onInstantDismiss: {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        editingEntry = nil
                    }
                },
                existingEntry: entry,
                // Note: Don't call loadWeightHistory() here - the .weightHistoryUpdated
                // notification already updates weightHistory optimistically.
                onSave: nil
            )
            .environmentObject(firebaseManager)
        }
        .sheet(isPresented: $showingGoalWeightEditor) {
            GoalWeightEditorSheet(
                goalWeight: $goalWeight,
                weightUnit: selectedWeightUnit,
                onSave: saveGoalWeight
            )
        }
        .alert("Delete Weight Entry?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    deleteWeightEntry(entry)
                }
            }
        } message: {
            if let entry = entryToDelete {
                Text("Are you sure you want to delete the weight entry from \(entry.date, style: .date)?")
            }
        }
        .onAppear {
            // PERFORMANCE: Guard against redundant loads - critical for tab switching speed
            guard !hasLoadedOnce else { return }
            hasLoadedOnce = true

            // PERFORMANCE: Use cached data IMMEDIATELY for instant display (no loading spinner)
            // Background refresh happens silently without blocking the UI
            let hasCachedData = !firebaseManager.cachedWeightHistory.isEmpty ||
                                firebaseManager.cachedUserHeight != nil ||
                                firebaseManager.cachedGoalWeight != nil

            // CRITICAL FIX: Use locally cached weight for instant display on app restart
            // This prevents the 70kg default issue when Firebase hasn't loaded yet
            if cachedCurrentWeight > 0 && currentWeight == 0 {
                currentWeight = cachedCurrentWeight
            }

            if hasCachedData {
                // Instant display from cache - no loading state shown
                currentWeight = firebaseManager.cachedWeightHistory.first?.weight ?? currentWeight
                weightHistory = firebaseManager.cachedWeightHistory
                if let h = firebaseManager.cachedUserHeight { userHeight = h }
                if let g = firebaseManager.cachedGoalWeight { goalWeight = g }
                hasCheckedHeight = true
                // Silent background refresh to check for newer data
                loadWeightHistory(silent: true)
            } else {
                // No cache - must show loading state
                loadWeightHistory()
            }

            // PERFORMANCE: Defer non-critical UI (modals/tips) to avoid blocking render
            if needsHeightSetup {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showingHeightSetup = true
                }
            } else if !FeatureTipsManager.shared.hasSeenTip(.progressOverview) {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showingProgressTip = true
                }
            }
        }
        .featureTip(isPresented: $showingProgressTip, tipKey: .progressOverview)
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .goalWeightUpdated)) { notification in
            if let gw = notification.userInfo?["goalWeight"] as? Double {
                goalWeight = gw
            } else {
                Task {
                    do {
                        let settings = try await firebaseManager.getUserSettings()
                        await MainActor.run { goalWeight = settings.goalWeight ?? 0 }
                    } catch {
                        // Ignore errors; UI will refresh on next load
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightHistoryUpdated)) { notification in
            // Optimistically reflect the saved entry if provided; otherwise reload
            if let entry = notification.userInfo?["entry"] as? WeightEntry {
                // Check if entry already exists (editing existing entry)
                if let existingIndex = weightHistory.firstIndex(where: { $0.id == entry.id }) {
                    // Update existing entry
                    weightHistory[existingIndex] = entry
                } else {
                    // Insert new entry at beginning
                    weightHistory.insert(entry, at: 0)
                }
                // Update current weight and re-sort by date
                weightHistory.sort { $0.date > $1.date }
                currentWeight = entry.weight
                cachedCurrentWeight = entry.weight
            } else {
                loadWeightHistory()
            }
        }
        .onChange(of: currentWeight) { _, newWeight in
            // Persist current weight locally for instant access on app restart
            if newWeight > 0 {
                cachedCurrentWeight = newWeight
            }
        }
    }

    // MARK: - Peach Background Gradient
    private var progressGlassBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.96, blue: 1.0),
                    Color(red: 0.93, green: 0.88, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [AppPalette.standard.accent.opacity(0.10), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )
            RadialGradient(
                colors: [Color.purple.opacity(0.08), Color.clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 280
            )
        }
        // PERFORMANCE: drawingGroup() flattens the gradient to a single Metal texture
        // This prevents repeated GPU recalculation of gradients on every frame
        .drawingGroup()
        .ignoresSafeArea()
    }

    private func loadWeightHistory(silent: Bool = false) {
        if !silent { isLoadingData = true }
        Task {
            do {
                // OPTIMIZATION: Load weight history and settings in parallel
                async let historyTask = firebaseManager.getWeightHistory()
                async let settingsTask = firebaseManager.getUserSettings()

                let (history, settings) = try await (historyTask, settingsTask)

                await MainActor.run {
                    weightHistory = history

                    // Set current weight from most recent entry
                    if let latest = history.first {
                        currentWeight = latest.weight
                    }

                    // Load height and goal weight from settings
                    if let height = settings.height {
                        userHeight = height
                    }
                    if let goal = settings.goalWeight {
                        goalWeight = goal
                    }

                    hasCheckedHeight = true
                    if !silent { isLoadingData = false }
                }
            } catch {
                                await MainActor.run {
                    hasCheckedHeight = true
                    if !silent { isLoadingData = false }
                }
            }
        }
    }

    private func deleteWeightEntry(_ entry: WeightEntry) {
        Task {
            do {
                try await firebaseManager.deleteWeightEntry(id: entry.id)
                await MainActor.run {
                    weightHistory.removeAll { $0.id == entry.id }
                    // Update current weight if we deleted the most recent entry
                    if let latest = weightHistory.first {
                        currentWeight = latest.weight
                    } else {
                        currentWeight = 0
                    }
                    entryToDelete = nil
                }
                            } catch {
                                await MainActor.run {
                    entryToDelete = nil
                }
            }
        }
    }

    private func saveGoalWeight() {
        Task {
            do {
                try await firebaseManager.saveUserSettings(height: nil, goalWeight: goalWeight)
                // Notify other views about goal weight change
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .goalWeightUpdated,
                        object: nil,
                        userInfo: ["goalWeight": goalWeight]
                    )
                }
            } catch {
                // Silently fail - the UI is already updated
            }
        }
    }

    // MARK: - Progress Tab Picker (Matching Health Tab Style)
    @Namespace private var progressTabAnimation

    private var progressTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ProgressSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        progressSubTab = tab
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            progressSubTab == tab ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.secondary, Color.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if progressSubTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "progressSegmentedControl", in: progressTabAnimation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(height: 40)
    }
}

// MARK: - Diet Management Tab Content
struct DietManagementTabContent: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    // Calorie goal
    @AppStorage("cachedCaloricGoal") private var cachedCaloricGoal: Int = 2000
    @State private var calorieGoal: Int = 2000

    // Macro goals
    @State private var macroGoals: [MacroGoal] = MacroGoal.defaultMacros
    @AppStorage("cachedDietType") private var cachedDietType: String = "flexible"
    @State private var selectedDietType: DietType? = nil // Initialized from cached value in onAppear

    // BMR Calculator
    @State private var showingBMRCalculator: Bool = false
    @AppStorage("userSex") private var userSex: String = "female"
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("userHeightCm") private var userHeightCm: Double = 165
    @AppStorage("userWeightKg") private var userWeightKg: Double = 65
    @AppStorage("userActivityLevel") private var userActivityLevel: String = "moderate"

    // Diet Management sheet
    @State private var showingDietManagement: Bool = false
    @State private var customCarbLimit: Int = 50
    @AppStorage("customCarbLimit") private var savedCarbLimit: Int = 50

    // Activity Goals
    @AppStorage("cachedStepGoal") private var cachedStepGoal: Int = 10000
    @AppStorage("cachedExerciseGoal") private var cachedExerciseGoal: Int = 400
    @State private var stepGoal: Int = 10000
    @State private var exerciseGoal: Int = 400

    // Calorie editing state
    @State private var isEditingCalories: Bool = false
    @State private var calorieText: String = ""
    @FocusState private var calorieFieldFocused: Bool

    // Step goal editing state
    @State private var isEditingSteps: Bool = false
    @State private var stepText: String = ""
    @FocusState private var stepFieldFocused: Bool

    // Exercise goal editing state
    @State private var isEditingExercise: Bool = false
    @State private var exerciseText: String = ""
    @FocusState private var exerciseFieldFocused: Bool

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        LazyVStack(spacing: DesignTokens.Spacing.lg) {
            // Welcome header
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Your Daily Goals")
                    .font(DesignTokens.Typography.sectionTitle(20))
                    .foregroundColor(palette.textPrimary)

                Text("Tap any value to edit. These are guides, not rules.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)
            .padding(.top, DesignTokens.Spacing.md)

            // Calorie Goal Card
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)

                    Text("Daily Calories")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Button {
                        showingBMRCalculator = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "function")
                                .font(.system(size: 12))
                            Text("BMR")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(palette.accent.opacity(0.12))
                        )
                    }
                }

                // Calorie display with tap-to-edit
                HStack(alignment: .center) {
                    if isEditingCalories {
                        TextField("", text: $calorieText)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .keyboardType(.numberPad)
                            .focused($calorieFieldFocused)
                            .multilineTextAlignment(.leading)
                            .frame(width: 140)
                            .onSubmit { commitCalorieEdit() }
                            .onChange(of: calorieFieldFocused) { _, focused in
                                if !focused { commitCalorieEdit() }
                            }
                    } else {
                        Text("\(calorieGoal)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .contentTransition(.numericText())
                            .onTapGesture {
                                calorieText = "\(calorieGoal)"
                                isEditingCalories = true
                                calorieFieldFocused = true
                            }
                    }

                    Text("kcal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(palette.textTertiary)

                    Spacer()

                    // Stepper controls
                    HStack(spacing: 12) {
                        Button {
                            if calorieGoal > 1000 {
                                calorieGoal -= 50
                                saveCalorieGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(calorieGoal > 1000 ? palette.textSecondary : palette.textTertiary.opacity(0.4))
                        }
                        .disabled(calorieGoal <= 1000)

                        Button {
                            if calorieGoal < 5000 {
                                calorieGoal += 50
                                saveCalorieGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(calorieGoal < 5000 ? palette.textSecondary : palette.textTertiary.opacity(0.4))
                        }
                        .disabled(calorieGoal >= 5000)
                    }
                }

                // UK Recommendations
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("UK Reference Intake")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(palette.textTertiary)

                    HStack(spacing: 10) {
                        // Show female option if gender is female, other/notSet, or not set
                        if OnboardingManager.shared.userGender != .male {
                            Button {
                                calorieGoal = 2000
                                saveCalorieGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "figure.stand.dress")
                                        .font(.system(size: 13))
                                    Text(OnboardingManager.shared.userGender == .female ? "2,000" : "Women: 2,000")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(calorieGoal == 2000 ? .white : Color.pink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                        .fill(calorieGoal == 2000 ? Color.pink : Color.pink.opacity(0.12))
                                )
                            }
                        }

                        // Show male option if gender is male, other/notSet, or not set
                        if OnboardingManager.shared.userGender != .female {
                            Button {
                                calorieGoal = 2500
                                saveCalorieGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "figure.stand")
                                        .font(.system(size: 13))
                                    Text(OnboardingManager.shared.userGender == .male ? "2,500" : "Men: 2,500")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(calorieGoal == 2500 ? .white : palette.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                        .fill(calorieGoal == 2500 ? palette.accent : palette.accent.opacity(0.12))
                                )
                            }
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(palette.cardBackground)
            )
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)

            // Current Diet Card
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)

                    Text("Diet Style")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Button {
                        showingDietManagement = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Customise")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(palette.accent)
                    }
                }

                if let diet = selectedDietType {
                    HStack(spacing: 14) {
                        Image(systemName: diet.icon)
                            .font(.system(size: 24))
                            .foregroundColor(diet.accentColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(diet.accentColor.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(diet.displayName)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                            Text(diet.shortDescription)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(palette.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }

                    // Macro breakdown - horizontal compact
                    HStack(spacing: 0) {
                        let ratios = diet.macroRatios

                        MacroChip(label: "Protein", value: "\(ratios.protein)%", color: .red.opacity(0.8))

                        Spacer()

                        MacroChip(label: "Carbs", value: "\(ratios.carbs)%", color: .orange)

                        Spacer()

                        MacroChip(label: "Fat", value: "\(ratios.fat)%", color: .yellow.opacity(0.9))
                    }
                    .padding(.top, 4)
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 24))
                            .foregroundColor(palette.accent)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(palette.accent.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Custom Macros")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                            Text("Your personalised balance")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(palette.textSecondary)
                        }

                        Spacer()
                    }
                }
            }
            .padding(DesignTokens.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(palette.cardBackground)
            )
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)

            // Activity Goals Card
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.system(size: 18))
                        .foregroundColor(palette.accent)

                    Text("Activity")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Spacer()
                }

                // Step Goal Row
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .frame(width: 28)

                        Text("Steps")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(palette.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button {
                            if stepGoal > 1000 {
                                stepGoal -= 500
                                saveStepGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(stepGoal <= 1000 ? palette.textTertiary.opacity(0.4) : palette.textSecondary)
                        }
                        .disabled(stepGoal <= 1000)

                        if isEditingSteps {
                            TextField("", text: $stepText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .keyboardType(.numberPad)
                                .focused($stepFieldFocused)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onSubmit { commitStepEdit() }
                                .onChange(of: stepFieldFocused) { _, focused in
                                    if !focused { commitStepEdit() }
                                }
                        } else {
                            Text(formatStepCount(Double(stepGoal)))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .frame(width: 80)
                                .lineLimit(1)
                                .contentTransition(.numericText())
                                .onTapGesture {
                                    stepText = "\(stepGoal)"
                                    isEditingSteps = true
                                    stepFieldFocused = true
                                }
                        }

                        Button {
                            if stepGoal < 30000 {
                                stepGoal += 500
                                saveStepGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(stepGoal >= 30000 ? palette.textTertiary.opacity(0.4) : palette.textSecondary)
                        }
                        .disabled(stepGoal >= 30000)
                    }
                }

                Divider()
                    .background(palette.textTertiary.opacity(0.3))

                // Exercise Calories Row
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "flame")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .frame(width: 28)

                        Text("Burn")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(palette.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Button {
                            if exerciseGoal > 100 {
                                exerciseGoal -= 50
                                saveExerciseGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(exerciseGoal <= 100 ? palette.textTertiary.opacity(0.4) : palette.textSecondary)
                        }
                        .disabled(exerciseGoal <= 100)

                        if isEditingExercise {
                            TextField("", text: $exerciseText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                                .keyboardType(.numberPad)
                                .focused($exerciseFieldFocused)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                                .onSubmit { commitExerciseEdit() }
                                .onChange(of: exerciseFieldFocused) { _, focused in
                                    if !focused { commitExerciseEdit() }
                                }
                        } else {
                            HStack(spacing: 2) {
                                Text("\(exerciseGoal)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                Text("kcal")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(palette.textTertiary)
                            }
                            .frame(width: 80)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .onTapGesture {
                                exerciseText = "\(exerciseGoal)"
                                isEditingExercise = true
                                exerciseFieldFocused = true
                            }
                        }

                        Button {
                            if exerciseGoal < 2000 {
                                exerciseGoal += 50
                                saveExerciseGoal()
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(exerciseGoal >= 2000 ? palette.textTertiary.opacity(0.4) : palette.textSecondary)
                        }
                        .disabled(exerciseGoal >= 2000)
                    }
                }
            }
            .padding(DesignTokens.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(palette.cardBackground)
            )
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)

            Spacer(minLength: 100)
        }
        .onAppear {
            calorieGoal = cachedCaloricGoal
            stepGoal = cachedStepGoal
            exerciseGoal = cachedExerciseGoal
            customCarbLimit = savedCarbLimit
            loadDietSettings()
        }
        .sheet(isPresented: $showingBMRCalculator) {
            BMRCalculatorRedesigned(
                userSex: $userSex,
                userAge: $userAge,
                userHeightCm: $userHeightCm,
                userWeightKg: $userWeightKg,
                userActivityLevel: $userActivityLevel,
                onCalculate: { calculatedGoal in
                    calorieGoal = calculatedGoal
                    saveCalorieGoal()
                }
            )
            .environmentObject(firebaseManager)
        }
        .fullScreenCover(isPresented: $showingDietManagement) {
            DietManagementRedesigned(
                macroGoals: $macroGoals,
                dietType: $selectedDietType,
                customCarbLimit: $customCarbLimit,
                onSave: { newDiet in
                    selectedDietType = newDiet
                    saveDietSettings()
                }
            )
            .environmentObject(firebaseManager)
        }
    }

    // MARK: - Calorie Edit Helpers

    private func commitCalorieEdit() {
        isEditingCalories = false
        if let newValue = Int(calorieText), newValue >= 1000, newValue <= 5000 {
            calorieGoal = newValue
            saveCalorieGoal()
        }
        calorieText = ""
    }

    private func commitStepEdit() {
        isEditingSteps = false
        if let newValue = Int(stepText), newValue >= 1000, newValue <= 30000 {
            stepGoal = newValue
            saveStepGoal()
        }
        stepText = ""
    }

    private func commitExerciseEdit() {
        isEditingExercise = false
        if let newValue = Int(exerciseText), newValue >= 100, newValue <= 2000 {
            exerciseGoal = newValue
            saveExerciseGoal()
        }
        exerciseText = ""
    }

    private func saveCalorieGoal() {
        cachedCaloricGoal = calorieGoal
        Task {
            try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, caloricGoal: calorieGoal)
        }
        NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
    }

    private func saveStepGoal() {
        cachedStepGoal = stepGoal
        Task {
            try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, stepGoal: stepGoal)
        }
        NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
    }

    private func saveExerciseGoal() {
        cachedExerciseGoal = exerciseGoal
        Task {
            try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, exerciseGoal: exerciseGoal)
        }
        NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
    }

    private func formatStepCount(_ count: Double) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", count / 1000)
        }
        return "\(Int(count))"
    }

    private func loadDietSettings() {
        Task {
            // First, initialize from cached values (includes onboarding-set values)
            await MainActor.run {
                // Initialize diet type from UserDefaults cache if not already set
                if selectedDietType == nil {
                    selectedDietType = DietType(rawValue: cachedDietType) ?? .flexible
                }
                // Initialize calorie goal from cache
                if calorieGoal == 2000 {
                    calorieGoal = cachedCaloricGoal
                }
            }

            do {
                let settings = try await firebaseManager.getUserSettings()
                await MainActor.run {
                    if let cal = settings.caloricGoal {
                        calorieGoal = cal
                        cachedCaloricGoal = cal
                    }
                }

                // Load diet type from Firebase (overrides cache if present)
                if let dietData = try? await firebaseManager.getDietType() {
                    await MainActor.run {
                        selectedDietType = dietData
                        cachedDietType = dietData.rawValue
                    }
                }
                // If Firebase doesn't have diet data, keep the cached value (from onboarding)
            } catch {
                // Use cached values (already initialized above)
            }
        }
    }

    private func saveDietSettings() {
        // Update local cache immediately
        if let diet = selectedDietType {
            cachedDietType = diet.rawValue
        }

        Task {
            // Save diet type along with macro goals to Firebase
            try? await firebaseManager.saveMacroGoals(macroGoals, dietType: selectedDietType)
            // Notify diary view to update immediately
            await MainActor.run {
                NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
            }
        }
    }
}

// MARK: - Macro Bar Row
struct MacroBarRow: View {
    let label: String
    let percent: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 55, alignment: .leading)

            // PERF: Replaced GeometryReader with percentage-based layout
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: CGFloat(min(max(percent, 0), 100)) / 100, y: 1, anchor: .leading)
            }
            .frame(height: 8)

            Text("\(percent)%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Macro Chip (for compact diet display)
struct MacroChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let value: String
    let color: Color

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Weight Entry Row
struct WeightEntryRow: View {
    let entry: WeightEntry
    let previousEntry: WeightEntry?
    let isLatest: Bool
    @AppStorage("weightUnit") private var selectedWeightUnit: WeightUnit = .kg

    private var weightChange: Double? {
        guard let previous = previousEntry else { return nil }
        return entry.weight - previous.weight
    }

    private func formatWeight(_ kg: Double) -> String {
        let converted = selectedWeightUnit.fromKg(kg)
        switch selectedWeightUnit {
        case .kg:
            return String(format: "%.1f", converted.primary)
        case .lbs:
            return String(format: "%.1f", converted.primary)
        case .stones:
            let st = Int(converted.primary)
            let lbs = converted.secondary ?? 0
            return "\(st)st \(String(format: "%.0f", lbs))lb"
        }
    }

    private var weightUnit: String {
        switch selectedWeightUnit {
        case .kg: return "kg"
        case .lbs: return "lbs"
        case .stones: return ""  // Already included in formatted string
        }
    }

    private var formattedDate: String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.shortDateUKFormatter.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(formattedDate)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(entry.date, style: .time)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            // Weight
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatWeight(entry.weight))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Text(weightUnit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                if let bmi = entry.bmi {
                    Text("BMI: \(String(format: "%.1f", bmi))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Change indicator
            if let change = weightChange {
                HStack(spacing: 4) {
                    Image(systemName: change < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(formatWeight(abs(change))) \(weightUnit)")
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(change < 0 ? .green : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((change < 0 ? Color.green : Color.red).opacity(0.15))
                )
            } else if isLatest {
                Text("Latest")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppPalette.standard.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppPalette.standard.accent.opacity(0.15))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.bottom, 8)
    }
}

// MARK: - Progress Tab Weight Entry Detail View
struct ProgressWeightEntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    let entry: WeightEntry
    @State private var photoImage: UIImage?
    @State private var isLoadingPhoto = false
    let onEdit: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Photo section
                    if entry.photoURL != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress Photo")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if let image = photoImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            } else if isLoadingPhoto {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Weight & BMI section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Measurements")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 32) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weight")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f kg", entry.weight))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppPalette.standard.accent)
                            }

                            if let bmi = entry.bmi {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BMI")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f", bmi))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    // Additional measurements
                    if entry.waistSize != nil || entry.dressSize != nil {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Measurements")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            if let waist = entry.waistSize {
                                HStack {
                                    Text("Waist Size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f cm", waist))
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }

                            if let dress = entry.dressSize {
                                HStack {
                                    Text("Dress Size")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dress)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Date section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(entry.date, style: .date)
                            .font(.system(size: 15))
                        Text(entry.date, style: .time)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)

                    // Note section
                    if let note = entry.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(note)
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                    }

                    // Edit button
                    Button(action: {
                        // First dismiss this sheet
                        dismiss()
                        // Then trigger the edit action after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            onEdit()
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Entry")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppPalette.standard.accent)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Weight Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load photo if available
                if let photoURL = entry.photoURL {
                    isLoadingPhoto = true
                    Task {
                        do {
                            let image = try await firebaseManager.downloadWeightPhoto(from: photoURL)
                            await MainActor.run {
                                photoImage = image
                                isLoadingPhoto = false
                            }
                        } catch {
                                                        await MainActor.run {
                                isLoadingPhoto = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Weight Unit System
enum WeightUnit: String, CaseIterable, Codable {
    case kg = "Kilograms (kg)"
    case lbs = "Pounds (lbs)"
    case stones = "Stones & lbs"

    var shortName: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        case .stones: return "st"
        }
    }

    // Convert from kg (storage format) to display format
    func fromKg(_ kg: Double) -> (primary: Double, secondary: Double?) {
        switch self {
        case .kg:
            return (kg, nil)
        case .lbs:
            return (kg * 2.20462, nil)
        case .stones:
            let totalPounds = kg * 2.20462
            let stones = floor(totalPounds / 14)
            let pounds = totalPounds.truncatingRemainder(dividingBy: 14)
            return (stones, pounds)
        }
    }

    // Convert from display format to kg (storage format)
    func toKg(primary: Double, secondary: Double? = nil) -> Double {
        switch self {
        case .kg:
            return primary
        case .lbs:
            return primary / 2.20462
        case .stones:
            let totalPounds = (primary * 14) + (secondary ?? 0)
            return totalPounds / 2.20462
        }
    }
}

// MARK: - Height Unit System
enum HeightUnit: String, CaseIterable, Codable {
    case cm = "Centimeters (cm)"
    case ftIn = "Feet & Inches (ft/in)"

    var shortName: String {
        switch self {
        case .cm: return "cm"
        case .ftIn: return "ft"
        }
    }

    // Convert from cm (storage format) to display format
    func fromCm(_ cm: Double) -> (primary: Double, secondary: Double?) {
        switch self {
        case .cm:
            return (cm, nil)
        case .ftIn:
            let totalInches = cm / 2.54
            let feet = floor(totalInches / 12)
            let inches = totalInches.truncatingRemainder(dividingBy: 12)
            return (feet, inches)
        }
    }

    // Convert from display format to cm (storage format)
    func toCm(primary: Double, secondary: Double? = nil) -> Double {
        switch self {
        case .cm:
            return primary
        case .ftIn:
            let totalInches = (primary * 12) + (secondary ?? 0)
            return totalInches * 2.54
        }
    }
}

// MARK: - Weight Entry Model
struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let weight: Double // Always stored in kg
    let date: Date
    let bmi: Double?
    let note: String?
    let photoURL: String? // Firebase Storage path (legacy - for backward compatibility)
    let photoURLs: [String]? // Multiple photo URLs
    let waistSize: Double? // Waist measurement in cm
    let dressSize: String? // Dress size (UK/US format)

    init(id: UUID = UUID(), weight: Double, date: Date = Date(), bmi: Double? = nil, note: String? = nil, photoURL: String? = nil, photoURLs: [String]? = nil, waistSize: Double? = nil, dressSize: String? = nil) {
        self.id = id
        self.weight = weight
        self.date = date
        self.bmi = bmi
        self.note = note
        self.photoURL = photoURL
        self.photoURLs = photoURLs
        self.waistSize = waistSize
        self.dressSize = dressSize
    }
}

// MARK: - History Row
struct WeightHistoryRow: View {
    let entry: WeightEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.system(size: 17, weight: .semibold))

                    Text(entry.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let bmi = entry.bmi {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BMI")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppPalette.standard.accent)
                    }
                }
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Simple Chart
struct SimpleWeightChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double

    // PERFORMANCE: Pre-compute sorted entries and bounds once
    private struct ChartData {
        let sortedEntries: [WeightEntry]
        let maxWeight: Double
        let minWeight: Double
        let weightRange: Double
    }

    private var chartData: ChartData {
        let sorted = entries.sorted { $0.date < $1.date }
        let weights = sorted.map { $0.weight }
        let maxW = max(weights.max() ?? 0, goalWeight)
        let minW = min(weights.min() ?? 0, goalWeight)
        return ChartData(sortedEntries: sorted, maxWeight: maxW, minWeight: minW, weightRange: max(maxW - minW, 1))
    }

    var body: some View {
        let data = chartData // Compute once per render
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Goal line
                if goalWeight > 0 {
                    let goalY = (1 - (goalWeight - data.minWeight) / data.weightRange) * geometry.size.height

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: goalY))
                    }
                    .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }

                // Weight line
                if data.sortedEntries.count > 1 {
                    Path { path in
                        for (index, entry) in data.sortedEntries.enumerated() {
                            let x = (CGFloat(index) / CGFloat(data.sortedEntries.count - 1)) * geometry.size.width
                            let y = (1 - (entry.weight - data.minWeight) / data.weightRange) * geometry.size.height

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(AppPalette.standard.accent, lineWidth: 3)
                }

                // Data points
                ForEach(data.sortedEntries.indices, id: \.self) { index in
                    let entry = data.sortedEntries[index]
                    let x = (CGFloat(index) / CGFloat(max(data.sortedEntries.count - 1, 1))) * geometry.size.width
                    let y = (1 - (entry.weight - data.minWeight) / data.weightRange) * geometry.size.height

                    Circle()
                        .fill(AppPalette.standard.accent)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .drawingGroup() // PERF: Flatten paths to Metal texture for scroll performance
    }
}

// MARK: - Weight Line Chart
struct WeightLineChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let startWeight: Double
    var weightUnit: WeightUnit = .kg

    // Date formatter for axis labels
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d/M"
        return f
    }()

    // Format weight value according to selected unit
    private func formatWeight(_ kg: Double) -> String {
        let converted = weightUnit.fromKg(kg)
        switch weightUnit {
        case .kg:
            return String(format: "%.1f", converted.primary)
        case .lbs:
            return String(format: "%.0f", converted.primary)
        case .stones:
            let st = Int(converted.primary)
            let lbs = converted.secondary ?? 0
            return "\(st).\(Int(lbs))"
        }
    }

    // Weight bounds based on actual entry weights for meaningful scaling
    // This makes small changes look significant when you only have a few entries
    private var weightBounds: (min: Double, max: Double, range: Double) {
        let weights = entries.map { $0.weight }
        guard !weights.isEmpty else {
            return (0, 100, 100)
        }

        let dataMin = weights.min() ?? 0
        let dataMax = weights.max() ?? 0
        let dataRange = dataMax - dataMin

        // Calculate padding - use at least 20% of the data range, or 2kg minimum
        // This ensures small changes are visually significant
        let padding = max(dataRange * 0.3, 2.0)

        var minW = dataMin - padding
        var maxW = dataMax + padding

        // Only include goal weight if it's reasonably close to the data
        // (within 10kg of the data range) - otherwise it compresses the chart too much
        if goalWeight > 0 {
            let distanceFromData = min(abs(goalWeight - dataMin), abs(goalWeight - dataMax))
            if distanceFromData <= 10 {
                minW = min(minW, goalWeight - 1)
                maxW = max(maxW, goalWeight + 1)
            }
        }

        // Ensure minimum range for visual impact
        let range = max(maxW - minW, 5.0)

        return (minW, maxW, range)
    }

    // Line color based on trend
    private var lineColor: Color {
        guard entries.count >= 2 else { return .blue }
        let firstWeight = entries.first?.weight ?? 0
        let lastWeight = entries.last?.weight ?? 0

        if goalWeight > 0 {
            // If losing towards goal
            if lastWeight < firstWeight && lastWeight >= goalWeight {
                return .green
            } else if lastWeight <= goalWeight {
                return .green
            }
        }
        return lastWeight <= firstWeight ? .green : .orange
    }

    var body: some View {
        let bounds = weightBounds

        GeometryReader { geometry in
            let width = geometry.size.width - 50 // Leave space for Y-axis labels
            let height = geometry.size.height - 30 // Leave space for X-axis labels
            let chartLeft: CGFloat = 45
            let chartTop: CGFloat = 10

            ZStack(alignment: .topLeading) {
                // Background grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 1)
                        if i < 4 {
                            Spacer()
                        }
                    }
                }
                .frame(width: width, height: height)
                .offset(x: chartLeft, y: chartTop)

                // Y-axis labels
                VStack {
                    Text(formatWeight(bounds.max))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatWeight((bounds.max + bounds.min) / 2))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatWeight(bounds.min))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 40, height: height)
                .offset(y: chartTop)

                // Goal line (dashed horizontal)
                if goalWeight > 0 {
                    let goalY = chartTop + height - CGFloat((goalWeight - bounds.min) / bounds.range) * height

                    Path { path in
                        path.move(to: CGPoint(x: chartLeft, y: goalY))
                        path.addLine(to: CGPoint(x: chartLeft + width, y: goalY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(.green.opacity(0.7))

                    // Goal label
                    Text("Goal: \(formatWeight(goalWeight))")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                        .offset(x: chartLeft + width - 60, y: goalY - 18)
                }

                // Line graph with gradient fill
                if entries.count >= 2 {
                    let points = entries.enumerated().map { index, entry -> CGPoint in
                        let x = chartLeft + (CGFloat(index) / CGFloat(max(entries.count - 1, 1))) * width
                        let y = chartTop + height - CGFloat((entry.weight - bounds.min) / bounds.range) * height
                        return CGPoint(x: x, y: y)
                    }

                    // Gradient fill under the line
                    Path { path in
                        guard let firstPoint = points.first else { return }
                        path.move(to: CGPoint(x: firstPoint.x, y: chartTop + height))
                        path.addLine(to: firstPoint)

                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }

                        if let lastPoint = points.last {
                            path.addLine(to: CGPoint(x: lastPoint.x, y: chartTop + height))
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.3), lineColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // The line itself
                    Path { path in
                        guard let firstPoint = points.first else { return }
                        path.move(to: firstPoint)

                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Dots for each entry
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        let isLast = index == points.count - 1
                        let isFirst = index == 0
                        let entry = entries[index]

                        Circle()
                            .fill(isLast ? lineColor : Color.white)
                            .frame(width: isLast ? 10 : 7, height: isLast ? 10 : 7)
                            .overlay(
                                Circle()
                                    .stroke(lineColor, lineWidth: isLast ? 0 : 2)
                            )
                            .shadow(color: lineColor.opacity(0.3), radius: isLast ? 4 : 0)
                            .position(point)

                        // Show weight label for first, last, and every ~5th point
                        if isFirst || isLast || (entries.count > 10 && index % max(entries.count / 5, 1) == 0) {
                            Text(formatWeight(entry.weight))
                                .font(.system(size: 9, weight: isLast ? .bold : .medium, design: .rounded))
                                .foregroundColor(isLast ? lineColor : .secondary)
                                .offset(x: point.x, y: point.y - 14)
                        }
                    }
                } else if entries.count == 1, let entry = entries.first {
                    // Single entry - just show a dot
                    let x = chartLeft + width / 2
                    let y = chartTop + height - CGFloat((entry.weight - bounds.min) / bounds.range) * height

                    Circle()
                        .fill(lineColor)
                        .frame(width: 12, height: 12)
                        .position(x: x, y: y)

                    Text(formatWeight(entry.weight))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(lineColor)
                        .position(x: x, y: y - 16)
                }

                // X-axis date labels (first, middle, last)
                if entries.count >= 2 {
                    HStack {
                        Text(dateFormatter.string(from: entries.first?.date ?? Date()))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        if entries.count > 2 {
                            Text(dateFormatter.string(from: entries[entries.count / 2].date))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        Text(dateFormatter.string(from: entries.last?.date ?? Date()))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: width)
                    .offset(x: chartLeft, y: chartTop + height + 5)
                }
            }
        }
    }
}

// MARK: - Picker Type Enum
enum PhotoPickerType: Identifiable {
    case camera
    case photoLibrary

    var id: String {
        switch self {
        case .camera: return "camera"
        case .photoLibrary: return "photoLibrary"
        }
    }

    var sourceType: UIImagePickerController.SourceType {
        switch self {
        case .camera: return .camera
        case .photoLibrary: return .photoLibrary
        }
    }
}

// MARK: - Identifiable Image Wrapper
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let url: String? // URL if this is an existing photo from server
}

// MARK: - Weighing Scale Icon
struct WeighingScaleIcon: View {
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        ZStack {
            // Platform base (rectangular with rounded corners)
            RoundedRectangle(cornerRadius: size * 0.15)
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.95, height: size * 0.7)
                .offset(y: size * 0.1)

            // Analog gauge dial (semi-circle at top)
            Circle()
                .trim(from: 0.25, to: 0.75)
                .stroke(color, lineWidth: size * 0.08)
                .frame(width: size * 0.5, height: size * 0.5)
                .rotationEffect(.degrees(180))
                .offset(y: -size * 0.1)

            // Needle
            Rectangle()
                .fill(color)
                .frame(width: size * 0.04, height: size * 0.2)
                .offset(y: -size * 0.1)
                .rotationEffect(.degrees(30))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Add Weight View
struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]
    @Binding var userHeight: Double
    @Binding var goalWeight: Double
    var onInstantDismiss: (() -> Void)? = nil  // For instant dismiss without animation

    var existingEntry: WeightEntry? = nil // For editing existing entries

    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm
    @AppStorage("userGender") private var userGender: Gender = .other
    @State private var primaryWeight: String = "" // kg, lbs, or stones
    @State private var secondaryWeight: String = "" // pounds (for stones only)
    @State private var primaryHeight: String = "" // cm or feet
    @State private var secondaryHeight: String = "" // inches (for ft/in only)
    @State private var note: String = ""
    @State private var date = Date()

    // Goal weight
    @State private var goalWeightText: String = ""
    @State private var initialGoalWeight: Double = 0

    // Photo picker
    @State private var selectedPhotos: [IdentifiableImage] = []
    @State private var isLoadingPhotos = false
    @State private var activePickerType: PhotoPickerType? = nil
    @State private var showingPhotoOptions = false
    @State private var isUploading = false
    @State private var selectedPhotoForViewing: IdentifiableImage? = nil
    @State private var showingMultiImagePicker = false

    // Measurements
    @State private var waistSize: String = ""
    @State private var dressSize: String = ""

    private var weightInKg: Double? {
        guard let primary = Double(primaryWeight) else { return nil }
        let secondary = selectedUnit == .stones ? Double(secondaryWeight) : nil
        return selectedUnit.toKg(primary: primary, secondary: secondary)
    }

    private var heightInCm: Double? {
        guard let primary = Double(primaryHeight) else { return nil }
        let secondary = selectedHeightUnit == .ftIn ? Double(secondaryHeight) : nil
        return selectedHeightUnit.toCm(primary: primary, secondary: secondary)
    }

    private var calculatedBMI: Double? {
        guard let weightKg = weightInKg else { return nil }
        guard let heightCm = heightInCm, heightCm > 0 else { return nil }
        let heightInMeters = heightCm / 100
        return weightKg / (heightInMeters * heightInMeters)
    }

    // Goal weight conversion helpers
    private var goalWeightInKg: Double? {
        let sanitized = goalWeightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(sanitized), value > 0 else { return nil }
        // Convert from display unit to kg
        switch selectedUnit {
        case .kg:
            return value
        case .lbs:
            return value / 2.20462
        case .stones:
            // For stones, we only use a single input for simplicity (total weight in stones)
            return value * 6.35029 // 1 stone = 6.35 kg
        }
    }

    private func goalWeightDisplayValue(_ kg: Double) -> String {
        switch selectedUnit {
        case .kg:
            return String(format: "%.1f", kg)
        case .lbs:
            return String(format: "%.1f", kg * 2.20462)
        case .stones:
            return String(format: "%.1f", kg / 6.35029)
        }
    }

    private var goalWeightUnitLabel: String {
        selectedUnit.shortName
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Height")) {
                    Picker("Height Unit", selection: $selectedHeightUnit) {
                        ForEach(HeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedHeightUnit == .ftIn {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Feet", text: $primaryHeight)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("ft").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Inches", text: $secondaryHeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("in").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Height", text: $primaryHeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedHeightUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Weight")) {
                    Picker("Weight Unit", selection: $selectedUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedUnit == .stones {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Stones", text: $primaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("st").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Pounds", text: $secondaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("lbs").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Weight", text: $primaryWeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let bmi = calculatedBMI {
                        HStack {
                            Text("BMI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }

                // Goal Weight Section
                Section(header: Text("Goal Weight (Optional)")) {
                    HStack {
                        TextField("Goal weight", text: $goalWeightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .semibold))

                        Text(goalWeightUnitLabel)
                            .foregroundColor(.secondary)
                    }

                    if let currentKg = weightInKg, let goalKg = goalWeightInKg {
                        let difference = currentKg - goalKg
                        HStack {
                            Text(difference > 0 ? "To lose" : "To gain")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f %@", abs(difference), selectedUnit == .kg ? "kg" : selectedUnit == .lbs ? "lbs" : "st"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(difference > 0 ? .green : .blue)
                        }
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Photo Section - AddWeightView
                Section(header: Text("Progress Photos (Optional - up to 3)")) {
                    // Show selected photos in a grid
                    if !selectedPhotos.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(selectedPhotos) { identifiableImage in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: identifiableImage.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedPhotoForViewing = identifiableImage
                                        }

                                    // Delete button
                                    Button(action: {
                                                                                selectedPhotos.removeAll { $0.id == identifiableImage.id }
                                                                            }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Show add photo buttons if less than 3 photos
                    if selectedPhotos.count < 3 {
                        Button(action: {
                                                        activePickerType = .camera
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                                if !selectedPhotos.isEmpty {
                                    Spacer()
                                    Text("(\(selectedPhotos.count)/3)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Button(action: {
                            showingMultiImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Library")
                            }
                        }
                    } else {
                        Text("Maximum 3 photos added")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    }
                }

                // Measurements Section (conditional based on gender)
                if userGender == .female {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Dress Size (e.g., UK 12)", text: $dressSize)
                            .keyboardType(.default)
                    }
                } else {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Waist Size (cm)", text: $waistSize)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let instantDismiss = onInstantDismiss {
                            instantDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(primaryWeight.isEmpty || weightInKg == nil || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(selectedPhotos.isEmpty ? "Saving weight..." : "Uploading photos...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .onAppear {
                // Pre-populate height fields from userHeight
                if userHeight > 0 {
                    let converted = selectedHeightUnit.fromCm(userHeight)
                    primaryHeight = String(format: converted.secondary != nil ? "%.0f" : "%.1f", converted.primary)
                    if let secondary = converted.secondary {
                        secondaryHeight = String(format: "%.1f", secondary)
                    }
                }
                // Pre-populate goal weight if set
                if goalWeight > 0 {
                    initialGoalWeight = goalWeight
                    goalWeightText = goalWeightDisplayValue(goalWeight)
                }
            }
            .fullScreenCover(item: $activePickerType) { pickerType in
                // Only use this for camera - library uses MultiImagePicker
                if pickerType == .camera {
                    ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                        activePickerType = nil // Dismiss picker
                        if let image = image, selectedPhotos.count < 3 {
                                                        selectedPhotos.append(IdentifiableImage(image: image, url: nil))
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingMultiImagePicker) {
                MultiImagePicker(maxSelection: 3 - selectedPhotos.count) { images in
                    showingMultiImagePicker = false // Dismiss the picker
                    let availableSlots = 3 - selectedPhotos.count
                    let photosToAdd = min(images.count, availableSlots)

                    for i in 0..<photosToAdd {
                        selectedPhotos.append(IdentifiableImage(image: images[i], url: nil))
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    activePickerType = .camera
                }
                Button("Choose from Library") {
                    showingMultiImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func saveWeight() {
        guard let weightKg = weightInKg else { return }

        isUploading = true

        // Save to Firebase
        Task {
            do {
                // Generate ID for new entry
                let entryId = UUID()

                // Extract images from selected photos
                let images = selectedPhotos.map { $0.image }

                // Save images to local cache first
                var photoURLs: [String] = []
                if !images.isEmpty {
                    // Save all images locally
                    do {
                        try ImageCacheManager.shared.saveWeightImages(images, for: entryId.uuidString)
                                            } catch {
                                            }

                    // Upload to Firebase for backup/sync
                    do {
                        photoURLs = try await firebaseManager.uploadWeightPhotos(images)
                                            } catch {
                                            }
                }

                // Parse measurements
                let waist = waistSize.isEmpty ? nil : Double(waistSize)
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create entry with all fields
                let entry = WeightEntry(
                    id: entryId,
                    weight: weightKg,
                    date: date,
                    bmi: calculatedBMI,
                    note: note.isEmpty ? nil : note,
                    photoURL: photoURLs.first, // For backward compatibility
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    waistSize: waist,
                    dressSize: dress
                )

                try await firebaseManager.saveWeightEntry(entry)

                // Save height changes if user modified it
                if let heightCm = heightInCm, heightCm != userHeight {
                    try await firebaseManager.saveUserSettings(height: heightCm, goalWeight: nil)
                }

                // Save goal weight if changed
                let newGoalKg = goalWeightInKg
                if let newGoal = newGoalKg, newGoal != initialGoalWeight {
                    try await firebaseManager.saveUserSettings(height: nil, goalWeight: newGoal)
                    // Notify other views about goal weight change
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .goalWeightUpdated,
                            object: nil,
                            userInfo: ["goalWeight": newGoal]
                        )
                    }
                }

                await MainActor.run {
                    // FIX: Don't insert locally - NotificationCenter listener handles it
                    // This prevents duplicate entries
                    currentWeight = weightKg

                    // Update height if changed
                    if let heightCm = heightInCm, heightCm != userHeight {
                        userHeight = heightCm
                    }

                    // Update goal weight binding if changed
                    if let newGoal = newGoalKg, newGoal != initialGoalWeight {
                        goalWeight = newGoal
                    }

                    isUploading = false
                    dismiss()
                }
            } catch {
                                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - Edit Weight View (DEPRECATED)
// NOTE: This view is deprecated. Use LogWeightView with existingEntry parameter instead.
// This view uses legacy Form-based UI that doesn't match the redesigned LogWeightView.
// Kept for reference during transition period - safe to remove once verified.
struct EditWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager
    let entry: WeightEntry
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]
    @Binding var userHeight: Double  // Changed from let to @Binding
    @Binding var goalWeight: Double
    let onSave: () -> Void
    var onInstantDismiss: (() -> Void)? = nil  // For instant dismiss without animation

    @AppStorage("weightUnit") private var selectedUnit: WeightUnit = .kg
    @AppStorage("heightUnit") private var selectedHeightUnit: HeightUnit = .cm  // NEW
    @AppStorage("userGender") private var userGender: Gender = .other
    @State private var primaryWeight: String = ""
    @State private var secondaryWeight: String = ""
    @State private var primaryHeight: String = ""  // NEW
    @State private var secondaryHeight: String = ""  // NEW
    @State private var note: String = ""
    @State private var date = Date()
    @State private var previousUnit: WeightUnit = .kg  // Track previous unit for conversions
    @State private var previousHeightUnit: HeightUnit = .cm  // Track previous height unit

    // Goal weight
    @State private var goalWeightText: String = ""
    @State private var initialGoalWeight: Double = 0

    // Photo picker
    @State private var selectedPhotos: [IdentifiableImage] = []
    @State private var isLoadingPhotos = false
    @State private var activePickerType: PhotoPickerType? = nil
    @State private var showingPhotoOptions = false
    @State private var isUploading = false
    @State private var selectedPhotoForViewing: IdentifiableImage? = nil
    @State private var showingMultiImagePicker = false

    // Measurements
    @State private var waistSize: String = ""
    @State private var dressSize: String = ""

    private var weightInKg: Double? {
        guard let primary = Double(primaryWeight) else { return nil }
        let secondary = selectedUnit == .stones ? Double(secondaryWeight) : nil
        return selectedUnit.toKg(primary: primary, secondary: secondary)
    }

    private var heightInCm: Double? {  // NEW
        guard let primary = Double(primaryHeight) else { return nil }
        let secondary = selectedHeightUnit == .ftIn ? Double(secondaryHeight) : nil
        return selectedHeightUnit.toCm(primary: primary, secondary: secondary)
    }

    private var calculatedBMI: Double? {
        guard let weightKg = weightInKg else { return nil }
        guard let heightCm = heightInCm, heightCm > 0 else { return nil }  // Updated to use heightInCm
        let heightInMeters = heightCm / 100
        return weightKg / (heightInMeters * heightInMeters)
    }

    // Goal weight conversion helpers
    private var goalWeightInKg: Double? {
        let sanitized = goalWeightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(sanitized), value > 0 else { return nil }
        // Convert from display unit to kg
        switch selectedUnit {
        case .kg:
            return value
        case .lbs:
            return value / 2.20462
        case .stones:
            return value * 6.35029
        }
    }

    private func goalWeightDisplayValue(_ kg: Double) -> String {
        switch selectedUnit {
        case .kg:
            return String(format: "%.1f", kg)
        case .lbs:
            return String(format: "%.1f", kg * 2.20462)
        case .stones:
            return String(format: "%.1f", kg / 6.35029)
        }
    }

    private var goalWeightUnitLabel: String {
        selectedUnit.shortName
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Height")) {
                    Picker("Height Unit", selection: $selectedHeightUnit) {
                        ForEach(HeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedHeightUnit == .ftIn {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Feet", text: $primaryHeight)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("ft").foregroundColor(.secondary).font(.caption)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Inches", text: $secondaryHeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("in").foregroundColor(.secondary).font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Height", text: $primaryHeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedHeightUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text("Weight")) {
                    Picker("Weight Unit", selection: $selectedUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedUnit == .stones {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Stones", text: $primaryWeight)
                                     .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))

                                Text("st")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Pounds", text: $secondaryWeight)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold))

                                Text("lbs")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    } else {
                        HStack {
                            TextField("Weight", text: $primaryWeight)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .semibold))

                            Text(selectedUnit.shortName)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let bmi = calculatedBMI {
                        HStack {
                            Text("BMI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }

                // Goal Weight Section
                Section(header: Text("Goal Weight (Optional)")) {
                    HStack {
                        TextField("Goal weight", text: $goalWeightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .semibold))

                        Text(goalWeightUnitLabel)
                            .foregroundColor(.secondary)
                    }

                    if let currentKg = weightInKg, let goalKg = goalWeightInKg {
                        let difference = currentKg - goalKg
                        HStack {
                            Text(difference > 0 ? "To lose" : "To gain")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f %@", abs(difference), selectedUnit == .kg ? "kg" : selectedUnit == .lbs ? "lbs" : "st"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(difference > 0 ? .green : .blue)
                        }
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                // Photo Section - EditWeightView
                Section(header: Text("Progress Photos (Optional - up to 3)")) {
                    // Show loading indicator while photos are being downloaded
                    if isLoadingPhotos {
                        HStack {
                            Spacer()
                            ProgressView("Loading photos...")
                                .padding(.vertical, 20)
                            Spacer()
                        }
                    }

                    // Show selected photos in a grid
                    if !selectedPhotos.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(selectedPhotos) { identifiableImage in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: identifiableImage.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            selectedPhotoForViewing = identifiableImage
                                        }

                                    // Delete button
                                    Button(action: {
                                                                                selectedPhotos.removeAll { $0.id == identifiableImage.id }
                                                                            }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.red))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Show add photo buttons if less than 3 photos
                    if selectedPhotos.count < 3 && !isLoadingPhotos {
                        Button(action: {
                            activePickerType = .camera
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                                if !selectedPhotos.isEmpty {
                                    Spacer()
                                    Text("(\(selectedPhotos.count)/3)")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Button(action: {
                            showingMultiImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Library")
                            }
                        }
                    } else if selectedPhotos.count >= 3 {
                        Text("Maximum 3 photos added")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    }
                }

                if userGender == .female {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Dress Size (e.g., UK 12)", text: $dressSize)
                            .keyboardType(.default)
                    }
                } else {
                    Section(header: Text("Measurements (Optional)")) {
                        TextField("Waist Size (cm)", text: $waistSize)
                            .keyboardType(.decimalPad)
                    }
                }

                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Edit Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let instantDismiss = onInstantDismiss {
                            instantDismiss()
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(weightInKg == nil || isUploading)
                }
            }
            .overlay {
                if isUploading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(selectedPhotos.isEmpty ? "Saving weight..." : "Uploading photos...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                    }
                }
            }
            .onChange(of: selectedUnit) { _, newUnit in
                convertWeight(from: previousUnit, to: newUnit)
                previousUnit = newUnit  // Update after conversion
            }
            .onChange(of: selectedHeightUnit) { _, newUnit in
                convertHeight(from: previousHeightUnit, to: newUnit)
                previousHeightUnit = newUnit  // Update after conversion
            }
            .onAppear {
                // Initialize previous units to current units
                previousUnit = selectedUnit
                previousHeightUnit = selectedHeightUnit

                // Pre-populate with existing entry data (convert from kg to selected unit)
                let converted = selectedUnit.fromKg(entry.weight)
                primaryWeight = String(format: "%.1f", converted.primary)
                if let secondary = converted.secondary {
                    secondaryWeight = String(format: "%.1f", secondary)
                }

                // Pre-populate height fields from userHeight
                if userHeight > 0 {
                    let convertedHeight = selectedHeightUnit.fromCm(userHeight)
                    primaryHeight = String(format: convertedHeight.secondary != nil ? "%.0f" : "%.0f", convertedHeight.primary)
                    if let secondary = convertedHeight.secondary {
                        secondaryHeight = String(format: "%.0f", secondary)
                    }
                }

                date = entry.date
                note = entry.note ?? ""

                // Pre-populate measurement fields
                if let waist = entry.waistSize {
                    waistSize = String(format: "%.1f", waist)
                }
                if let dress = entry.dressSize {
                    dressSize = dress
                }

                // Pre-populate goal weight if set
                if goalWeight > 0 {
                    initialGoalWeight = goalWeight
                    goalWeightText = goalWeightDisplayValue(goalWeight)
                }

                // Load existing photos
                loadExistingPhotos()
            }
            .fullScreenCover(item: $activePickerType) { pickerType in
                // Only use this for camera - library uses MultiImagePicker
                if pickerType == .camera {
                    ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                        activePickerType = nil // Dismiss picker
                        if let image = image, selectedPhotos.count < 3 {
                                                        selectedPhotos.append(IdentifiableImage(image: image, url: nil))
                        }
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                                        activePickerType = .camera
                }
                Button("Choose from Library") {
                    showingMultiImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showingMultiImagePicker) {
                MultiImagePicker(maxSelection: 3 - selectedPhotos.count) { images in
                    showingMultiImagePicker = false // Dismiss the picker
                    let availableSlots = 3 - selectedPhotos.count
                    let photosToAdd = min(images.count, availableSlots)

                    for i in 0..<photosToAdd {
                        selectedPhotos.append(IdentifiableImage(image: images[i], url: nil))
                    }
                }
            }
            .fullScreenCover(item: $selectedPhotoForViewing) { photo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                selectedPhotoForViewing = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }

                        Spacer()

                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFit()

                        Spacer()
                    }
                }
            }
        }
    }

    private func convertWeight(from oldUnit: WeightUnit, to newUnit: WeightUnit) {
        withAnimation(.easeInOut(duration: 0.2)) {
            // First, get current weight in kg for conversion
            guard let primary = Double(primaryWeight), primary > 0 else { return }
            let secondary = !secondaryWeight.isEmpty ? Double(secondaryWeight) : nil

            // Convert from old unit to kg
            let kg = oldUnit.toKg(primary: primary, secondary: secondary)

            if newUnit == .kg {
                // Converting TO kg - clear secondary first to avoid stale data
                self.secondaryWeight = ""
                self.primaryWeight = String(format: "%.1f", kg)
            } else if newUnit == .stones {
                // Converting TO stones/lbs - update both fields atomically
                let converted = WeightUnit.stones.fromKg(kg)
                self.primaryWeight = String(format: "%.0f", converted.primary)
                self.secondaryWeight = String(format: "%.1f", converted.secondary ?? 0)
            } else if newUnit == .lbs {
                // Converting TO lbs - clear secondary first to avoid stale data
                let converted = WeightUnit.lbs.fromKg(kg)
                self.secondaryWeight = ""
                self.primaryWeight = String(format: "%.1f", converted.primary)
            }
        }
    }

    private func convertHeight(from oldUnit: HeightUnit, to newUnit: HeightUnit) {
        withAnimation(.easeInOut(duration: 0.2)) {
            guard let primary = Double(primaryHeight), primary > 0 else { return }
            let secondary = !secondaryHeight.isEmpty ? Double(secondaryHeight) : nil

            // Convert from old unit to cm
            let cm = oldUnit.toCm(primary: primary, secondary: secondary)

            if newUnit == .cm {
                // Converting TO cm - clear secondary first to avoid stale data
                self.secondaryHeight = ""
                self.primaryHeight = String(format: "%.0f", cm)
            } else if newUnit == .ftIn {
                // Converting TO feet/inches - update both fields atomically
                let converted = HeightUnit.ftIn.fromCm(cm)
                self.primaryHeight = String(format: "%.0f", converted.primary)
                self.secondaryHeight = String(format: "%.0f", converted.secondary ?? 0)
            }
        }
    }

    private func loadExistingPhotos() {
        // Check for photos in photoURLs array (new format) or photoURL (legacy)
        var urls: [String] = []
        if let photoURLs = entry.photoURLs {
            urls = photoURLs
        } else if let photoURL = entry.photoURL {
            urls = [photoURL]
        }

        guard !urls.isEmpty else { return }

        isLoadingPhotos = true
        Task {
            var loadedImages: [IdentifiableImage] = []

            // Try loading from local cache first
            let cachedImages = await ImageCacheManager.shared.loadWeightImagesAsync(for: entry.id.uuidString, count: urls.count)

            if !cachedImages.isEmpty && cachedImages.count == urls.count {
                // All images found in cache
                for (index, image) in cachedImages.enumerated() {
                    loadedImages.append(IdentifiableImage(image: image, url: urls[index]))
                }
                            } else {
                // Load from Firebase and cache locally
                for (index, url) in urls.enumerated() {
                    do {
                        let image = try await firebaseManager.downloadWeightPhoto(from: url)
                        loadedImages.append(IdentifiableImage(image: image, url: url))

                        // Cache the downloaded image locally for next time
                        let imageId = "\(entry.id.uuidString)_\(index)"
                        do {
                            try await ImageCacheManager.shared.saveWeightImageAsync(image, for: imageId)
                                                    } catch {
                                                    }
                    } catch {
                                            }
                }
                            }

            await MainActor.run {
                selectedPhotos = loadedImages
                isLoadingPhotos = false
            }
        }
    }

    private func saveWeight() {
        guard let weightKg = weightInKg else { return }  // Convert to kg

        isUploading = true

        // Save to Firebase
        Task {
            do {
                // Separate existing photos (have URLs) from new photos (need upload)
                var photoURLs: [String] = []
                var newPhotosToUpload: [UIImage] = []

                for photo in selectedPhotos {
                    if let url = photo.url {
                        // Existing photo - keep the URL
                        photoURLs.append(url)
                    } else {
                        // New photo - needs upload
                        newPhotosToUpload.append(photo.image)
                    }
                }

                // Save new photos to local cache
                if !newPhotosToUpload.isEmpty {
                    do {
                        // Save all new images locally
                        let currentPhotoCount = selectedPhotos.count - newPhotosToUpload.count
                        for (index, image) in newPhotosToUpload.enumerated() {
                            let imageId = "\(entry.id.uuidString)_\(currentPhotoCount + index)"
                            try await ImageCacheManager.shared.saveWeightImageAsync(image, for: imageId)
                        }
                                            } catch {
                                            }

                    // Upload new photos to Firebase for backup/sync
                    do {
                        let newURLs = try await firebaseManager.uploadWeightPhotos(newPhotosToUpload)
                        photoURLs.append(contentsOf: newURLs)
                                            } catch {
                                            }
                }

                // Parse measurements
                let waist = waistSize.isEmpty ? nil : Double(waistSize)
                let dress = dressSize.isEmpty ? nil : dressSize

                // Create updated entry with same ID
                let updatedEntry = WeightEntry(
                    id: entry.id,
                    weight: weightKg,  // Store in kg
                    date: date,
                    bmi: calculatedBMI,
                    note: note.isEmpty ? nil : note,
                    photoURL: photoURLs.first, // For backward compatibility
                    photoURLs: photoURLs.isEmpty ? nil : photoURLs,
                    waistSize: waist,
                    dressSize: dress
                )

                try await firebaseManager.saveWeightEntry(updatedEntry)

                // Save height changes if user modified it
                if let heightCm = heightInCm, heightCm != userHeight {
                    try await firebaseManager.saveUserSettings(height: heightCm, goalWeight: nil)
                }

                // Save goal weight if changed
                let newGoalKg = goalWeightInKg
                if let newGoal = newGoalKg, newGoal != initialGoalWeight {
                    try await firebaseManager.saveUserSettings(height: nil, goalWeight: newGoal)
                    // Notify other views about goal weight change
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .goalWeightUpdated,
                            object: nil,
                            userInfo: ["goalWeight": newGoal]
                        )
                    }
                }

                await MainActor.run {
                    // Update local state
                    if let index = weightHistory.firstIndex(where: { $0.id == entry.id }) {
                        weightHistory[index] = updatedEntry
                        weightHistory.sort { $0.date > $1.date }
                    }

                    // Update current weight if this was the most recent entry
                    if let latest = weightHistory.first {
                        currentWeight = latest.weight
                    }

                    // Update height if changed
                    if let heightCm = heightInCm, heightCm != userHeight {
                        userHeight = heightCm
                    }

                    // Update goal weight binding if changed
                    if let newGoal = newGoalKg, newGoal != initialGoalWeight {
                        goalWeight = newGoal
                    }

                    isUploading = false
                    onSave()
                    dismiss()
                }
            } catch {
                                await MainActor.run {
                    isUploading = false
                }
            }
        }
    }
}

// MARK: - Height Setup View
struct HeightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Binding var userHeight: Double

    @State private var heightCm: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var useMetric: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 60))
                        .foregroundColor(AppPalette.standard.accent)

                    Text("What's your height?")
                        .font(.system(size: 28, weight: .bold))

                    Text("We need this to calculate your BMI")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                Picker("Unit", selection: $useMetric) {
                    Text("Metric (cm)").tag(true)
                    Text("Imperial (ft/in)").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                if useMetric {
                    HStack(spacing: 12) {
                        TextField("170", text: $heightCm)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("cm")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            TextField("5", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("feet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 8) {
                            TextField("9", text: $heightInches)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("inches")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: saveHeight) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? AppPalette.standard.accent : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    private var isValid: Bool {
        if useMetric {
            return Double(heightCm) ?? 0 > 0
        } else {
            return (Double(heightFeet) ?? 0) > 0 || (Double(heightInches) ?? 0) > 0
        }
    }

    private func saveHeight() {
        var heightInCm: Double = 0

        if useMetric {
            heightInCm = Double(heightCm) ?? 0
        } else {
            let feet = Double(heightFeet) ?? 0
            let inches = Double(heightInches) ?? 0
            heightInCm = (feet * 12 + inches) * 2.54
        }

        // Save to Firebase
        Task {
            do {
                try await firebaseManager.saveUserSettings(height: heightInCm, goalWeight: nil)
                await MainActor.run {
                    userHeight = heightInCm
                    dismiss()
                }
            } catch {
                            }
        }
    }
}

// MARK: - Goal Weight Editor Sheet
struct GoalWeightEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var goalWeight: Double
    let weightUnit: WeightUnit
    let onSave: () -> Void

    @State private var goalWeightText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var goalWeightInKg: Double? {
        let sanitized = goalWeightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(sanitized), value > 0 else { return nil }
        switch weightUnit {
        case .kg: return value
        case .lbs: return value / 2.20462
        case .stones:
            // Parse stone.pounds format (e.g., "10.7" = 10st 7lb)
            let parts = sanitized.split(separator: ".")
            if parts.count == 2, let stone = Double(parts[0]), let pounds = Double(parts[1]) {
                return (stone * 14 + pounds) / 2.20462
            }
            return value * 6.35029 // Plain stone to kg
        }
    }

    private func displayValue(_ kg: Double) -> String {
        switch weightUnit {
        case .kg: return String(format: "%.1f", kg)
        case .lbs: return String(format: "%.0f", kg * 2.20462)
        case .stones:
            let totalPounds = kg * 2.20462
            let stone = Int(totalPounds / 14)
            let pounds = Int(totalPounds.truncatingRemainder(dividingBy: 14))
            return "\(stone).\(pounds)"
        }
    }

    private var unitLabel: String {
        switch weightUnit {
        case .kg: return "kg"
        case .lbs: return "lbs"
        case .stones: return "st.lb"
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "target")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 20)

                Text("Set Your Goal Weight")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("This helps track your progress towards your target")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Weight Input
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Goal weight", text: $goalWeightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                            .focused($isTextFieldFocused)
                            .frame(maxWidth: 150)

                        Text(unitLabel)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )

                    if goalWeightInKg == nil && !goalWeightText.isEmpty {
                        Text("Please enter a valid weight")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Save Button
                Button(action: {
                    if let kg = goalWeightInKg {
                        goalWeight = kg
                        onSave()
                        dismiss()
                    }
                }) {
                    Text("Save Goal")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(goalWeightInKg != nil ? Color.green : Color.gray)
                        )
                }
                .disabled(goalWeightInKg == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .background(Color.adaptiveBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        goalWeight = 0
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            if goalWeight > 0 {
                goalWeightText = displayValue(goalWeight)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFieldFocused = true
            }
        }
    }
}

func formatRestTime(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if minutes > 0 {
        if remainingSeconds > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(minutes)m"
        }
    } else {
        return "\(remainingSeconds)s"
    }
}

struct DiaryMacroItem: View {
    let name: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MicronutrientFrequencyView: View {
    let breakfast: [DiaryFoodItem]
    let lunch: [DiaryFoodItem]
    let dinner: [DiaryFoodItem]
    let snacks: [DiaryFoodItem]
    
    private var allFoods: [DiaryFoodItem] {
        breakfast + lunch + dinner + snacks
    }
    
    private var micronutrientAnalysis: [LegacyMicronutrientStatus] {
        analyzeMicronutrientFrequency()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(micronutrientAnalysis.prefix(4), id: \.name) { nutrient in
                MicronutrientIndicator(nutrient: nutrient)
            }
        }
    }
    
    private func analyzeMicronutrientFrequency() -> [LegacyMicronutrientStatus] {
        let nutrientFoodSources: [String: [String]] = [
            "Vitamin C": ["orange", "lemon", "lime", "strawberry", "strawberries", "kiwi", "bell pepper", "broccoli", "tomato", "potato"],
            "Vitamin D": ["salmon", "tuna", "mackerel", "sardines", "egg", "fortified milk", "fortified cereal"],
            "Iron": ["spinach", "beef", "chicken", "turkey", "lentils", "beans", "quinoa", "tofu"],
            "Calcium": ["milk", "cheese", "yogurt", "yoghurt", "broccoli", "kale", "sardines", "almonds"],
            "Vitamin B12": ["meat", "fish", "dairy", "eggs", "nutritional yeast", "fortified"],
            "Folate": ["leafy greens", "spinach", "asparagus", "avocado", "beans", "lentils", "fortified"],
            "Omega-3": ["salmon", "sardines", "mackerel", "walnuts", "flax", "chia", "hemp"]
        ]
        
        var results: [LegacyMicronutrientStatus] = []
        
        for (nutrient, sources) in nutrientFoodSources {
            let hasSource = allFoods.contains { food in
                sources.contains { source in
                    food.name.lowercased().contains(source.lowercased())
                }
            }
            
            let status: LegacyNutrientStatus = hasSource ? .good : .needsAttention
            results.append(LegacyMicronutrientStatus(name: nutrient, status: status))
        }
        
        // Sort by status (needs attention first)
        return results.sorted { 
            if $0.status == .needsAttention && $1.status == .good { return true }
            if $0.status == .good && $1.status == .needsAttention { return false }
            return $0.name < $1.name
        }
    }
}

struct LegacyMicronutrientStatus {
    let name: String
    let status: LegacyNutrientStatus
}

enum LegacyNutrientStatus {
    case good              // Getting regularly (70%+)
    case inconsistent      // Getting sometimes (40-69%)
    case needsTracking     // Rarely getting (<40%)
    case needsAttention    // Legacy case for compatibility

    var color: Color {
        switch self {
        case .good: return .green
        case .inconsistent: return .orange
        case .needsTracking: return .gray
        case .needsAttention: return .orange
        }
    }

    var symbol: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .inconsistent: return "exclamationmark.triangle"
        case .needsTracking: return "circle.dotted"
        case .needsAttention: return "exclamationmark.triangle.fill"
        }
    }

    var label: String {
        switch self {
        case .good: return "Getting regularly"
        case .inconsistent: return "Track more often"
        case .needsTracking: return "Rarely tracked"
        case .needsAttention: return "Needs attention"
        }
    }
}

struct MicronutrientIndicator: View {
    let nutrient: LegacyMicronutrientStatus
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: nutrient.status.symbol)
                .font(.system(size: 12))
                .foregroundColor(nutrient.status.color)
            
            Text(nutrient.name.replacingOccurrences(of: "Vitamin ", with: "Vit "))
                .font(.system(size: 8))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompactHydrationRing: View {
    let currentDate: Date
    @State private var waterCount: Int = 0
    @State private var waterGoal: Int = 8
    
    private var fillPercentage: Double {
        min(Double(waterCount) / Double(waterGoal), 1.0)
    }
    
    var body: some View {
        Button(action: addWater) {
            VStack(spacing: 4) {
                // Beautiful glass shape
                ZStack(alignment: .bottom) {
                    // Glass outline
                    GlassShape()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 32, height: 50)
                    
                    // Water fill with animation
                    GlassShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.cyan.opacity(0.8), location: 0),
                                    .init(color: AppPalette.standard.accent.opacity(0.6), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 32, height: 50)
                        .clipShape(
                            Rectangle()
                                .offset(y: 50 * (1 - fillPercentage))
                        )
                        .animation(.easeInOut(duration: 0.8), value: fillPercentage)
                    
                    // Glass highlight effect
                    GlassShape()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 32, height: 50)
                }
                
                // Count display
                Text("\(waterCount)/\(waterGoal)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadHydrationData()
        }
        .onChange(of: currentDate) {
            loadHydrationData()
        }
    }
    
    private func addWater() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            waterCount += 1
        }
        saveHydrationData()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func loadHydrationData() {
        let dateKey = formatDateKey(currentDate)
        let saved = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount = saved[dateKey] ?? 0
        waterGoal = UserDefaults.standard.integer(forKey: "dailyWaterGoal") == 0 ? 8 : UserDefaults.standard.integer(forKey: "dailyWaterGoal")
    }
    
    private func saveHydrationData() {
        let dateKey = formatDateKey(currentDate)
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        hydrationData[dateKey] = waterCount
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")
    }
    
    private func formatDateKey(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.isoDateFormatter.string(from: date)
    }
}

// MARK: - Glass Shape for Hydration
struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Glass shape - slightly tapered drinking glass
        let topWidth = width * 0.9
        let bottomWidth = width * 0.7
        let topOffset = (width - topWidth) / 2
        let bottomOffset = (width - bottomWidth) / 2
        
        // Start from top left
        path.move(to: CGPoint(x: topOffset, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: width - topOffset, y: 0))
        
        // Right side (tapered)
        path.addLine(to: CGPoint(x: width - bottomOffset, y: height * 0.9))
        
        // Bottom right curve
        path.addQuadCurve(
            to: CGPoint(x: bottomOffset, y: height * 0.9),
            control: CGPoint(x: width / 2, y: height)
        )
        
        // Left side (tapered)
        path.addLine(to: CGPoint(x: topOffset, y: 0))
        
        return path
    }
}

struct MacroSummaryLabel: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
    }
}

struct CompactMacroLabel: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 32, height: 32)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
        )
    }
}

struct ModernMacroItem: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .frame(minWidth: 35)
    }
}


struct AddFoodMainView: View {
    @Binding var selectedTab: TabItem
    @State private var selectedAddOption: AddOption
    @State private var prefilledBarcode: String? = nil // Barcode from scanner to prefill manual entry
    @Binding var isPresented: Bool // Direct binding to presentation state
    var onDismiss: (() -> Void)?
    var onComplete: ((TabItem) -> Void)?
    @State private var keyboardVisible = false
    @State private var keyboardShowObserver: NSObjectProtocol?
    @State private var keyboardHideObserver: NSObjectProtocol?

    // Free tier limit checking
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var fastingViewModelWrapper: FastingViewModelWrapper
    @State private var isCheckingLimit = true
    @State private var canAddMore = true
    @State private var currentDayEntryCount = 0
    @State private var showingPaywall = false

    init(selectedTab: Binding<TabItem>, isPresented: Binding<Bool>, initialOption: AddOption? = nil, prefilledBarcode: String? = nil, onDismiss: (() -> Void)? = nil, onComplete: ((TabItem) -> Void)? = nil) {
        self._selectedTab = selectedTab
        self._isPresented = isPresented
        // Initialize selectedAddOption directly from initialOption to avoid race condition
        self._selectedAddOption = State(initialValue: initialOption ?? .search)
        self._prefilledBarcode = State(initialValue: prefilledBarcode)
        self.onDismiss = onDismiss
        self.onComplete = onComplete
    }

    enum AddOption: String, CaseIterable {
        case search = "Search"
        case meals = "My Meals"
        case manual = "Manual"
        case barcode = "Barcode"

        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .meals: return "fork.knife.circle"
            case .manual: return "square.and.pencil"
            case .barcode: return "barcode.viewfinder"
            }
        }

        var description: String {
            switch self {
            case .search: return "Search food database"
            case .meals: return "Saved meal combinations"
            case .manual: return "Enter manually"
            case .barcode: return "Scan product barcode"
            }
        }

        // Only show these tabs in the selector (barcode is accessed from search)
        static var visibleCases: [AddOption] {
            [.search, .meals, .manual]
        }
    }

    // Redesigned tab selector matching NutraSafe onboarding/diary visual language
    // Uses glassmorphic pills with soft backgrounds and proper visual hierarchy
    private struct OptionSelectorButton: View {
        @Environment(\.colorScheme) var colorScheme
        let title: String
        let icon: String
        let isSelected: Bool
        let onTap: () -> Void
        @Namespace private var animation

        var body: some View {
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onTap()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    Text(title)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                }
                .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white.opacity(0.7) : .primary.opacity(0.7)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        if isSelected {
                            // Active state: gradient fill with soft glow
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [AppPalette.standard.accent, AppPalette.standard.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 8, y: 2)
                        } else {
                            // Inactive state: subtle translucent background
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                        }
                    }
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // CRITICAL: Global opaque background to prevent transparency during transitions
                // This ensures the background persists when fullScreenCover dismiss animations occur
                Color.adaptiveBackground
                    .ignoresSafeArea()

                if isCheckingLimit {
                    // Loading state while checking limit
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.adaptiveBackground)
                } else if !canAddMore {
                    // At limit - show upgrade prompt
                    DiaryLimitReachedView(
                        currentCount: currentDayEntryCount,
                        maxCount: SubscriptionManager.freeDiaryEntriesPerDay,
                        onUnlockTapped: { showingPaywall = true },
                        onDismiss: { isPresented = false }
                    )
                } else {
                    // Normal add food flow - redesigned with NutraSafe visual language
                    VStack(spacing: 0) {
                        // Tab selector with glassmorphic pill container
                        VStack(spacing: 0) {
                            // Option selector - Search, My Meals, Manual (barcode accessed from search)
                            HStack(spacing: 6) {
                                ForEach(AddOption.visibleCases, id: \.self) { option in
                                    OptionSelectorButton(title: option.rawValue, icon: option.icon, isSelected: selectedAddOption == option) {
                                        selectedAddOption = option
                                    }
                                }
                            }
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        }
                        .zIndex(999)
                        .allowsHitTesting(true)

                    // Content based on selected option
                    Group {
                        switch selectedAddOption {
                        case .search:
                            AnyView(
                                AddFoodSearchView(
                                    selectedTab: $selectedTab,
                                    onComplete: onComplete,
                                    onSwitchToManual: {
                                        selectedAddOption = .manual
                                    },
                                    onSwitchToBarcode: {
                                        selectedAddOption = .barcode
                                    }
                                )
                            )
                        case .meals:
                            AnyView(
                                MyMealsView(selectedTab: $selectedTab, onComplete: onComplete)
                            )
                        case .manual:
                            AnyView(
                                AddFoodManualView(selectedTab: $selectedTab, prefilledBarcode: prefilledBarcode, onComplete: onComplete)
                            )
                        case .barcode:
                            AnyView(
                                AddFoodBarcodeView(selectedTab: $selectedTab, onSwitchToManual: { barcode in
                                    prefilledBarcode = barcode
                                    selectedAddOption = .manual
                                })
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(0)
                    }
                    .background(AppAnimatedBackground())
                }
            }
            .navigationTitle("Diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("[AddFoodMainView] Close button tapped - dismissing")
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                            )
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Check diary entry limit for free users
            checkDiaryLimit()

            // Monitor keyboard - store observer tokens for proper cleanup
            keyboardShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                keyboardVisible = true
            }
            keyboardHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardVisible = false
            }
        }
        .onDisappear {
            // Clean up keyboard observers using stored tokens
            if let observer = keyboardShowObserver {
                NotificationCenter.default.removeObserver(observer)
                keyboardShowObserver = nil
            }
            if let observer = keyboardHideObserver {
                NotificationCenter.default.removeObserver(observer)
                keyboardHideObserver = nil
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
                .onDisappear {
                    // Re-check limit after paywall dismisses (user may have subscribed)
                    checkDiaryLimit()
                }
        }
    }

    private func checkDiaryLimit() {
        Task {
            // Don't show loading for subscribers - instant check
            let hasAccess = subscriptionManager.hasAccess
            if hasAccess {
                // Subscriber - skip loading state entirely
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    canAddMore = true
                    currentDayEntryCount = 0
                    isCheckingLimit = false
                }
                return
            }

            // Free user - need to count entries (may take a moment)
            do {
                let count = try await FirebaseManager.shared.countFoodEntries(for: Date())
                let limit = SubscriptionManager.freeDiaryEntriesPerDay
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    currentDayEntryCount = count
                    canAddMore = count < limit
                    isCheckingLimit = false
                }
            } catch {
                // On error, allow adding (fail open)
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    canAddMore = true
                    isCheckingLimit = false
                }
            }
        }
    }
}

// MARK: - Benefit Item (for limit views)
private struct BenefitItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Diary Limit Reached View
/// Shows when free user has hit their daily diary entry limit
struct DiaryLimitReachedView: View {
    let currentCount: Int
    let maxCount: Int
    let onUnlockTapped: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppPalette.standard.accent.opacity(0.2), AppPalette.standard.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Title and subtitle
                VStack(spacing: 8) {
                    Text("Daily Limit Reached")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("You've added \(currentCount) of \(maxCount) free entries today")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Benefits list
                VStack(alignment: .leading, spacing: 10) {
                    BenefitItem(icon: "infinity", text: "Unlimited diary entries")
                    BenefitItem(icon: "flask.fill", text: "See additives and hidden ingredients")
                    BenefitItem(icon: "leaf.fill", text: "Full vitamin and mineral breakdown")
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
            }

            Spacer()

            // Unlock button
            Button(action: onUnlockTapped) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Unlock Unlimited")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Continue without upgrade (just dismiss)
            Button(action: onDismiss) {
                Text("Maybe Later")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)

            // Pro badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("NutraSafe Pro")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
    }
}

struct AddOptionSelector: View {
    @Binding var selectedOption: AddFoodMainView.AddOption

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(AddFoodMainView.AddOption.allCases, id: \.self) { option in
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    selectedOption = option
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedOption == option ? AppPalette.standard.accent : Color(.systemGray5))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: option.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedOption == option ? .white : .primary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(option.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(option.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedOption == option ? AppPalette.standard.accent : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }
}

// MARK: - Sample Data
private let sampleDailyNutrition = DailyNutrition(
    calories: NutrientTarget(current: 1450, target: 2000),
    protein: NutrientTarget(current: 95, target: 120),
    carbs: NutrientTarget(current: 180, target: 250),
    fat: NutrientTarget(current: 65, target: 78),
    fiber: NutrientTarget(current: 15, target: 25),
    sodium: NutrientTarget(current: 1200, target: 2300),
    sugar: NutrientTarget(current: 35, target: 50)
)

struct IngredientCameraView: View {
    @Environment(\.colorScheme) private var colorScheme
    let foodName: String
    let onImageCaptured: (UIImage) -> Void
    let onDismiss: () -> Void
    let photoType: PhotoType
    
    enum PhotoType {
        case ingredients, nutrition, barcode
        
        var title: String {
            switch self {
            case .ingredients: return "Ingredient Photo Captured"
            case .nutrition: return "Nutrition Photo Captured" 
            case .barcode: return "Barcode Photo Captured"
            }
        }
        
        var buttonText: String {
            switch self {
            case .ingredients: return "Submit Ingredients"
            case .nutrition: return "Submit Nutrition"
            case .barcode: return "Submit Barcode"
            }
        }
        
        var description: String {
            switch self {
            case .ingredients: return "ingredients list"
            case .nutrition: return "nutrition facts label"
            case .barcode: return "barcode"
            }
        }
    }
    
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    // Show captured image
                    VStack(spacing: 16) {
                        Text(photoType.title)
                            .font(.title2.bold())
                        
                        Text("Please verify this is a clear photo of the \(photoType.description) for \"\(foodName)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                        
                        VStack(spacing: 12) {
                            Button(photoType.buttonText) {
                                onImageCaptured(image)
                                onDismiss()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                            
                            Button("Retake Photo") {
                                capturedImage = nil
                                showingImagePicker = true
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .font(.headline)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    // Initial state - show camera instructions
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Photograph Ingredients")
                                .font(.title.bold())
                            
                            Text("Take a clear photo of the ingredients list for:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\"\(foodName)\"")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📸 Tips for best results:")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• Ensure good lighting")
                                Text("• Keep text straight and readable")
                                Text("• Include the complete ingredients list")
                                Text("• Avoid shadows or reflections")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                        
                        Button("Take Photo") {
                            showingImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .font(.headline)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Ingredient Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                }
            )
        }
        .fullScreenCover(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $capturedImage, sourceType: .camera) { image in
                showingImagePicker = false // Dismiss picker
                capturedImage = image
            }
        }
    }
}

// Database Building Photo Prompt View
// Pending Verifications View for user submissions
struct PendingVerificationsView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var pendingVerifications: [PendingFoodVerification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading pending verifications...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pendingVerifications.isEmpty {
                    VStack {
                        Image(systemName: "hourglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Pending Verifications")
                            .font(.title2)
                            .fontWeight(.medium)
                            .padding(.top)
                        Text("Your ingredient submissions will appear here as 'Pending Verification' until approved by our team.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(pendingVerifications) { verification in
                        PendingVerificationRow(verification: verification)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Pending Verifications")
            .task {
                await loadPendingVerifications()
            }
            .refreshable {
                await loadPendingVerifications()
            }
        }
    }
    
    private func loadPendingVerifications() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let verifications = try await firebaseManager.getPendingVerifications()
            await MainActor.run {
                self.pendingVerifications = verifications
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load verifications: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct PendingVerificationRow: View {
    let verification: PendingFoodVerification
    @State private var showingCompletionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(verification.foodName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                
                // Add completion button for pending verifications that need more photos
                if verification.status == .pending {
                    Button(action: {
                        showingCompletionSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.badge.plus")
                                .font(.caption)
                            Text("Complete")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppPalette.standard.accent)
                        .cornerRadius(8)
                    }
                    .fullScreenCover(isPresented: $showingCompletionSheet) {
                        DatabasePhotoPromptView(
                            foodName: verification.foodName,
                            brandName: verification.brandName,
                            sourceType: .search,
                            onPhotosCompleted: { ingredients, nutrition, barcode in
                                // Submit additional photos to complete verification
                                Task {
                                    do {
                                        _ = try await IngredientSubmissionService.shared.submitIngredientSubmission(
                                            foodName: verification.foodName,
                                            brandName: verification.brandName,
                                            ingredientsImage: ingredients,
                                            nutritionImage: nutrition,
                                            barcodeImage: barcode
                                        )
                                    } catch {
                                                                            }
                                }
                            },
                            onSkip: {
                                showingCompletionSheet = false
                            }
                        )
                    }
                }
                
                StatusBadge(status: verification.status)
            }
            
            if let brand = verification.brandName, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let ingredients = verification.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(ingredients)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(nil) // Show all ingredients
                        .padding(.leading, 8)
                    
                    // Show immediate intolerance warnings
                    AllergenWarningView(ingredients: ingredients)
                }
            }
            
            Text("Submitted: \(verification.submittedAt, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Immediate Allergen Warning for Pending Ingredients
struct AllergenWarningView: View {
    let ingredients: String
    @State private var detectedAllergens: [Allergen] = []
    @State private var riskLevel: RiskLevel = .safe
    
    enum RiskLevel {
        case safe, caution, danger
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .caution: return .orange
            case .danger: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .safe: return "checkmark.circle.fill"
            case .caution: return "exclamationmark.triangle.fill"
            case .danger: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack {
            if !detectedAllergens.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: riskLevel.icon)
                            .font(.caption2)
                            .foregroundColor(riskLevel.color)
                        Text("⚠️ Allergen Alert")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(riskLevel.color)
                    }
                }
                .padding(8)
                .background(riskLevel.color.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .onAppear {
            analyzeIngredients()
        }
    }
    
    private func analyzeIngredients() {
        detectedAllergens = []
        riskLevel = .safe
    }
}

struct StatusBadge: View {
    let status: PendingFoodVerification.VerificationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.caption2)
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .foregroundColor(statusColor)
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .approved:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        }
    }
}

struct FoodActionSheet: View {
    let food: DiaryFoodItem
    let isSelected: Bool
    let selectedCount: Int
    let onViewDetails: () -> Void
    let onEdit: () -> Void
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onMove: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Minimal handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 3)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            HStack(spacing: 20) {
                Text("Action buttons placeholder")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .modifier(iOS16PresentationModifier())
    }
}

struct iOS16PresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(120)]) // Much smaller and cleaner
                .presentationDragIndicator(.hidden)
        } else {
            content
        }
    }
}



#Preview {
    ContentView()
}
