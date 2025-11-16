import SwiftUI
import Charts

struct FastingMainView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEditTimes = false
    @State private var showingEducation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.activeSession == nil {
                        IdleStateView(viewModel: viewModel)
                    } else {
                        ActiveSessionView(viewModel: viewModel)
                    }
                    
                    if let analytics = viewModel.analytics {
                        QuickStatsView(analytics: analytics)
                    }
                    
                    if let recentSessions = viewModel.recentSessions.first {
                        LastSessionCard(session: recentSessions)
                    }

                    // Bottom spacer for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .navigationTitle("Fasting")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        FastingPlanManagementView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "clock.badge.checkmark")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        FastingInsightsView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .sheet(isPresented: $showingEducation) {
                FastingEducationView()
            }
            .sheet(isPresented: $showingEditTimes) {
                if let session = viewModel.activeSession {
                    EditSessionTimesView(viewModel: viewModel, session: session)
                }
            }
        }
    }
}

struct IdleStateView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEducation = false
    @State private var showingPlanCreation = false

    var body: some View {
        VStack(spacing: 24) {
            // Welcome Card
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text(viewModel.activePlan == nil ? "Create Your First Plan" : "Ready to Begin")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(viewModel.activePlan == nil ?
                     "Set up a fasting schedule that fits your lifestyle" :
                     "Start your fasting journey with a personalized plan")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)

            // Primary Action Button
            if viewModel.activePlan == nil {
                // No plan yet - show plan creation button
                Button {
                    showingPlanCreation = true
                } label: {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                        Text("Create Fasting Plan")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                // Has plan - show start/resume button
                Button {
                    Task {
                        await viewModel.startFastingSession()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(viewModel.recentSessions.isEmpty ? "Start Fasting" : "Resume Fasting")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }

            // Secondary Action - Education
            Button {
                showingEducation = true
            } label: {
                HStack {
                    Image(systemName: "graduationcap.fill")
                    Text("Learn About Fasting")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Active Plan Info
            if let plan = viewModel.activePlan {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundColor(.green)
                        Text("Your Active Plan")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(plan.durationDisplay)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if !plan.daysOfWeek.isEmpty {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(plan.daysOfWeek.count) days/week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if let nextDate = plan.nextScheduledDate {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                            Text("Next: \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .sheet(isPresented: $showingEducation) {
            FastingEducationView()
        }
        .sheet(isPresented: $showingPlanCreation) {
            FastingPlanCreationView(viewModel: viewModel)
        }
    }
}

struct ActiveSessionView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEditTimes = false

    var body: some View {
        VStack(spacing: 20) {
            // Progress Ring Card
            ProgressRingCard(viewModel: viewModel)

            // Phase Timeline Card
            PhaseTimelineCard(viewModel: viewModel)

            // Current Phase Info Card
            CurrentPhaseCard(viewModel: viewModel)

            // Action Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.endFastingSession()
                    }
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("End Fast")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                HStack(spacing: 12) {
                    Button {
                        showingEditTimes = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Times")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await viewModel.skipCurrentSession()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Today")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 30) // Add space above tab bar
        }
        .sheet(isPresented: $showingEditTimes) {
            if let session = viewModel.activeSession {
                EditSessionTimesView(viewModel: viewModel, session: session)
            }
        }
    }
}

struct ProgressRingCard: View {
    @ObservedObject var viewModel: FastingViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.currentProgress))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.currentProgress)
                
                VStack(spacing: 4) {
                    Text(viewModel.currentElapsedTime)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    Text("of \(viewModel.activeSession?.targetDurationHours ?? 0)h")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.currentProgress < 1.0 {
                Text(viewModel.nextMilestone)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Target achieved! 🎉")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PhaseTimelineCard: View {
    @ObservedObject var viewModel: FastingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                Text("Fasting Timeline")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                ForEach(FastingPhase.allCases, id: \.self) { phase in
                    PhaseRow(
                        phase: phase,
                        isReached: viewModel.activeSession?.phasesReached.contains(phase) ?? false,
                        isCurrent: viewModel.currentPhase == phase,
                        elapsedHours: viewModel.activeSession?.actualDurationHours ?? 0
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PhaseRow: View {
    let phase: FastingPhase
    let isReached: Bool
    let isCurrent: Bool
    let elapsedHours: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                if isCurrent {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }
            
            // Phase info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(phase.displayName)
                        .font(.subheadline)
                        .fontWeight(isCurrent ? .semibold : .regular)
                    
                    if isCurrent {
                        Text("• Active")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time info
            if isReached {
                Text("✓")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if isCurrent {
                Text("\(Int(Double(phase.timeRange.upperBound) - elapsedHours))h to next")
                    .font(.caption)
                    .foregroundColor(.blue)
            } else {
                Text("\(phase.timeRange.lowerBound)h+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(isReached || isCurrent ? 1.0 : 0.6)
    }
    
    private var statusColor: Color {
        if isReached {
            return .green
        } else if isCurrent {
            return .blue
        } else {
            return .gray
        }
    }
}

struct CurrentPhaseCard: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView

            if let phase = viewModel.currentPhase {
                phaseInfoView(for: phase)
            }

            motivationalMessageView
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(.orange)
            Text("Current Phase")
                .font(.headline)
        }
    }

    private func phaseInfoView(for phase: FastingPhase) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(phase.displayName)
                .font(.title3)
                .fontWeight(.semibold)

            Text(phase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let nextPhase = nextPhase(after: phase) {
                nextPhaseIndicator(nextPhase)
            }
        }
    }

    private func nextPhaseIndicator(_ nextPhase: FastingPhase) -> some View {
        let elapsedHours = viewModel.activeSession?.actualDurationHours ?? 0
        let hoursToNext = Int(Double(nextPhase.timeRange.lowerBound) - elapsedHours)

        return HStack {
            Image(systemName: "arrow.forward.circle")
                .font(.caption)
            Text("Next: \(nextPhase.displayName) in \(hoursToNext)h")
                .font(.caption)
        }
        .foregroundColor(.blue)
    }

    private var motivationalMessageView: some View {
        Text(viewModel.motivationalMessage)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .italic()
            .padding(.top, 8)
    }

    private func nextPhase(after phase: FastingPhase) -> FastingPhase? {
        let allPhases = FastingPhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: phase),
              currentIndex < allPhases.count - 1 else { return nil }
        return allPhases[currentIndex + 1]
    }
}

struct QuickStatsView: View {
    let analytics: FastingAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.indigo)
                Text("Your Progress")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(analytics.totalFastsCompleted)",
                    label: "Completed",
                    color: .green
                )
                
                StatItem(
                    icon: "percent",
                    value: String(format: "%.0f%%", analytics.averageCompletionPercentage),
                    label: "Avg Success",
                    color: .blue
                )
                
                StatItem(
                    icon: "clock.fill",
                    value: analytics.averageDurationFormatted,
                    label: "Avg Duration",
                    color: .purple
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.indigo.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LastSessionCard: View {
    let session: FastingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.teal)
                Text("Last Session")
                    .font(.headline)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.completionStatus.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(for: session.completionStatus))
                    
                    Text("\(session.actualDurationHours, specifier: "%.1f")h of \(session.targetDurationHours)h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let notes = session.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.teal.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.teal.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func statusColor(for status: FastingCompletionStatus) -> Color {
        switch status {
        case .completed, .overGoal:
            return .green
        case .earlyEnd:
            return .orange
        case .failed:
            return .red
        case .skipped:
            return .gray
        case .active:
            return .blue
        }
    }
}


struct EditSessionTimesView: View {
    @ObservedObject var viewModel: FastingViewModel
    let session: FastingSession
    @Environment(\.dismiss) private var dismiss
    
    @State private var startTime: Date
    @State private var endTime: Date?
    @State private var isActive: Bool
    
    init(viewModel: FastingViewModel, session: FastingSession) {
        self.viewModel = viewModel
        self.session = session
        self._startTime = State(initialValue: session.startTime)
        self._endTime = State(initialValue: session.endTime)
        self._isActive = State(initialValue: session.endTime == nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Session Times")) {
                    DatePicker("Start Time", selection: $startTime)
                    
                    Toggle("Session Active", isOn: $isActive)
                    
                    if !isActive {
                        DatePicker("End Time", selection: Binding(
                            get: { endTime ?? Date() },
                            set: { endTime = $0 }
                        ))
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.editSessionTimes(
                                startTime: startTime,
                                endTime: isActive ? nil : endTime
                            )
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Edit Session Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FastingMainView(viewModel: FastingViewModel.preview)
    }
}