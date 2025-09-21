import SwiftUI
import Foundation

// MARK: - Workout Main Content View
struct WorkoutMainContent: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingTemplates = false

    var body: some View {
        VStack(spacing: 20) {
            if workoutManager.isWorkoutActive {
                // Active Workout Card
                ActiveWorkoutCard()
                    .environmentObject(workoutManager)
            } else {
                // No Active Workout - Enhanced Design
                VStack(spacing: 0) {
                    // Hero Section
                    VStack(spacing: 24) {
                        // Animated Icon with Gradient Background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 48, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(spacing: 8) {
                            Text("Ready to Get Strong?")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)

                            Text("Track your workouts, build strength,\nand achieve your fitness goals")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 32)

                    Spacer()

                    // Action Buttons - Modern Design
                    VStack(spacing: 16) {
                        // Primary Action
                        Button(action: {
                            workoutManager.startWorkout()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Start Empty Workout")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(SpringyButtonStyle())

                        // Secondary Action
                        Button(action: { showingTemplates = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Browse Templates")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(SpringyButtonStyle())

                        // Quick Stats Row
                        HStack(spacing: 32) {
                            QuickStatItem(icon: "flame.fill", title: "Calories", value: "0", color: .orange)
                            QuickStatItem(icon: "timer", title: "Duration", value: "0:00", color: .green)
                            QuickStatItem(icon: "dumbbell.fill", title: "Exercises", value: "0", color: .purple)
                        }
                        .padding(.top, 24)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingTemplates) {
            WorkoutTemplatesView(onSelectTemplate: { _ in
                showingTemplates = false
            })
                .environmentObject(workoutManager)
        }
    }
}

// MARK: - Active Workout Card
struct ActiveWorkoutCard: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(workoutManager.workoutName)
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                Text(workoutManager.workoutDurationFormatted)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }

            Divider()

            // Exercise Summary
            HStack {
                Label("\(workoutManager.exercises.count) exercises", systemImage: "dumbbell.fill")
                    .font(.caption)

                Spacer()

                Label("\(Int(workoutManager.totalVolume)) lbs", systemImage: "scalemass")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Continue Button
            NavigationLink(destination: NewWorkoutView().environmentObject(workoutManager)) {
                Text("Continue Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Exercise History, Stats, and other components are defined in ExerciseDetailViews.swift

// MARK: - Workout History List
struct WorkoutHistoryList: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout History")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Your workout history will appear here")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Exercise Stats Display
struct ExerciseStatsDisplay: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Exercise Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Your exercise statistics will appear here")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ExerciseTabView: View {
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var selectedExerciseSubTab: ExerciseSubTab = .workout
    @EnvironmentObject var workoutManager: WorkoutManager

    enum ExerciseSubTab: String, CaseIterable {
        case workout = "Workout"
        case history = "History"
        case stats = "Stats"

        var icon: String {
            switch self {
            case .workout: return "dumbbell.fill"
            case .history: return "clock.arrow.circlepath"
            case .stats: return "chart.bar.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            // If there's an active workout, show it directly
            if workoutManager.isWorkoutActive {
                NewWorkoutView()
                    .environmentObject(workoutManager)
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Exercise")
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

                    // Enhanced Sub-tab Picker
                    HStack(spacing: 4) {
                        ForEach(ExerciseSubTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedExerciseSubTab = tab
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 18, weight: .semibold))

                                    Text(tab.rawValue)
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(selectedExerciseSubTab == tab ? .white : .primary)
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedExerciseSubTab == tab ? Color.blue : Color.clear)
                                        .shadow(color: selectedExerciseSubTab == tab ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
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
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Main Content based on selected sub-tab
                    ScrollView {
                        VStack(spacing: 16) {
                            switch selectedExerciseSubTab {
                            case .workout:
                                WorkoutMainContent()
                                    .environmentObject(workoutManager)
                            case .history:
                                WorkoutHistoryList()
                            case .stats:
                                ExerciseStatsDisplay()
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Quick Stat Item Component
struct QuickStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}