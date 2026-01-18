//
//  ReactionLogView.swift
//  NutraSafe Beta
//
//  Reaction Log Mode - Track reactions and analyze possible food triggers
//

import SwiftUI

struct ReactionLogView: View {
    @StateObject private var manager = ReactionLogManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingLogSheet = false
    @State private var selectedEntry: ReactionLogEntry?
    @State private var selectedDayRange: DayRange = .threeDays
    @State private var selectedTab: AnalysisTab = .potentialTriggers
    @State private var showingPDFExportSheet = false
    @State private var isLoadingData = false
    @State private var userAllergens: Set<Allergen> = []

    enum DayRange: Int, CaseIterable {
        case threeDays = 3
        case fiveDays = 5
        case sevenDays = 7

        var displayText: String {
            "\(rawValue) days"
        }
    }

    enum AnalysisTab: String, CaseIterable {
        case potentialTriggers = "Potential Triggers"
        case reactionTimeline = "Reaction Timeline"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Log Reaction Button
                logReactionButton

                // Export PDF Button (only show if there are reactions)
                if !manager.reactionLogs.isEmpty {
                    exportPDFButton
                }

                // Loading state or content
                if isLoadingData {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(.circular)
                        Text("Loading reaction history...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    // Analysis Tabs
                    analysisTabPicker

                    // Tab Content
                    tabContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color.adaptiveBackground)
        .fullScreenCover(isPresented: $showingLogSheet) {
            LogReactionSheet(selectedDayRange: selectedDayRange)
        }
        .fullScreenCover(item: $selectedEntry) { entry in
            ReactionLogDetailView(entry: entry, selectedDayRange: selectedDayRange)
        }
        .fullScreenCover(isPresented: $showingPDFExportSheet) {
            MultiReactionPDFExportSheet()
        }
        .task {
            isLoadingData = true
            async let logsTask: () = manager.loadReactionLogs()
            async let allergensTask: () = loadUserAllergens()
            await logsTask
            await allergensTask
            isLoadingData = false
        }
    }

    // MARK: - Load User Allergens

    private func loadUserAllergens() async {
        do {
            let settings = try await FirebaseManager.shared.getUserSettings()
            await MainActor.run {
                userAllergens = Set(settings.allergens ?? [])
            }
        } catch {
            // Silently fail - allergens are optional
        }
    }

