//
//  NutrientHistoryCalendarView.swift
//  NutraSafe Beta
//
//  Calendar view for navigating nutrient history
//

import SwiftUI

struct NutrientHistoryCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    var selectedDate: Binding<Date>? // Optional binding for date selection mode
    var nutrientId: String? // Optional for nutrient-specific filtering
    var nutrientName: String? // Optional for title display

    @State private var displayedMonth: Date = Date()
    @State private var hasActivity: Set<String> = [] // Date strings with activity
    @State private var nutrientLevels: [String: SourceLevel] = [:] // Date -> Level for nutrient mode
    @State private var showingDateDetail: Bool = false
    @State private var detailDate: Date = Date()
    @State private var detailLevel: SourceLevel = .none
    @State private var detailFoods: [ContributingFood] = []

    let firebaseManager: FirebaseManager

    // Convenience init for date selection mode
    init(selectedDate: Binding<Date>, firebaseManager: FirebaseManager) {
        self.selectedDate = selectedDate
        self.nutrientId = nil
        self.nutrientName = nil
        self.firebaseManager = firebaseManager
    }

    // Convenience init for nutrient history mode
    init(nutrientId: String, nutrientName: String, firebaseManager: FirebaseManager) {
        self.selectedDate = nil
        self.nutrientId = nutrientId
        self.nutrientName = nutrientName
        self.firebaseManager = firebaseManager
    }

    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month navigation header
                monthNavigationHeader

                Divider()

                // Calendar grid
                ScrollView {
                    VStack(spacing: 24) {
                        calendarGrid
                    }
                    .padding()
                }
            }
            .navigationTitle(nutrientName ?? "Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(nutrientId == nil ? "Cancel" : "Done") {
                        dismiss()
                    }
                }

                if selectedDate != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Today") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate?.wrappedValue = Date()
                                displayedMonth = Date()
                            }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .task {
                await loadActivityData()
            }
            .sheet(isPresented: $showingDateDetail) {
                DateDetailSheet(
                    date: detailDate,
                    nutrientName: nutrientName ?? "",
                    level: detailLevel,
                    foods: detailFoods
                )
            }
        }
    }

    // MARK: - Month Navigation Header
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthYearString)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(canGoForward ? .blue : .gray.opacity(0.3))
                    .frame(width: 44, height: 44)
            }
            .disabled(!canGoForward)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 12) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        let dateString = dateFormatter.string(from: date)
                        CalendarDayCell(
                            date: date,
                            isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!.wrappedValue),
                            isToday: calendar.isDateInToday(date),
                            hasActivity: hasActivity.contains(dateString),
                            nutrientLevel: nutrientId != nil ? nutrientLevels[dateString] : nil,
                            isFutureDate: date > Date()
                        )
                        .onTapGesture {
                            if date <= Date() {
                                if let binding = selectedDate {
                                    // Date selection mode
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        binding.wrappedValue = date
                                    }
                                    dismiss()
                                } else if nutrientId != nil, let level = nutrientLevels[dateString] {
                                    // Nutrient history mode - show details
                                    detailDate = date
                                    detailLevel = level
                                    Task {
                                        await loadDateDetails(for: date)
                                        showingDateDetail = true
                                    }
                                }
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
    }

    // MARK: - Helper Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        // Rotate to start with Monday if needed (UK convention)
        // For now, keep Sunday start (US convention) - adjust based on locale
        return symbols
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []

        // Add empty cells for days before month starts
        let emptyDays = firstWeekday - calendar.firstWeekday
        for _ in 0..<emptyDays {
            days.append(nil)
        }

        // Add actual days of the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return days
    }

    private var canGoForward: Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else {
            return false
        }
        return nextMonth <= Date()
    }

    // MARK: - Navigation Actions
    private func previousMonth() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                displayedMonth = newDate
            }
        }
    }

    private func nextMonth() {
        guard canGoForward else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                displayedMonth = newDate
            }
        }
    }

    // MARK: - Load Activity Data
    private func loadActivityData() async {
        // Get diary entries from Firebase (last 90 days to cover most calendar views)
        let entries = (try? await firebaseManager.getFoodEntriesForPeriod(days: 90)) ?? []

        // Extract unique dates with activity
        let activeDates = Set(entries.map { dateFormatter.string(from: $0.date) })

        // If in nutrient mode, calculate levels for each date
        var levels: [String: SourceLevel] = [:]
        if let nutrientId = nutrientId {
            // Group entries by date
            let dateGroups = Dictionary(grouping: entries) { dateFormatter.string(from: $0.date) }

            for (dateString, dateEntries) in dateGroups {
                // Calculate the highest level for this nutrient on this date
                var bestLevel: SourceLevel = .none

                for entry in dateEntries {
                    let profile = recalculateMicronutrientProfile(for: entry)
                    let profileKey = nutrientIdToProfileKey(nutrientId)

                    if let amt = profile.vitamins[profileKey] ?? profile.minerals[profileKey] {
                        let level = classify(amount: amt, key: profileKey, profile: profile)
                        bestLevel = max(bestLevel, level)
                    }
                }

                levels[dateString] = bestLevel
            }
        }

        await MainActor.run {
            hasActivity = activeDates
            nutrientLevels = levels
        }
    }

    // Helper methods from DiaryTabView for nutrient calculation
    private func recalculateMicronutrientProfile(for entry: FoodEntry) -> MicronutrientProfile {
        let servingSize = entry.servingSize
        let multiplier = servingSize / 100.0

        let per100gCalories = multiplier > 0 ? entry.calories / multiplier : entry.calories
        let per100gProtein = multiplier > 0 ? entry.protein / multiplier : entry.protein
        let per100gCarbs = multiplier > 0 ? entry.carbohydrates / multiplier : entry.carbohydrates
        let per100gFat = multiplier > 0 ? entry.fat / multiplier : entry.fat
        let per100gFiber = multiplier > 0 ? (entry.fiber ?? 0) / multiplier : (entry.fiber ?? 0)
        let per100gSugar = multiplier > 0 ? (entry.sugar ?? 0) / multiplier : (entry.sugar ?? 0)
        let per100gSodium = multiplier > 0 ? (entry.sodium ?? 0) / multiplier : (entry.sodium ?? 0)

        let foodSearchResult = FoodSearchResult(
            id: entry.id,
            name: entry.foodName,
            brand: entry.brandName,
            calories: per100gCalories,
            protein: per100gProtein,
            carbs: per100gCarbs,
            fat: per100gFat,
            fiber: per100gFiber,
            sugar: per100gSugar,
            sodium: per100gSodium,
            servingDescription: "100g",
            servingSizeG: 100.0,
            ingredients: entry.ingredients,
            isVerified: true,
            micronutrientProfile: nil
        )

        return MicronutrientManager.shared.getMicronutrientProfile(for: foodSearchResult, quantity: multiplier)
    }

    private func classify(amount: Double, key: String, profile: MicronutrientProfile) -> SourceLevel {
        if amount <= 0 { return .none }
        let dvKey = dvKey(for: key)

        if let percent = profile.getDailyValuePercentage(for: dvKey, amount: amount) {
            if percent >= 70 { return .strong }
            if percent >= 30 { return .moderate }
            return .trace
        }

        return .trace
    }

    private func nutrientIdToProfileKey(_ nutrientId: String) -> String {
        switch nutrientId.lowercased() {
        case "vitamin_c": return "vitaminC"
        case "vitamin_d": return "vitaminD"
        case "vitamin_a": return "vitaminA"
        case "vitamin_e": return "vitaminE"
        case "vitamin_k": return "vitaminK"
        case "vitamin_b1": return "thiamine"
        case "vitamin_b2": return "riboflavin"
        case "vitamin_b3": return "niacin"
        case "vitamin_b5": return "pantothenicAcid"
        case "vitamin_b6": return "vitaminB6"
        case "vitamin_b7", "biotin": return "biotin"
        case "vitamin_b9", "folate": return "folate"
        case "vitamin_b12": return "vitaminB12"
        case "choline": return "choline"
        case "calcium": return "calcium"
        case "iron": return "iron"
        case "magnesium": return "magnesium"
        case "phosphorus": return "phosphorus"
        case "potassium": return "potassium"
        case "sodium": return "sodium"
        case "zinc": return "zinc"
        case "copper": return "copper"
        case "manganese": return "manganese"
        case "selenium": return "selenium"
        case "chromium": return "chromium"
        case "molybdenum": return "molybdenum"
        case "iodine": return "iodine"
        default: return nutrientId.lowercased()
        }
    }

    private func dvKey(for key: String) -> String {
        switch key.lowercased() {
        case "vitaminc": return "vitaminC"
        case "vitamina": return "vitaminA"
        case "vitamind": return "vitaminD"
        case "vitamine": return "vitaminE"
        case "vitamink": return "vitaminK"
        case "thiamine": return "thiamine"
        case "riboflavin": return "riboflavin"
        case "niacin": return "niacin"
        case "pantothenicacid": return "pantothenicAcid"
        case "vitaminb6": return "vitaminB6"
        case "biotin": return "biotin"
        case "folate": return "folate"
        case "vitaminb12": return "vitaminB12"
        case "choline": return "choline"
        default: return key.lowercased()
        }
    }

    // MARK: - Load Date Details
    private func loadDateDetails(for date: Date) async {
        guard let nutrientId = nutrientId else { return }

        let entries = (try? await firebaseManager.getFoodEntries(for: date)) ?? []
        let profileKey = nutrientIdToProfileKey(nutrientId)

        var foods: [ContributingFood] = []

        for entry in entries {
            let profile = recalculateMicronutrientProfile(for: entry)

            if let amt = profile.vitamins[profileKey] ?? profile.minerals[profileKey] {
                let level = classify(amount: amt, key: profileKey, profile: profile)
                if level != .none {
                    let food = ContributingFood(
                        name: entry.foodName,
                        amount: amt,
                        unit: getUnit(for: nutrientId),
                        mealType: entry.mealType.rawValue
                    )
                    foods.append(food)
                }
            }
        }

        await MainActor.run {
            detailFoods = foods.sorted { $0.amount > $1.amount }
        }
    }

    private func getUnit(for nutrientId: String) -> String {
        let id = nutrientId.lowercased()
        if id.contains("vitamin_a") || id.contains("vitamin_d") || id.contains("vitamin_k") ||
           id.contains("folate") || id.contains("vitamin_b12") || id.contains("selenium") {
            return "μg"
        }
        return "mg"
    }
}

