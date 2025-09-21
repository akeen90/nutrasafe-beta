import SwiftUI
import Foundation

// MARK: - Workout History View

struct WorkoutHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Text("Workout History")
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
                
                // Placeholder for history list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Sample history items would go here
                        ForEach(0..<5) { index in
                            WorkoutHistoryCard(
                                workoutName: "Push Day",
                                date: Date(),
                                duration: 45 + (index * 5),
                                exercises: 6 - index,
                                volume: Double(1500 + (index * 200))
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

// MARK: - Exercise Workouts View

struct ExerciseWorkoutsView: View {
    let savedWorkouts: [WorkoutTemplate]
    let onStartWorkout: (WorkoutTemplate) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !savedWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Saved Workouts")
                                .font(.headline)
                                .padding(.horizontal, 16)
                            
                            Spacer()
                            
                            Button("View All") {
                                // Navigate to all workouts
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(savedWorkouts.prefix(5)) { workout in
                                    WorkoutTemplateQuickCard(
                                        template: workout,
                                        onStart: {
                                            onStartWorkout(workout)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No Saved Workouts")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Create and save your first workout template")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 32)
                }
            }
        }
    }
}

// MARK: - Exercise Stats View

struct ExerciseStatsView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Weekly Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("This Week")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(
                            title: "Workouts",
                            value: "4",
                            subtitle: "This week",
                            color: .blue,
                            icon: "dumbbell.fill"
                        )
                        
                        StatCard(
                            title: "Total Time",
                            value: "3.2h",
                            subtitle: "Active time",
                            color: .green,
                            icon: "clock"
                        )
                        
                        StatCard(
                            title: "Volume",
                            value: "18.5k",
                            subtitle: "Pounds lifted",
                            color: .orange,
                            icon: "scalemass"
                        )
                        
                        StatCard(
                            title: "Calories",
                            value: "1,240",
                            subtitle: "Burned",
                            color: .red,
                            icon: "flame.fill"
                        )
                    }
                    .padding(.horizontal, 16)
                }
                
                // Progress Charts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Progress")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                    
                    // Placeholder for charts
                    VStack(spacing: 16) {
                        ExerciseSummaryView(
                            exerciseName: "Bench Press",
                            currentWeight: 185,
                            previousWeight: 175,
                            bestSet: "185 lbs × 8 reps"
                        )
                        
                        ExerciseSummaryView(
                            exerciseName: "Squats",
                            currentWeight: 225,
                            previousWeight: 215,
                            bestSet: "225 lbs × 10 reps"
                        )
                        
                        ExerciseSummaryView(
                            exerciseName: "Deadlifts",
                            currentWeight: 275,
                            previousWeight: 265,
                            bestSet: "275 lbs × 5 reps"
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Workout History Card

struct WorkoutHistoryCard: View {
    let workoutName: String
    let date: Date
    let duration: Int
    let exercises: Int
    let volume: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(date, style: .date)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(duration) min")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(exercises) exercises")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Volume: \(Int(volume)) lbs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("View Details") {
                    // View workout details
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
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

// MARK: - Workout Template Quick Card

struct WorkoutTemplateQuickCard: View {
    let template: WorkoutTemplate
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            HStack {
                Text("\(template.exercises.count) exercises")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("\(template.estimatedDuration) min")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Start") {
                onStart()
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue)
            )
        }
        .padding(16)
        .frame(width: 160, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Stat Card

struct StatCard: View {
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

// MARK: - Exercise Summary View

struct ExerciseSummaryView: View {
    let exerciseName: String
    let currentWeight: Int
    let previousWeight: Int
    let bestSet: String
    
    private var progressPercentage: Double {
        guard previousWeight > 0 else { return 0 }
        return Double(currentWeight - previousWeight) / Double(previousWeight) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exerciseName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if progressPercentage > 0 {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                        
                        Text("+\(Int(progressPercentage))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    } else if progressPercentage < 0 {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text("\(Int(progressPercentage))%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "minus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("0%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("\(currentWeight) lbs")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best Set")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(bestSet)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
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