    /// Check if an ingredient matches user's saved allergens
    private func isUserAllergenIngredient(_ ingredient: String) -> Bool {
        let lower = ingredient.lowercased()

        for allergen in userAllergens {
            // Check against allergen keywords
            for keyword in allergen.keywords {
                if lower.contains(keyword.lowercased()) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Log Reaction Button
    private var logReactionButton: some View {
        Button(action: { showingLogSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)

                Text("Log Reaction")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.5, blue: 1.0),
                        Color(red: 0.5, green: 0.3, blue: 0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Export PDF Button
    private var exportPDFButton: some View {
        Button(action: { showingPDFExportSheet = true }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Export PDF Report")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.8),
                        Color.blue.opacity(0.6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }

    // MARK: - Analysis Tab Picker
    private var analysisTabPicker: some View {
        HStack(spacing: 0) {
            ForEach(AnalysisTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                            .foregroundColor(selectedTab == tab ? .white : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == tab ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.3, green: 0.5, blue: 1.0),
                                            Color(red: 0.5, green: 0.3, blue: 0.9)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                            .cornerRadius(10)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .potentialTriggers:
            potentialTriggersView
        case .reactionTimeline:
            reactionTimelineView
        }
    }

    // MARK: - Potential Triggers View
    private var potentialTriggersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if manager.reactionLogs.isEmpty {
                emptyStateView(
                    icon: "chart.bar.doc.horizontal",
                    title: "No reactions logged yet",
                    message: "Log your first reaction to start identifying potential food triggers"
                )
            } else if manager.reactionLogs.count < 2 {
                emptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Building your pattern analysis",
                    message: "Log at least 2 reactions to identify potential triggers and patterns"
                )
            } else {
                // Flagged foods patterns
                commonFoodsView

                // Common ingredients patterns
                commonIngredientsView
            }
        }
    }

    // MARK: - Reaction Timeline View
    private var reactionTimelineView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if manager.reactionLogs.isEmpty {
                emptyStateView(
                    icon: "clock.badge.questionmark",
                    title: "No reactions logged yet",
                    message: "Start logging reactions to see your timeline and meal history"
                )
            } else {
                // Reaction history list
                ForEach(manager.reactionLogs) { entry in
                    Button(action: {
                        selectedEntry = entry
                    }) {
                        ReactionLogCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty State
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Helpful tip
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .frame(width: 20)

                    Text("Track reactions to help identify patterns and potential food sensitivities over time")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Common Foods View (Flagged Foods)
    private var commonFoodsView: some View {
        let commonFoods = calculateCommonFoods()

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                Text("Flagged Foods")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("These specific foods appear frequently before your reactions. Track these items to identify patterns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            if commonFoods.isEmpty {
                Text("Not enough observations yet to identify food patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(commonFoods.prefix(10), id: \.name) { food in
                    CommonFoodRow(
                        name: food.name,
                        frequency: food.frequency,
                        percentage: food.percentage
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Common Ingredients View
    private var commonIngredientsView: some View {
        let commonIngredients = calculateCommonIngredients()
        let matchedAllergens = commonIngredients.filter { isUserAllergenIngredient($0.name) }

        return VStack(alignment: .leading, spacing: 16) {
            Text("Ingredient Patterns")
                .font(.headline)
                .foregroundColor(.primary)

            Text("These ingredients appear frequently in foods consumed before your reactions. This information may help you spot potential connections to discuss with your healthcare provider.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            // User allergen warning banner
            if !matchedAllergens.isEmpty && !userAllergens.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(matchedAllergens.count) of your allergens detected")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text("These match allergens you've saved in your profile")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    LinearGradient(
                        colors: [Color.red, Color.orange.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
            }

            if commonIngredients.isEmpty {
                Text("Not enough observations yet to identify ingredient patterns")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(commonIngredients.prefix(10), id: \.name) { ingredient in
                    CommonIngredientRow(
                        name: ingredient.name,
                        frequency: ingredient.frequency,
                        percentage: ingredient.percentage,
                        isUserAllergen: isUserAllergenIngredient(ingredient.name)
                    )
                }
            }
        }
    }


    // MARK: - Calculate Common Ingredients
    private func calculateCommonIngredients() -> [(name: String, frequency: Int, percentage: Double)] {
        var ingredientCounts: [String: (count: Int, displayName: String)] = [:]

        // Count ingredients across all reactions (case-insensitive)
        for entry in manager.reactionLogs {
            guard let analysis = entry.triggerAnalysis else { continue }

            for ingredient in analysis.topIngredients {
                let normalizedName = ingredient.ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if ingredientCounts[normalizedName] == nil {
                    ingredientCounts[normalizedName] = (count: 1, displayName: ingredient.ingredientName)
                } else {
                    ingredientCounts[normalizedName]?.count += 1
                }
            }
        }

        // Filter to ingredients appearing in 2+ reactions and calculate percentages
        let totalReactions = manager.reactionLogs.count
        return ingredientCounts
            .filter { $0.value.count >= 2 }
            .map { (name: $0.value.displayName, frequency: $0.value.count, percentage: (Double($0.value.count) / Double(totalReactions)) * 100.0) }
            .sorted { $0.frequency > $1.frequency }
    }

    // MARK: - Calculate Common Foods (Flagged Foods)
    private func calculateCommonFoods() -> [(name: String, frequency: Int, percentage: Double)] {
        var foodCounts: [String: (count: Int, displayName: String)] = [:]

        // Count foods across all reactions (case-insensitive)
        for entry in manager.reactionLogs {
            guard let analysis = entry.triggerAnalysis else { continue }

            for food in analysis.topFoods {
                let normalizedName = food.foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

                if foodCounts[normalizedName] == nil {
                    foodCounts[normalizedName] = (count: 1, displayName: food.foodName)
                } else {
                    foodCounts[normalizedName]?.count += 1
                }
            }
        }

        // Filter to foods appearing in 2+ reactions and calculate percentages
        let totalReactions = manager.reactionLogs.count
        return foodCounts
            .filter { $0.value.count >= 2 }
            .map { (name: $0.value.displayName, frequency: $0.value.count, percentage: (Double($0.value.count) / Double(totalReactions)) * 100.0) }
            .sorted { $0.frequency > $1.frequency }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Common Ingredient Row
struct CommonIngredientRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let frequency: Int
    let percentage: Double
    var isUserAllergen: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // User allergen warning badge
            if isUserAllergen {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.4), radius: 3, x: 0, y: 2)
            } else {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isUserAllergen ? .red : .primary)

                    if isUserAllergen {
                        Text("YOUR ALLERGEN")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }

                Text("Appears in \(frequency) reaction\(frequency == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(frequencyColor)

                Text("frequency")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            isUserAllergen
                ? Color.red.opacity(0.1)
                : (colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isUserAllergen ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .cornerRadius(10)
        .shadow(color: isUserAllergen ? .red.opacity(0.2) : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var frequencyColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Common Food Row (Flagged Foods)
struct CommonFoodRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let name: String
    let frequency: Int
    let percentage: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 12))
                .foregroundColor(frequencyColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text("Before \(frequency) reaction\(frequency == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(frequencyColor)

                Text("correlation")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var frequencyColor: Color {
        if percentage >= 80 {
            return .red
        } else if percentage >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Log Card

struct ReactionLogCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: ReactionLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Reaction type icon
                Image(systemName: reactionIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.reactionType)
                        .font(.headline)

                    Text(entry.reactionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(" at ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(entry.reactionDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let analysis = entry.triggerAnalysis {
                HStack(spacing: 16) {
                    Label("\(analysis.mealCount) meals analyzed", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(analysis.topFoods.count) foods identified", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Log Reaction Sheet

struct LogReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ReactionLogManager.shared

    let selectedDayRange: ReactionLogView.DayRange

    @State private var selectedType: ReactionType = .headache
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var dayRange: ReactionLogView.DayRange
    @State private var foodLoggedInDiary: Bool? = nil  // nil = not selected, true = yes, false = no
    @State private var selectedFoodId: String? = nil
    @State private var manualFoodName: String = ""
    @State private var recentMeals: [FoodEntry] = []
    @State private var isLoadingMeals = false
    @State private var showMealSelection = false

    init(selectedDayRange: ReactionLogView.DayRange) {
        self.selectedDayRange = selectedDayRange
        self._dayRange = State(initialValue: selectedDayRange)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reaction Details")) {
                    // Reaction type picker
                    Picker("Reaction Type", selection: $selectedType) {
                        ForEach(ReactionType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    if selectedType == .custom {
                        TextField("Describe reaction", text: $customType)
                    }

                    DatePicker("Date & Time", selection: $reactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Food Connection (Optional)")) {
                    Text("Have you logged this food in your food diary?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    foodDiaryButtons

                    foodDiaryContent

                    Text("Linking a specific food is optional. The app will automatically analyze your entire food diary from the last \(dayRange.rawValue) days to identify potential patterns.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(header: Text("Analysis Window")) {
                    Picker("Look back", selection: $dayRange) {
                        ForEach(ReactionLogView.DayRange.allCases, id: \.self) { range in
                            Text(range.displayText).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text("The system will analyze your food diary from the last \(dayRange.rawValue) days to identify potential triggers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Log a Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveReaction()
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Analyzing potential triggers...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color.adaptiveCard)
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showMealSelection) {
            NavigationView {
                List {
                    Button(action: {
                        selectedFoodId = nil
                        showMealSelection = false
                    }) {
                        HStack {
                            Text("None")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFoodId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    ForEach(recentMeals) { meal in
                        Button(action: {
                            selectedFoodId = meal.id
                            showMealSelection = false
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(meal.foodName)
                                        .foregroundColor(.primary)
                                    Text(meal.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedFoodId == meal.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Meal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showMealSelection = false
                        }
                    }
                }
            }
        }
    }

    private func loadRecentMeals() {
        isLoadingMeals = true
        Task {
            let endDate = reactionDate
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate

            do {
                let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: endDate)
                await MainActor.run {
                    self.recentMeals = meals.sorted { $0.date > $1.date }
                    self.isLoadingMeals = false
                }
            } catch {
                await MainActor.run {
                    self.recentMeals = []
                    self.isLoadingMeals = false
                }
            }
        }
    }

    private var foodDiaryButtons: some View {
        HStack(spacing: 12) {
            // Yes button
            Button(action: {
                foodLoggedInDiary = true
                loadRecentMeals()
            }) {
                foodDiaryButtonContent(isSelected: foodLoggedInDiary == true, title: "Yes")
            }
            .buttonStyle(.plain)

            // No button
            Button(action: {
                foodLoggedInDiary = false
                selectedFoodId = nil
            }) {
                foodDiaryButtonContent(isSelected: foodLoggedInDiary == false, title: "No")
            }
            .buttonStyle(.plain)
        }
    }

    private func foodDiaryButtonContent(isSelected: Bool, title: String) -> some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
            Text(title)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var foodDiaryContent: some View {
        if foodLoggedInDiary == true {
            if isLoadingMeals {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(.trailing, 8)
                    Text("Loading recent meals...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else if recentMeals.isEmpty {
                Text("No recent meals found in your diary")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                Button(action: {
                    showMealSelection = true
                }) {
                    HStack {
                        if let selectedId = selectedFoodId,
                           let selectedMeal = recentMeals.first(where: { $0.id == selectedId }) {
                            Text(selectedMeal.foodName)
                                .foregroundColor(.primary)
                        } else {
                            Text("Choose from recent meals")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
            }
        } else if foodLoggedInDiary == false {
            TextField("Food name (optional)", text: $manualFoodName)
                .textInputAutocapitalization(.words)
        }
    }

    private var isValid: Bool {
        if selectedType == .custom {
            return !customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private func saveReaction() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let reactionType = selectedType == .custom ? customType : selectedType.rawValue
            let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await manager.saveReactionLog(
                reactionType: reactionType,
                reactionDate: reactionDate,
                notes: notesText.isEmpty ? nil : notesText,
                dayRange: dayRange.rawValue
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Reaction Detail View

struct ReactionLogDetailView: View {
    let entry: ReactionLogEntry
    let selectedDayRange: ReactionLogView.DayRange

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingExportSheet = false
    @State private var showOtherIngredients = false
    @State private var selectedFood: WeightedFoodScore?
    @State private var selectedIngredient: WeightedIngredientScore?
    @State private var selectedAllergenCategory: String?
    @State private var userAllergens: Set<Allergen> = []
    @State private var isLoadingAllergens = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    reactionHeader

                    if let analysis = entry.triggerAnalysis {
                        // Analysis Summary
                        analysisOverview(analysis: analysis)

                        // Top Trigger Foods
                        if !analysis.topFoods.isEmpty {
                            topFoodsSection(foods: analysis.topFoods)
                        }

                        // Top Trigger Ingredients
                        if !analysis.topIngredients.isEmpty {
                            topIngredientsSection(ingredients: analysis.topIngredients)
                        }
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingExportSheet) {
                PDFExportSheet(entry: entry)
            }
            .fullScreenCover(item: $selectedFood) { food in
                FoodHistoryDetailView(food: food, reactionDate: entry.reactionDate)
            }
            .fullScreenCover(item: $selectedIngredient) { ingredient in
                IngredientHistoryDetailView(ingredient: ingredient, reactionDate: entry.reactionDate)
            }
            .fullScreenCover(item: $selectedAllergenCategory) { category in
                AllergenCategoryDetailView(category: category, entry: entry)
            }
            .task {
                await loadUserAllergens()
            }
        }
    }

    // MARK: - Load User Allergens

    private func loadUserAllergens() async {
        do {
            let settings = try await FirebaseManager.shared.getUserSettings()
            await MainActor.run {
                userAllergens = Set(settings.allergens ?? [])
                isLoadingAllergens = false
            }
        } catch {
            await MainActor.run {
                isLoadingAllergens = false
            }
        }
    }

    /// Check if an allergen category matches user's saved allergens
    private func isUserAllergen(_ category: String) -> Bool {
        let categoryLower = category.lowercased()

        for allergen in userAllergens {
            switch allergen {
            case .dairy, .lactose:
                if categoryLower == "milk" || categoryLower == "dairy" || categoryLower == "lactose" {
                    return true
                }
            case .eggs:
                if categoryLower == "eggs" { return true }
            case .fish:
                if categoryLower == "fish" { return true }
            case .shellfish:
                if categoryLower == "shellfish" { return true }
            case .treeNuts:
                if categoryLower == "tree nuts" { return true }
            case .peanuts:
                if categoryLower == "peanuts" { return true }
            case .wheat, .gluten:
                if categoryLower == "gluten" || categoryLower == "wheat" { return true }
            case .soy:
                if categoryLower == "soya" || categoryLower == "soy" { return true }
            case .sesame:
                if categoryLower == "sesame" { return true }
            case .sulfites:
                if categoryLower == "sulphites" || categoryLower == "sulfites" { return true }
            case .msg:
                if categoryLower == "msg" { return true }
            case .corn:
                if categoryLower == "corn" { return true }
            }
        }
        return false
    }

    private var reactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reactionIcon)
                    .font(.title)
                    .foregroundColor(.orange)

                Text(entry.reactionType)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                Label(entry.reactionDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                Label(entry.reactionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func analysisOverview(analysis: TriggerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Summary")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(value: "\(analysis.mealCount)", label: "Meals Analyzed", icon: "fork.knife")
                StatBox(value: "\(analysis.totalFoodsAnalyzed)", label: "Foods Reviewed", icon: "list.bullet")
            }

            Text("\(analysis.dayRange)-Day Window")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text(" • ")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text("\(analysis.timeRangeStart.formatted(date: .abbreviated, time: .shortened)) to \(analysis.timeRangeEnd.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topFoodsSection(foods: [WeightedFoodScore]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Foods Appearing Alongside Reactions")
                .font(.headline)

            Text("These foods were consumed in the days before this reaction. Patterns may help you identify connections.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            ForEach(foods.prefix(10)) { food in
                Button(action: {
                    selectedFood = food
                }) {
                    FoodScoreRow(score: food)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topIngredientsSection(ingredients: [WeightedIngredientScore]) -> some View {
        let ingredientData = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens Section
            if !ingredientData.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recognised Allergens")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ingredientData.allergenGroups, id: \.category) { group in
                            ReactionAllergenGroup(
                                allergenCategory: group.category,
                                categoryScore: group.maxScore,
                                ingredients: group.ingredients,
                                isUserAllergen: isUserAllergen(group.category),
                                onIngredientTap: { ingredient in
                                    selectedIngredient = ingredient
                                },
                                onCategoryTap: {
                                    selectedAllergenCategory = group.category
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }

            // Other Ingredients Section (Expandable)
            if !ingredientData.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOtherIngredients.toggle()
                        }
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: showOtherIngredients ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 20)
                    }
                    .buttonStyle(.plain)

                    if showOtherIngredients {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredientData.otherIngredients) { ingredient in
                                Button(action: {
                                    selectedIngredient = ingredient
                                }) {
                                    IngredientScoreRow(score: ingredient)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [WeightedIngredientScore]) -> (allergenGroups: [(category: String, maxScore: Int, ingredients: [WeightedIngredientScore])], otherIngredients: [WeightedIngredientScore]) {
        var allergenDict: [String: [WeightedIngredientScore]] = [:]
        var otherIngredients: [WeightedIngredientScore] = []

        for ingredient in ingredients.prefix(10) {
            if let allergenCategory = getBaseAllergen(for: ingredient.ingredientName) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category, ingredients) -> (category: String, maxScore: Int, ingredients: [WeightedIngredientScore]) in
            // Use maximum cross-reaction frequency for the category
            let maxScore = ingredients.map { Int($0.crossReactionFrequency) }.max() ?? 0
            return (category, maxScore, ingredients.sorted { $0.crossReactionFrequency > $1.crossReactionFrequency })
        }.sorted { $0.maxScore > $1.maxScore }

        return (allergenGroups, otherIngredients.sorted { $0.totalScore > $1.totalScore })
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy (uses comprehensive cheese/dairy detection)
        if AllergenDetector.shared.containsDairyMilk(in: lower) {
            return "Milk"
        }

        // Eggs (comprehensive)
        let eggKeywords = ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin", "lysozyme",
                           "quiche", "frittata", "omelette", "omelet", "brioche", "challah", "hollandaise",
                           "béarnaise", "bearnaise", "aioli", "carbonara", "pavlova", "soufflé", "souffle",
                           "custard", "eggnog", "scotch egg"]
        if eggKeywords.contains(where: { lower.contains($0) }) {
            return "Eggs"
        }

        // Peanuts
        let peanutKeywords = ["peanut", "groundnut", "arachis", "peanut butter", "peanut oil", "satay", "monkey nuts"]
        if peanutKeywords.contains(where: { lower.contains($0) }) {
            return "Peanuts"
        }

        // Tree nuts (comprehensive)
        let treeNutKeywords = ["almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "filbert",
                               "brazil nut", "macadamia", "pine nut", "chestnut", "praline", "gianduja",
                               "marzipan", "frangipane", "nougat", "nutella", "nut butter", "almond flour",
                               "ground almonds", "flaked almonds", "walnut oil", "hazelnut oil"]
        if treeNutKeywords.contains(where: { lower.contains($0) }) {
            return "Tree Nuts"
        }

        // Gluten (comprehensive)
        let glutenKeywords = ["wheat", "gluten", "barley", "rye", "oats", "spelt", "kamut", "einkorn",
                              "triticale", "durum", "farro", "freekeh", "seitan", "malt", "brewer's yeast",
                              "semolina", "bulgur", "couscous", "flour", "bread", "pasta", "beer", "lager", "ale", "stout"]
        if glutenKeywords.contains(where: { lower.contains($0) }) {
            return "Gluten"
        }

        // Soya (comprehensive)
        let soyKeywords = ["soy", "soya", "soybean", "tofu", "tempeh", "miso", "shoyu", "tamari",
                           "edamame", "soy sauce", "soy milk", "soy protein", "soy lecithin", "natto", "tvp"]
        if soyKeywords.contains(where: { lower.contains($0) }) {
            return "Soya"
        }

        // Fish (comprehensive)
        let fishKeywords = ["fish", "fish sauce", "worcestershire", "fish finger", "fish cake", "fish pie",
                            "salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel",
                            "haddock", "plaice", "pollock", "hake", "monkfish", "halibut", "tilapia",
                            "bream", "sole", "herring", "kipper", "whitebait", "pilchard", "sprat",
                            "swordfish", "snapper", "grouper", "perch", "catfish", "carp", "pike", "eel"]
        if fishKeywords.contains(where: { lower.contains($0) }) {
            return "Fish"
        }

        // Shellfish (crustaceans and molluscs combined)
        let shellfishKeywords = ["shellfish", "shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish", "langoustine",
                                 "king prawn", "tiger prawn", "crab stick", "mollusc", "clam", "mussel", "oyster",
                                 "scallop", "cockle", "winkle", "whelk", "squid", "calamari", "octopus",
                                 "cuttlefish", "abalone", "snail", "escargot"]
        if shellfishKeywords.contains(where: { lower.contains($0) }) {
            return "Shellfish"
        }

        // Sesame (comprehensive)
        let sesameKeywords = ["sesame", "tahini", "sesame oil", "sesame seed", "hummus", "houmous",
                              "halvah", "halva", "za'atar", "zaatar", "gomashio", "benne seed"]
        if sesameKeywords.contains(where: { lower.contains($0) }) {
            return "Sesame"
        }

        // Celery
        let celeryKeywords = ["celery", "celeriac", "celery salt", "celery extract"]
        if celeryKeywords.contains(where: { lower.contains($0) }) {
            return "Celery"
        }

        // Mustard
        let mustardKeywords = ["mustard", "mustard seed", "dijon", "wholegrain mustard"]
        if mustardKeywords.contains(where: { lower.contains($0) }) {
            return "Mustard"
        }

        // Lupin
        let lupinKeywords = ["lupin", "lupine", "lupin flour"]
        if lupinKeywords.contains(where: { lower.contains($0) }) {
            return "Lupin"
        }

        // Sulphites (comprehensive)
        let sulphiteKeywords = ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide",
                                "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
                                "metabisulphite", "metabisulfite"]
        if sulphiteKeywords.contains(where: { lower.contains($0) }) {
            return "Sulphites"
        }

        return nil
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FoodScoreRow: View {
    let score: WeightedFoodScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.occurrencesWithin24h > 0 {
                        Text("\(score.occurrencesWithin24h)× <24h")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Last seen \(Int(score.lastSeenHoursBeforeReaction))h before reaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct IngredientScoreRow: View {
    let score: WeightedIngredientScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Frequency indicator (only show if we have cross-reaction data)
            if score.crossReactionFrequency > 0 {
                Circle()
                    .fill(frequencyColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(score.ingredientName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.symptomAssociationScore > 0 {
                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Found in: \(score.contributingFoodNames.prefix(3).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Only show cross-reaction percentage if there are 2+ reactions (crossReactionFrequency > 0)
            if score.crossReactionFrequency > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(score.crossReactionFrequency))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(frequencyColor)
                    Text("of reactions")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var frequencyColor: Color {
        let percentage = Int(score.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Allergen Group Component

struct ReactionAllergenGroup: View {
    let allergenCategory: String
    let categoryScore: Int
    let ingredients: [WeightedIngredientScore]
    var isUserAllergen: Bool = false
    let onIngredientTap: (WeightedIngredientScore) -> Void
    let onCategoryTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header with score badge - clickable
            Button(action: {
                onCategoryTap()
            }) {
                HStack(alignment: .center, spacing: 12) {
                    // User allergen warning badge
                    if isUserAllergen {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text("YOUR ALLERGEN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                        .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
                    }

                    Text(allergenCategory)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isUserAllergen ? .red : .primary)

                    Spacer()

                    // Frequency badge (only show if there's cross-reaction data)
                    if categoryScore > 0 {
                        VStack(spacing: 2) {
                            Text("\(categoryScore)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("of reactions")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.red.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.red.opacity(0.12))
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .shadow(color: Color.red.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 14)

            // Ingredient list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { ingredient in
                    Button(action: {
                        onIngredientTap(ingredient)
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.ingredientName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    Label("\(ingredient.occurrences)×", systemImage: "repeat")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    if ingredient.symptomAssociationScore > 0 {
                                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }

                                Text("Found in: \(ingredient.contributingFoodNames.prefix(3).joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(Int(ingredient.totalScore))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(for: ingredient.totalScore))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 28)
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 100 {
            return .red
        } else if score >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - PDF Export Sheet

struct PDFExportSheet: View {
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var selectedDayRange: Int = 7

    let dayRangeOptions = [3, 7, 14, 30]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .font(.headline)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            errorMessage = nil
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if pdfURL != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("PDF Ready")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your observation report has been generated and is ready to share with your nutritionist or healthcare provider.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Export Observation Report")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Create a detailed PDF report of your food patterns and reactions to share with your nutritionist or healthcare provider.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            // Date Range Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Time Period")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack(spacing: 12) {
                                    ForEach(dayRangeOptions, id: \.self) { days in
                                        Button(action: {
                                            selectedDayRange = days
                                        }) {
                                            VStack(spacing: 4) {
                                                Text("\(days)")
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                Text("days")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(selectedDayRange == days ? .white : .blue)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedDayRange == days ?
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.3, green: 0.5, blue: 1.0),
                                                            Color(red: 0.5, green: 0.3, blue: 0.9)
                                                        ],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                    : LinearGradient(
                                                        colors: [Color.blue.opacity(0.1)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                            )
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedDayRange == days ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                Text("Report will include all reactions and food patterns from the last \(selectedDayRange) days")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Report Includes")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Reaction details and timeline", systemImage: "info.circle")
                                    Label("Foods appearing alongside reactions", systemImage: "fork.knife")
                                    Label("Ingredient frequency patterns", systemImage: "chart.bar")
                                    Label("Common allergen observations", systemImage: "list.bullet")
                                    Label("Meal timing context", systemImage: "clock")
                                    Label("7-day meal history with ingredients", systemImage: "calendar.badge.clock")
                                }
                                .font(.callout)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            Text("This report is for informational purposes only and represents your personal food observations. Please share with a qualified healthcare provider or nutritionist for professional guidance.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                generatePDF()
                            }) {
                                Label("Generate PDF Report", systemImage: "doc.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)

                            Button("Cancel") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Calculate date range for meal history (7 days prior to reaction)
                let reactionDate = entry.reactionDate
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before

                // Fetch meals in the 7-day period
                var meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Fetch food reactions in the same 7-day period
                let allFoodReactions = try await FirebaseManager.shared.getReactions()
                let reactionDates = allFoodReactions.filter { reaction in
                    let date = reaction.timestamp.dateValue()
                    return date >= startDate && date <= reactionDate
                }

                // Convert FoodReactions to FoodEntry format
                let reactionEntries = reactionDates.compactMap { reaction -> FoodEntry? in
                    guard let userId = FirebaseManager.shared.currentUser?.uid else { return nil }
                    let date = reaction.timestamp.dateValue()

                    return FoodEntry(
                        id: reaction.id.uuidString,
                        userId: userId,
                        foodName: reaction.foodName,
                        brandName: reaction.foodBrand,
                        servingSize: 100,
                        servingUnit: "g",
                        calories: 0,
                        protein: 0,
                        carbohydrates: 0,
                        fat: 0,
                        ingredients: reaction.suspectedIngredients,
                        mealType: .snacks,
                        date: date,
                        dateLogged: date
                    )
                }

                // Merge reaction entries with diary meals, deduplicating by food name + same day
                for reactionEntry in reactionEntries {
                    let calendar = Calendar.current
                    let reactionDay = calendar.startOfDay(for: reactionEntry.date)

                    // Check if this food (by name) is already in diary for the same day
                    let alreadyExists = meals.contains { meal in
                        let mealDay = calendar.startOfDay(for: meal.date)
                        return mealDay == reactionDay && meal.foodName.lowercased() == reactionEntry.foodName.lowercased()
                    }

                    // Only add if not already in diary
                    if !alreadyExists {
                        meals.append(reactionEntry)
                    }
                }

                // Sort meals by date
                meals.sort { $0.date < $1.date }

                // Get all reactions for cross-reaction analysis
                let allReactions = ReactionLogManager.shared.reactionLogs

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportReactionReport(entry: entry, mealHistory: meals, allReactions: allReactions)
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch meal history: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - History Detail Views (Placeholders)

struct FoodHistoryDetailView: View {
    let food: WeightedFoodScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var foodEntry: FoodEntry?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(food.foodName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 16) {
                            Label("\(food.occurrences)× consumed", systemImage: "repeat")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Label("Last: \(Int(food.lastSeenHoursBeforeReaction))h before", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Cross-reaction frequency
                        if food.crossReactionFrequency > 0 {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(frequencyColor)
                                    .frame(width: 10, height: 10)

                                Text("Appears in \(Int(food.crossReactionFrequency))% of reactions")
                                    .font(.caption)
                                    .foregroundColor(frequencyColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Ingredients Section
                    if isLoading {
                        ProgressView("Loading ingredients...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if let ingredients = foodEntry?.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ingredients")
                                .font(.headline)

                            ingredientsBreakdownView(ingredients: ingredients)
                        }
                        .padding()
                        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 3)
                    } else {
                        Text("No ingredient information available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }

                    // Time Window Breakdown
                    timeWindowBreakdown
                }
                .padding()
            }
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadFoodEntry()
            }
        }
    }

    private var frequencyColor: Color {
        let percentage = Int(food.crossReactionFrequency)
        if percentage >= 80 {
            return .red
        } else if percentage >= 40 {
            return .orange
        } else {
            return .yellow
        }
    }

    private var timeWindowBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Window Breakdown")
                .font(.headline)

            VStack(spacing: 8) {
                TimeWindowRow(label: "Within 24 hours", count: food.occurrencesWithin24h, color: .red)
                TimeWindowRow(label: "24-48 hours before", count: food.occurrencesBetween24_48h, color: .orange)
                TimeWindowRow(label: "48-72 hours before", count: food.occurrencesBetween48_72h, color: .yellow)
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color.midnightCard : Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
    }

    private func ingredientsBreakdownView(ingredients: [String]) -> some View {
        let categorized = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens
            if !categorized.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognised Allergens")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)

                    ForEach(categorized.allergenGroups, id: \.category) { group in
                        AllergenCategoryCard(category: group.category, ingredients: group.ingredients)
                    }
                }
            }

            // Other Ingredients
            if !categorized.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Ingredients")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    ForEach(categorized.otherIngredients, id: \.self) { ingredient in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)

                            Text(ingredient)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [String]) -> (allergenGroups: [(category: String, ingredients: [String])], otherIngredients: [String]) {
        var allergenDict: [String: [String]] = [:]
        var otherIngredients: [String] = []

        for ingredient in ingredients {
            if let allergenCategory = getBaseAllergen(for: ingredient) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category: $0.key, ingredients: $0.value) }
            .sorted { $0.category < $1.category }

        return (allergenGroups, otherIngredients)
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }
        if lower.contains("mustard") {
            return "Mustard"
        }
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }

    private func loadFoodEntry() async {
        isLoading = true
        defer { isLoading = false }

        // Try to fetch the food entry from the reaction date
        // We'll fetch all meals around the reaction time to find this specific food
        let startTime = reactionDate.addingTimeInterval(-7 * 24 * 3600) // 7 days before
        let endTime = reactionDate

        do {
            let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startTime, to: endTime)

            // Find the food entry that matches our meal ID
            if let firstMealId = food.contributingMealIds.first {
                foodEntry = meals.first { $0.id == firstMealId }
            }
        } catch {
                    }
    }
}

// MARK: - Time Window Row
struct TimeWindowRow: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(count)×")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Allergen Category Card
struct AllergenCategoryCard: View {
    let category: String
    let ingredients: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)

            ForEach(ingredients, id: \.self) { ingredient in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 4, height: 4)

                    Text(ingredient)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

struct IngredientHistoryDetailView: View {
    let ingredient: WeightedIngredientScore
    let reactionDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("History for \(ingredient.ingredientName)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Occurrence history and pattern analysis will be displayed here, showing all times this ingredient appeared before reactions.")
                        .foregroundColor(.secondary)

                    Text("Score: \(Int(ingredient.totalScore))")
                    Text("Occurrences: \(ingredient.occurrences)")
                    Text("Found in foods: \(ingredient.contributingFoodNames.joined(separator: ", "))")

                    if ingredient.symptomAssociationScore > 0 {
                        Text("Pattern detected: This ingredient has appeared before \(ingredient.appearedInSameSymptomCount) similar reactions")
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Ingredient History")
            .navigationBarTitleDisplayMode(.inline)
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

struct AllergenCategoryDetailView: View {
    let category: String
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(category) History")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Complete history of all \(category.lowercased())-containing foods consumed before reactions will be displayed here.")
                        .foregroundColor(.secondary)

                    Text("This view will show:")
                        .font(.headline)
                        .padding(.top)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Timeline of \(category.lowercased()) consumption")
                        Text("• Specific ingredients within this category")
                        Text("• Cross-reaction patterns")
                        Text("• Severity trends over time")
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("\(category) Analysis")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Recent Meals List View

struct RecentMealsListView: View {
    @State private var mealsByDay: [(date: Date, meals: [FoodEntry])] = []
    @State private var isLoading = true
    @State private var allIngredients: [String] = []
    @State private var allergens: [String: [String]] = [:]
    @State private var otherIngredients: [String] = []
    @State private var mealFrequencies: [(name: String, count: Int)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                ProgressView("Loading recent meals...")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else if mealsByDay.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No meals logged recently")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // Meals by Day
                    ForEach(mealsByDay, id: \.date) { dayData in
                        DayMealsSection(date: dayData.date, meals: dayData.meals)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Pattern Frequencies
                    if !mealFrequencies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Meal Pattern Frequencies")
                                .font(.headline)
                                .foregroundColor(.primary)

                            ForEach(mealFrequencies.prefix(10), id: \.name) { item in
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)

                                    Text(item.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("\(item.count)×")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Recognised Allergens
                    if !allergens.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recognised Allergens")
                                .font(.headline)
                                .foregroundColor(.red)

                            ForEach(allergens.sorted(by: { $0.key < $1.key }), id: \.key) { category, ingredients in
                                AllergenCategoryCard(category: category, ingredients: ingredients)
                            }
                        }
                        .padding(.bottom, 8)
                    }

                    // Other Ingredients
                    if !otherIngredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            ForEach(otherIngredients.prefix(20), id: \.self) { ingredient in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.3))
                                        .frame(width: 4, height: 4)

                                    Text(ingredient)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadRecentMeals()
        }
    }

    private func loadRecentMeals() async {
        isLoading = true
        defer { isLoading = false }

        // Fetch meals from the last 7 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!

        do {
            let meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: endDate)

            // Group by day (reverse chronological)
            let calendar = Calendar.current
            var grouped: [Date: [FoodEntry]] = [:]

            for meal in meals {
                let dayStart = calendar.startOfDay(for: meal.date)
                grouped[dayStart, default: []].append(meal)
            }

            // Sort by date (most recent first)
            mealsByDay = grouped.map { (date: $0.key, meals: $0.value) }
                .sorted { $0.date > $1.date }

            // Calculate meal frequencies
            var foodCounts: [String: Int] = [:]
            for meal in meals {
                let normalizedName = meal.foodName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                foodCounts[normalizedName, default: 0] += 1
            }
            mealFrequencies = foodCounts
                .map { (name: $0.key.capitalized, count: $0.value) }
                .sorted { $0.count > $1.count }

            // Extract all ingredients
            var allIngredientsList: [String] = []
            for meal in meals {
                if let ingredients = meal.ingredients {
                    allIngredientsList.append(contentsOf: ingredients)
                }
            }

            // Categorize ingredients
            categorizeIngredients(allIngredientsList)

        } catch {
                    }
    }

    private func categorizeIngredients(_ ingredients: [String]) {
        var allergenDict: [String: Set<String>] = [:]
        var otherSet: Set<String> = []

        for ingredient in ingredients {
            if let allergenCategory = getBaseAllergen(for: ingredient) {
                allergenDict[allergenCategory, default: []].insert(ingredient)
            } else {
                otherSet.insert(ingredient)
            }
        }

        allergens = allergenDict.mapValues { Array($0).sorted() }
        otherIngredients = Array(otherSet).sorted()
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }
        if lower.contains("mustard") {
            return "Mustard"
        }
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }
}

// MARK: - Day Meals Section

struct DayMealsSection: View {
    let date: Date
    let meals: [FoodEntry]

    private var dayName: String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.fullDayOfWeekFormatter.string(from: date)
    }

    private var dateText: String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.mediumDateFormatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day header
            VStack(alignment: .leading, spacing: 4) {
                Text(dayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Text(dateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Meals for this day
            VStack(alignment: .leading, spacing: 8) {
                ForEach(meals) { meal in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(mealTypeColor(meal.mealType))
                            .frame(width: 8, height: 8)

                        Text(meal.foodName)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(mealTypeLabel(meal.mealType))
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(mealTypeColor(meal.mealType).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(12)
        .background(Color.adaptiveCard)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }

    private func mealTypeColor(_ mealType: MealType) -> Color {
        switch mealType {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snacks: return .green
        }
    }

    private func mealTypeLabel(_ mealType: MealType) -> String {
        switch mealType {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snack"
        }
    }
}

// MARK: - Multi-Reaction PDF Export Sheet

struct MultiReactionPDFExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ReactionLogManager.shared
    @State private var isGenerating = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isGenerating {
                    ProgressView("Generating PDF...")
                        .font(.headline)
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)

                        Text("Export Failed")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            errorMessage = nil
                            generatePDF()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if pdfURL != nil {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("PDF Ready")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your comprehensive reaction report is ready to share.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Report", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()

                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Export Comprehensive Report")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Generate a PDF report of your last \(min(manager.reactionLogs.count, 5)) reactions with complete pattern analysis.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Report Includes")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Most recent reaction details", systemImage: "info.circle")
                                    Label("7-day meal history", systemImage: "calendar.badge.clock")
                                    Label("Previous reactions timeline", systemImage: "list.bullet")
                                    Label("Pattern analysis for allergens", systemImage: "chart.bar")
                                    Label("Other ingredient patterns", systemImage: "list.bullet")
                                }
                                .font(.callout)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            Text("This report is for informational purposes only. Please share with a qualified healthcare provider or nutritionist for professional guidance.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Button(action: {
                                generatePDF()
                            }) {
                                Label("Generate PDF Report", systemImage: "doc.badge.plus")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)

                            Button("Cancel") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                    }
                }
            }
            .padding()
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .onDisappear {
            // Clean up temporary file when sheet is dismissed
            if let url = pdfURL {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func generatePDF() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Get last 5 reactions (or fewer if less than 5 exist)
                let reactions = Array(manager.reactionLogs.prefix(5))

                guard !reactions.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No reactions found to export."
                        self.isGenerating = false
                    }
                    return
                }

                // Get the most recent reaction for meal history
                let mostRecentReaction = reactions[0]
                let reactionDate = mostRecentReaction.reactionDate
                let startDate = reactionDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days before

                // Fetch meals in the 7-day period
                var meals = try await DiaryDataManager.shared.getMealsInTimeRange(from: startDate, to: reactionDate)

                // Fetch food reactions in the same 7-day period and merge
                let allFoodReactions = try await FirebaseManager.shared.getReactions()
                let reactionDates = allFoodReactions.filter { reaction in
                    let date = reaction.timestamp.dateValue()
                    return date >= startDate && date <= reactionDate
                }

                // Convert FoodReactions to FoodEntry format
                let reactionEntries = reactionDates.compactMap { reaction -> FoodEntry? in
                    guard let userId = FirebaseManager.shared.currentUser?.uid else { return nil }
                    let date = reaction.timestamp.dateValue()

                    return FoodEntry(
                        id: reaction.id.uuidString,
                        userId: userId,
                        foodName: reaction.foodName,
                        brandName: reaction.foodBrand,
                        servingSize: 100,
                        servingUnit: "g",
                        calories: 0,
                        protein: 0,
                        carbohydrates: 0,
                        fat: 0,
                        ingredients: reaction.suspectedIngredients,
                        mealType: .snacks,
                        date: date,
                        dateLogged: date
                    )
                }

                // Merge reaction entries with diary meals (deduplicate)
                for reactionEntry in reactionEntries {
                    let calendar = Calendar.current
                    let reactionDay = calendar.startOfDay(for: reactionEntry.date)

                    let alreadyExists = meals.contains { meal in
                        let mealDay = calendar.startOfDay(for: meal.date)
                        return mealDay == reactionDay && meal.foodName.lowercased() == reactionEntry.foodName.lowercased()
                    }

                    if !alreadyExists {
                        meals.append(reactionEntry)
                    }
                }

                // Sort meals by date
                meals.sort { $0.date < $1.date }

                // Get all reactions for pattern analysis
                let allReactions = manager.reactionLogs

                // Generate PDF on background thread
                let url = await Task.detached(priority: .userInitiated) {
                    return ReactionPDFExporter.exportMultipleReactionsReport(
                        reactions: reactions,
                        mealHistory: meals,
                        allReactions: allReactions
                    )
                }.value

                if let url = url {
                    await MainActor.run {
                        self.pdfURL = url
                        self.isGenerating = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Failed to generate PDF. Please try again."
                        self.isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch data: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - String Identifiable Extension
// Note: Required for .sheet(item:) modifier with String? types (line 767)
// @retroactive suppresses warning about conforming String to Identifiable
extension String: @retroactive Identifiable {
    public var id: String { self }
}
