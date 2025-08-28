import SwiftUI
import Foundation
import CryptoKit
import HealthKit

// MARK: - Data Models
struct SearchResult: Identifiable {
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
    
    var servingSize: String {
        return "100g"
    }
}

typealias FoodSearchResult = SearchResult

// MARK: - FatSecret API Service via Firebase Functions
class FatSecretService: ObservableObject {
    static let shared = FatSecretService()
    
    // Firebase Functions URL for NutraSafe project
    private let functionsBaseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"
    
    private init() {}
    
    func searchFoods(query: String) async throws -> [SearchResult] {
        print("Searching FatSecret API for: \(query)")
        return try await performFatSecretSearch(query: query)
    }
    
    private func performFatSecretSearch(query: String) async throws -> [SearchResult] {
        let url = URL(string: "\(functionsBaseURL)/searchFoods")!
        
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
                let calories: Double
                let protein: Double
                let carbs: Double
                let fat: Double
                let fiber: Double
                let sugar: Double
                let sodium: Double
            }
        }
        
        let searchResponse = try JSONDecoder().decode(FirebaseFoodSearchResponse.self, from: data)
        
        return searchResponse.foods.map { food in
            SearchResult(
                id: food.id,
                name: food.name,
                brand: food.brand,
                calories: food.calories,
                protein: food.protein,
                carbs: food.carbs,
                fat: food.fat,
                fiber: food.fiber,
                sugar: food.sugar,
                sodium: food.sodium
            )
        }
    }
    
    func getFoodDetails(foodId: String) async throws -> SearchResult? {
        let url = URL(string: "\(functionsBaseURL)/getFoodDetails")!
        
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
        }
        
        let detailResponse = try JSONDecoder().decode(FirebaseFoodDetailsResponse.self, from: data)
        
        return SearchResult(
            id: detailResponse.id,
            name: detailResponse.name,
            brand: detailResponse.brand,
            calories: detailResponse.calories,
            protein: detailResponse.protein,
            carbs: detailResponse.carbs,
            fat: detailResponse.fat,
            fiber: detailResponse.fiber,
            sugar: detailResponse.sugar,
            sodium: detailResponse.sodium
        )
    }
    
}

