import SwiftUI

struct TodayView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Header with date
                    Text("Today")
                        .font(.headline)
                        .padding(.top)
                    
                    // Nutrition Summary Card
                    if let summary = watchDataManager.nutritionSummary {
                        NutritionSummaryCard(summary: summary)
                    } else {
                        LoadingCard()
                    }
                    
                    // Recent Food Entries
                    FoodEntriesSection()
                    
                    // Refresh Button
                    Button(action: {
                        connectivityManager.requestTodayData()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom)
                }
            }
        }
    }
}

struct NutritionSummaryCard: View {
    let summary: WatchNutritionSummary
    
    var body: some View {
        VStack(spacing: 8) {
            // Grade Badge
            HStack {
                Text("Today's Grade")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(summary.averageGrade)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(summary.averageGradeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(summary.averageGradeColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Calories
            HStack {
                Text("Calories")
                    .font(.caption)
                Spacer()
                Text("\(Int(summary.totalCalories))")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            // Macros
            HStack {
                MacroView(title: "Protein", value: summary.totalProtein, unit: "g", color: .red)
                Spacer()
                MacroView(title: "Carbs", value: summary.totalCarbs, unit: "g", color: .orange)
                Spacer()
                MacroView(title: "Fat", value: summary.totalFat, unit: "g", color: .yellow)
            }
            
            // Food Count
            HStack {
                Text("Foods Logged")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(summary.foodCount)")
                    .font(.body)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MacroView: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(Int(value))\(unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct FoodEntriesSection: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Foods")
                    .font(.headline)
                    .padding(.horizontal)
                Spacer()
            }
            
            if watchDataManager.todayEntries.isEmpty {
                Text("No foods logged today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(watchDataManager.todayEntries.prefix(3)) { entry in
                        FoodEntryRow(entry: entry)
                    }
                    
                    if watchDataManager.todayEntries.count > 3 {
                        Text("+ \(watchDataManager.todayEntries.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct FoodEntryRow: View {
    let entry: WatchFoodEntry
    
    var body: some View {
        HStack {
            // Grade indicator
            Text(entry.grade)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(entry.gradeColor)
                .frame(width: 24, height: 24)
                .background(entry.gradeColor.opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("\(Int(entry.calories)) cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DateFormatter.timeOnly.string(from: entry.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct LoadingCard: View {
    var body: some View {
        VStack {
            ProgressView()
                .padding()
            Text("Loading nutrition data...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    TodayView()
        .environmentObject(WatchDataManager())
        .environmentObject(WatchConnectivityManager())
}