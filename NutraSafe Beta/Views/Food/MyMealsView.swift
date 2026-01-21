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
        .background(AppAnimatedBackground())
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

    // MARK: - Empty State - Redesigned with NutraSafe visual language
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Central card panel
            VStack(spacing: 24) {
                // Icon with soft container
                ZStack {
                    Circle()
                        .fill(AppPalette.standard.accent.opacity(colorScheme == .dark ? 0.2 : 0.12))
                        .frame(width: 88, height: 88)

                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(AppPalette.standard.accent)
                }

                VStack(spacing: 10) {
                    Text("No saved meals yet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Create meals to log your favourite\ncombinations in one tap")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // Benefits - redesigned with soft styling
                VStack(alignment: .leading, spacing: 14) {
                    BenefitRow(icon: "bolt.fill", text: "Log entire meals in one tap", color: SemanticColors.neutral)
                    BenefitRow(icon: "clock.fill", text: "Save time on daily logging", color: AppPalette.standard.accent)
                    BenefitRow(icon: "heart.fill", text: "Track your favourites easily", color: .pink)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )

                // Create Button - primary CTA style
                Button(action: { showingCreateMeal = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                        Text("Create Your First Meal")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Size.buttonHeight)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.standard.accent, AppPalette.standard.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(DesignTokens.Radius.lg)
                    .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 15, y: 5)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(Color.nutraSafeCard)
                    .shadow(
                        color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y
                    )
            )
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)

            Spacer()
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Meals List - Redesigned with NutraSafe visual language
    private var mealsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with create button - redesigned
                HStack(alignment: .center) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(AppPalette.standard.accent.opacity(0.12))
                                .frame(width: 36, height: 36)

                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppPalette.standard.accent)
                        }

                        Text("My Meals")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    Button(action: { showingCreateMeal = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("New")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [AppPalette.standard.accent, AppPalette.standard.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.pill)
                        .shadow(color: AppPalette.standard.accent.opacity(0.2), radius: 6, y: 2)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)

                // Hint text - softer styling
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Long press to edit or delete")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
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
                .padding(.horizontal, DesignTokens.Spacing.md)

                // Bottom spacing
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 80)
            }
        }
    }
}

// MARK: - Benefit Row - Redesigned with icon container
private struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - Meal Card - Redesigned with NutraSafe visual language
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
                    // Icon with gradient container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.standard.accent.opacity(0.15), AppPalette.standard.primary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)

                        Image(systemName: meal.iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(AppPalette.standard.accent)
                    }

                    // Name and items
                    VStack(alignment: .leading, spacing: 5) {
                        Text(meal.name)
                            .font(.system(size: 17, weight: .semibold))
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(18)

                // Macro bar - redesigned with softer colors
                HStack(spacing: 12) {
                    MacroTag(label: "P", value: meal.totalProtein, color: Color(red: 0.9, green: 0.4, blue: 0.4))
                    MacroTag(label: "C", value: meal.totalCarbs, color: SemanticColors.neutral)
                    MacroTag(label: "F", value: meal.totalFat, color: Color(red: 0.6, green: 0.5, blue: 0.8))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(Color.nutraSafeCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
            )
            .shadow(
                color: DesignTokens.Shadow.subtle.color,
                radius: DesignTokens.Shadow.subtle.radius,
                y: DesignTokens.Shadow.subtle.y
            )
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

// MARK: - Macro Tag - Redesigned with softer styling
private struct MacroTag: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)

            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(color.opacity(0.12))
        )
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
            .background(AppAnimatedBackground())
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
