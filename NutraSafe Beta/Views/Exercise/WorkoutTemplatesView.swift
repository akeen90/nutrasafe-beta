import SwiftUI
import Foundation

struct WorkoutTemplatesView: View {
    let onSelectTemplate: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: WorkoutTemplate?
    
    private let workoutTemplates: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: UUID(),
            name: "Push Day (Beginner)",
            exercises: [
                ExerciseModel(id: UUID(), name: "Push-ups", category: .chest, primaryMuscles: ["Chest", "Triceps"], secondaryMuscles: ["Shoulders"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Dumbbell Shoulder Press", category: .shoulders, primaryMuscles: ["Shoulders"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Dumbbell Chest Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Tricep Dips", category: .triceps, primaryMuscles: ["Triceps"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2)
            ],
            category: .strength,
            estimatedDuration: 45,
            difficulty: .beginner
        ),
        
        WorkoutTemplate(
            id: UUID(),
            name: "Pull Day (Beginner)",
            exercises: [
                ExerciseModel(id: UUID(), name: "Pull-ups", category: .back, primaryMuscles: ["Back"], secondaryMuscles: ["Biceps"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                ExerciseModel(id: UUID(), name: "Dumbbell Rows", category: .back, primaryMuscles: ["Back"], secondaryMuscles: ["Biceps"], equipment: .dumbbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Bicep Curls", category: .biceps, primaryMuscles: ["Biceps"], secondaryMuscles: [], equipment: .dumbbell, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 1),
                ExerciseModel(id: UUID(), name: "Face Pulls", category: .shoulders, primaryMuscles: ["Rear Deltoids"], secondaryMuscles: ["Rhomboids"], equipment: .cable, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2)
            ],
            category: .strength,
            estimatedDuration: 40,
            difficulty: .beginner
        ),
        
        WorkoutTemplate(
            id: UUID(),
            name: "Leg Day (Beginner)",
            exercises: [
                ExerciseModel(id: UUID(), name: "Squats", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Lunges", category: .legs, primaryMuscles: ["Quadriceps", "Glutes"], secondaryMuscles: ["Hamstrings"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2),
                ExerciseModel(id: UUID(), name: "Calf Raises", category: .legs, primaryMuscles: ["Calves"], secondaryMuscles: [], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 1),
                ExerciseModel(id: UUID(), name: "Wall Sit", category: .legs, primaryMuscles: ["Quadriceps"], secondaryMuscles: ["Glutes"], equipment: .bodyweight, movementType: .isolation, instructions: nil, isPopular: true, difficulty: 2)
            ],
            category: .strength,
            estimatedDuration: 35,
            difficulty: .beginner
        ),
        
        WorkoutTemplate(
            id: UUID(),
            name: "Full Body (Intermediate)",
            exercises: [
                ExerciseModel(id: UUID(), name: "Deadlifts", category: .legs, primaryMuscles: ["Hamstrings", "Glutes", "Back"], secondaryMuscles: ["Core"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 4),
                ExerciseModel(id: UUID(), name: "Bench Press", category: .chest, primaryMuscles: ["Chest"], secondaryMuscles: ["Triceps", "Shoulders"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                ExerciseModel(id: UUID(), name: "Barbell Rows", category: .back, primaryMuscles: ["Back"], secondaryMuscles: ["Biceps"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                ExerciseModel(id: UUID(), name: "Overhead Press", category: .shoulders, primaryMuscles: ["Shoulders"], secondaryMuscles: ["Triceps"], equipment: .barbell, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3)
            ],
            category: .strength,
            estimatedDuration: 60,
            difficulty: .intermediate
        ),
        
        WorkoutTemplate(
            id: UUID(),
            name: "HIIT Cardio",
            exercises: [
                ExerciseModel(id: UUID(), name: "Burpees", category: .cardio, primaryMuscles: ["Full Body"], secondaryMuscles: [], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 4),
                ExerciseModel(id: UUID(), name: "Mountain Climbers", category: .cardio, primaryMuscles: ["Core", "Shoulders"], secondaryMuscles: ["Legs"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                ExerciseModel(id: UUID(), name: "Jump Squats", category: .cardio, primaryMuscles: ["Legs"], secondaryMuscles: ["Glutes"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 3),
                ExerciseModel(id: UUID(), name: "High Knees", category: .cardio, primaryMuscles: ["Legs"], secondaryMuscles: ["Core"], equipment: .bodyweight, movementType: .compound, instructions: nil, isPopular: true, difficulty: 2)
            ],
            category: .cardio,
            estimatedDuration: 20,
            difficulty: .intermediate
        )
    ]
    
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
                    
                    Text("Workout Templates")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        if let template = selectedTemplate {
                            onSelectTemplate(template)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedTemplate != nil ? .blue : .gray)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(selectedTemplate == nil)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Templates List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(workoutTemplates) { template in
                            WorkoutTemplateCardView(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id,
                                onSelect: {
                                    selectedTemplate = template
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct WorkoutTemplateCardView: View {
    let template: WorkoutTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            Text(template.difficulty.rawValue.capitalized)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(difficultyColor(template.difficulty))
                                )
                            
                            Text("\(template.estimatedDuration) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("\(template.exercises.count) exercises")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                // Exercise List Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercises:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(template.exercises.prefix(3)) { exercise in
                        HStack {
                            Text("• \(exercise.name)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(exercise.equipment.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.gray.opacity(0.05))
                                )
                        }
                    }
                    
                    if template.exercises.count > 3 {
                        Text("+ \(template.exercises.count - 3) more exercises")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func difficultyColor(_ difficulty: WorkoutTemplate.Difficulty) -> Color {
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
}

struct WorkoutTemplateDetailView: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(template.icon ?? "💪")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 16) {
                                    Text(template.difficulty.rawValue.capitalized)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(difficultyColor(template.difficulty))
                                        )
                                    
                                    Text("\(template.estimatedDuration) min")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    // Description
                    if let description = template.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This Workout")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Exercises List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Exercises (\(template.exercises.count))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ForEach(Array(template.exercises.enumerated()), id: \.offset) { index, exercise in
                            HStack(alignment: .top, spacing: 16) {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(exercise.equipment.rawValue.capitalized)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(.gray.opacity(0.05))
                                            )
                                        
                                        Text(exercise.category.rawValue.capitalized)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(
                                                Capsule()
                                                    .fill(.blue.opacity(0.05))
                                            )
                                    }
                                    
                                    if !exercise.primaryMuscles.isEmpty {
                                        Text("Primary: \(exercise.primaryMuscles.joined(separator: ", "))")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start Workout") {
                        onStart()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func difficultyColor(_ difficulty: WorkoutTemplate.Difficulty) -> Color {
        switch difficulty {
        case .beginner:
            return .green
        case .intermediate:
            return .orange
        case .advanced:
            return .red
        }
    }
}