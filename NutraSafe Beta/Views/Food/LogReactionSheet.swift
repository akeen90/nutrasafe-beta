//
//  LogReactionSheet.swift
//  NutraSafe Beta
//
//  Extracted from ReactionLogView.swift
//  Active reaction logging interface used in Add menu
//

import SwiftUI
import FirebaseFirestore
import UIKit

// MARK: - Day Range Selection
extension LogReactionSheet {
    enum DayRange: Int, CaseIterable {
        case threeDays = 3
        case fiveDays = 5
        case sevenDays = 7

        var displayText: String {
            "\(rawValue) days"
        }
    }
}
struct LogReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var manager = ReactionLogManager.shared

    let selectedDayRange: LogReactionSheet.DayRange

    // Core state - supports multiple symptom selection
    @State private var selectedTypes: Set<ReactionType> = []
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var selectedSeverity: ReactionSeverity = .moderate
    @State private var notes: String = ""
    @State private var dayRange: LogReactionSheet.DayRange

    // Food source state - 4 options as requested
    @State private var foodSource: FoodSource = .diary
    @State private var recentMeals: [FoodEntry] = []
    @State private var isLoadingMeals = false
    @State private var showMealSelection = false
    @State private var showDatabaseSearch = false

    // Multiple foods support - stores all selected foods
    @State private var selectedFoods: [SelectedFood] = []

    // Temporary state for adding a new food (cleared after adding)
    @State private var tempSelectedFoodId: String? = nil
    @State private var tempManualFoodName: String = ""
    @State private var tempSelectedSearchFood: FoodSearchResult? = nil

    // Inline database search state
    @State private var databaseSearchText: String = ""
    @State private var databaseSearchResults: [FoodSearchResult] = []
    @State private var isDatabaseSearching = false
    @State private var databaseSearchTask: Task<Void, Never>?
    @FocusState private var isDatabaseSearchFocused: Bool
    @StateObject private var searchDebouncer = Debouncer(milliseconds: 300)

    // Barcode scanning state
    @State private var showingBarcodeScanner = false
    @State private var isBarcodeSearching = false

    // Editable ingredients list
    @State private var editableIngredients: [String] = []
    @State private var newIngredientText: String = ""

    // AI Ingredient Estimation state
    @State private var showingInferredIngredientsSheet = false
    @State private var inferredIngredients: [InferredIngredient] = []

    // UI state
    @State private var isSaving: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    // Food source options: Diary, Database Search, AI Estimate, Manual
    enum FoodSource: String, CaseIterable {
        case diary = "Diary"
        case database = "Search"
        case ai = "AI"
        case manual = "Manual"

        var icon: String {
            switch self {
            case .diary: return "book.fill"
            case .database: return "magnifyingglass"
            case .ai: return "sparkles"
            case .manual: return "pencil"
            }
        }
    }

    // Represents a food item selected for the reaction
    struct SelectedFood: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let source: FoodSource
        var ingredients: [String]
        let diaryEntryId: String? // For diary entries
        let searchResult: FoodSearchResult? // For database searches

        static func == (lhs: SelectedFood, rhs: SelectedFood) -> Bool {
            lhs.id == rhs.id
        }
    }

    init(selectedDayRange: LogReactionSheet.DayRange) {
        self.selectedDayRange = selectedDayRange
        self._dayRange = State(initialValue: selectedDayRange)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Reaction Type Section
                    reactionTypeSection

                    // Severity Section
                    severitySection

                    // Date & Time Section
                    dateTimeSection

                    // Food Connection Section
                    foodConnectionSection

                    // Notes Section
                    notesSection

                    // Save Button
                    saveButton
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppAnimatedBackground())
            .navigationTitle("Log Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    savingOverlay
                } else if showSuccess {
                    successOverlay
                }
            }
        }
        .fullScreenCover(isPresented: $showMealSelection) {
            mealSelectionSheet
        }
        .sheet(isPresented: $showingInferredIngredientsSheet) {
            InferredIngredientsSheet(
                foodName: tempManualFoodName.isEmpty ? "Food" : tempManualFoodName,
                inferredIngredients: $inferredIngredients
            )
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            ReactionBarcodeScannerSheet(
                onFoodFound: { food in
                    showingBarcodeScanner = false
                    selectDatabaseFood(food)
                },
                onCancel: {
                    showingBarcodeScanner = false
                }
            )
        }
        .onAppear {
            loadRecentMeals()
        }
        .onChange(of: inferredIngredients) { _, _ in
            // When AI inference completes, populate editable ingredients
            populateIngredientsFromAI()
        }
        .onDisappear {
            // Cancel any pending search tasks when the sheet is dismissed
            databaseSearchTask?.cancel()
        }
    }

    // MARK: - Reaction Type Section

    private var reactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "What happened?", icon: "exclamationmark.triangle.fill", color: .orange)
                Spacer()
                if !selectedTypes.isEmpty {
                    Text("\(selectedTypes.count) selected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            Text("Select all that apply")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            // Reaction type grid (2 columns)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ReactionType.allCases.filter { $0 != .custom }, id: \.self) { type in
                    reactionTypeButton(type)
                }
            }

            // Custom/Other option
            reactionTypeButton(.custom)
                .frame(maxWidth: .infinity)

            if selectedTypes.contains(.custom) {
                TextField("Describe your reaction...", text: $customType)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    private func reactionTypeButton(_ type: ReactionType) -> some View {
        let isSelected = selectedTypes.contains(type)
        return Button(action: {
            // Toggle selection
            if isSelected {
                selectedTypes.remove(type)
            } else {
                selectedTypes.insert(type)
            }
        }) {
            HStack(spacing: 8) {
                // Checkmark for selected items
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                } else {
                    Image(systemName: type.icon)
                        .font(.system(size: 16))
                }
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                isSelected ?
                LinearGradient(colors: [.orange, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Severity Section

    private var severitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "How severe?", icon: "speedometer", color: .red)

            HStack(spacing: 10) {
                ForEach(ReactionSeverity.allCases, id: \.self) { severity in
                    Button(action: { selectedSeverity = severity }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(severityColor(severity).opacity(selectedSeverity == severity ? 0.2 : 0.1))
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(severityColor(severity))
                                    .frame(width: selectedSeverity == severity ? 20 : 12, height: selectedSeverity == severity ? 20 : 12)
                            }
                            Text(severityLabel(severity))
                                .font(.system(size: 13, weight: selectedSeverity == severity ? .bold : .medium))
                                .foregroundColor(selectedSeverity == severity ? severityColor(severity) : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedSeverity == severity ? severityColor(severity).opacity(0.1) : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedSeverity == severity ? severityColor(severity).opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    private func severityColor(_ severity: ReactionSeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func severityLabel(_ severity: ReactionSeverity) -> String {
        switch severity {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    // MARK: - Date & Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "When did it happen?", icon: "clock.fill", color: .blue)

            DatePicker("", selection: $reactionDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Food Connection Section

    private var foodConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionHeader(title: "Suspected foods", icon: "fork.knife", color: .green)
                Spacer()
                if selectedFoods.isEmpty {
                    Text("Required")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("\(selectedFoods.count) added")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Food source picker - 4 compact buttons
            HStack(spacing: 6) {
                ForEach(FoodSource.allCases, id: \.self) { source in
                    Button(action: {
                        foodSource = source
                        // Reset temporary state when switching modes
                        tempSelectedFoodId = nil
                        tempManualFoodName = ""
                        editableIngredients = []
                        inferredIngredients = []
                        databaseSearchText = ""
                        databaseSearchResults = []
                        if source == .diary {
                            loadRecentMeals()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: source.icon)
                                .font(.system(size: 16))
                            Text(source.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(foodSource == source ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            foodSource == source ?
                            AppPalette.standard.accent : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Selected foods list
            if !selectedFoods.isEmpty {
                selectedFoodsSection
            }

            // Food selection content based on mode
            foodSelectionContent

            // Info text
            Text("Add all foods you think might be related to this reaction.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Selected Foods Section
    private var selectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Added foods:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(selectedFoods) { food in
                    selectedFoodCard(food)
                }
            }
        }
    }

    private func selectedFoodCard(_ food: SelectedFood) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Food name header with remove button
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: food.source.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text(food.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFoods.removeAll { $0.id == food.id }
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }

            // Ingredients list
            if !food.ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ingredients:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 4) {
                        ForEach(food.ingredients.prefix(10), id: \.self) { ingredient in
                            Text(ingredient)
                                .font(.system(size: 11))
                                .foregroundColor(.primary.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                                .cornerRadius(4)
                        }
                        if food.ingredients.count > 10 {
                            Text("+\(food.ingredients.count - 10) more")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                        }
                    }
                }
            } else {
                Text("No ingredients listed")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .italic()
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var foodSelectionContent: some View {
        switch foodSource {
        case .diary:
            // Diary meal selection
            diaryFoodContent

        case .database:
            // Search database for foods
            databaseSearchContent

        case .ai:
            // AI estimate ingredients
            aiEstimateContent

        case .manual:
            // Manual entry with ingredients
            manualEntryContent
        }
    }

    // MARK: - Diary Food Content
    @ViewBuilder
    private var diaryFoodContent: some View {
        if isLoadingMeals {
            HStack(spacing: 10) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading recent meals...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(12)
        } else if recentMeals.isEmpty {
            Text("No meals found in your diary")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        } else {
            VStack(spacing: 12) {
                Button(action: { showMealSelection = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppPalette.standard.accent)
                        Text("Add from recent meals")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppPalette.standard.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(14)
                    .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Database Search Content
    private var databaseSearchContent: some View {
        VStack(spacing: 12) {
            // Inline search field
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search foods...", text: $databaseSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($isDatabaseSearchFocused)
                        .onChange(of: databaseSearchText) { _, newValue in
                            // Debounce search to avoid excessive API calls
                            searchDebouncer.debounce {
                                await performDatabaseSearch(query: newValue)
                            }
                        }

                    if !databaseSearchText.isEmpty {
                        Button(action: {
                            databaseSearchText = ""
                            databaseSearchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
                .contentShape(Rectangle())
                .onTapGesture {
                    isDatabaseSearchFocused = true
                }

                // Barcode scan button
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppPalette.standard.accent)
                        .frame(width: 48, height: 48)
                        .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        .cornerRadius(12)
                }
            }

            // Search results dropdown
            if isDatabaseSearching {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if !databaseSearchResults.isEmpty {
                VStack(spacing: 8) {
                    ForEach(databaseSearchResults.prefix(5), id: \.id) { food in
                        Button(action: {
                            selectDatabaseFood(food)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    if let brand = food.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    if let ingredients = food.ingredients, !ingredients.isEmpty {
                                        let displayText = ingredients.prefix(3).joined(separator: ", ")
                                        Text(displayText + (ingredients.count > 3 ? "..." : ""))
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppPalette.standard.accent)
                            }
                            .padding(12)
                            .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }

                    if databaseSearchResults.count > 5 {
                        Text("\(databaseSearchResults.count - 5) more results...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                }
            } else if !databaseSearchText.isEmpty && databaseSearchText.count >= 2 {
                // No results message
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No foods found")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Try different keywords")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

        }
    }

    // MARK: - Database Search Helpers

    private func performDatabaseSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 2 else {
            await MainActor.run {
                databaseSearchResults = []
                isDatabaseSearching = false
            }
            return
        }

        await MainActor.run {
            isDatabaseSearching = true
        }

        do {
            let results = try await FirebaseManager.shared.searchFoods(query: trimmed)
            await MainActor.run {
                databaseSearchResults = results
                isDatabaseSearching = false
            }
        } catch {
            await MainActor.run {
                databaseSearchResults = []
                isDatabaseSearching = false
            }
            print("Database search error: \(error)")
        }
    }

    private func selectDatabaseFood(_ food: FoodSearchResult) {
        // Parse ingredients from the selected food
        var ingredients: [String] = []
        if let foodIngredients = food.ingredients, !foodIngredients.isEmpty {
            // Check if ingredients came as a single comma-separated string
            if foodIngredients.count == 1, let first = foodIngredients.first, first.contains(",") {
                ingredients = first.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else {
                ingredients = foodIngredients
            }
        }

        // Add to selected foods list
        let newFood = SelectedFood(
            name: food.name,
            source: .database,
            ingredients: ingredients,
            diaryEntryId: nil,
            searchResult: food
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
        }

        // Clear search state
        databaseSearchText = ""
        databaseSearchResults = []
        isDatabaseSearchFocused = false
    }

    // MARK: - AI Estimate Content
    private var aiEstimateContent: some View {
        VStack(spacing: 12) {
            TextField("Food name (e.g., chippy sausage, doner kebab)", text: $tempManualFoodName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)

            if !tempManualFoodName.isEmpty {
                Button(action: { showingInferredIngredientsSheet = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("Estimate Ingredients with AI")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                        if !inferredIngredients.isEmpty {
                            Text("\(inferredIngredients.count) found")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Show inferred ingredients as editable chips after AI estimation
                if !inferredIngredients.isEmpty {
                    ingredientsEditorSection

                    // Add food button
                    addFoodButton(source: .ai)
                } else {
                    Text("AI estimates likely ingredients for generic foods like takeaways")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Manual Entry Content
    private var manualEntryContent: some View {
        VStack(spacing: 12) {
            TextField("Food name", text: $tempManualFoodName)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .padding(14)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)

            // Always show ingredients editor for manual entry
            if !tempManualFoodName.isEmpty {
                ingredientsEditorSection

                // Add food button
                addFoodButton(source: .manual)
            }
        }
    }

    // MARK: - Add Food Button
    private func addFoodButton(source: FoodSource) -> some View {
        Button(action: {
            addCurrentFoodToList(source: source)
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Add to suspected foods")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(tempManualFoodName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private func addCurrentFoodToList(source: FoodSource) {
        let name = tempManualFoodName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let ingredients = source == .ai ? inferredIngredients.map { $0.name } : editableIngredients

        let newFood = SelectedFood(
            name: name,
            source: source,
            ingredients: ingredients,
            diaryEntryId: nil,
            searchResult: nil
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
        }

        // Clear temporary state
        tempManualFoodName = ""
        editableIngredients = []
        inferredIngredients = []
    }

    // MARK: - Ingredients Editor Section

    private var ingredientsEditorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                Text("Ingredients")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(editableIngredients.count)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Display existing ingredients as chips
            if !editableIngredients.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(editableIngredients, id: \.self) { ingredient in
                        ingredientChip(ingredient)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Add new ingredient field
            HStack(spacing: 8) {
                TextField("Add ingredient...", text: $newIngredientText)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5).opacity(0.5))
                    .cornerRadius(8)
                    .onSubmit {
                        addNewIngredient()
                    }

                Button(action: addNewIngredient) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
                .disabled(newIngredientText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
        .background(colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }

    private func ingredientChip(_ ingredient: String) -> some View {
        HStack(spacing: 4) {
            Text(ingredient)
                .font(.system(size: 13))
                .foregroundColor(.primary)
            Button(action: {
                withAnimation {
                    editableIngredients.removeAll { $0 == ingredient }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
        .cornerRadius(16)
    }

    private func addNewIngredient() {
        let trimmed = newIngredientText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if !editableIngredients.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            withAnimation {
                editableIngredients.append(trimmed)
            }
        }
        newIngredientText = ""
    }

    // MARK: - Analysis Window Section

    private var analysisWindowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Analysis period", icon: "calendar", color: .purple)

            Picker("", selection: $dayRange) {
                ForEach(LogReactionSheet.DayRange.allCases, id: \.self) { range in
                    Text(range.displayText).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Notes (optional)", icon: "note.text", color: .gray)

            TextEditor(text: $notes)
                .frame(height: 80)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        VStack(spacing: 8) {
            // Show validation hints if not valid
            if !isValid && !isSaving {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text(validationHint)
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Button(action: {
                Task { await saveReaction() }
            }) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                    }
                    Text(isSaving ? "Saving..." : "Log Reaction")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isValid {
                            // Use user-adaptive gradient matching onboarding aesthetic
                            let userIntent = UserIntent(rawValue: UserDefaults.standard.string(forKey: "userIntent") ?? "safer") ?? .safer
                            let palette = OnboardingPalette.forIntent(userIntent)
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            LinearGradient(
                                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(14)
                .shadow(color: isValid ? Color.black.opacity(0.15) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(isSaving || !isValid)
        }
        .padding(.top, 8)
    }

    private var validationHint: String {
        if selectedTypes.isEmpty {
            return "Select at least one reaction type"
        }
        if selectedTypes.contains(.custom) && selectedTypes.count == 1 && customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Describe your custom reaction"
        }
        if selectedFoods.isEmpty {
            return "Add at least one suspected food"
        }
        return ""
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    private var cardBackground: some View {
        colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Saving reaction...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text("Analyzing your food history")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background(Color(.systemGray6).opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }

                Text("Reaction Logged")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("\(selectedFoods.count) food\(selectedFoods.count == 1 ? "" : "s") recorded")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity)
    }

    private var mealSelectionSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header showing count of added foods
                if !selectedFoods.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(selectedFoods.count) food\(selectedFoods.count == 1 ? "" : "s") added")
                            .font(.system(size: 14, weight: .medium))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.1))
                }

                List {
                    Section(header: Text("Tap to add meals from the past 7 days")) {
                        if recentMeals.isEmpty {
                            Text("No meals found in your diary")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentMeals) { meal in
                                mealSelectionRow(meal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showMealSelection = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func mealSelectionRow(_ meal: FoodEntry) -> some View {
        let isAlreadyAdded = selectedFoods.contains { $0.diaryEntryId == meal.id }

        // Get ingredients preview
        let ingredientsPreview: String = {
            if let ingredients = meal.ingredients, !ingredients.isEmpty {
                if ingredients.count == 1, let first = ingredients.first, first.contains(",") {
                    let parsed = first.components(separatedBy: ",").prefix(3).map { $0.trimmingCharacters(in: .whitespaces) }
                    return parsed.joined(separator: ", ")
                } else {
                    return ingredients.prefix(3).joined(separator: ", ")
                }
            } else if let inferred = meal.inferredIngredients, !inferred.isEmpty {
                return inferred.prefix(3).map { $0.name }.joined(separator: ", ")
            }
            return ""
        }()

        return Button(action: {
            if !isAlreadyAdded {
                addDiaryMealToList(meal)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.foodName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isAlreadyAdded ? .secondary : .primary)

                    HStack(spacing: 4) {
                        Text(meal.date, style: .date)
                        Text("•")
                        Text(meal.date, style: .time)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                    if !ingredientsPreview.isEmpty {
                        Text(ingredientsPreview + "...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isAlreadyAdded {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Added")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppPalette.standard.accent)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)
        .opacity(isAlreadyAdded ? 0.6 : 1.0)
    }

    private func addDiaryMealToList(_ meal: FoodEntry) {
        // Get ingredients from the meal
        var ingredients: [String] = []
        if let mealIngredients = meal.ingredients, !mealIngredients.isEmpty {
            if mealIngredients.count == 1, let first = mealIngredients.first, first.contains(",") {
                ingredients = first.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else {
                ingredients = mealIngredients
            }
        } else if let inferred = meal.inferredIngredients, !inferred.isEmpty {
            ingredients = inferred.map { $0.name }
        }

        let newFood = SelectedFood(
            name: meal.foodName,
            source: .diary,
            ingredients: ingredients,
            diaryEntryId: meal.id,
            searchResult: nil
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            selectedFoods.append(newFood)
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

    private var isValid: Bool {
        // Must have at least one symptom selected
        guard !selectedTypes.isEmpty else { return false }

        // Must have at least one food selected
        guard !selectedFoods.isEmpty else { return false }

        // If "Other" is selected, must have custom text
        if selectedTypes.contains(.custom) {
            // If ONLY custom is selected, require custom text
            if selectedTypes.count == 1 {
                return !customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            // If custom is selected along with others, custom text is optional
        }
        return true
    }

    private func saveReaction() async {
        isSaving = true

        print("🔵 [LogReactionSheet] saveReaction started")
        print("🔵 [LogReactionSheet] Manager reactionLogs count BEFORE: \(manager.reactionLogs.count)")
        print("🔵 [LogReactionSheet] Selected foods count: \(selectedFoods.count)")

        do {
            // Build array of selected symptom types
            var symptomStrings: [String] = selectedTypes.filter { $0 != .custom }.map { $0.rawValue }
            if selectedTypes.contains(.custom) && !customType.isEmpty {
                symptomStrings.append(customType)
            }

            // Use first symptom as primary reaction type for backward compatibility
            let reactionType = symptomStrings.first ?? "Unknown"
            let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            print("🔵 [LogReactionSheet] Reaction type: \(reactionType)")
            print("🔵 [LogReactionSheet] Reaction date: \(reactionDate)")

            // Combine all food names
            let foodNames = selectedFoods.map { $0.name }
            let combinedFoodName = foodNames.joined(separator: ", ")

            // Combine all ingredients from selected foods
            let allIngredients = selectedFoods.flatMap { $0.ingredients }
            let uniqueIngredients = Array(Set(allIngredients))

            print("🔵 [LogReactionSheet] Foods: \(combinedFoodName)")
            print("🔵 [LogReactionSheet] Ingredients count: \(uniqueIngredients.count)")

            print("🔵 [LogReactionSheet] Calling manager.saveReactionLog...")
            let savedEntry = try await manager.saveReactionLog(
                reactionType: reactionType,
                reactionDate: reactionDate,
                notes: notesText.isEmpty ? nil : notesText,
                dayRange: dayRange.rawValue
            )

            print("✅ [LogReactionSheet] Save successful! Entry ID: \(savedEntry.id ?? "no-id")")
            print("✅ [LogReactionSheet] Manager reactionLogs count AFTER: \(manager.reactionLogs.count)")

            // Also update the FoodReactionsView's ReactionManager so Health tab shows the reaction
            // Create a FoodReaction from the saved entry data with ALL selected symptoms
            let foodReaction = FoodReaction(
                foodName: combinedFoodName,
                foodId: nil,
                foodBrand: nil,
                timestamp: FirebaseFirestore.Timestamp(date: reactionDate),
                severity: selectedSeverity,
                symptoms: symptomStrings,
                suspectedIngredients: uniqueIngredients,
                notes: notesText.isEmpty ? nil : notesText
            )
            await ReactionManager.shared.addReaction(foodReaction)
            print("✅ [LogReactionSheet] Also added to ReactionManager for Health tab with \(symptomStrings.count) symptoms")

            // Show success state before dismissing
            await MainActor.run {
                isSaving = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }
            }

            // Wait a moment so user sees the success confirmation
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds

            // Dismiss
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ [LogReactionSheet] Save FAILED: \(error.localizedDescription)")
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // Populate editable ingredients from AI inference
    private func populateIngredientsFromAI() {
        guard !inferredIngredients.isEmpty else { return }
        editableIngredients = inferredIngredients.map { $0.name }
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
                                        .fill(AppPalette.standard.accent)
                                        .frame(width: 8, height: 8)

                                    Text(item.name)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    Text("\(item.count)×")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppPalette.standard.accent)
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
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate

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
           lower.contains("kamut") || lower.contains(" bread ") || lower.contains("breaded") || lower.contains("breadcrumb") {
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

// MARK: - Barcode Scanner Sheet
struct ReactionBarcodeScannerSheet: View {
    let onFoodFound: (FoodSearchResult) -> Void
    let onCancel: () -> Void

    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // Camera scanner
                BarcodeScannerViewControllerRepresentable { barcode in
                    handleBarcodeScanned(barcode)
                }
                .edgesIgnoringSafeArea(.all)

                // Overlay UI
                VStack {
                    Spacer()

                    // Bottom instruction text
                    if !isSearching {
                        VStack(spacing: 8) {
                            Text("Position barcode within frame")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Text("Scan a product to link with your reaction")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.black.opacity(0.7))
                    }
                }

                // Searching overlay
                if isSearching {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Looking up product...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(16)
                }
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
            .alert("Product Not Found", isPresented: $showError) {
                Button("Try Again") {
                    errorMessage = nil
                }
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
            } message: {
                Text(errorMessage ?? "This product wasn't found in our database.")
            }
        }
    }

    // MARK: - Barcode Handling

    private func handleBarcodeScanned(_ barcode: String) {
        guard !isSearching else { return }

        isSearching = true
        errorMessage = nil

        Task {
            // Normalize barcode for format variations
            let variations = normalizeBarcode(barcode)

            // Try Algolia search first
            var foundProduct: FoodSearchResult?
            for variation in variations {
                do {
                    if let hit = try await AlgoliaSearchManager.shared.searchByBarcode(variation) {
                        foundProduct = hit
                        break
                    }
                } catch {
                    continue
                }
            }

            if let product = foundProduct {
                await MainActor.run {
                    isSearching = false
                    onFoodFound(product)
                }
                return
            }

            // Fallback to Firebase cloud function
            await searchProductCloud(barcode: barcode)
        }
    }

    private func searchProductCloud(barcode: String) async {
        guard let url = URL(string: "https://us-central1-nutrasafe-705c7.cloudfunctions.net/searchFoodByBarcode") else {
            await MainActor.run {
                isSearching = false
                errorMessage = "Unable to search. Please try again."
                showError = true
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["barcode": barcode])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let foodData = json["food"] as? [String: Any] {

                // Parse the food result
                let product = FoodSearchResult(
                    id: foodData["id"] as? String ?? UUID().uuidString,
                    name: foodData["name"] as? String ?? "Unknown",
                    brand: foodData["brand"] as? String,
                    calories: foodData["calories"] as? Double ?? 0,
                    protein: foodData["protein"] as? Double ?? 0,
                    carbs: foodData["carbs"] as? Double ?? 0,
                    fat: foodData["fat"] as? Double ?? 0,
                    saturatedFat: foodData["saturatedFat"] as? Double,
                    fiber: foodData["fiber"] as? Double ?? 0,
                    sugar: foodData["sugar"] as? Double ?? 0,
                    sodium: foodData["sodium"] as? Double ?? 0,
                    ingredients: foodData["ingredients"] as? [String],
                    barcode: foodData["barcode"] as? String ?? barcode
                )

                await MainActor.run {
                    isSearching = false
                    onFoodFound(product)
                }
            } else {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "This product wasn't found in our database."
                    showError = true
                }
            }
        } catch {
            await MainActor.run {
                isSearching = false
                errorMessage = "Unable to search. Please try again."
                showError = true
            }
        }
    }

    private func normalizeBarcode(_ barcode: String) -> [String] {
        var variations = [barcode]

        // EAN-13 with leading 0 → UPC-A (12 digits)
        if barcode.count == 13 && barcode.hasPrefix("0") {
            variations.append(String(barcode.dropFirst()))
        }

        // EAN-13 without leading 0 → GTIN-14 (Tesco format: 0 + EAN-13)
        if barcode.count == 13 && !barcode.hasPrefix("0") {
            variations.append("0" + barcode)
        }

        // UPC-A (12 digits) → EAN-13 and GTIN-14
        if barcode.count == 12 {
            variations.append("0" + barcode)   // EAN-13
            variations.append("00" + barcode)  // GTIN-14
        }

        return variations
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