// MARK: - Date Detail Sheet
struct DateDetailSheet: View {
    let date: Date
    let nutrientName: String
    let level: SourceLevel
    let foods: [ContributingFood]

    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with level indicator
                VStack(spacing: 16) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(level.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        )

                    Text(nutrientName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)

                    Text(dateFormatter.string(from: date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                // Contributing foods list
                if foods.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No foods with \\(nutrientName) on this date")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section(header: Text("Foods Contributing \\(nutrientName)")) {
                            ForEach(foods) { food in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(food.name)
                                            .font(.body)
                                            .foregroundColor(.primary)

                                        if let mealType = food.mealType {
                                            Text(mealType)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    Text(sourceLevel(for: food.amount))
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.green.opacity(0.15))
                                        )
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func sourceLevel(for amount: Double) -> String {
        // This mirrors the logic from DiaryTabView for consistency
        if amount >= 20 {
            return "High source"
        } else if amount >= 5 {
            return "Moderate source"
        } else {
            return "Low source"
        }
    }
}

// MARK: - Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasActivity: Bool
    let nutrientLevel: SourceLevel?
    let isFutureDate: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.body.weight(isSelected ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: isToday ? 2 : 0)
                        )
                )

            // Activity indicator or nutrient level indicator
            if let level = nutrientLevel, !isFutureDate {
                Circle()
                    .fill(level.color)
                    .frame(width: 6, height: 6)
            } else if hasActivity && !isFutureDate {
                Circle()
                    .fill(Color.green)
                    .frame(width: 4, height: 4)
            } else {
                Color.clear
                    .frame(width: 6, height: 6)
            }
        }
        .opacity(isFutureDate ? 0.3 : 1.0)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.blue
        } else if isFutureDate {
            return Color.clear
        } else {
            return Color(.secondarySystemBackground)
        }
    }

    private var textColor: Color {
        if isSelected {
            return .white
        } else if isFutureDate {
            return .secondary
        } else {
            return .primary
        }
    }

    private var borderColor: Color {
        if isToday && !isSelected {
            return .blue
        } else {
            return .clear
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedDate = Date()

        var body: some View {
            NutrientHistoryCalendarView(
                selectedDate: $selectedDate,
                firebaseManager: .shared
            )
        }
    }

    return PreviewWrapper()
}
