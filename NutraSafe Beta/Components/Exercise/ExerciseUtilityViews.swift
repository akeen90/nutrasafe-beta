import SwiftUI
import Foundation

// MARK: - Exercise Rest Timer View

struct ExerciseRestTimerView: View {
    @ObservedObject var timer: RestTimer
    let manager: ExerciseRestTimerManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Timer")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                
                Text(timer.exerciseName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text("\(timer.remainingTime / 60) min")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Button(action: {
                manager.stopTimer()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.3))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Exercise Tab Selector

struct ExerciseTabSelector: View {
    @Binding var selectedTab: ExerciseSubTab
    
    enum ExerciseSubTab: String, CaseIterable {
        case workout = "Workout"
        case history = "History"
        case stats = "Stats"
        
        var icon: String {
            switch self {
            case .workout: return "dumbbell.fill"
            case .history: return "clock"
            case .stats: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ExerciseSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .background(
                    Rectangle()
                        .fill(selectedTab == tab ? .blue.opacity(0.05) : .clear)
                )
            }
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Exercise Home View

struct ExerciseHomeView: View {
    @Binding var selectedTab: TabItem
    let onStartWorkout: () -> Void
    let onViewHistory: () -> Void
    let onBrowseTemplates: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                
                // Welcome Section
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready to Exercise?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Choose how you'd like to get started")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Quick Actions
                VStack(spacing: 16) {
                    // Start Workout Button
                    Button(action: onStartWorkout) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Start New Workout")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Create a custom workout")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    
                    // Browse Templates Button
                    Button(action: onBrowseTemplates) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Browse Templates")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Pre-built workout routines")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "book.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
                
                // Quick Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("This Week")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("View All") {
                            onViewHistory()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        QuickStatCard(
                            title: "Workouts",
                            value: "3",
                            subtitle: "This week",
                            color: .blue,
                            icon: "dumbbell.fill"
                        )
                        
                        QuickStatCard(
                            title: "Total Time",
                            value: "2.5h",
                            subtitle: "Active time",
                            color: .green,
                            icon: "clock"
                        )
                        
                        QuickStatCard(
                            title: "Volume",
                            value: "12.5k",
                            subtitle: "Pounds lifted",
                            color: .orange,
                            icon: "scalemass"
                        )
                        
                        QuickStatCard(
                            title: "Best Streak",
                            value: "7",
                            subtitle: "Days in a row",
                            color: .purple,
                            icon: "flame.fill"
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Exercise Picker View

struct ExercisePickerView: View {
    let onSelection: (ExerciseModel) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    
    private let exercises: [ExerciseModel] = [
        // Sample exercises - in real app this would come from a database
        ExerciseModel(id: UUID(), name: "Bench Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
        ExerciseModel(id: UUID(), name: "Squats", category: .legs, primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Glutes"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
        ExerciseModel(id: UUID(), name: "Pull-ups", category: .back, primaryMuscles: ["Back"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 4)
    ]
    
    private var filteredExercises: [ExerciseModel] {
        exercises.filter { exercise in
            (selectedCategory == nil || exercise.category == selectedCategory) &&
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select Exercise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search exercises...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            Button(action: {
                                onSelection(exercise)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            Text(exercise.category.rawValue.capitalized)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                            
                                            Text("•")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                            
                                            Text(exercise.equipment.rawValue.capitalized)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}