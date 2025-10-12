import SwiftUI
import Foundation

// MARK: - Exercise History View

struct ExerciseHistoryView: View {
    let exerciseName: String
    @Environment(\.dismiss) private var dismiss
    
    // Sample data - in real app this would come from database
    private let historyEntries = [
        (date: Date().addingTimeInterval(-86400 * 1), weight: 185, reps: 8, sets: 3),
        (date: Date().addingTimeInterval(-86400 * 3), weight: 180, reps: 8, sets: 3),
        (date: Date().addingTimeInterval(-86400 * 7), weight: 175, reps: 10, sets: 3),
        (date: Date().addingTimeInterval(-86400 * 10), weight: 175, reps: 8, sets: 3),
        (date: Date().addingTimeInterval(-86400 * 14), weight: 170, reps: 10, sets: 3)
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
                    
                    Text("\(exerciseName) History")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Export") {
                        // Export functionality
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Progress Overview
                VStack(spacing: 16) {
                    HStack {
                        Text("Progress Overview")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        ExerciseStatCard(
                            title: "Best Set",
                            value: "185×8",
                            subtitle: "Personal record",
                            color: .green,
                            icon: "trophy.fill"
                        )
                        
                        ExerciseStatCard(
                            title: "Volume",
                            value: "4.4k",
                            subtitle: "Last workout",
                            color: .blue,
                            icon: "scalemass"
                        )
                        
                        ExerciseStatCard(
                            title: "Frequency",
                            value: "2.3x",
                            subtitle: "Per week",
                            color: .orange,
                            icon: "calendar"
                        )
                        
                        ExerciseStatCard(
                            title: "Trend",
                            value: "+5.7%",
                            subtitle: "This month",
                            color: .green,
                            icon: "arrow.up.right"
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                
                // History List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(historyEntries.enumerated()), id: \.offset) { index, entry in
                            ExerciseEntryRow(
                                date: entry.date,
                                weight: entry.weight,
                                reps: entry.reps,
                                sets: entry.sets,
                                isPersonalRecord: index == 0 // First entry is most recent/best
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Exercise Templates View

struct ExerciseTemplatesView: View {
    let onSelectTemplate: (WorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: WorkoutTemplate.Category = .strength
    
    // Sample templates organized by category
    private var templates: [WorkoutTemplate.Category: [WorkoutTemplate]] {
        [
            .strength: [
                WorkoutTemplate(
                    id: UUID(),
                    name: "Upper Body Push",
                    exercises: [],
                    category: .strength,
                    estimatedDuration: 45,
                    difficulty: .intermediate
                ),
                WorkoutTemplate(
                    id: UUID(),
                    name: "Lower Body Power",
                    exercises: [],
                    category: .strength,
                    estimatedDuration: 50,
                    difficulty: .advanced
                )
            ],
            .cardio: [
                WorkoutTemplate(
                    id: UUID(),
                    name: "HIIT Blast",
                    exercises: [],
                    category: .cardio,
                    estimatedDuration: 20,
                    difficulty: .intermediate
                ),
                WorkoutTemplate(
                    id: UUID(),
                    name: "Endurance Run",
                    exercises: [],
                    category: .cardio,
                    estimatedDuration: 35,
                    difficulty: .beginner
                )
            ]
        ]
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
                    
                    Text("Exercise Templates")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Create New") {
                        // Create new template
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Category Selector
                HStack(spacing: 0) {
                    ForEach(WorkoutTemplate.Category.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            Text(category.rawValue.capitalized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedCategory == category ? .blue : .gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .background(
                            Rectangle()
                                .fill(selectedCategory == category ? .blue.opacity(0.05) : .clear)
                        )
                    }
                }
                .background(.ultraThinMaterial)
                
                // Templates List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let categoryTemplates = templates[selectedCategory] {
                            ForEach(categoryTemplates) { template in
                                WorkoutTemplateCard(
                                    template: template,
                                    onSelect: {
                                        onSelectTemplate(template)
                                        dismiss()
                                    }
                                )
                            }
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

// MARK: - Workout Template Card

struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
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
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                if let description = template.description {
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
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

// MARK: - Workout Summary Row

struct WorkoutSummaryRow: View {
    let workoutName: String
    let date: Date
    let duration: Int
    let exerciseCount: Int
    let totalVolume: Double
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Text(date, style: .date)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(duration) min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("\(exerciseCount) exercises")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalVolume)) lbs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Volume")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Entry Row

struct ExerciseEntryRow: View {
    let date: Date
    let weight: Int
    let reps: Int
    let sets: Int
    let isPersonalRecord: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date, style: .date)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(date, style: .time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                HStack(spacing: 8) {
                    Text("\(weight) lbs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("×")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(reps) reps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("\(sets) sets")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isPersonalRecord {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    
                    Text("PR")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            } else {
                Text("\(Int(Double(weight * reps * sets))) lbs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPersonalRecord ? .green.opacity(0.05) : Color(.systemGray6))
        )
    }
}
