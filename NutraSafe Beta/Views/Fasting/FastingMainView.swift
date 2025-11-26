import SwiftUI
import Charts

struct FastingMainView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEditTimes = false
    @State private var showingEducation = false
    @State private var showingCitations = false
    @State private var showingActionSheet = false
    @State private var actionSheetSession: FastingSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.activeSession == nil {
                        IdleStateView(viewModel: viewModel)
                    } else {
                        ActiveSessionView(viewModel: viewModel)
                    }

                    // Last Session card (only show when no active session)
                    if viewModel.activeSession == nil, let lastSession = viewModel.recentSessions.first {
                        LastSessionCard(session: lastSession)
                    }

                    // Bottom spacer for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .navigationTitle("Fasting")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingCitations = true
                    } label: {
                        Image(systemName: "doc.text.fill")
                    }
                }

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
            .sheet(isPresented: $showingCitations) {
                FastingCitationsView()
            }
            .sheet(isPresented: $showingEditTimes) {
                if let session = viewModel.activeSession {
                    EditSessionTimesView(viewModel: viewModel, session: session)
                }
            }
            .sheet(isPresented: $showingActionSheet) {
                if let session = actionSheetSession {
                    FastingActionSheet(
                        session: session,
                        onSnooze: { minutes in
                            Task {
                                await viewModel.snoozeSession(session, minutes: minutes)
                            }
                        },
                        onSkip: {
                            Task {
                                await viewModel.skipSession(session)
                            }
                        },
                        onStartNow: {
                            Task {
                                await viewModel.startSessionNow(session)
                            }
                        },
                        onAdjustTime: { newStartTime in
                            Task {
                                await viewModel.adjustSessionStartTime(session, newTime: newStartTime)
                            }
                        },
                        onDismiss: {
                            showingActionSheet = false
                            actionSheetSession = nil
                        }
                    )
                    .presentationDetents([.large])
                }
            }
            .onAppear {
                Task {
                    await viewModel.refreshActivePlan()
                    checkForMissedScheduledFast()
                }
            }
        }
    }

    // Check if a fast was scheduled but user hasn't started yet
    private func checkForMissedScheduledFast() {
        guard let plan = viewModel.activePlan,
              plan.regimeActive,
              viewModel.activeSession == nil else { return }

        // Check if we're past a scheduled fast start time
        if let nextFastStart = plan.nextScheduledFastingWindow(),
           nextFastStart < Date(),
           abs(nextFastStart.timeIntervalSinceNow) < 7200 { // Within 2 hours of scheduled start

            // Show action sheet
            let missedSession = FastingManager.createSession(
                userId: viewModel.userId,
                plan: plan,
                targetDurationHours: plan.durationHours,
                startTime: nextFastStart
            )

            actionSheetSession = missedSession
            showingActionSheet = true
        }
    }
}

struct IdleStateView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEducation = false
    @State private var showingPlanCreation = false

    var body: some View {
        if let plan = viewModel.activePlan {
            // Has active plan - show Plan Dashboard
            PlanDashboardView(viewModel: viewModel, plan: plan)
        } else {
            // No plan - show onboarding
            NoPlanView(viewModel: viewModel, showingEducation: $showingEducation, showingPlanCreation: $showingPlanCreation)
        }
    }
}

// MARK: - No Plan View
struct NoPlanView: View {
    @ObservedObject var viewModel: FastingViewModel
    @Binding var showingEducation: Bool
    @Binding var showingPlanCreation: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Welcome Card
            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Create Your First Plan")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Set up a fasting schedule that fits your lifestyle")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(16)

            // Create Plan Button
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

            // Education Button
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
        }
        .sheet(isPresented: $showingEducation) {
            FastingEducationView()
        }
        .sheet(isPresented: $showingPlanCreation) {
            FastingPlanCreationView(viewModel: viewModel)
        }
    }
}

