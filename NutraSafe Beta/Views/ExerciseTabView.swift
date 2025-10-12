import SwiftUI
import Foundation

// MARK: - Workout Main Content View
struct WorkoutMainContent: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showingTemplates = false

    var body: some View {
        VStack(spacing: 0) {
            // Primary action button - Hevy style (only 2 taps)
            NavigationLink(destination: NewWorkoutView().environmentObject(workoutManager)) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Start Empty Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout in Progress")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Text(workoutManager.workoutName)
                        .font(.system(size: 20, weight: .bold))
                }

                Spacer()

                Text(workoutManager.workoutDurationFormatted)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }

            Divider()

            // Exercise Summary
            HStack {
                Label("\(workoutManager.exercises.count) exercises", systemImage: "dumbbell.fill")
                    .font(.system(size: 12))

                Spacer()

                Label("\(Int(workoutManager.totalVolume)) lbs", systemImage: "scalemass")
                    .font(.system(size: 12))
            }
            .foregroundColor(.secondary)

            // Continue Button
            NavigationLink(destination: NewWorkoutView().environmentObject(workoutManager)) {
                Text("Continue Workout")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
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
            VStack(spacing: 0) {
                // Header with tabs
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Text("Exercise")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .frame(height: 44, alignment: .center)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.9, green: 0.4, blue: 0.3),
                                        Color(red: 0.7, green: 0.3, blue: 0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Spacer()

                        Button(action: { showingSettings = true }) {
                            ZStack {
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .accessibilityLabel("Open exercise settings")
                    }

                    // Simple tab selector - Hevy style
                    HStack(spacing: 0) {
                        ForEach(ExerciseSubTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedExerciseSubTab = tab
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 16, weight: selectedExerciseSubTab == tab ? .semibold : .regular))
                                        .foregroundColor(selectedExerciseSubTab == tab ? .primary : .secondary)

                                    Rectangle()
                                        .fill(selectedExerciseSubTab == tab ? Color.blue : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Main Content
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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Quick Stat Item Component (AAA Modern Design)
struct QuickStatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), color.opacity(0)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)

                // Glassmorphic circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [color.opacity(0.5), color.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Sub-tab Selector (AAA Modern Design)
struct ExerciseSubTabSelector: View {
    @Binding var selectedTab: ExerciseTabView.ExerciseSubTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ExerciseTabView.ExerciseSubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 7) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(
                        selectedTab == tab ?
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        Group {
                            if selectedTab == tab {
                                ZStack {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.3, green: 0.5, blue: 1.0),
                                            Color(red: 0.5, green: 0.3, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )

                                    LinearGradient(
                                        colors: [.white.opacity(0.25), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.3), lineWidth: 1.5)
                                )
                                .shadow(color: Color(red: 0.4, green: 0.4, blue: 0.9).opacity(0.3), radius: 8, x: 0, y: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Exercise Quick Action Card (AAA Modern Design)
struct ExerciseQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    // Glow effect background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [color.opacity(0.4), color.opacity(0)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)

                    // Glassmorphic circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [color.opacity(0.6), color.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: color.opacity(0.25), radius: 12, x: 0, y: 6)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.hierarchical)
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(SpringyButtonStyle())
    }
}