// MARK: - Professional Nutrition App UI Following Research Standards
// Based on analysis of MyFitnessPal, Lose It!, Cronometer, and Lifesum

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showingAddView = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            // Main Content with padding for tab bar
            Group {
                switch selectedTab {
                case .home:
                    HomeTabView(showingSettings: $showingSettings)
                case .diary:
                    DiaryTabView(showingSettings: $showingSettings)
                case .add:
                    AddTabView()
                case .food:
                    FoodTabView(showingSettings: $showingSettings)
                case .kitchen:
                    KitchenTabView(showingSettings: $showingSettings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar positioned at bottom
            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $selectedTab,
                    showingAddView: $showingAddView
                )
                .offset(y: 34) // Lower the tab bar to bottom edge
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showingAddView) {
            AddFoodMainView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Tab Items
enum TabItem: String, CaseIterable {
    case home = "home"
    case diary = "diary"  
    case add = "add"
    case food = "food"
    case kitchen = "kitchen"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .diary: return "Diary"
        case .add: return ""
        case .food: return "Food"
        case .kitchen: return "Kitchen"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .diary: return "book"
        case .add: return "plus"
        case .food: return "fork.knife"
        case .kitchen: return "refrigerator"
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    @Binding var showingAddView: Bool
    
    var body: some View {
        HStack {
            ForEach(TabItem.allCases, id: \.self) { tab in
                if tab == .add {
                    // Center Plus Button
                    Button(action: {
                        showingAddView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(y: -8)
                } else {
                    // Regular Tab Items
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                            
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(selectedTab == tab ? .blue : .gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            // Frosted Glass Effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(.white.opacity(0.1))
                )
        )
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
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
struct HomeTabView: View {
    @State private var animateProgress = false
    @Binding var showingSettings: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    
                    // Header with Settings
                    HStack {
                        Text("Home")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Main Daily Nutrition Summary
                    ProfessionalSummaryCard(
                        dailyNutrition: sampleDailyNutrition,
                        selectedDate: Date(),
                        animateProgress: animateProgress
                    )
                    .padding(.horizontal, 16)
                    
                    // Quick Actions Section
                    HomeQuickActionsCard()
                        .padding(.horizontal, 16)
                    
                    // Today's Diary Overview
                    HomeDiaryOverviewCard()
                        .padding(.horizontal, 16)
                    
                    // Kitchen Expiry Alerts
                    HomeKitchenAlertsCard()
                        .padding(.horizontal, 16)
                    
                    // Food Insights
                    HomeFoodInsightsCard()
                        .padding(.horizontal, 16)
                    
                    // Health Score Overview
                    HomeHealthScoreCard()
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Home Tab Overview Cards

struct HomeQuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                HomeQuickActionButton(
                    icon: "plus.circle.fill",
                    title: "Add Food",
                    color: .blue
                ) {
                    print("Add food tapped")
                }
                
                HomeQuickActionButton(
                    icon: "camera.fill",
                    title: "Scan",
                    color: .green
                ) {
                    print("Scan tapped")
                }
                
                HomeQuickActionButton(
                    icon: "drop.fill",
                    title: "Water",
                    color: .cyan
                ) {
                    print("Water tapped")
                }
                
                HomeQuickActionButton(
                    icon: "clock.fill",
                    title: "Fast",
                    color: .orange
                ) {
                    print("Fasting tapped")
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HomeQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeDiaryOverviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Diary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    print("View all diary tapped")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                HomeDiaryMealRow(
                    mealType: "Breakfast",
                    calories: 420,
                    items: 3,
                    color: .orange
                )
                
                HomeDiaryMealRow(
                    mealType: "Lunch", 
                    calories: 0,
                    items: 0,
                    color: .green
                )
                
                HomeDiaryMealRow(
                    mealType: "Dinner",
                    calories: 0,
                    items: 0,
                    color: .purple
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HomeDiaryMealRow: View {
    let mealType: String
    let calories: Int
    let items: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(mealType)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if calories > 0 {
                Text("\(calories) cal • \(items) items")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                Text("No items")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct HomeKitchenAlertsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Kitchen Alerts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Manage") {
                    print("Manage kitchen tapped")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                HomeKitchenAlertRow(
                    item: "Greek Yoghurt",
                    daysLeft: 2,
                    urgency: .high
                )
                
                HomeKitchenAlertRow(
                    item: "Chicken Breast",
                    daysLeft: 1,
                    urgency: .critical
                )
                
                HomeKitchenAlertRow(
                    item: "Spinach",
                    daysLeft: 4,
                    urgency: .medium
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HomeKitchenAlertRow: View {
    let item: String
    let daysLeft: Int
    let urgency: AlertUrgency
    
    enum AlertUrgency {
        case low, medium, high, critical
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        func text(for days: Int) -> String {
            switch self {
            case .critical: return "Expires today"
            default: return "\(days) days left"
            }
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(urgency.color)
                .frame(width: 8, height: 8)
            
            Text(item)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(urgency.text(for: daysLeft))
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct HomeFoodInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safe Foods")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("47 items")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Pattern")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Improving trends")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HomeHealthScoreCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Score")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("84")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Today")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Nutrition:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("Good")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        Text("Hydration:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("Excellent")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Balance:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text("Improving")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DiaryTabView: View {
    @State private var selectedSubTab: DiarySubTab = .food
    @Binding var showingSettings: Bool
    
    enum DiarySubTab: String, CaseIterable {
        case food = "Food"
        case exercise = "Exercise"
        
        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .exercise: return "figure.run"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Diary")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Date selector
                        Button(action: {
                            print("Date picker tapped")
                        }) {
                            HStack(spacing: 8) {
                                Text("Today")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        // Settings button
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Sub-tab selector
                    DiarySubTabSelector(selectedTab: $selectedSubTab)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected sub-tab
                Group {
                    switch selectedSubTab {
                    case .food:
                        DiaryFoodView()
                    case .exercise:
                        DiaryExerciseView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Diary Sub-Tab Selector
struct DiarySubTabSelector: View {
    @Binding var selectedTab: DiaryTabView.DiarySubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(DiaryTabView.DiarySubTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab 
                            ? Color.blue
                            : Color.clear
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Diary Food View
struct DiaryFoodView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                
                // Daily Summary
                DiaryDailySummaryCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Meal sections
                DiaryMealCard(
                    mealType: "Breakfast",
                    targetCalories: 400,
                    currentCalories: 420,
                    foods: [
                        DiaryFoodItem(name: "Greek Yoghurt", calories: 150, protein: 18.0, carbs: 6.0, fat: 0.5, time: "08:30"),
                        DiaryFoodItem(name: "Banana", calories: 120, protein: 1.3, carbs: 27.0, fat: 0.4, time: "08:30"),
                        DiaryFoodItem(name: "Granola", calories: 150, protein: 5.0, carbs: 22.0, fat: 6.0, time: "08:30")
                    ],
                    color: .orange
                )
                .padding(.horizontal, 16)
                
                DiaryMealCard(
                    mealType: "Lunch",
                    targetCalories: 500,
                    currentCalories: 485,
                    foods: [
                        DiaryFoodItem(name: "Chicken Caesar Salad", calories: 320, protein: 28.0, carbs: 12.0, fat: 18.0, time: "13:15"),
                        DiaryFoodItem(name: "Wholemeal Bread Roll", calories: 165, protein: 6.5, carbs: 28.0, fat: 3.2, time: "13:15")
                    ],
                    color: .green
                )
                .padding(.horizontal, 16)
                
                DiaryMealCard(
                    mealType: "Dinner",
                    targetCalories: 600,
                    currentCalories: 625,
                    foods: [
                        DiaryFoodItem(name: "Grilled Salmon Fillet", calories: 280, protein: 25.0, carbs: 0.0, fat: 18.5, time: "19:30"),
                        DiaryFoodItem(name: "Roasted Sweet Potato", calories: 180, protein: 4.0, carbs: 41.0, fat: 0.5, time: "19:30"),
                        DiaryFoodItem(name: "Steamed Broccoli", calories: 55, protein: 5.0, carbs: 11.0, fat: 0.6, time: "19:30"),
                        DiaryFoodItem(name: "Mixed Green Salad", calories: 110, protein: 3.0, carbs: 8.0, fat: 8.5, time: "19:30")
                    ],
                    color: .purple
                )
                .padding(.horizontal, 16)
                
                DiaryMealCard(
                    mealType: "Snacks",
                    targetCalories: 200,
                    currentCalories: 195,
                    foods: [
                        DiaryFoodItem(name: "Apple with Almond Butter", calories: 195, protein: 6.0, carbs: 25.0, fat: 11.0, time: "15:45")
                    ],
                    color: .blue
                )
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

// MARK: - Diary Exercise View
struct DiaryExerciseView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var todayWorkouts: [HKWorkout] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                
                // Exercise Summary
                DiaryExerciseSummaryCard(
                    totalCalories: healthKitManager.exerciseCalories,
                    workouts: todayWorkouts
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Exercise entries
                DiaryExerciseCard(
                    exerciseType: "Cardio",
                    exercises: [
                        DiaryExerciseItem(name: "Morning Run", duration: 30, calories: 280, time: "07:00"),
                        DiaryExerciseItem(name: "Cycling", duration: 45, calories: 320, time: "18:30")
                    ],
                    color: .red
                )
                .padding(.horizontal, 16)
                
                DiaryExerciseCard(
                    exerciseType: "Strength",
                    exercises: [
                        DiaryExerciseItem(name: "Weight Training", duration: 60, calories: 180, time: "19:00")
                    ],
                    color: .indigo
                )
                .padding(.horizontal, 16)
                
                DiaryExerciseCard(
                    exerciseType: "Other",
                    exercises: [],
                    color: .teal
                )
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
        .onAppear {
            loadHealthData()
        }
        .refreshable {
            loadHealthData()
        }
    }
    
    private func loadHealthData() {
        guard healthKitManager.isAuthorized else { return }
        
        isLoading = true
        Task {
            await healthKitManager.updateExerciseCalories()
            
            do {
                let workouts = try await healthKitManager.fetchWorkouts(for: Date())
                await MainActor.run {
                    todayWorkouts = workouts
                    isLoading = false
                }
            } catch {
                print("Failed to fetch workouts: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Diary Components

struct DiaryDailySummaryCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Overview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("27 August 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("420")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("of 1800 cal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 8) // 420/1800 * total_width
                    .cornerRadius(4)
            }
            
            // Macro breakdown
            HStack(spacing: 20) {
                DiaryMacroItem(name: "Carbs", value: 45, unit: "g", color: .orange)
                DiaryMacroItem(name: "Protein", value: 28, unit: "g", color: .red)
                DiaryMacroItem(name: "Fat", value: 18, unit: "g", color: .yellow)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct DiaryMealCard: View {
    let mealType: String
    let targetCalories: Int
    let currentCalories: Int
    @State var foods: [DiaryFoodItem]
    let color: Color
    
    private var totalProtein: Double {
        foods.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        foods.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFat: Double {
        foods.reduce(0) { $0 + $1.fat }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(mealType)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentCalories)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("/ \(targetCalories) kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    // Show macronutrient totals if foods exist
                    if !foods.isEmpty {
                        HStack(spacing: 6) {
                            MacroSummaryLabel(value: totalProtein, label: "P", color: .red)
                            MacroSummaryLabel(value: totalCarbs, label: "C", color: .orange)
                            MacroSummaryLabel(value: totalFat, label: "F", color: .purple)
                        }
                        .padding(.top, 2)
                    }
                }
            }
            
            if foods.isEmpty {
                Button(action: {
                    print("Add \(mealType.lowercased()) tapped")
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Add \(mealType.lowercased())")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 8) {
                    ForEach(foods) { food in
                        DiaryFoodRow(food: food) {
                            // Delete food from list
                            if let index = foods.firstIndex(of: food) {
                                _ = withAnimation(.easeOut(duration: 0.3)) {
                                    foods.remove(at: index)
                                }
                            }
                        }
                    }
                    
                    Button(action: {
                        print("Add more \(mealType.lowercased()) tapped")
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            Text("Add more")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DiaryFoodItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let time: String
    
    static func == (lhs: DiaryFoodItem, rhs: DiaryFoodItem) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DiaryFoodRow: View {
    let food: DiaryFoodItem
    let onDelete: () -> Void
    @State private var showingFoodDetail = false
    
    var body: some View {
        Button(action: {
            showingFoodDetail = true
        }) {
            HStack(spacing: 12) {
                // Food name and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(food.time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Enhanced nutrition display
                VStack(alignment: .trailing, spacing: 4) {
                    // Energy (calories)
                    HStack(spacing: 4) {
                        Text("\(food.calories)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    // Macronutrients in compact format
                    HStack(spacing: 6) {
                        CompactMacroLabel(value: food.protein, label: "Prot", color: .red)
                        CompactMacroLabel(value: food.carbs, label: "Carb", color: .orange)
                        CompactMacroLabel(value: food.fat, label: "Fat", color: .purple)
                    }
                    
                    // Nutrition Score
                    NutritionScoreView(food: food)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .sheet(isPresented: $showingFoodDetail) {
            FoodDetailView(food: food)
        }
    }
}

struct MacroLabel: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
        .frame(minWidth: 20)
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
        HStack(spacing: 1) {
            Text(String(format: "%.0f", value))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct NutritionScoreView: View {
    let food: DiaryFoodItem
    @State private var showingScoreDetails = false
    
    private var nutritionScore: NutritionProcessingScore {
        ProcessingScorer.shared.calculateProcessingScore(for: food.name)
    }
    
    var body: some View {
        Button(action: {
            showingScoreDetails = true
        }) {
            HStack(spacing: 4) {
                // Score grade
                Text(nutritionScore.grade.rawValue)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 18, height: 18)
                    .background(nutritionScore.color)
                    .clipShape(Circle())
                
                Text("Score")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingScoreDetails) {
            NutritionScoreDetailView(food: food, score: nutritionScore)
        }
    }
}

struct NutritionScoreDetailView: View {
    let food: DiaryFoodItem
    let score: NutritionProcessingScore
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with score
                    VStack(spacing: 12) {
                        Text(food.name)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            // Grade circle
                            Text(score.grade.rawValue)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(score.color)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Processing Score")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("\(score.score)/100")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(score.color)
                                
                                Text(score.processingLevel.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Explanation")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(score.explanation)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Scoring factors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scoring Factors")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ForEach(score.factors, id: \.self) { factor in
                            HStack {
                                Image(systemName: factor.contains("✅") ? "checkmark.circle.fill" : 
                                                 factor.contains("⚠️") ? "exclamationmark.triangle.fill" : "info.circle")
                                    .foregroundColor(factor.contains("✅") ? .green : 
                                                   factor.contains("⚠️") ? .orange : .blue)
                                    .frame(width: 16)
                                
                                Text(factor.replacingOccurrences(of: "✅ ", with: "")
                                          .replacingOccurrences(of: "⚠️ ", with: ""))
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // About the scoring system
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Score")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("This processing score evaluates how much a food has been altered from its natural state:")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                GradeExplanationRow(grade: "A+/A", color: .green, description: "Whole, unprocessed foods")
                                GradeExplanationRow(grade: "B", color: .orange, description: "Lightly processed for preservation")
                                GradeExplanationRow(grade: "C", color: .yellow, description: "Moderately processed with some additives")
                                GradeExplanationRow(grade: "D/F", color: .red, description: "Highly processed with many additives")
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct GradeExplanationRow: View {
    let grade: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(grade)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 20)
                .background(color)
                .cornerRadius(4)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct DiaryExerciseSummaryCard: View {
    let totalCalories: Double
    let workouts: [HKWorkout]
    
    private var totalDuration: Int {
        Int(workouts.reduce(0) { $0 + $1.duration })
    }
    
    private var workoutCount: Int {
        workouts.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise Summary")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("27 August 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("energy burnt")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                DiaryExerciseStat(name: "Duration", value: "\(totalDuration)", unit: "min", color: .blue)
                DiaryExerciseStat(name: "Activities", value: "\(workoutCount)", unit: "", color: .green)
                DiaryExerciseStat(name: "Energy", value: "\(Int(totalCalories))", unit: "kcal", color: .red)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DiaryExerciseStat: View {
    let name: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value + unit)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DiaryExerciseCard: View {
    let exerciseType: String
    let exercises: [DiaryExerciseItem]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text(exerciseType)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if !exercises.isEmpty {
                    Text("\(exercises.reduce(0) { $0 + $1.calories }) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            if exercises.isEmpty {
                Button(action: {
                    print("Add \(exerciseType.lowercased()) tapped")
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("Add \(exerciseType.lowercased())")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises, id: \.name) { exercise in
                        DiaryExerciseRow(exercise: exercise)
                    }
                    
                    Button(action: {
                        print("Add more \(exerciseType.lowercased()) tapped")
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            
                            Text("Add more")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DiaryExerciseItem {
    let name: String
    let duration: Int
    let calories: Int
    let time: String
}

struct DiaryExerciseRow: View {
    let exercise: DiaryExerciseItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(exercise.time) • \(exercise.duration) min")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(exercise.calories) cal")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AddTabView: View {
    var body: some View {
        EmptyView()
    }
}

struct FoodTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedFoodSubTab: FoodSubTab = .reactions
    
    enum FoodSubTab: String, CaseIterable {
        case reactions = "Reactions"
        case safe = "Safe Foods"
        case shopping = "Shopping"
        case meals = "Meal Plans"
        case recipes = "Recipes"
        
        var icon: String {
            switch self {
            case .reactions: return "exclamationmark.triangle"
            case .safe: return "checkmark.seal"
            case .shopping: return "cart"
            case .meals: return "calendar"
            case .recipes: return "book.closed"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Food Hub")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Sub-tab selector
                    FoodSubTabSelector(selectedTab: $selectedFoodSubTab)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected sub-tab
                Group {
                    switch selectedFoodSubTab {
                    case .reactions:
                        FoodReactionsView()
                    case .safe:
                        SafeFoodsView()
                    case .shopping:
                        ShoppingListView()
                    case .meals:
                        MealPlanView()
                    case .recipes:
                        RecipesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Food Sub-Tab Selector
struct FoodSubTabSelector: View {
    @Binding var selectedTab: FoodTabView.FoodSubTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(FoodTabView.FoodSubTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(width: 80, height: 60)
                        .background(
                            selectedTab == tab 
                                ? Color.blue
                                : Color.clear
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Food Sub Views

struct FoodReactionsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Reaction Summary
                FoodReactionSummaryCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Recent Reactions
                FoodReactionListCard(
                    title: "Recent Reactions",
                    reactions: sampleReactions
                )
                .padding(.horizontal, 16)
                
                // Pattern Analysis
                FoodPatternAnalysisCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct SafeFoodsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Safe Foods Summary
                SafeFoodsSummaryCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Categories
                SafeFoodsCategoriesCard()
                    .padding(.horizontal, 16)
                
                // Recent Safe Foods
                SafeFoodsListCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct ShoppingListView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Active Lists
                ShoppingListSummaryCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Quick Add
                ShoppingQuickAddCard()
                    .padding(.horizontal, 16)
                
                // Current List
                ShoppingCurrentListCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct MealPlanView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // This Week
                MealPlanWeekCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Meal Prep
                MealPrepCard()
                    .padding(.horizontal, 16)
                
                // Nutrition Targets
                MealNutritionTargetsCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct RecipesView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Recipe Collections
                RecipeCollectionsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Favourite Recipes
                FavouriteRecipesCard()
                    .padding(.horizontal, 16)
                
                // Safe Recipe Suggestions
                SafeRecipeSuggestionsCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct KitchenTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedKitchenSubTab: KitchenSubTab = .expiry
    
    enum KitchenSubTab: String, CaseIterable {
        case expiry = "Expiry"
        case inventory = "Inventory" 
        case storage = "Storage"
        case waste = "Waste Track"
        
        var icon: String {
            switch self {
            case .expiry: return "clock.arrow.circlepath"
            case .inventory: return "list.bullet.rectangle"
            case .storage: return "square.grid.3x3"
            case .waste: return "trash.circle"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Kitchen")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Sub-tab selector
                    KitchenSubTabSelector(selectedTab: $selectedKitchenSubTab)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected sub-tab
                Group {
                    switch selectedKitchenSubTab {
                    case .expiry:
                        KitchenExpiryView()
                    case .inventory:
                        KitchenInventoryView()
                    case .storage:
                        KitchenStorageView()
                    case .waste:
                        KitchenWasteView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Kitchen Sub-Tab Selector
struct KitchenSubTabSelector: View {
    @Binding var selectedTab: KitchenTabView.KitchenSubTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(KitchenTabView.KitchenSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        selectedTab == tab 
                            ? Color.blue
                            : Color.clear
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

// MARK: - Kitchen Sub Views

struct KitchenExpiryView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Expiry Alerts Summary
                KitchenExpiryAlertsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Critical Expiring Items
                KitchenCriticalExpiryCard()
                    .padding(.horizontal, 16)
                
                // This Week's Expiry
                KitchenWeeklyExpiryCard()
                    .padding(.horizontal, 16)
                
                // Quick Add Item
                KitchenQuickAddCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct KitchenInventoryView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Inventory Overview
                KitchenInventoryOverviewCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Categories
                KitchenInventoryCategoriesCard()
                    .padding(.horizontal, 16)
                
                // Recent Items
                KitchenRecentItemsCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct KitchenStorageView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Storage Locations
                KitchenStorageLocationsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Storage Tips
                KitchenStorageTipsCard()
                    .padding(.horizontal, 16)
                
                // Temperature Monitoring
                KitchenTemperatureCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct KitchenWasteView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Waste Statistics
                KitchenWasteStatsCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Most Wasted Items
                KitchenMostWastedCard()
                    .padding(.horizontal, 16)
                
                // Waste Reduction Tips
                KitchenWasteReductionCard()
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct AddFoodMainView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAddOption: AddOption = .search
    
    enum AddOption: String, CaseIterable {
        case search = "Search"
        case manual = "Manual"
        case barcode = "Barcode"
        case ai = "AI Scanner"
        
        var icon: String {
            switch self {
            case .search: return "magnifyingglass"
            case .manual: return "square.and.pencil"
            case .barcode: return "barcode.viewfinder"
            case .ai: return "camera.viewfinder"
            }
        }
        
        var description: String {
            switch self {
            case .search: return "Search food database"
            case .manual: return "Enter manually"
            case .barcode: return "Scan product barcode"
            case .ai: return "AI-powered food recognition"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Text("Add Food")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Option selector
                    AddOptionSelector(selectedOption: $selectedAddOption)
                        .padding(.horizontal, 16)
                }
                .background(Color(.systemBackground))
                
                // Content based on selected option
                Group {
                    switch selectedAddOption {
                    case .search:
                        AddFoodSearchView()
                    case .manual:
                        AddFoodManualView()
                    case .barcode:
                        AddFoodBarcodeView()
                    case .ai:
                        AddFoodAIView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Option Selector
struct AddOptionSelector: View {
    @Binding var selectedOption: AddFoodMainView.AddOption
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(AddFoodMainView.AddOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedOption == option ? Color.blue : Color(.systemGray5))
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
                            .stroke(selectedOption == option ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }
}

// MARK: - Add Food Views

struct AddFoodManualView: View {
    @State private var foodName = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servingSize = ""
    @State private var servingUnit = "g"
    
    let servingUnits = ["g", "ml", "cup", "tbsp", "tsp", "piece", "slice"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    TextField("Enter food name...", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Serving Size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Serving Size")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("Amount", text: $servingSize)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $servingUnit) {
                            ForEach(servingUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                    }
                }
                
                // Nutrition Facts
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nutrition Facts (per serving)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        NutritionInputRow(label: "Energy", value: $calories, unit: "kcal")
                        NutritionInputRow(label: "Protein", value: $protein, unit: "g")
                        NutritionInputRow(label: "Carbs", value: $carbs, unit: "g")
                        NutritionInputRow(label: "Fat", value: $fat, unit: "g")
                    }
                }
                
                // Add Button
                Button(action: {
                    addManualFood()
                }) {
                    Text("Add Food")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(foodName.isEmpty || calories.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(foodName.isEmpty || calories.isEmpty)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    private func addManualFood() {
        print("Adding manual food: \(foodName)")
        // Implementation for adding manual food
    }
}

struct AddFoodBarcodeView: View {
    @State private var isScanning = false
    @State private var scannedProduct: FoodSearchResult?
    
    var body: some View {
        VStack(spacing: 20) {
            if !isScanning && scannedProduct == nil {
                // Initial state
                VStack(spacing: 24) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Scan Product Barcode")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Point your camera at the product barcode to automatically identify the food item")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: {
                        startScanning()
                    }) {
                        Text("Start Scanning")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
            } else if isScanning {
                // Scanning state
                VStack(spacing: 20) {
                    Text("Scanning...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Mock camera viewfinder
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Spacer()
                                HStack {
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: 200, height: 2)
                                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isScanning)
                                }
                                Spacer()
                            }
                        )
                        .padding(.horizontal, 32)
                    
                    Button("Cancel") {
                        isScanning = false
                    }
                    .foregroundColor(.red)
                }
                
            } else if let product = scannedProduct {
                // Result state
                VStack(spacing: 16) {
                    Text("Product Found!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                    
                    FoodSearchResultRow(food: product) {
                        print("Adding scanned food: \(product.name)")
                    }
                    .padding(.horizontal, 16)
                    
                    Button("Scan Another") {
                        scannedProduct = nil
                        startScanning()
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func startScanning() {
        isScanning = true
        // Simulate barcode scanning
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isScanning = false
            scannedProduct = sampleSearchResults.randomElement()
        }
    }
}

struct AddFoodAIView: View {
    @State private var isScanning = false
    @State private var recognizedFoods: [FoodSearchResult] = []
    
    var body: some View {
        VStack(spacing: 20) {
            if !isScanning && recognizedFoods.isEmpty {
                // Initial state
                VStack(spacing: 24) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 8) {
                        Text("AI Food Recognition")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Take a photo of your meal and our AI will identify the foods and estimate portions")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            startAIScanning()
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            selectFromGallery()
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Gallery")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
            } else if isScanning {
                // Scanning state
                VStack(spacing: 20) {
                    Text("Analyzing Image...")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("AI is identifying foods in your image")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
            } else if !recognizedFoods.isEmpty {
                // Results state
                VStack(spacing: 16) {
                    Text("Foods Detected")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(recognizedFoods, id: \.id) { food in
                                FoodSearchResultRow(food: food) {
                                    print("Adding AI-detected food: \(food.name)")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Button("Scan Another") {
                        recognizedFoods = []
                    }
                    .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    private func startAIScanning() {
        isScanning = true
        // Simulate AI analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            isScanning = false
            recognizedFoods = Array(sampleSearchResults.shuffled().prefix(3))
        }
    }
    
    private func selectFromGallery() {
        startAIScanning()
    }
}

// MARK: - Supporting Views

struct NutritionInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
            
            Text(unit)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }
}

struct FoodSearchResultRow: View {
    let food: FoodSearchResult
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(food.name)
                    .font(.headline)
                if let brand = food.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                Text("\(Int(food.calories))")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("kcal")
                    .font(.caption)
            }
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

// MARK: - Scroll Dismiss Modifier for iOS Compatibility
struct ScrollDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}

// MARK: - Add Food Search View
struct AddFoodSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @StateObject private var fatSecretService = FatSecretService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search foods...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Quick filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Recent", "Popular", "Brands", "Organic", "Gluten Free"], id: \.self) { filter in
                            Button(filter) {
                                searchText = filter.lowercased()
                                performSearch()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            // Results
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(searchResults, id: \.id) { food in
                            FoodSearchResultRow(food: food) {
                                // Add food action
                                print("Adding \(food.name)")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Extra padding to avoid keyboard
                }
                .modifier(ScrollDismissModifier())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Start with empty results - user needs to search
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        Task {
            do {
                let results = try await fatSecretService.searchFoods(query: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.isSearching = false
                }
            } catch {
                print("Search failed: \(error)")
                await MainActor.run {
                    self.searchResults = []
                    self.isSearching = false
                }
            }
        }
    }
}

// MARK: - Sample Data

let sampleSearchResults: [FoodSearchResult] = [
    FoodSearchResult(id: "1", name: "Greek Yoghurt", brand: "Fage", calories: 100, protein: 18.0, carbs: 6.0, fat: 0.0, fiber: 0, sugar: 6.0, sodium: 50),
    FoodSearchResult(id: "2", name: "Banana", brand: nil, calories: 89, protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6, sugar: 12.2, sodium: 1),
    FoodSearchResult(id: "3", name: "Chicken Breast", brand: nil, calories: 165, protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0, sugar: 0, sodium: 74),
    FoodSearchResult(id: "4", name: "Brown Rice", brand: nil, calories: 111, protein: 2.6, carbs: 23.0, fat: 0.9, fiber: 1.8, sugar: 0.4, sodium: 5),
    FoodSearchResult(id: "5", name: "Avocado", brand: nil, calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, fiber: 6.7, sugar: 0.7, sodium: 7),
    FoodSearchResult(id: "6", name: "Spinach", brand: nil, calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, sugar: 0.4, sodium: 79),
    FoodSearchResult(id: "7", name: "Salmon", brand: nil, calories: 208, protein: 22.0, carbs: 0.0, fat: 12.4, fiber: 0, sugar: 0, sodium: 59),
    FoodSearchResult(id: "8", name: "Oats", brand: "Quaker", calories: 150, protein: 5.0, carbs: 27.0, fat: 3.0, fiber: 4.0, sugar: 1.1, sodium: 2),
    // Additional foods to test allergen detection
    FoodSearchResult(id: "9", name: "Whole Milk", brand: "Organic Valley", calories: 150, protein: 8.0, carbs: 12.0, fat: 8.0, fiber: 0, sugar: 12.0, sodium: 105),
    FoodSearchResult(id: "10", name: "Scrambled Eggs", brand: nil, calories: 155, protein: 13.0, carbs: 1.0, fat: 11.0, fiber: 0, sugar: 1.0, sodium: 124),
    FoodSearchResult(id: "11", name: "Wheat Bread", brand: "Hovis", calories: 265, protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7, sugar: 3.0, sodium: 491),
    FoodSearchResult(id: "12", name: "Cheddar Cheese", brand: nil, calories: 403, protein: 25.0, carbs: 1.3, fat: 33.0, fiber: 0, sugar: 0.5, sodium: 621)
]


// MARK: - Food Tab Component Cards

struct FoodReactionSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reaction Tracking")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("12")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("This month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("3")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("This week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("85%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Identified")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Reaction")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FoodReactionListCard: View {
    let title: String
    let reactions: [FoodReaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if reactions.isEmpty {
                Text("No reactions logged")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(reactions, id: \.id) { reaction in
                        FoodReactionRow(reaction: reaction)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FoodReactionRow: View {
    let reaction: FoodReaction
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor(for: reaction.severity))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reaction.foodName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(reaction.symptoms.joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatDate(reaction.reactionTime))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func severityColor(for severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            return "\(daysDiff) days ago"
        }
    }
}

struct FoodPatternAnalysisCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Analysis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                PatternRow(trigger: "Dairy Products", frequency: "67%", trend: .increasing)
                PatternRow(trigger: "Gluten", frequency: "34%", trend: .stable)
                PatternRow(trigger: "Nuts", frequency: "12%", trend: .decreasing)
            }
            
            Button("View Full Analysis") {
                print("View analysis tapped")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PatternRow: View {
    let trigger: String
    let frequency: String
    let trend: Trend
    
    enum Trend {
        case increasing, stable, decreasing
        
        var icon: String {
            switch self {
            case .increasing: return "arrow.up"
            case .stable: return "minus"
            case .decreasing: return "arrow.down"
            }
        }
        
        var color: Color {
            switch self {
            case .increasing: return .red
            case .stable: return .yellow
            case .decreasing: return .green
            }
        }
    }
    
    var body: some View {
        HStack {
            Text(trigger)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(frequency)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Image(systemName: trend.icon)
                .font(.system(size: 12))
                .foregroundColor(trend.color)
        }
    }
}

struct SafeFoodsSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe Foods Library")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("147")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Safe foods")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("23")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("New this week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafeFoodsCategoriesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                SafeFoodCategoryItem(name: "Vegetables", count: 45, color: .green)
                SafeFoodCategoryItem(name: "Fruits", count: 32, color: .orange)
                SafeFoodCategoryItem(name: "Proteins", count: 28, color: .red)
                SafeFoodCategoryItem(name: "Grains", count: 18, color: .yellow)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafeFoodCategoryItem: View {
    let name: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct SafeFoodsListCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Added")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                SafeFoodRow(name: "Quinoa", category: "Grains", date: "Today")
                SafeFoodRow(name: "Sweet Potato", category: "Vegetables", date: "Yesterday")
                SafeFoodRow(name: "Salmon", category: "Proteins", date: "2 days ago")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafeFoodRow: View {
    let name: String
    let category: String
    let date: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(date)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Shopping List Components
struct ShoppingListSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shopping Lists")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("3")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Active lists")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("15")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Items pending")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShoppingQuickAddCard: View {
    @State private var newItem = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack {
                TextField("Add item...", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShoppingCurrentListCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Shop")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ShoppingItemRow(name: "Greek Yoghurt", category: "Dairy", checked: false)
                ShoppingItemRow(name: "Bananas", category: "Fruit", checked: true)
                ShoppingItemRow(name: "Chicken Breast", category: "Meat", checked: false)
                ShoppingItemRow(name: "Spinach", category: "Vegetables", checked: false)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShoppingItemRow: View {
    let name: String
    let category: String
    @State var checked: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                checked.toggle()
            }) {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(checked ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(checked ? .secondary : .primary)
                    .strikethrough(checked)
                
                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Meal Plan Components
struct MealPlanWeekCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Plan")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                MealPlanDayRow(day: "Today", meals: "Planned", status: .complete)
                MealPlanDayRow(day: "Tomorrow", meals: "2 meals", status: .partial)
                MealPlanDayRow(day: "Thursday", meals: "Not planned", status: .empty)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MealPlanDayRow: View {
    let day: String
    let meals: String
    let status: MealPlanStatus
    
    enum MealPlanStatus {
        case complete, partial, empty
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .partial: return .orange
            case .empty: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .complete: return "checkmark.circle.fill"
            case .partial: return "clock.circle.fill"
            case .empty: return "circle"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .font(.system(size: 16))
                .foregroundColor(status.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(meals)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MealPrepCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Prep")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("3")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Recipes ready")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("2h")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Prep time")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MealNutritionTargetsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Nutrition Targets")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                NutritionTargetRow(nutrient: "Protein", current: 87, target: 120, unit: "g")
                NutritionTargetRow(nutrient: "Fibre", current: 45, target: 35, unit: "g")
                NutritionTargetRow(nutrient: "Vitamin D", current: 12, target: 15, unit: "μg")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutritionTargetRow: View {
    let nutrient: String
    let current: Int
    let target: Int
    let unit: String
    
    private var progress: Double {
        Double(current) / Double(target)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.7 { return .orange }
        return .red
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(nutrient)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(current)/\(target)\(unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

// Recipe Components
struct RecipeCollectionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Collections")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                RecipeCollectionItem(name: "Quick & Easy", count: 24, color: .blue)
                RecipeCollectionItem(name: "Dairy Free", count: 18, color: .green)
                RecipeCollectionItem(name: "High Protein", count: 15, color: .red)
                RecipeCollectionItem(name: "Meal Prep", count: 12, color: .purple)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecipeCollectionItem: View {
    let name: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(count) recipes")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct FavouriteRecipesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favourite Recipes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                RecipeRow(name: "Quinoa Buddha Bowl", time: "25 min", difficulty: "Easy")
                RecipeRow(name: "Grilled Salmon", time: "20 min", difficulty: "Medium")
                RecipeRow(name: "Sweet Potato Curry", time: "35 min", difficulty: "Easy")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SafeRecipeSuggestionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe Recipe Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Based on your safe foods and dietary preferences")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                RecipeRow(name: "Herb Roasted Chicken", time: "45 min", difficulty: "Easy")
                RecipeRow(name: "Mediterranean Rice Bowl", time: "30 min", difficulty: "Easy")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecipeRow: View {
    let name: String
    let time: String
    let difficulty: String
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(time) • \(difficulty)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Sample Data - using DataModels.swift structures
import Foundation

let sampleReactions: [FoodReaction] = [
    FoodReaction(
        foodName: "Milk",
        foodIngredients: ["milk", "lactose"],
        reactionTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        symptoms: ["Bloating", "nausea"],
        severity: .moderate,
        notes: "Had with cereal"
    ),
    FoodReaction(
        foodName: "Peanuts",
        foodIngredients: ["peanuts", "groundnuts"],
        reactionTime: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
        symptoms: ["Hives", "itching"],
        severity: .severe,
        notes: "Trail mix snack"
    ),
    FoodReaction(
        foodName: "Wheat bread",
        foodIngredients: ["wheat", "gluten"],
        reactionTime: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
        symptoms: ["Stomach pain"],
        severity: .mild,
        notes: "With breakfast"
    )
]

// MARK: - Kitchen Tab Component Cards

struct KitchenExpiryAlertsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expiry Alerts")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("5")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("Critical")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("12")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("This week")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("28")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Total items")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenCriticalExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Critical - Use Today!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                KitchenExpiryItemRow(
                    name: "Greek Yoghurt", 
                    location: "Fridge", 
                    daysLeft: 0,
                    urgency: .critical
                )
                KitchenExpiryItemRow(
                    name: "Chicken Breast", 
                    location: "Fridge", 
                    daysLeft: 1,
                    urgency: .high
                )
                KitchenExpiryItemRow(
                    name: "Spinach", 
                    location: "Fridge", 
                    daysLeft: 2,
                    urgency: .medium
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenWeeklyExpiryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Expiry")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenExpiryDayRow(day: "Today", count: 3, items: ["Milk", "Yoghurt", "Lettuce"])
                KitchenExpiryDayRow(day: "Tomorrow", count: 2, items: ["Bread", "Bananas"])
                KitchenExpiryDayRow(day: "Thursday", count: 4, items: ["Cheese", "Tomatoes", "Carrots", "Eggs"])
                KitchenExpiryDayRow(day: "Friday", count: 3, items: ["Salmon", "Broccoli", "Mushrooms"])
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenExpiryItemRow: View {
    let name: String
    let location: String
    let daysLeft: Int
    let urgency: ExpiryUrgency
    
    enum ExpiryUrgency {
        case critical, high, medium, low
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .medium: return .yellow
            case .low: return .green
            }
        }
        
        func text(for days: Int) -> String {
            switch self {
            case .critical: return "Expires today!"
            default: return "\(days) days left"
            }
        }
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(urgency.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(location)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(urgency.text(for: daysLeft))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(urgency.color)
        }
        .padding(.vertical, 4)
    }
}

struct KitchenExpiryDayRow: View {
    let day: String
    let count: Int
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(day)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(items.joined(separator: ", "))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

struct KitchenQuickAddCard: View {
    @State private var newItem = ""
    @State private var selectedLocation = "Fridge"
    
    let locations = ["Fridge", "Freezer", "Pantry", "Cupboard"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add Item")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    TextField("Item name...", text: $newItem)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                
                Picker("Location", selection: $selectedLocation) {
                    ForEach(locations, id: \.self) { location in
                        Text(location).tag(location)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Add Item") {}
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Kitchen Inventory Components
struct KitchenInventoryOverviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kitchen Inventory")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("147")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Total items")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("£285")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("Est. value")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("12")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Low stock")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenInventoryCategoriesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Locations")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                KitchenLocationItem(name: "Fridge", count: 45, icon: "refrigerator", color: .blue)
                KitchenLocationItem(name: "Freezer", count: 32, icon: "snowflake", color: .cyan)
                KitchenLocationItem(name: "Pantry", count: 38, icon: "cabinet", color: .brown)
                KitchenLocationItem(name: "Cupboard", count: 32, icon: "archivebox", color: .gray)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenLocationItem: View {
    let name: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(count) items")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct KitchenRecentItemsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Added")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenRecentItemRow(name: "Organic Milk", location: "Fridge", date: "Today", expiry: "5 days")
                KitchenRecentItemRow(name: "Sourdough Bread", location: "Pantry", date: "Yesterday", expiry: "3 days")
                KitchenRecentItemRow(name: "Free Range Eggs", location: "Fridge", date: "2 days ago", expiry: "2 weeks")
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenRecentItemRow: View {
    let name: String
    let location: String
    let date: String
    let expiry: String
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(location) • Expires in \(expiry)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(date)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Kitchen Storage Components
struct KitchenStorageLocationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                KitchenStorageLocationDetail(
                    name: "Refrigerator",
                    icon: "refrigerator",
                    temperature: "4°C",
                    capacity: "85%",
                    items: 45,
                    color: .blue
                )
                
                KitchenStorageLocationDetail(
                    name: "Freezer",
                    icon: "snowflake",
                    temperature: "-18°C",
                    capacity: "62%",
                    items: 32,
                    color: .cyan
                )
                
                KitchenStorageLocationDetail(
                    name: "Pantry",
                    icon: "cabinet",
                    temperature: "20°C",
                    capacity: "73%",
                    items: 38,
                    color: .brown
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenStorageLocationDetail: View {
    let name: String
    let icon: String
    let temperature: String
    let capacity: String
    let items: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(items) items • \(capacity) full")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(temperature)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct KitchenStorageTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Tips")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenStorageTipRow(
                    tip: "Store apples separately - they release ethylene gas",
                    category: "Fruits"
                )
                KitchenStorageTipRow(
                    tip: "Keep potatoes in dark, cool places to prevent sprouting",
                    category: "Vegetables"
                )
                KitchenStorageTipRow(
                    tip: "Herbs last longer with stems in water",
                    category: "Fresh produce"
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenStorageTipRow: View {
    let tip: String
    let category: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(category)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct KitchenTemperatureCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temperature Monitoring")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenTemperatureRow(location: "Fridge", current: "4°C", optimal: "1-4°C", status: .good)
                KitchenTemperatureRow(location: "Freezer", current: "-16°C", optimal: "-18°C", status: .warning)
                KitchenTemperatureRow(location: "Room", current: "22°C", optimal: "18-21°C", status: .warning)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenTemperatureRow: View {
    let location: String
    let current: String
    let optimal: String
    let status: TemperatureStatus
    
    enum TemperatureStatus {
        case good, warning, critical
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .font(.system(size: 16))
                .foregroundColor(status.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(location)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Optimal: \(optimal)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(current)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(status.color)
        }
        .padding(.vertical, 4)
    }
}

// Kitchen Waste Components
struct KitchenWasteStatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Food Waste Tracking")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("2.1kg")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                    Text("This month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("£18")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    Text("Value wasted")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("-15%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                    Text("vs last month")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenMostWastedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Wasted Items")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenWasteItemRow(item: "Lettuce & Salad", amount: "0.8kg", value: "£6", percentage: 35)
                KitchenWasteItemRow(item: "Bread", amount: "0.5kg", value: "£4", percentage: 25)
                KitchenWasteItemRow(item: "Bananas", amount: "0.3kg", value: "£3", percentage: 18)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenWasteItemRow: View {
    let item: String
    let amount: String
    let value: String
    let percentage: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(item)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(amount) • \(value)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * (Double(percentage) / 100), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

struct KitchenWasteReductionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waste Reduction Tips")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                KitchenWasteTipRow(
                    tip: "Plan weekly meals to buy only what you need",
                    impact: "Reduces waste by 30%"
                )
                KitchenWasteTipRow(
                    tip: "Store foods properly to extend freshness",
                    impact: "Saves £15/month"
                )
                KitchenWasteTipRow(
                    tip: "Use 'first in, first out' rotation system",
                    impact: "Prevents forgotten items"
                )
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct KitchenWasteTipRow: View {
    let tip: String
    let impact: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(tip)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(impact)
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    
                    // Profile Section
                    SettingsSection(title: "Profile") {
                        SettingsRow(icon: "person.fill", title: "Personal Information", action: {})
                        SettingsRow(icon: "target", title: "Goals & Targets", action: {})
                        SettingsRow(icon: "heart.text.square", title: "Health Conditions", action: {})
                        SettingsRow(icon: "exclamationmark.triangle", title: "Allergies & Intolerances", action: {})
                    }
                    
                    // Data & Sync Section
                    SettingsSection(title: "Data & Sync") {
                        SettingsRow(icon: "heart.circle", title: "Apple Health", action: {})
                        SettingsRow(icon: "icloud", title: "Cloud Sync", action: {})
                        SettingsRow(icon: "arrow.up.doc", title: "Export Data", action: {})
                        SettingsRow(icon: "arrow.down.doc", title: "Import Data", action: {})
                    }
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications") {
                        SettingsRow(icon: "bell", title: "Meal Reminders", action: {})
                        SettingsRow(icon: "clock", title: "Water Reminders", action: {})
                        SettingsRow(icon: "refrigerator", title: "Food Expiry Alerts", action: {})
                    }
                    
                    // App Settings Section
                    SettingsSection(title: "App Settings") {
                        SettingsRow(icon: "textformat", title: "Units & Measurements", action: {})
                        SettingsRow(icon: "moon", title: "Dark Mode", action: {})
                        SettingsRow(icon: "lock", title: "Privacy & Security", action: {})
                        SettingsRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                    }
                    
                    // About Section
                    SettingsSection(title: "About") {
                        SettingsRow(icon: "info.circle", title: "Version 1.0.0 (Beta)", action: {})
                        SettingsRow(icon: "doc.text", title: "Terms & Conditions", action: {})
                        SettingsRow(icon: "hand.raised", title: "Privacy Policy", action: {})
                    }
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Professional Summary Card (Following Research Standards)
struct ProfessionalSummaryCard: View {
    let dailyNutrition: DailyNutrition
    let selectedDate: Date
    let animateProgress: Bool
    
    var body: some View {
        VStack(spacing: 12) { // Reduced from 16px for better screen usage
            
            // Date Header with Professional Typography
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's Summary")
                        .font(.system(size: 24, weight: .bold)) // Reduced from 34pt for better screen usage
                        .foregroundColor(.primary)
                    
                    Text(selectedDate, style: .date)
                        .font(.system(size: 16, weight: .medium)) // Reduced from 22pt
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Calories Remaining - Reduced for better screen usage
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(dailyNutrition.calories.remaining))")
                        .font(.system(size: 22, weight: .bold)) // Reduced from 28pt
                        .foregroundColor(.primary)
                    
                    Text("cal remaining")
                        .font(.system(size: 14)) // Reduced from 17pt
                        .foregroundColor(.secondary)
                }
            }
            
            // Circular Progress Indicators - Research: Professional apps use circular progress for daily goals
            HStack(spacing: 24) { // 24-32dp between unrelated groups (research standard)
                
                // Main Calories Ring
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: animateProgress ? dailyNutrition.calories.percentage : 0)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#4CAF50"), Color(hex: "#8BC34A")], // Evidence-based green for healthy/under goal
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2), value: animateProgress)
                    
                    VStack(spacing: 1) {
                        Text("\(Int(dailyNutrition.calories.current))")
                            .font(.system(size: 20, weight: .bold)) // Reduced from 24pt for better screen usage
                            .foregroundColor(.primary)
                        
                        Text("of \(Int(dailyNutrition.calories.target))")
                            .font(.system(size: 12, weight: .medium)) // Reduced from 14pt
                            .foregroundColor(.secondary)
                        
                        Text("kcal")
                            .font(.system(size: 10)) // Reduced from 12pt
                            .foregroundColor(.secondary)
                    }
                }
                
                // Macro Pie Charts - Research: Pie charts for macro breakdowns
                VStack(spacing: 12) {
                    MacroPieChart(
                        title: "Protein",
                        current: dailyNutrition.protein.current,
                        target: dailyNutrition.protein.target,
                        color: Color(hex: "#2196F3"), // Evidence-based blue for protein
                        animateProgress: animateProgress
                    )
                    
                    MacroPieChart(
                        title: "Carbs",
                        current: dailyNutrition.carbs.current,
                        target: dailyNutrition.carbs.target,
                        color: Color(hex: "#FF9800"), // Evidence-based orange for carbs
                        animateProgress: animateProgress
                    )
                    
                    MacroPieChart(
                        title: "Fat",
                        current: dailyNutrition.fat.current,
                        target: dailyNutrition.fat.target,
                        color: Color(hex: "#9C27B0"), // Evidence-based purple for fat
                        animateProgress: animateProgress
                    )
                }
            }
        }
        .padding(16) // 16px internal padding (research standard)
        .background(
            RoundedRectangle(cornerRadius: 16) // 8-12dp corner radii (research standard)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2) // Subtle shadows
        )
        .frame(minHeight: 140) // 120-160px height range (research standard)
    }
}

// MARK: - Macro Pie Chart Component
struct MacroPieChart: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    let animateProgress: Bool
    
    private var percentage: Double {
        min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray6), lineWidth: 3)
                    .frame(width: 44, height: 44) // 44pt minimum touch targets (research standard)
                
                Circle()
                    .trim(from: 0, to: animateProgress ? percentage : 0)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0).delay(0.2), value: animateProgress)
                
                Text("\(Int(current))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium)) // 12pt minimum (research standard)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Professional Meal Section
struct ProfessionalMealSection: View {
    let mealType: MealType
    let items: [MealItem]
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // 12px vertical spacing (research standard)
            
            // Meal Header - Research: 22-28pt for section headers
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: mealType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(mealType.color)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(mealType.color.opacity(0.15))
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(mealType.displayName)
                            .font(.system(size: 18, weight: .semibold)) // Reduced from 24pt for better screen usage
                            .foregroundColor(.primary)
                        
                        if !items.isEmpty {
                            Text("\(totalCalories) energy")
                                .font(.system(size: 14)) // Reduced from 17pt
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Add Button - Research: 44pt minimum touch targets
                Button(action: onAddTapped) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold)) // Reduced from 24pt
                        .foregroundColor(mealType.color)
                        .frame(width: 44, height: 44) // 44pt minimum touch targets (research standard)
                }
            }
            
            // Food Items - Research: 56-72dp for single-line items
            if items.isEmpty {
                ProfessionalEmptyMealState(mealType: mealType, onAddTapped: onAddTapped)
            } else {
                LazyVStack(spacing: 8) { // 8dp spacing between related elements (research standard)
                    ForEach(items) { item in
                        ProfessionalFoodItemCard(item: item)
                    }
                }
            }
        }
        .padding(16) // 16px internal padding (research standard)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
    
    private var totalCalories: Int {
        items.reduce(0) { $0 + $1.calories }
    }
}

// MARK: - Professional Food Item Card
struct ProfessionalFoodItemCard: View {
    let item: MealItem
    
    var body: some View {
        HStack(spacing: 16) { // 16dp horizontal padding (research standard)
            
            // Food Quality Indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(qualityColor)
                .frame(width: 4, height: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                // Truncation with ellipsis - Research: prevents word wrapping disasters
                Text(item.name)
                    .font(.system(size: 15, weight: .medium)) // Reduced from 17pt for better screen usage
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.system(size: 14)) // Never use body text smaller than 14sp Android / 17px iOS (research standard)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer(minLength: 16) // Minimum spacing to prevent cramping
            
            // Nutrition Summary - Research: Icon + text combinations
            HStack(spacing: 12) {
                NutritionBadge(value: item.calories, unit: "cal", color: .primary)
                NutritionBadge(value: Int(item.protein), unit: "p", color: Color(hex: "#2196F3"))
                NutritionBadge(value: Int(item.carbs), unit: "c", color: Color(hex: "#FF9800"))
                NutritionBadge(value: Int(item.fat), unit: "f", color: Color(hex: "#9C27B0"))
            }
        }
        .frame(minHeight: 56) // 56-72dp for single-line items (research standard)
        .padding(.horizontal, 16) // Minimum 16dp horizontal padding (research standard)
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var qualityColor: Color {
        // Traffic light system - Research: universally effective for nutritional assessment
        switch item.qualityScore {
        case 80...100: return Color(hex: "#4CAF50") // Green for healthy/under goal
        case 60..<80: return Color(hex: "#FF9800") // Orange for moderate/caution  
        default: return Color(hex: "#F44336") // Red for excessive/over limit
        }
    }
}

// MARK: - Nutrition Badge Component
struct NutritionBadge: View {
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Professional Empty State
struct ProfessionalEmptyMealState: View {
    let mealType: MealType
    let onAddTapped: () -> Void
    
    var body: some View {
        Button(action: onAddTapped) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16)) // Reduced from 20pt for better screen usage
                    .foregroundColor(mealType.color)
                
                Text("Add \(mealType.displayName.lowercased())")
                    .font(.system(size: 15)) // Reduced from 17pt for better screen usage
                    .foregroundColor(mealType.color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(minHeight: 48) // 48dp minimum button height (research standard)
            .padding(.horizontal, 16)
            .background(mealType.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models
enum MealType: String, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snacks = "snacks"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "sunset.fill"
        case .snacks: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return Color(hex: "#FF9800") // Orange
        case .lunch: return Color(hex: "#FFC107") // Amber
        case .dinner: return Color(hex: "#3F51B5") // Indigo
        case .snacks: return Color(hex: "#9C27B0") // Purple
        }
    }
}

struct MealItem: Identifiable {
    let id = UUID()
    let name: String
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let qualityScore: Int // 0-100
    
    init(name: String, brand: String? = nil, calories: Int, protein: Double, carbs: Double, fat: Double, qualityScore: Int) {
        self.name = name
        self.brand = brand
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.qualityScore = qualityScore
    }
}

struct DailyNutrition {
    let calories: NutritionValue
    let protein: NutritionValue
    let carbs: NutritionValue
    let fat: NutritionValue
}

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

// MARK: - Color Extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Food Detail Page
struct FoodDetailView: View {
    let food: DiaryFoodItem
    @State private var selectedServingIndex = 0
    @State private var quantity: Double = 1.0
    @State private var customGrams: String = ""
    @State private var isCustomGrams = false
    @Environment(\.dismiss) private var dismiss
    
    // Mock serving options - in production these would come from the food data
    private var servingOptions: [FoodServingOption] {
        [
            FoodServingOption(name: "1 serving", unit: "serving", gramsPerServing: 100.0, isDefault: true),
            FoodServingOption(name: "100g", unit: "g", gramsPerServing: 100.0, isDefault: false),
            FoodServingOption(name: "1 cup", unit: "cup", gramsPerServing: 150.0, isDefault: false),
            FoodServingOption(name: "Custom", unit: "g", gramsPerServing: 100.0, isDefault: false)
        ]
    }
    
    private var selectedServing: FoodServingOption {
        servingOptions[selectedServingIndex]
    }
    
    private var actualGrams: Double {
        if isCustomGrams, let customValue = Double(customGrams), customValue > 0 {
            return customValue
        }
        return selectedServing.gramsPerServing * quantity
    }
    
    private var scalingFactor: Double {
        actualGrams / 100.0 // Assuming nutrition is per 100g
    }
    
    private var scaledCalories: Int {
        Int(Double(food.calories) * scalingFactor)
    }
    
    private var scaledProtein: Double {
        food.protein * scalingFactor
    }
    
    private var scaledCarbs: Double {
        food.carbs * scalingFactor
    }
    
    private var scaledFat: Double {
        food.fat * scalingFactor
    }
    
    private var glycemicData: GlycemicIndexData? {
        GlycemicIndexDatabase.shared.getGIData(for: food.name)
    }
    
    private var glycemicLoad: Double? {
        guard let giData = glycemicData, let giValue = giData.value else { return nil }
        let carbGrams = scaledCarbs
        return (Double(giValue) * carbGrams) / 100.0
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(food.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let brand = extractBrand(from: food.name) {
                            Text(brand)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Serving Size Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Serving Size")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Serving options picker
                        Picker("Serving Size", selection: $selectedServingIndex) {
                            ForEach(0..<servingOptions.count, id: \.self) { index in
                                Text(servingOptions[index].name)
                                    .tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedServingIndex) { newValue in
                            isCustomGrams = (newValue == servingOptions.count - 1)
                            if !isCustomGrams {
                                customGrams = ""
                            }
                        }
                        
                        // Custom grams input
                        if isCustomGrams {
                            HStack {
                                TextField("Enter grams", text: $customGrams)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                Text("g")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Quantity selector
                        if !isCustomGrams {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quantity")
                                    .font(.system(size: 16, weight: .medium))
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if quantity > 0.25 {
                                            quantity -= 0.25
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Text(String(format: "%.2g", quantity))
                                        .font(.system(size: 18, weight: .medium))
                                        .frame(minWidth: 60)
                                    
                                    Button(action: {
                                        quantity += 0.25
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        // Total weight display
                        Text("Total: \(String(format: "%.0f", actualGrams))g")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Nutrition Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Nutrition")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Large calorie display
                        HStack {
                            Text("\(scaledCalories)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("kcal")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            Spacer()
                        }
                        
                        // Macronutrient breakdown
                        VStack(spacing: 12) {
                            MacroNutrientRow(label: "Protein", value: scaledProtein, unit: "g", color: .red)
                            MacroNutrientRow(label: "Carbohydrate", value: scaledCarbs, unit: "g", color: .orange)
                            MacroNutrientRow(label: "Fat", value: scaledFat, unit: "g", color: .purple)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Glycemic Index Information
                    if let giData = glycemicData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Glycemic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Glycemic Index:")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text("\(giData.value ?? 0)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(giData.category.color)
                                    Text("(\(giData.category.rawValue.capitalized))")
                                        .font(.system(size: 14))
                                        .foregroundColor(giData.category.color)
                                }
                                
                                if let gl = glycemicLoad {
                                    HStack {
                                        Text("Glycemic Load:")
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(String(format: "%.1f", gl))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(glColor(for: gl))
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Processing Score
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Processing Score")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            let score = ProcessingScorer.shared.calculateProcessingScore(for: food.name)
                            
                            // Score circle
                            ZStack {
                                Circle()
                                    .fill(score.color)
                                    .frame(width: 50, height: 50)
                                
                                Text(score.grade.rawValue)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(score.processingLevel.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text(score.explanation)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Add to Diary Button
                    Button(action: {
                        // Add food to diary with current serving size
                        dismiss()
                    }) {
                        HStack {
                            Text("Add to Diary")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func extractBrand(from name: String) -> String? {
        // Simple brand extraction - could be enhanced
        let components = name.components(separatedBy: " - ")
        return components.count > 1 ? components.last : nil
    }
    
    private func glColor(for gl: Double) -> Color {
        if gl < 10 { return .green }
        else if gl < 20 { return .orange }
        else { return .red }
    }
}

struct MacroNutrientRow: View {
    let label: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sample Data
private let sampleDailyNutrition = DailyNutrition(
    calories: NutritionValue(current: 1450, target: 2000),
    protein: NutritionValue(current: 95, target: 120),
    carbs: NutritionValue(current: 180, target: 250),
    fat: NutritionValue(current: 65, target: 78)
)

private let sampleBreakfastItems = [
    MealItem(name: "Steel-cut oats with mixed berries", brand: "Quaker", calories: 320, protein: 12, carbs: 58, fat: 6, qualityScore: 92),
    MealItem(name: "Greek yogurt, plain", brand: "Fage 0%", calories: 100, protein: 18, carbs: 7, fat: 0, qualityScore: 95)
]

private let sampleLunchItems = [
    MealItem(name: "Grilled chicken salad with quinoa", calories: 420, protein: 35, carbs: 28, fat: 18, qualityScore: 88)
]

private let sampleDinnerItems = [
    MealItem(name: "Baked salmon fillet", calories: 280, protein: 42, carbs: 0, fat: 12, qualityScore: 95),
    MealItem(name: "Roasted sweet potato", calories: 180, protein: 4, carbs: 42, fat: 0.2, qualityScore: 88)
]

private let sampleSnackItems = [
    MealItem(name: "Apple with almond butter", calories: 190, protein: 4, carbs: 25, fat: 8, qualityScore: 85)
]

#Preview {
    ContentView()
}