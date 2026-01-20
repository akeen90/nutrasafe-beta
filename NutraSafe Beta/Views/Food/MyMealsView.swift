//
//  MyMealsView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-16.
//  View for displaying and managing saved meals in the Meal Builder feature
//

import SwiftUI

struct MyMealsView: View {
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    @StateObject private var mealManager = MealManager.shared
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingCreateMeal = false
    @State private var selectedMealForEdit: Meal?
    @State private var selectedMealForLog: Meal?
    @State private var showingDeleteConfirmation = false
    @State private var mealToDelete: Meal?
    @State private var showingPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            if mealManager.meals.isEmpty {
                emptyStateView
            } else {
                mealsListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
        .fullScreenCover(isPresented: $showingCreateMeal) {
            CreateMealView(selectedTab: $selectedTab, onComplete: onComplete)
                .environmentObject(diaryDataManager)
        }
        .fullScreenCover(item: $selectedMealForEdit) { meal in
            CreateMealView(selectedTab: $selectedTab, editingMeal: meal, onComplete: onComplete)
                .environmentObject(diaryDataManager)
        }
        .sheet(item: $selectedMealForLog) { meal in
            LogMealSheet(meal: meal, selectedTab: $selectedTab, onComplete: onComplete)
                .environmentObject(diaryDataManager)
        }
        .alert("Delete Meal?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    Task {
                        try? await mealManager.deleteMeal(meal)
                    }
                }
                mealToDelete = nil
            }
        } message: {
            if let meal = mealToDelete {
                Text("Are you sure you want to delete '\(meal.name)'? This cannot be undone.")
            }
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .trackScreen("My Meals")
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppPalette.standard.accent.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppPalette.standard.accent, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("No Saved Meals")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Create meals to quickly log your favourite combinations")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Benefits
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "bolt.fill", text: "Log entire meals in one tap", color: .orange)
                BenefitRow(icon: "clock.fill", text: "Save time on daily logging", color: .blue)
                BenefitRow(icon: "heart.fill", text: "Track your favourites easily", color: .pink)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)

            // Create Button
            Button(action: { showingCreateMeal = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Create Your First Meal")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Meals List
    private var mealsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with create button
                HStack {
                    Text("My Meals")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: { showingCreateMeal = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("New")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppPalette.standard.accent)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Hint text
                HStack {
                    Text("Long press to edit or delete")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                // Meals Grid/List
                LazyVStack(spacing: 12) {
                    ForEach(mealManager.meals) { meal in
                        MealCard(
                            meal: meal,
                            onTap: { selectedMealForLog = meal },
                            onEdit: { selectedMealForEdit = meal },
                            onDelete: {
                                mealToDelete = meal
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)

                // Bottom spacing
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 80)
            }
        }
    }
}

// MARK: - Benefit Row
private struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Meal Card
struct MealCard: View {
    let meal: Meal
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppPalette.standard.accent.opacity(0.12))
                            .frame(width: 50, height: 50)

                        Image(systemName: meal.iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppPalette.standard.accent)
                    }

                    // Name and items
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text("\(meal.itemCount) item\(meal.itemCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Calories
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meal.totalCalories)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                }
                .padding(16)

                // Macro bar
                HStack(spacing: 16) {
                    MacroTag(label: "P", value: meal.totalProtein, color: .red)
                    MacroTag(label: "C", value: meal.totalCarbs, color: .orange)
                    MacroTag(label: "F", value: meal.totalFat, color: .purple)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(.systemGray5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit Meal", systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete Meal", systemImage: "trash")
            }
        }
    }
}

// MARK: - Macro Tag
private struct MacroTag: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)

            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Log Meal Sheet
struct LogMealSheet: View {
    let meal: Meal
    @Binding var selectedTab: TabItem
    var onComplete: ((TabItem) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var selectedMealType = "breakfast"
    @State private var isLogging = false
    @State private var showingSuccess = false

    private let mealTypes = ["breakfast", "lunch", "dinner", "snacks"]

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Meal Summary
                VStack(spacing: 16) {
                    // Icon and name
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppPalette.standard.accent.opacity(0.12))
                                .frame(width: 56, height: 56)

                            Image(systemName: meal.iconName)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(AppPalette.standard.accent)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))

                            Text("\(meal.itemCount) items • \(meal.totalCalories) kcal")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Meal Type Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add to")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    HStack(spacing: 0) {
                        ForEach(mealTypes, id: \.self) { type in
                            Button(action: { selectedMealType = type }) {
                                VStack(spacing: 6) {
                                    Image(systemName: mealTypeIcon(type))
                                        .font(.system(size: 18))
                                    Text(type.capitalized)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(selectedMealType == type ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedMealType == type ? AppPalette.standard.accent : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Items Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Items to add")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(meal.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .lineLimit(1)

                                        Text(item.servingDescription)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("\(Int(Double(item.calories) * item.quantity)) kcal")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxHeight: 200)
                }

                Spacer()

                // Log Button
                Button(action: logMeal) {
                    HStack(spacing: 10) {
                        if isLogging {
                            ProgressView()
                                .tint(.white)
                        } else if showingSuccess {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                        }
                        Text(showingSuccess ? "Added!" : "Add to \(selectedMealType.capitalized)")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(showingSuccess ? Color.green : AppPalette.standard.accent)
                    .cornerRadius(14)
                }
                .disabled(isLogging || showingSuccess)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func mealTypeIcon(_ type: String) -> String {
        switch type {
        case "breakfast": return "sunrise.fill"
        case "lunch": return "sun.max.fill"
        case "dinner": return "moon.fill"
        case "snacks": return "leaf.fill"
        default: return "fork.knife"
        }
    }

    private func logMeal() {
        isLogging = true

        // Get the target date
        let targetDate: Date
        if let savedTimestamp = UserDefaults.standard.object(forKey: "preselectedDate") as? TimeInterval {
            targetDate = Date(timeIntervalSince1970: savedTimestamp)
        } else {
            targetDate = Date()
        }

        Task {
            // Convert meal items to diary items and add them
            let diaryItems = meal.toDiaryFoodItems(mealType: selectedMealType.capitalized)

            for item in diaryItems {
                do {
                    try await diaryDataManager.addFoodItem(item, to: selectedMealType, for: targetDate, hasProAccess: true)
                } catch {
                    // Continue with other items even if one fails
                }
            }

            await MainActor.run {
                isLogging = false
                showingSuccess = true

                // Dismiss after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dismiss()
                    selectedTab = .diary
                    onComplete?(.diary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MyMealsView(selectedTab: .constant(.diary))
        .environmentObject(DiaryDataManager.shared)
        .environmentObject(SubscriptionManager())
}