// MARK: - Plan Dashboard View
struct PlanDashboardView: View {
    @ObservedObject var viewModel: FastingViewModel
    let plan: FastingPlan
    @State private var showRegimeDetails = false
    @State private var showStartTimeChoice = false
    @State private var showFastSettings = false
    @State private var scheduledStartTime: Date?
    @State private var showSnoozePicker = false
    @State private var snoozeUntilTime = Date()
    @State private var selectedWeek: WeekSummary?
    @State private var showWeekDetail = false
    @State private var showingCitations = false

    // PERFORMANCE: Cache average duration to prevent redundant calculations on every render
    // Pattern from Clay's production app: move expensive operations to cached state
    @State private var cachedAverageDuration: Double = 0

    // Use all recent sessions (since typically only one plan is active at a time)
    private var planSessions: [FastingSession] {
        viewModel.recentSessions
    }

    // Plan statistics
    private var totalFasts: Int {
        planSessions.count
    }

    private var completedFasts: Int {
        planSessions.filter { $0.completionStatus == .completed || $0.completionStatus == .overGoal }.count
    }

    private var completionRate: Int {
        guard totalFasts > 0 else { return 0 }
        return Int((Double(completedFasts) / Double(totalFasts)) * 100)
    }

    private var averageDuration: Double { cachedAverageDuration }

    // Update cached average duration when data changes
    private func updateCachedAverageDuration() {
        guard !planSessions.isEmpty else {
            cachedAverageDuration = 0
            return
        }
        let total = planSessions.reduce(0.0) { $0 + $1.actualDurationHours }
        cachedAverageDuration = total / Double(planSessions.count)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Plan Header Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundColor(.green)
                    Text(plan.displayName)
                        .font(.headline)
                    Spacer()
                }

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
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Stats Grid
            HStack(spacing: 12) {
                FastingStatCard(title: "Total Fasts", value: "\(totalFasts)", icon: "calendar")
                FastingStatCard(title: "Completed", value: "\(completionRate)%", icon: "checkmark.circle.fill")
                FastingStatCard(title: "Avg Duration", value: String(format: "%.1fh", averageDuration), icon: "clock.fill")
            }

