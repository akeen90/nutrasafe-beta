import SwiftUI
import Charts

struct FastingMainView: View {
    @ObservedObject var viewModel: FastingViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingEditTimes = false
    @State private var showingEducation = false
    @State private var showingCitations = false
    @State private var showingActionSheet = false
    @State private var actionSheetSession: FastingSession?
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionManager.hasAccess {
                    fastingContent
                } else {
                    premiumLockedView
                }
            }
            .navigationTitle("Fasting")
        }
    }

    // MARK: - Premium Locked View
    private var premiumLockedView: some View {
        PremiumUnlockCard(
            icon: "timer",
            iconColor: .green,
            title: "Intermittent Fasting",
            subtitle: "Take regular breaks from eating to support your metabolism and energy levels. Popular with the NHS and health experts.",
            benefits: [
                "Simple plans like 16:8 — fast 16 hours (mostly whilst sleeping), eat within 8",
                "Live timer tracks your progress through different fasting stages",
                "Build streaks and stay motivated with your fasting history",
                "Science-backed approach used by millions worldwide"
            ],
            onUnlockTapped: {
                showingPaywall = true
            }
        )
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Fasting Content (Premium)
    private var fastingContent: some View {
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
        .fullScreenCover(isPresented: $showingEducation) {
            FastingEducationView()
        }
        .fullScreenCover(isPresented: $showingCitations) {
            FastingCitationsView()
        }
        .fullScreenCover(isPresented: $showingEditTimes) {
            if let session = viewModel.activeSession {
                EditSessionTimesView(viewModel: viewModel, session: session)
            }
        }
        .fullScreenCover(isPresented: $showingActionSheet) {
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
            }
        }
        // MARK: - Clock-in Confirmation Sheet (Start Fast)
        .sheet(isPresented: $viewModel.showingStartConfirmation) {
            if let context = viewModel.confirmationContext {
                FastingStartConfirmationSheet(
                    context: context,
                    onConfirmScheduledTime: {
                        Task {
                            await viewModel.confirmStartAtScheduledTime()
                        }
                    },
                    onConfirmCustomTime: { customTime in
                        Task {
                            await viewModel.confirmStartAtCustomTime(customTime)
                        }
                    },
                    onNotStartedYet: {
                        viewModel.confirmNotStartedYet()
                    },
                    onDismiss: {
                        viewModel.showingStartConfirmation = false
                        viewModel.confirmationContext = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        // MARK: - Clock-out Confirmation Sheet (End Fast)
        .sheet(isPresented: $viewModel.showingEndConfirmation) {
            if let context = viewModel.confirmationContext,
               let session = viewModel.activeSession {
                FastingEndConfirmationSheet(
                    context: context,
                    actualStartTime: session.startTime,
                    onConfirmNow: {
                        Task {
                            await viewModel.confirmEndNow()
                        }
                    },
                    onConfirmCustomTime: { customTime in
                        Task {
                            await viewModel.confirmEndAtCustomTime(customTime)
                        }
                    },
                    onContinueFasting: {
                        viewModel.confirmContinueFasting()
                    },
                    onDismiss: {
                        viewModel.showingEndConfirmation = false
                        viewModel.confirmationContext = nil
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        // MARK: - Listen for Notification Confirmation Requests
        .onReceive(NotificationCenter.default.publisher(for: .fastingConfirmationRequired)) { notification in
            if let userInfo = notification.userInfo {
                viewModel.handleConfirmationNotification(userInfo: userInfo)
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshActivePlan()
                checkForMissedScheduledFast()
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
            // Welcome Card with UK-friendly explanation
            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Get Started with Fasting")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Intermittent fasting means giving your body regular breaks from eating. Popular plans like 16:8 involve fasting for 16 hours (including sleep) and eating within an 8-hour window.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
                    Text("Create My Plan")
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
                    Text("What is Fasting? Learn More")
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

            // Simple benefit list for new users
            VStack(alignment: .leading, spacing: 8) {
                Text("Why people fast:")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                ForEach(["May support weight management", "Gives your digestive system a rest", "Many find it helps energy levels"], id: \.self) { benefit in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text(benefit)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .fullScreenCover(isPresented: $showingEducation) {
            FastingEducationView()
        }
        .fullScreenCover(isPresented: $showingPlanCreation) {
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
    @State private var weekToDelete: WeekSummary?
    @State private var showDeleteAlert = false
    @State private var showingCitations = false

    // Timeline view state
    @State private var selectedTimelineDate: Date?
    @State private var sessionToDelete: FastingSession?
    @State private var showDeleteSessionAlert = false

    // PERFORMANCE: Cache average duration to prevent redundant calculations on every render
    // Pattern from Clay's production app: move expensive operations to cached state
    @State private var cachedAverageDuration: Double = 0

    // Use all recent sessions (since typically only one plan is active at a time)
    // Filter out only cleared sessions (actualDurationHours == 0)
    // Skipped sessions SHOULD count their actual hours in totals
    private var planSessions: [FastingSession] {
        viewModel.recentSessions.filter { $0.actualDurationHours > 0 }
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

    private var effectiveDurationHours: Int {
        switch viewModel.currentRegimeState {
        case .fasting(let started, let ends):
            return max(1, Int(round(ends.timeIntervalSince(started) / 3600)))
        default:
            if let sessionHours = viewModel.activeSession?.targetDurationHours { return sessionHours }
            return plan.durationHours
        }
    }

    private var effectiveDisplayName: String {
        let h = effectiveDurationHours
        if h == 16 { return "16:8 Fasting Plan" }
        if h == 12 { return "12:12 Fasting Plan" }
        if h == 18 { return "18:6 Fasting Plan" }
        if h == 20 { return "20:4 Fasting Plan" }
        if h == 24 { return "OMAD Plan" }
        return "\(h)-Hour Fast"
    }

    // MARK: - Extracted View Components

    @ViewBuilder
    private var planHeaderCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.green)
                Text(effectiveDisplayName)
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text("\(effectiveDurationHours)h")
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
    }

    @ViewBuilder
    private var statsGrid: some View {
        HStack(spacing: 12) {
            FastingStatCard(title: "Total Fasts", value: "\(totalFasts)", icon: "calendar")
            FastingStatCard(title: "Completed", value: "\(completionRate)%", icon: "checkmark.circle.fill")
            FastingStatCard(title: "Avg Duration", value: String(format: "%.1fh", averageDuration), icon: "clock.fill")
        }
    }

    @ViewBuilder
    private var regimeActiveControls: some View {
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

            regimeStateView

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
    }

    @ViewBuilder
    private var regimeStateView: some View {
        switch viewModel.currentRegimeState {
        case .fasting(_, let ends):
            fastingStateView(ends: ends)
        case .eating(let nextFastStart):
            eatingStateView(nextFastStart: nextFastStart)
        case .inactive:
            EmptyView()
        }
    }

    @ViewBuilder
    private func fastingStateView(ends: Date) -> some View {
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
                        Text("End Fast Early")
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
    }

    @ViewBuilder
    private func eatingStateView(nextFastStart: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Eating Window")
                    .font(.subheadline)
                    .fontWeight(.medium)
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
    }

    @ViewBuilder
    private var regimeInactiveControls: some View {
        VStack(spacing: 12) {
            Button {
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

    @ViewBuilder
    private var fastingHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fasting History")
                    .font(.headline)
                Spacer()
                // Use allSessions count (not recentSessions which is limited to 10)
                let actualTotalFasts = viewModel.allSessions.filter { $0.actualDurationHours > 0 }.count
                if actualTotalFasts > 0 {
                    Text("\(actualTotalFasts) total fasts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.allSessions.isEmpty {
                Text("No fasts recorded yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                FastingTimelineView(
                    sessions: viewModel.allSessions,
                    selectedDate: $selectedTimelineDate,
                    onDeleteSession: { session in
                        sessionToDelete = session
                        showDeleteSessionAlert = true
                    }
                )
            }
        }
        .alert("Delete Fast?", isPresented: $showDeleteSessionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    Task {
                        await viewModel.deleteSession(session)
                    }
                }
            }
        } message: {
            Text("This will permanently delete this fasting session.")
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            planHeaderCard
            statsGrid

            if viewModel.isRegimeActive {
                regimeActiveControls
            } else {
                regimeInactiveControls
            }

            fastingHistorySection
        }
        .fullScreenCover(isPresented: $showRegimeDetails) {
            RegimeDetailView(viewModel: viewModel, plan: plan)
        }
        .fullScreenCover(isPresented: $showFastSettings) {
            FastingPlanCreationView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingCitations) {
            FastingCitationsView()
        }
        .fullScreenCover(isPresented: $showSnoozePicker) {
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
                                showSnoozePicker = false
                                return
                            }

                            // If the time is in the past, move to tomorrow
                            var finalSnoozeTime = todayAtSelectedTime
                            if todayAtSelectedTime <= now {
                                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayAtSelectedTime) {
                                    finalSnoozeTime = tomorrow
                                }
                            }

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
            
        .fullScreenCover(isPresented: $showWeekDetail) {
            if let week = selectedWeek {
                WeekDetailView(week: week, viewModel: viewModel)
            }
        }
        .alert("Delete Week", isPresented: $showDeleteAlert, presenting: weekToDelete) { week in
            Button("Delete Permanently", role: .destructive) {
                Task {
                    await viewModel.deleteAllSessionsForDay(week.sessions)
                }
            }
            Button("Clear (Keep Record)") {
                Task {
                    await viewModel.clearAllSessionsForDay(week.sessions)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { week in
            Text("Remove \(week.dateRangeText) fasting data?")
        }
        .onReceive(NotificationCenter.default.publisher(for: .fastHistoryUpdated)) { _ in
            viewModel.objectWillChange.send()
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
        .onChange(of: viewModel.recentSessions) { updateCachedAverageDuration() }
    }
}

// MARK: - Regime Detail View
struct RegimeDetailView: View {
    @ObservedObject var viewModel: FastingViewModel
    let plan: FastingPlan
    @Environment(\.dismiss) private var dismiss
    @State private var showingCitations = false
    @State private var showingEditTimes = false
    @State private var editStartTime = Date()
    @State private var editTargetHours = 16

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

                    if case .fasting(let started, _) = viewModel.currentRegimeState {
                        Button {
                            editStartTime = started
                            editTargetHours = viewModel.activeSession?.targetDurationHours ?? viewModel.activePlan?.durationHours ?? 16
                            showingEditTimes = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                Text("Edit Fast")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

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
            .fullScreenCover(isPresented: $showingCitations) {
                FastingCitationsView()
            }
            .fullScreenCover(isPresented: $showingEditTimes) {
                NavigationStack {
                    Form {
                        Section("Current Fast") {
                            DatePicker("Start Time", selection: $editStartTime, in: ...Date())
                            Stepper("Goal: \(editTargetHours)h", value: $editTargetHours, in: 8...24)
                        }
                        Section {
                            Button {
                                Task { await viewModel.editActiveFast(startTime: editStartTime, targetHours: editTargetHours) }
                                showingEditTimes = false
                            } label: {
                                HStack { Spacer(); Text("Save Changes").fontWeight(.semibold); Spacer() }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .navigationTitle("Edit Fast")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingEditTimes = false }
                        }
                    }
                }
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
                if case .fasting(let started, let ends) = viewModel.currentRegimeState {
                    Text("Fast started: \(started.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    let targetHours = Int(round(ends.timeIntervalSince(started) / 3600))
                    Text("Target: \(targetHours)h fast / \(max(0, 24 - targetHours))h eating window")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                            Text("End Fast Early")
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
        .fullScreenCover(isPresented: $showingEditTimes) {
            if let session = viewModel.activeSession {
                EditSessionTimesView(viewModel: viewModel, session: session)
            }
        }
        .fullScreenCover(isPresented: $showingEarlyEndModal) {
            if let session = endedSession {
                EarlyEndModal(viewModel: viewModel, session: session)
            }
        }
        .fullScreenCover(isPresented: $showingCitations) {
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
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .animation(.linear(duration: 0.15), value: viewModel.currentProgress)
                
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
    var onDeleteTap: (() -> Void)? = nil

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

                Spacer()

                // Delete button
                Button {
                    onDeleteTap?()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
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
                        Text("\(week.totalHours, specifier: "%.1f")h")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Text("Total Hours")
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

    // Generate dates for each day of the week (most recent first - Sun to Mon)
    private var weekDays: [(date: Date, dayName: String, dayDate: String, isToday: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        // PERFORMANCE: Use cached static formatters instead of creating in loop
        // Reverse order so most recent day is at the top
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: week.weekStart) else { return nil }
            return (date: date,
                    dayName: DateHelper.fullDayOfWeekFormatter.string(from: date),
                    dayDate: DateHelper.monthDayFormatter.string(from: date),
                    isToday: calendar.isDate(date, inSameDayAs: today))
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

                        // Summary Stats - Modern Design
                        HStack(spacing: 30) {
                            VStack {
                                Text("\(week.totalFasts)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .purple.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Text("Fasts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if week.totalFasts > 0 {
                                VStack {
                                    Text("\(week.totalHours, specifier: "%.1f")h")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .green.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if week.averageDuration > 0 {
                                    VStack {
                                        Text("\(week.averageDuration, specifier: "%.1f")h")
                                            .font(.system(size: 36, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.blue, .blue.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
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
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                // Daily Breakdown Section - Modern card design showing all fasts
                Section {
                    ForEach(weekDays, id: \.date) { day in
                        let allSessions = sessionsForDate(day.date)
                        let hasActiveFast = allSessions.contains { $0.completionStatus == .active }

                        VStack(alignment: .leading, spacing: 12) {
                            // Day header with modern styling
                            HStack(alignment: .center, spacing: 12) {
                                // Day indicator circle
                                ZStack {
                                    Circle()
                                        .fill(day.isToday ? Color.purple : (allSessions.isEmpty ? Color.gray.opacity(0.15) : Color.green.opacity(0.15)))
                                        .frame(width: 44, height: 44)

                                    if hasActiveFast {
                                        // Pulsing ring for active fast
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue)
                                    } else if !allSessions.isEmpty {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.green)
                                    } else {
                                        Text(String(day.dayName.prefix(1)))
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(day.isToday ? .white : .secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 8) {
                                        Text(day.dayName)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)

                                        if day.isToday {
                                            Text("Today")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.purple)
                                                .cornerRadius(6)
                                        }

                                        if hasActiveFast {
                                            Text("In Progress")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Color.blue)
                                                .cornerRadius(6)
                                        }
                                    }

                                    Text(day.dayDate)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Day summary badge
                                if !allSessions.isEmpty {
                                    let dayTotal = allSessions.reduce(0.0) { sum, session in
                                        let endTime = session.endTime ?? Date()
                                        return sum + (endTime.timeIntervalSince(session.startTime) / 3600)
                                    }
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(dayTotal, specifier: "%.1f")h")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(hasActiveFast ? .blue : .green)
                                        Text(allSessions.count == 1 ? "1 fast" : "\(allSessions.count) fasts")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                            // Show all fasts for this day
                            if allSessions.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "moon.stars.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary.opacity(0.4))
                                    Text("No fasts recorded")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary.opacity(0.7))
                                }
                                .padding(.leading, 56)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(Array(allSessions.enumerated()), id: \.element.id) { index, session in
                                        ModernFastCard(
                                            session: session,
                                            sessionNumber: allSessions.count > 1 ? index + 1 : nil,
                                            onClear: {
                                                Task {
                                                    await viewModel.clearSession(session)
                                                }
                                            }
                                        )

                                        if index < allSessions.count - 1 {
                                            Divider()
                                                .padding(.vertical, 10)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(day.isToday ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 2)
                        )
                        .contextMenu {
                            if !allSessions.isEmpty {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteAllSessionsForDay(allSessions)
                                    }
                                } label: {
                                    Label("Delete Day", systemImage: "trash")
                                }

                                Button {
                                    Task {
                                        await viewModel.clearAllSessionsForDay(allSessions)
                                    }
                                } label: {
                                    Label("Clear Day (Keep Record)", systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Daily Breakdown")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Week Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
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
        // PERFORMANCE: Use cached static formatter

        // Calculate the actual date for this weekday
        let calendar = Calendar.current
        let daysToAdd = weekday == 1 ? 6 : (weekday - 2) // Adjust for Monday as week start
        guard let date = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else {
            return ""
        }
        return DateHelper.fullDayOfWeekFormatter.string(from: date)
    }

    private var dayDate: String {
        let calendar = Calendar.current
        let daysToAdd = weekday == 1 ? 6 : (weekday - 2)
        guard let date = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else {
            return ""
        }

        // PERFORMANCE: Use cached static formatter
        return DateHelper.monthDayFormatter.string(from: date)
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
    @State private var targetHours: Int
    
    init(viewModel: FastingViewModel, session: FastingSession) {
        self.viewModel = viewModel
        self.session = session
        self._startTime = State(initialValue: session.startTime)
        self._endTime = State(initialValue: session.endTime)
        self._isActive = State(initialValue: session.endTime == nil)
        self._targetHours = State(initialValue: session.targetDurationHours)
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
                Section(header: Text("Target")) {
                    Stepper("Goal: \(targetHours)h", value: $targetHours, in: 8...24)
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.editActiveFast(startTime: startTime, targetHours: targetHours)
                            if !isActive {
                                await viewModel.editSessionTimes(startTime: startTime, endTime: endTime)
                            }
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

// MARK: - Fasting Timeline View
struct FastingTimelineView: View {
    let sessions: [FastingSession]
    @Binding var selectedDate: Date?
    let onDeleteSession: (FastingSession) -> Void

    // Group sessions by date
    private var dailySummaries: [(date: Date, sessions: [FastingSession])] {
        let calendar = Calendar.current
        var dateMap: [Date: [FastingSession]] = [:]

        for session in sessions {
            let reportDate = session.endTime ?? session.startTime
            let dayStart = calendar.startOfDay(for: reportDate)
            if dateMap[dayStart] == nil {
                dateMap[dayStart] = []
            }
            dateMap[dayStart]?.append(session)
        }

        // Sort by date ascending (oldest first, newest last)
        return dateMap.sorted { $0.key < $1.key }
            .map { (date: $0.key, sessions: $0.value) }
    }

    // Find sessions for the selected date
    private var selectedSessions: [FastingSession] {
        guard let selected = selectedDate else { return [] }
        let calendar = Calendar.current
        return dailySummaries.first { calendar.isDate($0.date, inSameDayAs: selected) }?.sessions ?? []
    }

    // Date range label
    private var dateRangeLabel: String {
        guard let first = dailySummaries.first?.date,
              let last = dailySummaries.last?.date else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        if Calendar.current.isDate(first, inSameDayAs: last) {
            return formatter.string(from: first)
        } else {
            return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
        }
    }

    // Max hours in any single day (for bar scaling)
    private var maxHoursInADay: Double {
        let maxHours = dailySummaries.map { summary in
            summary.sessions.reduce(0) { $0 + $1.actualDurationHours }
        }.max() ?? 24
        return max(maxHours, 1) // Avoid division by zero
    }

    var body: some View {
        VStack(spacing: 12) {
            // Timeline header
            HStack {
                Text("← Older")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(dateRangeLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Today →")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            // Horizontal scrolling timeline with mini bars
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(dailySummaries, id: \.date) { summary in
                            TimelineBarView(
                                date: summary.date,
                                sessions: summary.sessions,
                                isSelected: selectedDate != nil && Calendar.current.isDate(selectedDate!, inSameDayAs: summary.date),
                                maxHours: maxHoursInADay,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if selectedDate != nil && Calendar.current.isDate(selectedDate!, inSameDayAs: summary.date) {
                                            selectedDate = nil
                                        } else {
                                            selectedDate = summary.date
                                        }
                                    }
                                }
                            )
                            .id(summary.date)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
                .background(Color.gray.opacity(0.06))
                .cornerRadius(16)
                .onAppear {
                    // Auto-scroll to most recent (rightmost)
                    if let lastDate = dailySummaries.last?.date {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(lastDate, anchor: .trailing)
                            }
                        }
                    }
                }
            }

            // Selected day detail card
            if let selected = selectedDate, !selectedSessions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Day header
                    HStack {
                        Text(formatDayHeader(selected))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(selectedSessions.count) fast\(selectedSessions.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Sessions for this day
                    ForEach(Array(selectedSessions.enumerated()), id: \.element.id) { index, session in
                        TimelineFastCard(
                            session: session,
                            sessionNumber: selectedSessions.count > 1 ? index + 1 : nil,
                            onClear: {
                                onDeleteSession(session)
                            }
                        )
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func formatDayHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Timeline Bar View (Mini Graph)
struct TimelineBarView: View {
    let date: Date
    let sessions: [FastingSession]
    let isSelected: Bool
    let maxHours: Double // Max hours across all days for scaling
    let onTap: () -> Void

    private var totalHours: Double {
        sessions.reduce(0) { $0 + $1.actualDurationHours }
    }

    private var barColor: Color {
        guard !sessions.isEmpty else { return .gray.opacity(0.3) }

        let statuses = sessions.map { $0.completionStatus }

        if statuses.contains(.overGoal) { return .blue }
        if statuses.contains(.completed) { return .green }
        if statuses.contains(.active) { return .blue }
        if statuses.contains(.earlyEnd) { return .orange }
        if statuses.contains(.failed) { return .red }
        return .gray
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthLabel: String? {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        if day == 1 || isToday {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        return nil
    }

    // Bar height based on hours (min 8pt, max 60pt)
    private var barHeight: CGFloat {
        guard maxHours > 0, totalHours > 0 else { return 8 }
        let ratio = totalHours / maxHours
        return max(8, CGFloat(ratio) * 60)
    }

    var body: some View {
        VStack(spacing: 4) {
            // Month label (shown on 1st of month or today)
            if let month = monthLabel {
                Text(month)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Text(" ")
                    .font(.system(size: 9))
            }

            // The bar with hours
            ZStack(alignment: .bottom) {
                // Background bar (empty state)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: isSelected ? 32 : 24, height: 60)

                // Filled bar
                if totalHours > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.7), barColor],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: isSelected ? 32 : 24, height: barHeight)
                }

                // Hours label inside bar
                if totalHours > 0 {
                    Text("\(Int(totalHours))hr")
                        .font(.system(size: totalHours >= 10 ? 8 : 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        .padding(.bottom, 4)
                }

                // Selection ring
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(barColor, lineWidth: 2)
                        .frame(width: 36, height: 64)
                }
            }

            // Day number
            Text(dayLabel)
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .primary : .secondary)

            // Today indicator
            if isToday {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(width: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Timeline Fast Card (wider version)
struct TimelineFastCard: View {
    let session: FastingSession
    let sessionNumber: Int?
    let onClear: () -> Void

    private var completionPercentage: Double {
        guard session.targetDurationHours > 0 else { return 0 }
        return min(1.0, session.actualDurationHours / Double(session.targetDurationHours))
    }

    private var statusColor: Color {
        switch session.completionStatus {
        case .completed, .overGoal: return .green
        case .earlyEnd: return .orange
        case .failed: return .red
        case .skipped: return .gray
        case .active: return .blue
        }
    }

    private var statusIcon: String {
        switch session.completionStatus {
        case .completed: return "checkmark.circle.fill"
        case .overGoal: return "star.circle.fill"
        case .earlyEnd: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "moon.zzz.fill"
        case .active: return "clock.fill"
        }
    }

    private var statusText: String {
        switch session.completionStatus {
        case .completed: return "Completed"
        case .overGoal: return "Exceeded Goal"
        case .earlyEnd: return "Ended Early"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        case .active: return "In Progress"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: completionPercentage)
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(Int(completionPercentage * 100))")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                    Text("%")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Fast details
            VStack(alignment: .leading, spacing: 4) {
                // Session number and status
                HStack(spacing: 6) {
                    if let number = sessionNumber {
                        Text("Fast #\(number)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Image(systemName: statusIcon)
                        .font(.system(size: 11))
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(statusColor)
                }

                // Duration
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(session.actualDurationHours, specifier: "%.1f")")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("hours")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    if session.targetDurationHours > 0 {
                        Text("/ \(session.targetDurationHours)h target")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                // Time range
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(DateHelper.shortTimeFormatter.string(from: session.startTime))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.6))
                    if let endTime = session.endTime {
                        Text(DateHelper.shortTimeFormatter.string(from: endTime))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ongoing")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onClear()
            } label: {
                Label("Clear Fast", systemImage: "xmark.circle")
            }
        }
    }
}

// MARK: - Modern Fast Card
struct ModernFastCard: View {
    let session: FastingSession
    let sessionNumber: Int? // Show "Fast #1", "Fast #2" if multiple fasts per day
    let onClear: () -> Void

    private var completionPercentage: Double {
        guard session.targetDurationHours > 0 else { return 0 }
        return min(1.0, session.actualDurationHours / Double(session.targetDurationHours))
    }

    private var statusColor: Color {
        switch session.completionStatus {
        case .completed, .overGoal: return .green
        case .earlyEnd: return .orange
        case .failed: return .red
        case .skipped: return .gray
        case .active: return .blue
        }
    }

    private var statusIcon: String {
        switch session.completionStatus {
        case .completed: return "checkmark.circle.fill"
        case .overGoal: return "star.circle.fill"
        case .earlyEnd: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "moon.zzz.fill"
        case .active: return "clock.fill"
        }
    }

    private var statusText: String {
        switch session.completionStatus {
        case .completed: return "Completed"
        case .overGoal: return "Exceeded Goal"
        case .earlyEnd: return "Ended Early"
        case .failed: return "Failed"
        case .skipped: return "Skipped"
        case .active: return "In Progress"
        }
    }

    // PERFORMANCE: Use cached static formatter instead of computed property
    private var timeFormatter: DateFormatter {
        DateHelper.shortTimeFormatter
    }

    var body: some View {
        HStack(spacing: 16) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: completionPercentage)
                    .stroke(
                        statusColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(completionPercentage * 100))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                    Text("%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // Fast details
            VStack(alignment: .leading, spacing: 6) {
                // Session number and status
                HStack(spacing: 6) {
                    if let number = sessionNumber {
                        Text("Fast #\(number)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(6)
                    }

                    Image(systemName: statusIcon)
                        .font(.system(size: 12))
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(statusColor)
                }

                // Duration
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(session.actualDurationHours, specifier: "%.1f")")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("hours")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // Time range
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(timeFormatter.string(from: session.startTime))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.6))
                    if let endTime = session.endTime {
                        Text("\(timeFormatter.string(from: endTime))")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Ongoing")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }

                // Target info
                if session.targetDurationHours > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("Target: \(session.targetDurationHours)h")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onClear()
            } label: {
                Label("Clear Fast", systemImage: "xmark.circle")
            }
        }
    }
}

#Preview {
    NavigationStack {
        FastingMainView(viewModel: FastingViewModel.preview)
    }
}
