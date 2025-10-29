//
//  DiaryComponents.swift
//  NutraSafe Beta
//
//  Modern diary components with enhanced visual design
//

import SwiftUI

// MARK: - Diary Meal Card
struct DiaryMealCard: View {
    let mealType: String
    let targetCalories: Int
    let currentCalories: Int
    @Binding var foods: [DiaryFoodItem]
    let color: Color
    @Binding var selectedTab: TabItem
    @Binding var selectedFoodItems: Set<String>
    let currentDate: Date
    let onEditFood: () -> Void
    let onSaveNeeded: () -> Void
    let onDelete: (DiaryFoodItem) -> Void
    
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
        VStack(alignment: .leading, spacing: 0) {
            // Column headers (only show once at the top)
            if mealType == "Breakfast" {
                HStack {
                    Text("ITEM")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(0.5)

                    Spacer()

                    HStack(spacing: 0) {
                        Text("KCAL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .frame(width: 50, alignment: .trailing)
                        Text("PROT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .frame(width: 50, alignment: .trailing)
                        Text("CARB")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .frame(width: 50, alignment: .trailing)
                        Text("FAT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground).opacity(0.5))
            }

            // Modern meal header with enhanced styling
            HStack {
                HStack(spacing: 10) {
                    // Enhanced color indicator
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color.opacity(0.8), color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 14, height: 14)
                            .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 14, height: 14)
                    }

                    Text(mealType.uppercased())
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .tracking(0.5)
                }

                Spacer()

                // Calories and macros with enhanced typography
                HStack(spacing: 0) {
                    Text("\(currentCalories)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalProtein))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalCarbs))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", totalFat))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemGray5).opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2),
                alignment: .bottom
            )

            // Food items section
            if !foods.isEmpty {
                VStack(spacing: 0) {
                    ForEach(foods) { food in
                        DiaryFoodRow(
                            food: food,
                            mealType: mealType,
                            isSelected: selectedFoodItems.contains(food.id.uuidString),
                            hasAnySelection: !selectedFoodItems.isEmpty,
                            onTap: {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                
                                if selectedFoodItems.contains(food.id.uuidString) {
                                    selectedFoodItems.remove(food.id.uuidString)
                                } else {
                                    selectedFoodItems.insert(food.id.uuidString)
                                }
                            },
                            onDelete: {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                if let index = foods.firstIndex(of: food) {
                                    _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        foods.remove(at: index)
                                    }
                                    onDelete(food)
                                    onSaveNeeded()
                                }
                            }
                        )
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))

                        if food.id != foods.last?.id {
                            Divider()
                                .padding(.leading, 18)
                        }
                    }

                    // Modern add more button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        UserDefaults.standard.set(mealType, forKey: "preselectedMealType")
                        UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: "preselectedDate")
                        selectedTab = .add
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Add more")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.blue)

                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(ModernCardButtonStyle())
                }
            } else {
                // Enhanced empty state
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    UserDefaults.standard.set(mealType, forKey: "preselectedMealType")
                    UserDefaults.standard.set(currentDate.timeIntervalSince1970, forKey: "preselectedDate")
                    selectedTab = .add
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add \(mealType.lowercased())")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Tap to start logging")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(ModernCardButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
        .shadow(color: color.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Card Button Style
struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(.systemGray6).opacity(0.5) : Color.clear)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Diary Food Row
struct DiaryFoodRow: View {
    let food: DiaryFoodItem
    let mealType: String
    let isSelected: Bool
    let hasAnySelection: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showingFoodDetail = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Modern selection circle
                if hasAnySelection {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: isSelected ? [Color.blue, Color.blue.opacity(0.8)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.clear, radius: 3, x: 0, y: 1)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                }

                // Food info with enhanced typography
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        Text(food.servingDescription)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        if food.quantity > 1 {
                            Text("× \(String(format: "%.0f", food.quantity))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Enhanced macros display
                HStack(spacing: 0) {
                    Text("\(food.calories)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.protein))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.carbs))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)

                    Text("\(String(format: "%.1f", food.fat))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            .animation(nil, value: hasAnySelection)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showingFoodDetail = true
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onDelete()
            }) {
                Label("Delete", systemImage: "trash.fill")
            }
            .tint(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .sheet(isPresented: $showingFoodDetail) {
            FoodDetailViewFromSearch(
                food: food.toFoodSearchResult(),
                sourceType: .diary,
                selectedTab: .constant(.diary),
                destination: .diary,
                diaryEntryId: food.id,
                diaryMealType: mealType
            )
        }
    }
}