            // Regime Control Button
            if viewModel.isRegimeActive {
                // Show regime state info
                VStack(spacing: 12) {
                    Button {
                        showRegimeDetails = true
                    } label: {
                        HStack {
                            Image(systemName: "bolt.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Regime Active")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("Tap for timer & stages")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Show current state
                    switch viewModel.currentRegimeState {
                    case .fasting(let started, let ends):
                        VStack(spacing: 12) {
                            // Snooze indicator (if snoozed)
                            if viewModel.isRegimeSnoozed, let snoozeUntil = viewModel.regimeSnoozedUntil {
                                HStack {
                                    Image(systemName: "bell.zzz.fill")
                                        .foregroundColor(.orange)
                                    Text("Snoozed until \(snoozeUntil.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.15))
                                .cornerRadius(8)
                            }

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Currently Fasting")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Ends: \(ends.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(viewModel.timeUntilFastEnds)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)

                            // Snooze and Skip buttons
                            HStack(spacing: 12) {
                                Button {
                                    // Initialize with current time TODAY (not 30 min in future which might roll to tomorrow)
                                    snoozeUntilTime = Date()
                                    showSnoozePicker = true
                                } label: {
                                    HStack {
                                        Image(systemName: "bell.zzz.fill")
                                        Text("Snooze Fast")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    Task {
                                        await viewModel.skipCurrentRegimeFast()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "forward.fill")
                                        Text("Skip Fast")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                    case .eating(let nextFastStart):
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Eating Window")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                // Show snooze time if snoozed, otherwise next scheduled fast
                                if viewModel.isRegimeSnoozed, let snoozeUntil = viewModel.regimeSnoozedUntil {
                                    Text("Resume fasting: \(snoozeUntil.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Next fast: \(nextFastStart.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(viewModel.timeUntilNextFast)
                                .font(.title3)
                                .fontWeight(.bold)
                                .monospacedDigit()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)

                    case .inactive:
                        EmptyView()
                    }

                    // Stop Regime Button
                    Button {
                        Task {
                            await viewModel.stopRegime()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Regime")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // View Sources Button (always visible)
                    Button {
                        showingCitations = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("View Sources")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                // Start Regime and Fast Settings Buttons
                VStack(spacing: 12) {
                    // Start Regime Button
                    Button {
                        // Check if past today's start time
                        let (isPast, startTime) = viewModel.checkIfPastTodaysStartTime()
                        if isPast {
                            scheduledStartTime = startTime
                            showStartTimeChoice = true
                        } else {
                            Task {
                                await viewModel.startRegime()
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bolt.circle.fill")
                            Text("Start Regime")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Fast Settings Button
                    Button {
                        showFastSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Fast Settings")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Weekly History
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Weeks")
                        .font(.headline)
                    Spacer()
                    if totalFasts > 0 {
                        Text("\(totalFasts) total fasts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                let weeks = viewModel.weekSummaries.prefix(5)

                if weeks.isEmpty {
                    Text("No fasts recorded yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(weeks)) { week in
                            WeekSummaryCard(week: week)
                                .onTapGesture {
                                    selectedWeek = week
                                    showWeekDetail = true
                                }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRegimeDetails) {
            RegimeDetailView(viewModel: viewModel, plan: plan)
        }
        .sheet(isPresented: $showFastSettings) {
            FastingPlanCreationView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCitations) {
            FastingCitationsView()
        }
        .sheet(isPresented: $showSnoozePicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Resume fasting at:")
                        .font(.headline)
                        .padding(.top)

                    DatePicker(
                        "Resume Time",
                        selection: $snoozeUntilTime,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()

                    Text(snoozeUntilTime < Date() ?
                        "Will snooze until tomorrow at \(snoozeUntilTime.formatted(date: .omitted, time: .shortened))" :
                        "Will snooze until today at \(snoozeUntilTime.formatted(date: .omitted, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        Task {
                            let now = Date()
                            let calendar = Calendar.current

                            // Extract hour and minute from the picker
                            let components = calendar.dateComponents([.hour, .minute], from: snoozeUntilTime)

                            // Build a date for TODAY at the selected time
                            guard let todayAtSelectedTime = calendar.date(
                                bySettingHour: components.hour ?? 0,
                                minute: components.minute ?? 0,
                                second: 0,
                                of: now
                            ) else {
                                print("❌ Failed to create snooze time")
                                showSnoozePicker = false
                                return
                            }

                            print("🕐 Snooze Confirm Debug:")
                            print("   Current time: \(now.formatted(date: .abbreviated, time: .complete))")
                            print("   Selected time components: \(components.hour ?? 0):\(components.minute ?? 0)")
                            print("   Today at selected time: \(todayAtSelectedTime.formatted(date: .abbreviated, time: .complete))")

                            // If the time is in the past, move to tomorrow
                            var finalSnoozeTime = todayAtSelectedTime
                            if todayAtSelectedTime <= now {
                                print("   ⚠️ Selected time has passed today, moving to tomorrow")
                                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayAtSelectedTime) {
                                    finalSnoozeTime = tomorrow
                                    print("   ✅ Adjusted to: \(finalSnoozeTime.formatted(date: .abbreviated, time: .complete))")
                                }
                            } else {
                                print("   ✅ Selected time is later today")
                            }

                            print("   Final snooze time: \(finalSnoozeTime.formatted(date: .abbreviated, time: .complete))")
                            print("   Time until snooze: \(finalSnoozeTime.timeIntervalSince(now)) seconds")

                            await viewModel.snoozeCurrentRegimeFast(until: finalSnoozeTime)
                            showSnoozePicker = false
                        }
                    } label: {
                        Text("Confirm Snooze")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .navigationTitle("Snooze Fast")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showSnoozePicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showWeekDetail) {
            if let week = selectedWeek {
                WeekDetailView(week: week, viewModel: viewModel)
            }
        }
        .confirmationDialog(
            "Start Fasting",
            isPresented: $showStartTimeChoice,
            titleVisibility: .visible
        ) {
            Button("Start from now") {
                Task {
                    await viewModel.startRegime(startFromNow: true)
                }
            }

            Button("Start from scheduled time (\(scheduledStartTime?.formatted(date: .omitted, time: .shortened) ?? ""))") {
                Task {
                    await viewModel.startRegime(startFromNow: false)
                }
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You're starting after your scheduled fast time. Would you like to start from now or from your scheduled time?")
        }
        .onAppear {
            // PERFORMANCE: Initialize cached average duration on first appearance
            updateCachedAverageDuration()
        }
        // PERFORMANCE: Update cached average duration only when sessions change
        .onChange(of: viewModel.recentSessions) { _ in updateCachedAverageDuration() }
    }
}

// MARK: - Regime Detail View
struct RegimeDetailView: View {
    @ObservedObject var viewModel: FastingViewModel
    let plan: FastingPlan
    @Environment(\.dismiss) private var dismiss
    @State private var showingCitations = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer Ring (simplified for regime view)
                    RegimeTimerCard(viewModel: viewModel)

                    // Phase Timeline
                    RegimePhaseTimeline(viewModel: viewModel)

                    // Current state info
                    RegimeStateInfo(viewModel: viewModel)

                    // View Sources Button
                    Button {
                        showingCitations = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("View Sources")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Fasting Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCitations) {
                FastingCitationsView()
            }
        }
    }
}

// MARK: - Regime Timer Card
struct RegimeTimerCard: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Current state indicator
            switch viewModel.currentRegimeState {
            case .fasting(_, let ends):
                VStack(spacing: 12) {
                    Text("Currently Fasting")
                        .font(.headline)
                        .foregroundColor(.blue)

                    Text(viewModel.timeUntilFastEnds)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.blue)

                    Text("until eating window")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Ends at \(ends.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            case .eating(let nextFastStart):
                VStack(spacing: 12) {
                    Text("Eating Window")
                        .font(.headline)
                        .foregroundColor(.green)

                    Text(viewModel.timeUntilNextFast)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.green)

                    // Show snooze text if snoozed, otherwise regular text
                    if viewModel.isRegimeSnoozed {
                        Text("until fasting resumes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("until next fast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Show snooze time if snoozed, otherwise next scheduled fast
                    if viewModel.isRegimeSnoozed, let snoozeUntil = viewModel.regimeSnoozedUntil {
                        Text("Resumes at \(snoozeUntil.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Fast starts at \(nextFastStart.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            case .inactive:
                Text("Regime not active")
                    .font(.headline)
                    .foregroundColor(.secondary)
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

// MARK: - Regime Phase Timeline
struct RegimePhaseTimeline: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                Text("Fasting Stages")
                    .font(.headline)
            }

            VStack(spacing: 8) {
                ForEach(FastingPhase.allCases, id: \.self) { phase in
                    RegimePhaseRow(phase: phase, viewModel: viewModel)
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

// MARK: - Regime Phase Row
struct RegimePhaseRow: View {
    let phase: FastingPhase
    @ObservedObject var viewModel: FastingViewModel

    private var isCurrentPhase: Bool {
        guard case .fasting = viewModel.currentRegimeState else { return false }
        // Calculate current fasting hours from regime state
        let hoursInFast = viewModel.hoursIntoCurrentFast
        return phase.timeRange.contains(Int(hoursInFast)) ||
               (hoursInFast >= Double(phase.timeRange.lowerBound) && hoursInFast < Double(phase.timeRange.upperBound))
    }

    private var isPastPhase: Bool {
        guard case .fasting = viewModel.currentRegimeState else { return false }
        let hoursInFast = viewModel.hoursIntoCurrentFast
        return hoursInFast >= Double(phase.timeRange.upperBound)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            // Phase info
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(.subheadline)
                    .fontWeight(isCurrentPhase ? .semibold : .regular)
                    .foregroundColor(isCurrentPhase ? .primary : .secondary)

                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Time range
            Text(phase.timeRange.upperBound == Int.max
                 ? "\(phase.timeRange.lowerBound)h+"
                 : "\(phase.timeRange.lowerBound)-\(phase.timeRange.upperBound)h")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .opacity(isPastPhase || isCurrentPhase ? 1.0 : 0.6)
    }

    private var statusColor: Color {
        if isPastPhase {
            return .green
        } else if isCurrentPhase {
            return .blue
        } else {
            return .gray
        }
    }
}

// MARK: - Regime State Info
struct RegimeStateInfo: View {
    @ObservedObject var viewModel: FastingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("About Your Regime")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                if case .fasting(let started, _) = viewModel.currentRegimeState {
                    Text("Fast started: \(started.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let plan = viewModel.activePlan {
                        Text("Target: \(plan.durationHours)h fast / \(24 - plan.durationHours)h eating window")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if case .eating = viewModel.currentRegimeState {
                    Text("Enjoy your eating window!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let plan = viewModel.activePlan {
                        Text("Plan: \(plan.durationHours):\(24 - plan.durationHours) (\(plan.displayName))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
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
}

// MARK: - Fasting Stat Card Component
struct FastingStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Session History Row Component
struct SessionHistoryRow: View {
    let session: FastingSession

    private var statusColor: Color {
        switch session.completionStatus {
        case .completed: return .green
        case .overGoal: return .blue
        case .earlyEnd: return .orange
        case .active: return .purple
        case .failed, .skipped: return .gray
        }
    }

    private var statusText: String {
        switch session.completionStatus {
        case .completed: return "Completed"
        case .overGoal: return "Over Goal"
        case .earlyEnd: return "Early End"
        case .active: return "Active"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "In Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(String(format: "%.1f hours", session.actualDurationHours))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ActiveSessionView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingEditTimes = false
    @State private var showingEarlyEndModal = false
    @State private var showingEndRegimeAlert = false
    @State private var showingCitations = false
    @State private var endedSession: FastingSession?
    @State private var successMessage: String?
    @State private var showingSuccessMessage = false

    var body: some View {
        VStack(spacing: 20) {
            // Progress Ring Card
            ProgressRingCard(viewModel: viewModel)

            // Phase Timeline Card
            PhaseTimelineCard(viewModel: viewModel)

            // Current Phase Info Card
            CurrentPhaseCard(viewModel: viewModel)

            // View Sources Button
            Button {
                showingCitations = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                    Text("View Sources")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Secondary Action Buttons
            VStack(spacing: 12) {
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
                        if let session = viewModel.activeSession {
                            Task {
                                await viewModel.snoozeSession(session, minutes: 30)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.zzz.fill")
                            Text("Snooze 30m")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.skipCurrentSession()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "forward.fill")
                            Text("Skip Fast")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                        .frame(maxWidth: .infinity)
                }

                // End Fast for the Day Button
                Button {
                    Task {
                        if let session = await viewModel.endFastingSession() {
                            // Check completion status and show appropriate UI
                            if session.completionStatus == .earlyEnd || session.attemptType == .warmup {
                                // Show early-end modal with motivational message
                                endedSession = session
                                showingEarlyEndModal = true
                            } else {
                                // Show success message for completed fasts
                                successMessage = "Fast completed successfully!"
                                showingSuccessMessage = true
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("End Fast for the Day")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // End Fasting Regime Button
                Button {
                    showingEndRegimeAlert = true
                } label: {
                    HStack {
                        Image(systemName: "stop.circle.fill")
                        Text("End Fasting Regime")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 30) // Add space above tab bar
        }
        .sheet(isPresented: $showingEditTimes) {
            if let session = viewModel.activeSession {
                EditSessionTimesView(viewModel: viewModel, session: session)
            }
        }
        .sheet(isPresented: $showingEarlyEndModal) {
            if let session = endedSession {
                EarlyEndModal(viewModel: viewModel, session: session)
            }
        }
        .sheet(isPresented: $showingCitations) {
            FastingCitationsView()
        }
        .alert("End Fasting Regime?", isPresented: $showingEndRegimeAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Regime", role: .destructive) {
                Task {
                    await viewModel.endFastingRegime()
                }
            }
        } message: {
            Text("This will end your current fast and deactivate your fasting plan. You'll need to create or activate a plan to continue fasting.")
        }
        .alert("Success", isPresented: $showingSuccessMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = successMessage {
                Text(message)
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
                
                VStack(spacing: 8) {
                    // Time IN fast (current)
                    VStack(spacing: 2) {
                        Text("Time Fasting")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(viewModel.currentElapsedTime)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        Text("of \(viewModel.activeSession?.targetDurationHours ?? 0)h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Divider
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 1)

                    // Time OUT of fast (previous eating window)
                    VStack(spacing: 2) {
                        Text("Eating Window")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        Text(viewModel.previousEatingWindowDuration)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.green)
                    }
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

// MARK: - Week Summary Card
struct WeekSummaryCard: View {
    let week: WeekSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: week.isCurrentWeek ? "calendar.badge.clock" : "calendar")
                    .foregroundColor(.purple)
                Text(week.dateRangeText)
                    .font(.headline)

                if week.isCurrentWeek {
                    Spacer()
                    Text("This Week")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(week.totalFasts)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    Text("Total Fasts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if week.totalFasts > 0 {
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(week.completedCount)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if week.skippedCount > 0 {
                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(week.skippedCount)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            Text("Skipped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if week.averageDuration > 0 {
                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(week.averageDuration, specifier: "%.1f")h")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("Avg Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if week.totalFasts == 0 {
                Text("No fasts recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

// MARK: - Week Detail View
struct WeekDetailView: View {
    let week: WeekSummary
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss

    // Generate dates for each day of the week (Mon-Sun)
    private var weekDays: [(date: Date, dayName: String, dayDate: String)] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.weekStart) else { return nil }
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM"
            return (date: date, dayName: dayFormatter.string(from: date), dayDate: dateFormatter.string(from: date))
        }
    }

    // Get sessions for a specific date
    private func sessionsForDate(_ date: Date) -> [FastingSession] {
        let calendar = Calendar.current
        return viewModel.recentSessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }

    // Get the best session for a day (longest completed, or just longest)
    private func bestSessionForDate(_ date: Date) -> FastingSession? {
        let sessions = sessionsForDate(date)
        // Prefer completed sessions, then longest duration
        let completed = sessions.filter { $0.completionStatus == .completed || $0.completionStatus == .overGoal }
        if let best = completed.max(by: { $0.actualDurationHours < $1.actualDurationHours }) {
            return best
        }
        // Otherwise return the longest session
        return sessions.max(by: { $0.actualDurationHours < $1.actualDurationHours })
    }

    var body: some View {
        NavigationStack {
            List {
                // Week Summary Header Section
                Section {
                    VStack(spacing: 12) {
                        Text(week.dateRangeText)
                            .font(.title2)
                            .fontWeight(.bold)

                        if week.isCurrentWeek {
                            Text("This Week")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.15))
                                .cornerRadius(8)
                        }

                        // Summary Stats
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(week.totalFasts)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                Text("Fasts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if week.totalFasts > 0 {
                                VStack {
                                    Text("\(week.completedCount)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Text("Completed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if week.averageDuration > 0 {
                                    VStack {
                                        Text("\(week.averageDuration, specifier: "%.1f")h")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("Average")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Daily Breakdown Section - One row per day
                Section(header: Text("Daily Breakdown")) {
                    ForEach(weekDays, id: \.date) { day in
                        let bestSession = bestSessionForDate(day.date)
                        let allSessions = sessionsForDate(day.date)

                        DaySummaryRow(
                            dayName: day.dayName,
                            dayDate: day.dayDate,
                            bestSession: bestSession,
                            totalSessions: allSessions.count,
                            onClear: bestSession != nil ? {
                                Task {
                                    // Clear all sessions for this day
                                    for session in allSessions {
                                        await viewModel.clearSession(session)
                                    }
                                }
                            } : nil
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Week Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Day Summary Row (one row per day)
struct DaySummaryRow: View {
    let dayName: String
    let dayDate: String
    let bestSession: FastingSession?
    let totalSessions: Int
    var onClear: (() -> Void)?

    var body: some View {
        HStack {
            // Day info
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(dayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status display
            if let session = bestSession {
                HStack(spacing: 6) {
                    if session.skipped {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.orange)
                        Text("Skipped")
                            .foregroundColor(.orange)
                    } else if session.actualDurationHours == 0 {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.gray)
                        Text("Cleared")
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: statusIcon(for: session.completionStatus))
                            .foregroundColor(statusColor(for: session.completionStatus))
                        // Show actual/target format e.g. "18/18h"
                        let actual = Int(session.actualDurationHours.rounded())
                        let target = session.targetDurationHours
                        Text("\(actual)/\(target)h")
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor(for: session.completionStatus))
                    }
                }
                .font(.subheadline)
            } else {
                Text("No fast")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if onClear != nil {
                Button(role: .destructive) {
                    onClear?()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                }
                .tint(.orange)
            }
        }
    }

    private func statusIcon(for status: FastingCompletionStatus) -> String {
        switch status {
        case .completed, .overGoal: return "checkmark.circle.fill"
        case .earlyEnd: return "exclamationmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "moon.zzz.fill"
        case .active: return "clock.fill"
        }
    }

    private func statusColor(for status: FastingCompletionStatus) -> Color {
        switch status {
        case .completed, .overGoal: return .green
        case .earlyEnd: return .orange
        case .failed: return .red
        case .skipped: return .gray
        case .active: return .blue
        }
    }
}

// MARK: - Day Session Row
struct DaySessionRow: View {
    let weekday: Int // 1 = Sunday, 2 = Monday, etc.
    let sessions: [FastingSession]
    let weekStart: Date
    var onClearSession: ((FastingSession) -> Void)?

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name

        // Calculate the actual date for this weekday
        let calendar = Calendar.current
        let daysToAdd = weekday == 1 ? 6 : (weekday - 2) // Adjust for Monday as week start
        guard let date = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else {
            return ""
        }
        return formatter.string(from: date)
    }

    private var dayDate: String {
        let calendar = Calendar.current
        let daysToAdd = weekday == 1 ? 6 : (weekday - 2)
        guard let date = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(dayDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if sessions.isEmpty {
                    Text("No fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .trailing, spacing: 4) {
                        ForEach(sessions) { session in
                            HStack(spacing: 8) {
                                if session.skipped {
                                    Image(systemName: "moon.zzz.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("Skipped")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else if session.actualDurationHours == 0 {
                                    Image(systemName: "xmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("0h")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                } else {
                                    Image(systemName: statusIcon(for: session.completionStatus))
                                        .font(.caption)
                                        .foregroundColor(statusColor(for: session.completionStatus))
                                    Text("\(session.actualDurationHours, specifier: "%.1f")h")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(statusColor(for: session.completionStatus))
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(sessions.isEmpty ? Color.gray.opacity(0.05) : Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }

    private func statusIcon(for status: FastingCompletionStatus) -> String {
        switch status {
        case .completed, .overGoal:
            return "checkmark.circle.fill"
        case .earlyEnd:
            return "exclamationmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .skipped:
            return "moon.zzz.fill"
        case .active:
            return "clock.fill"
        }
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