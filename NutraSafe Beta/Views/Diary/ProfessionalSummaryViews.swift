//
//  ProfessionalSummaryViews.swift
//  NutraSafe Beta
//
//  Professional Summary Cards System
//  Extracted from ContentView.swift - Lines ~5510-5918 (408+ lines)
//  Advanced nutrition visualization with professional UI components
//

import SwiftUI

// MARK: - Professional Summary Card (Following Research Standards)
struct ProfessionalSummaryCard: View {
    let dailyNutrition: DailyNutrition
    let selectedDate: Date
    let animateProgress: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Modern Header with enhanced styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition Overview")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(selectedDate, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Enhanced calories remaining with modern styling
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(Int(dailyNutrition.calories.remaining))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(dailyNutrition.calories.remaining > 0 ? .green : .orange)
                        
                        Text("cal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(dailyNutrition.calories.remaining > 0 ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
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

// MARK: - Professional Meal Card
struct ProfessionalMealCard: View {
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
        guard let score = item.qualityScore else {
            return Color(hex: "#F44336") // Red for unknown quality
        }
        switch score {
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

// MARK: - Supporting Data Models
// MealType is now defined in CoreModels.swift with additional properties

// DailyNutrition and NutrientTarget are now defined in NutritionModels.swift

struct MealItem: Identifiable {
    let id = UUID()
    let name: String
    let brand: String?
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let qualityScore: Int?
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

// MARK: - Modern Card Style
struct ModernCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: shadowRadius, x: 0, y: 4)
            )
    }
}