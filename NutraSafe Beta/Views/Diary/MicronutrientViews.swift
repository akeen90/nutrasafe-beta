import SwiftUI
import Foundation

// MARK: - Micronutrient Views

struct ImprovedMicronutrientView: View {
    let breakfast: [DiaryFoodItem]
    let lunch: [DiaryFoodItem]
    let dinner: [DiaryFoodItem]
    let snacks: [DiaryFoodItem]
    @State private var showingDetailedInsights = false
    
    private var allFoods: [DiaryFoodItem] {
        breakfast + lunch + dinner + snacks
    }
    
    private var hasWeekOfData: Bool {
        // Check if we have at least 7 days of food entries
        // For now, simplified check - if we have foods, assume we have some data
        !allFoods.isEmpty
    }
    
    private var nutrientAnalysis: [NutrientInsight] {
        analyzeNutrients()
    }
    
    var body: some View {
        if allFoods.isEmpty {
            // Initial state - no foods added yet
            Button(action: {
                showingDetailedInsights = true
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Click for deeper insights into vitamins and minerals")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Discover your nutrition patterns")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        } else if hasWeekOfData {
            // After accumulating data - show intelligent insights
            Button(action: {
                showingDetailedInsights = true
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text(generateInsightSummary())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick visual indicators
                    HStack(spacing: 8) {
                        ForEach(nutrientAnalysis.prefix(4), id: \.name) { insight in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(insight.status.indicatorColor)
                                    .frame(width: 8, height: 8)
                                
                                Text(insight.name)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // Building up data - transitional state
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(nutrientAnalysis.prefix(6), id: \.name) { insight in
                    NutrientInsightCard(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func generateInsightSummary() -> String {
        let goodNutrients = nutrientAnalysis.filter { $0.status == .adequate }
        let needsMore = nutrientAnalysis.filter { $0.status == .needsMore }
        
        if goodNutrients.count >= 4 {
            let examples = goodNutrients.prefix(2).map { $0.name }.joined(separator: " and ")
            if needsMore.isEmpty {
                return "Great nutrition balance! You're getting good amounts of key nutrients."
            } else {
                let missing = needsMore.prefix(1).first?.name ?? "B12"
                return "You're getting good amounts of \(examples). Consider adding foods with \(missing)."
            }
        } else if needsMore.count > 2 {
            let suggestions = ["fortified cereals", "leafy greens", "nuts", "fish"].randomElement() ?? "varied foods"
            return "Add variety to boost your nutrition - try \(suggestions) for balanced vitamins and minerals."
        } else {
            return "Keep building your nutrition profile. Add more variety for deeper insights."
        }
    }
    
    private func analyzeNutrients() -> [NutrientInsight] {
        let nutrientSources: [String: (icon: String, sources: [String], color: Color)] = [
            "Vitamin C": ("c.circle.fill", ["orange", "lemon", "strawberry", "bell pepper", "broccoli", "tomato"], .orange),
            "Protein": ("p.circle.fill", ["chicken", "beef", "fish", "eggs", "beans", "tofu", "milk"], .red),
            "Fiber": ("f.circle.fill", ["apple", "banana", "oats", "beans", "broccoli", "whole grain"], .brown),
            "Iron": ("i.circle.fill", ["spinach", "beef", "lentils", "quinoa", "dark chocolate"], .gray),
            "Calcium": ("c.circle.fill", ["milk", "cheese", "yogurt", "broccoli", "almonds"], .blue),
            "Omega-3": ("fish.fill", ["salmon", "sardines", "walnuts", "flax", "chia"], .teal)
        ]
        
        return nutrientSources.map { name, info in
            let hasGoodSource = allFoods.contains { food in
                info.sources.contains { source in
                    food.name.lowercased().contains(source.lowercased())
                }
            }
            
            return NutrientInsight(
                name: name,
                icon: info.icon,
                status: hasGoodSource ? .adequate : .needsMore,
                color: info.color,
                recommendation: hasGoodSource ? "Good!" : "Add more"
            )
        }.sorted { insight1, insight2 in
            if insight1.status == .needsMore && insight2.status == .adequate { return true }
            if insight1.status == .adequate && insight2.status == .needsMore { return false }
            return insight1.name < insight2.name
        }
    }
}

// MARK: - Data Models

struct NutrientInsight {
    let name: String
    let icon: String
    let status: NutrientInsightStatus
    let color: Color
    let recommendation: String
}

enum NutrientInsightStatus {
    case adequate
    case needsMore
    
    var indicatorColor: Color {
        switch self {
        case .adequate: return .green
        case .needsMore: return .orange
        }
    }
}

// MARK: - Supporting Views

struct NutrientInsightCard: View {
    let insight: NutrientInsight
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: insight.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(insight.color)
                
                Circle()
                    .fill(insight.status.indicatorColor)
                    .frame(width: 6, height: 6)
            }
            
            Text(insight.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(insight.recommendation)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
}