import SwiftUI
import Foundation

// MARK: - Advanced Exercise Picker

struct AdvancedExercisePicker: View {
    let onSelection: ([ExerciseSummary]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedExercises: Set<String> = []
    @State private var selectedTab: ExerciseType = .resistance
    
    enum ExerciseType: String, CaseIterable {
        case resistance = "Resistance"
        case cardio = "Cardio"
    }
    
    // Get exercises from comprehensive database
    private var exerciseGroups: [String: [String]] {
        var groups: [String: [String]] = [:]
        
        if selectedTab == .resistance {
            groups = [
                "Chest": ["Bench Press", "Incline Bench Press", "Dumbbell Press", "Push-ups", "Chest Dips", "Chest Flyes"],
                "Back": ["Pull-ups", "Lat Pulldowns", "Barbell Rows", "Dumbbell Rows", "Deadlifts", "T-Bar Rows"],
                "Shoulders": ["Overhead Press", "Lateral Raises", "Front Raises", "Rear Delt Flyes", "Arnold Press", "Pike Push-ups"],
                "Arms": ["Bicep Curls", "Hammer Curls", "Tricep Dips", "Close-Grip Bench Press", "Tricep Extensions", "21s"],
                "Legs": ["Squats", "Lunges", "Leg Press", "Leg Curls", "Leg Extensions", "Calf Raises"],
                "Core": ["Planks", "Russian Twists", "Mountain Climbers", "Bicycle Crunches", "Leg Raises", "Dead Bugs"]
            ]
        } else {
            groups = [
                "High Intensity": ["Burpees", "Mountain Climbers", "Jump Squats", "High Knees", "Jumping Jacks"],
                "Endurance": ["Running", "Cycling", "Swimming", "Rowing", "Elliptical", "Walking"],
                "Sports": ["Tennis", "Basketball", "Soccer", "Boxing", "Martial Arts", "Rock Climbing"]
            ]
        }
        
        return groups
    }
    
    private var filteredGroups: [String: [String]] {
        guard !searchText.isEmpty else { return exerciseGroups }
        
        var filtered: [String: [String]] = [:]
        for (category, exercises) in exerciseGroups {
            let filteredExercises = exercises.filter { exercise in
                exercise.localizedCaseInsensitiveContains(searchText)
            }
            if !filteredExercises.isEmpty {
                filtered[category] = filteredExercises
            }
        }
        return filtered
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
                    
                    Text("Select Exercises")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        let exercises = selectedExercises.map { name in
                            ExerciseSummary(
                                id: UUID(),
                                name: name,
                                category: selectedTab == .resistance ? .strength : .cardio,
                                sets: [],
                                totalVolume: 0,
                                personalRecord: nil
                            )
                        }
                        onSelection(exercises)
                        dismiss()
                    }
                    .foregroundColor(selectedExercises.isEmpty ? .gray : .blue)
                    .fontWeight(.semibold)
                    .disabled(selectedExercises.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Exercise Type Tabs
                HStack(spacing: 0) {
                    ForEach(ExerciseType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedTab = type
                            selectedExercises.removeAll() // Clear selection when switching tabs
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == type ? .blue : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .background(
                            Rectangle()
                                .fill(selectedTab == type ? .blue.opacity(0.05) : .clear)
                        )
                    }
                }
                .background(.ultraThinMaterial)
                
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search exercises...")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                
                // Exercises List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredGroups.keys.sorted()), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 8) {
                                // Category Header
                                HStack {
                                    Text(category)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(filteredGroups[category]?.count ?? 0) exercises")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                
                                // Exercise List
                                ForEach(filteredGroups[category] ?? [], id: \.self) { exercise in
                                    ExerciseSelectionRow(
                                        exercise: exercise,
                                        isSelected: selectedExercises.contains(exercise),
                                        onToggle: {
                                            if selectedExercises.contains(exercise) {
                                                selectedExercises.remove(exercise)
                                            } else {
                                                selectedExercises.insert(exercise)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                // Selected Count Footer
                if !selectedExercises.isEmpty {
                    HStack {
                        Text("\(selectedExercises.count) exercises selected")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("Clear All") {
                            selectedExercises.removeAll()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Exercise Selection Row

struct ExerciseSelectionRow: View {
    let exercise: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(exercise)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? .blue.opacity(0.05) : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Empty Workout View

struct EmptyWorkoutView: View {
    let onAddExercise: () -> Void
    let onSelectTemplate: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "dumbbell")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
            
            // Text
            VStack(spacing: 8) {
                Text("No Workout Started")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Create a new workout by adding exercises or selecting a template")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: onAddExercise) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Exercise")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: onSelectTemplate) {
                    HStack {
                        Image(systemName: "book.fill")
                        Text("Browse Templates")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }
}