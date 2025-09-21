import SwiftUI
import Foundation

struct FoodTabView: View {
    @Binding var showingSettings: Bool
    @State private var selectedFoodSubTab: FoodSubTab = .reactions

    enum FoodSubTab: String, CaseIterable {
        case reactions = "Reactions"
        case fasting = "Fasting"
        case pending = "Pending"
        case recipes = "Recipes"

        var icon: String {
            switch self {
            case .reactions: return "exclamationmark.triangle.fill"
            case .fasting: return "clock.fill"
            case .pending: return "hourglass.circle.fill"
            case .recipes: return "book.closed.fill"
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
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12 + 2)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        .buttonStyle(SpringyButtonStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

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
                    case .fasting:
                        FastingTimerView()
                    case .pending:
                        PendingVerificationsView()
                    case .recipes:
                        RecipesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Food Sub-Tab Selector
struct FoodSubTabSelector: View {
    @Binding var selectedTab: FoodTabView.FoodSubTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FoodTabView.FoodSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))

                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(SpringyButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
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

// MARK: - Food Tab Component Cards
struct FoodReactionSummaryCard: View {
    @State private var showingAlert = false

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

            Button(action: {
                showingAlert = true
            }) {
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
        .alert("Log Food Reaction", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Coming Soon") { }
        } message: {
            Text("Food reaction logging feature is being developed. Stay tuned!")
        }
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

            Text(formatDate(reaction.timestamp.dateValue()))
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

// MARK: - Recipe Components
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

// MARK: - Sample Data
import FirebaseFirestore

let sampleReactions: [FoodReaction] = [
    FoodReaction(
        foodName: "Milk",
        timestamp: Timestamp(),
        severity: .moderate,
        symptoms: ["Bloating", "nausea"],
        suspectedIngredients: ["milk", "lactose"],
        notes: "Had with cereal"
    ),
    FoodReaction(
        foodName: "Peanuts",
        timestamp: Timestamp(),
        severity: .severe,
        symptoms: ["Hives", "itching"],
        suspectedIngredients: ["peanuts", "groundnuts"],
        notes: "Trail mix snack"
    ),
    FoodReaction(
        foodName: "Wheat bread",
        timestamp: Timestamp(),
        severity: .mild,
        symptoms: ["Stomach pain"],
        suspectedIngredients: ["wheat", "gluten"],
        notes: "With breakfast"
    )
]}