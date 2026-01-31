//
//  FastingRedesign.swift
//  NutraSafe Beta
//
//  Complete UX/UI redesign of the Fasting experience
//  Philosophy: Calm, supportive, non-judgemental, user-led
//
//  Design Principles:
//  - No pressure, no guilt, no "discipline" energy
//  - Feels optional, flexible, and user-led
//  - Educational and observational, not prescriptive
//  - Consistent with NutraSafe's "track, understand, adjust" philosophy
//

import SwiftUI
import Charts

// MARK: - Main Fasting View (Redesigned)

struct FastingMainViewRedesigned: View {
    @ObservedObject var viewModel: FastingViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingPlanSettings = false
    @State private var showingHistory = false
    @State private var showingInsights = false
    @State private var showingEducation = false
    @State private var showingPaywall = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptionManager.hasAccess {
                    mainContent
                } else {
                    premiumLockedView
                }
            }
            .navigationTitle("Fasting")
            .navigationBarTitleDisplayMode(.large)
        }
        .trackScreen("Fasting")
    }

    // MARK: - Premium Locked View
    private var premiumLockedView: some View {
        PremiumUnlockCard(
            icon: "timer",
            iconColor: palette.accent,
            title: "Intermittent Fasting",
            subtitle: "A gentle approach to meal timing that works with your body's natural rhythms.",
            benefits: [
                "Simple, flexible schedules you can adjust anytime",
                "Track your patterns without pressure or judgement",
                "Learn what works for your body and routine",
                "Science-informed insights, not rules"
            ],
            onUnlockTapped: {
                showingPaywall = true
            }
        )
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Primary: Current State Card
                currentStateCard

                // Secondary: Quick Actions (when applicable)
                if viewModel.activePlan != nil {
                    quickActionsRow
                }

                // Tertiary: Recent Activity (subtle)
                if !viewModel.recentSessions.isEmpty {
                    recentActivityCard
                }

                // Educational content for new users
                if viewModel.activePlan == nil {
                    gettingStartedCard
                }

                // Bottom spacer
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, DesignTokens.Spacing.screenEdge)
            .padding(.top, DesignTokens.Spacing.md)
        }
        .background(AppAnimatedBackground())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if viewModel.activePlan != nil {
                        Button {
                            showingInsights = true
                        } label: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(palette.textSecondary)
                        }
                    }

                    Button {
                        showingPlanSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(palette.textSecondary)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingPlanSettings) {
            FastingPlanSettingsRedesigned(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingHistory) {
            FastingHistoryRedesigned(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingInsights) {
            FastingInsightsRedesigned(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingEducation) {
            FastingEducationView()
        }
        .sheet(isPresented: $viewModel.showStaleSessionSheet) {
            if let staleSession = viewModel.staleSessionToResolve {
                StaleSessionRecoverySheet(session: staleSession)
                    .environmentObject(viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showingStartConfirmation) {
            if let context = viewModel.confirmationContext {
                FastingStartConfirmationRedesigned(
                    context: context,
                    onConfirmScheduledTime: { [viewModel] in
                        Task {
                            await viewModel.confirmStartAtScheduledTime()
                        }
                    },
                    onConfirmCustomTime: { [viewModel] customTime in
                        Task {
                            await viewModel.confirmStartAtCustomTime(customTime)
                        }
                    },
                    onSkipFast: {
                        viewModel.confirmationContext = nil
                    },
                    onSnoozeUntil: { snoozeTime in
                        // Schedule snooze notification
                        let content = UNMutableNotificationContent()
                        content.title = "Time to start your fast"
                        content.body = "Snoozed reminder - \(context.planName)"
                        content.sound = .default
                        content.userInfo = [
                            "type": "fasting",
                            "fastingType": "start",
                            "planId": context.planId,
                            "planName": context.planName,
                            "durationHours": context.durationHours,
                            "scheduledStartTime": context.scheduledTime.timeIntervalSince1970
                        ]

                        let trigger = UNCalendarNotificationTrigger(
                            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeTime),
                            repeats: false
                        )
                        let request = UNNotificationRequest(
                            identifier: "fast_snooze_\(UUID().uuidString)",
                            content: content,
                            trigger: trigger
                        )
                        UNUserNotificationCenter.current().add(request)
                        viewModel.confirmationContext = nil
                    },
                    onDismiss: {
                        viewModel.showingStartConfirmation = false
                        viewModel.confirmationContext = nil
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showingEndConfirmation) {
            if let context = viewModel.confirmationContext,
               let session = viewModel.activeSession {
                FastingEndConfirmationRedesigned(
                    context: context,
                    actualStartTime: session.startTime,
                    onConfirmNow: { [viewModel] in
                        Task {
                            await viewModel.confirmEndNow()
                        }
                    },
                    onConfirmCustomTime: { [viewModel] customTime in
                        Task {
                            await viewModel.confirmEndAtCustomTime(customTime)
                        }
                    },
                    onContinueFasting: {
                        viewModel.confirmationContext = nil
                    },
                    onDismiss: {
                        viewModel.showingEndConfirmation = false
                        viewModel.confirmationContext = nil
                    }
                )
            }
        }
        // PERFORMANCE FIX: Removed onAppear/onDisappear for timer visibility
        // With opacity-based tab switching, views are always mounted in the hierarchy
        // so onAppear fires immediately even when the user is on a different subtab.
        // Timer visibility is now managed by onChange handlers in FoodTabViews.swift
        // which correctly track when selectedFoodSubTab == .fasting
    }

    // MARK: - Current State Card (Primary Focus)
    private var currentStateCard: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            if let plan = viewModel.activePlan {
                // Has an active plan
                switch viewModel.currentRegimeState {
                case .fasting(let started, let ends):
                    fastingStateContent(started: started, ends: ends)
                case .eating(let nextFastStart):
                    eatingWindowContent(nextFastStart: nextFastStart)
                case .inactive:
                    readyToStartContent(plan: plan)
                }
            } else {
                // No plan yet
                noPlanContent
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: DesignTokens.Shadow.subtle.color,
                        radius: DesignTokens.Shadow.subtle.radius,
                        y: DesignTokens.Shadow.subtle.y)
        )
    }

    // MARK: - Fasting State (Active Fast)
    private func fastingStateContent(started: Date, ends: Date) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Header - calm, informative
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("You're fasting")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.textSecondary)

                Text(viewModel.timeUntilFastEnds)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(palette.textPrimary)

                Text("remaining")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textTertiary)
            }

            // Current phase - educational, not achievement
            if let phase = viewModel.currentRegimeFastingPhase {
                currentPhaseIndicator(phase: phase)
            }

            // Progress bar - subtle, not competitive
            progressIndicator(started: started, ends: ends)

            // Time info
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Started")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                    Text(started.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Window ends")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                    Text(ends.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }
            }
            .padding(.top, DesignTokens.Spacing.sm)

            // Primary action - gentle, user-controlled
            Button {
                Task {
                    await viewModel.skipCurrentRegimeFast()
                }
            } label: {
                Text("End fasting window")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(palette.accent.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)

            // Supportive copy
            Text("Listen to your body. It's okay to adjust.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .italic()
        }
    }

    // MARK: - Eating Window State
    private func eatingWindowContent(nextFastStart: Date) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Header
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "leaf")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(SemanticColors.positive)

                Text("Eating window")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text("Nourish yourself mindfully")
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
            }

            // Time until next fast
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(viewModel.timeUntilNextFast)
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(palette.textPrimary)

                Text("until your next fasting window")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textTertiary)
            }
            .padding(.vertical, DesignTokens.Spacing.md)

            // Next fast time
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textTertiary)
                Text("Next window starts at \(nextFastStart.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textSecondary)
            }

            // Optional: Start early
            Button {
                Task {
                    await viewModel.startRegime(startFromNow: true)
                }
            } label: {
                Text("Start fasting early")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Ready to Start State
    private func readyToStartContent(plan: FastingPlan) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Header
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "timer")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(palette.accent)

                Text("Ready when you are")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text("Your \(plan.durationHours)-hour fasting plan")
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
            }

            // Start button - inviting but not pushy
            Button {
                Task {
                    await viewModel.startRegime()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                    Text("Begin fasting")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)
            }
            .buttonStyle(.plain)

            // Reassuring copy
            Text("You can stop or adjust anytime")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
        }
    }

    // MARK: - No Plan State
    private var noPlanContent: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(palette.accent.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Image(systemName: "timer")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(palette.accent)
                }

                Text("Intermittent Fasting")
                    .font(DesignTokens.Typography.sectionTitle(22))
                    .foregroundColor(palette.textPrimary)

                Text("A flexible approach to meal timing that many people find helpful for their routine.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(DesignTokens.Spacing.lineSpacing)
            }

            Button {
                showingPlanSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Set up my plan")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)
            }
            .buttonStyle(.plain)

            Button {
                showingEducation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "book")
                        .font(.system(size: 14))
                    Text("Learn about fasting")
                }
                .font(.system(size: 15))
                .foregroundColor(palette.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Current Phase Indicator
    private func currentPhaseIndicator(phase: FastingPhase) -> some View {
        HStack(spacing: 10) {
            Image(systemName: phaseIcon(for: phase))
                .font(.system(size: 14, weight: .medium))

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(.system(size: 14, weight: .medium))
                Text(phase.description)
                    .font(.system(size: 12))
                    .foregroundColor(palette.textSecondary)
                    .lineLimit(1)
            }
        }
        .foregroundColor(phaseColor(for: phase))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(phaseColor(for: phase).opacity(0.1))
        )
    }

    // MARK: - Progress Indicator (Subtle)
    private func progressIndicator(started: Date, ends: Date) -> some View {
        let totalDuration = ends.timeIntervalSince(started)
        let elapsed = Date().timeIntervalSince(started)
        let progress = min(max(elapsed / totalDuration, 0), 1)

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(palette.tertiary.opacity(0.2))
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [palette.accent.opacity(0.7), palette.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 8)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Quick Actions Row
    private var quickActionsRow: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // History
            quickActionButton(
                icon: "clock.arrow.circlepath",
                label: "History",
                action: { showingHistory = true }
            )

            // Settings
            quickActionButton(
                icon: "slider.horizontal.3",
                label: "Settings",
                action: { showingPlanSettings = true }
            )

            // Learn
            quickActionButton(
                icon: "book",
                label: "Learn",
                action: { showingEducation = true }
            )
        }
    }

    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(palette.accent.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(palette.accent)
                }

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Activity Card (Subtle)
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Recent sessions")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.textSecondary)

                Spacer()

                Button {
                    showingHistory = true
                } label: {
                    Text("See all")
                        .font(.system(size: 13))
                        .foregroundColor(palette.accent)
                }
            }

            // Show last 3 sessions
            ForEach(viewModel.recentSessions.prefix(3)) { session in
                recentSessionRow(session: session)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func recentSessionRow(session: FastingSession) -> some View {
        HStack(spacing: 12) {
            // Status indicator - neutral colors
            Circle()
                .fill(sessionStatusColor(session))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.dateSpanDisplay)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Text(sessionDescription(session))
                    .font(.system(size: 12))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()

            Text("\(session.actualDurationHours, specifier: "%.1f")h")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Getting Started Card
    private var gettingStartedCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("How fasting works")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                benefitRow(icon: "clock", text: "Choose a fasting window that fits your routine")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your patterns over time")
                benefitRow(icon: "arrow.triangle.2.circlepath", text: "Adjust whenever you need to")
                benefitRow(icon: "heart", text: "No pressure — your pace, your choice")
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.accent)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
        }
    }

    // MARK: - Helper Methods
    private func phaseIcon(for phase: FastingPhase) -> String {
        switch phase {
        case .postMeal: return "fork.knife"
        case .fuelSwitching: return "arrow.triangle.swap"
        case .fatMobilization: return "flame"
        case .mildKetosis: return "bolt"
        case .autophagyPotential: return "sparkles"
        case .deepAdaptive: return "star"
        }
    }

    private func phaseColor(for phase: FastingPhase) -> Color {
        switch phase {
        case .postMeal: return palette.textSecondary
        case .fuelSwitching: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .fatMobilization: return Color(red: 0.9, green: 0.4, blue: 0.3)
        case .mildKetosis: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .autophagyPotential: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .deepAdaptive: return Color(red: 0.3, green: 0.7, blue: 0.5)
        }
    }

    private func sessionStatusColor(_ session: FastingSession) -> Color {
        // Neutral colors - no red/error for "failures"
        switch session.completionStatus {
        case .completed, .overGoal:
            return SemanticColors.positive
        case .earlyEnd:
            return palette.textTertiary // Neutral, not warning
        case .active:
            return palette.accent
        case .failed, .skipped:
            return palette.textTertiary
        }
    }

    private func sessionDescription(_ session: FastingSession) -> String {
        // Gentle, non-judgemental descriptions
        switch session.completionStatus {
        case .completed:
            return "Completed session"
        case .overGoal:
            return "Extended session"
        case .earlyEnd:
            return "Shorter session" // Not "Ended early" or "Failed"
        case .active:
            return "In progress"
        case .skipped:
            return "Skipped"
        case .failed:
            return "Session" // Neutral
        }
    }
}

// MARK: - Plan Settings (Redesigned)

struct FastingPlanSettingsRedesigned: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDuration: Int = 16
    @State private var selectedStartTime: Date = Date()
    @State private var reminderEnabled: Bool = true
    @State private var reminderMinutes: Int = 30
    @State private var showingCustomDuration = false
    @State private var customDurationHours: Int = 20
    @State private var isCustomDuration = false
    @State private var showingStopConfirmation = false
    @State private var showingHowItWorks = false

    private var isNewPlan: Bool {
        viewModel.activePlan == nil
    }

    private var isRegimeActive: Bool {
        viewModel.activePlan?.regimeActive == true
    }

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // How it works section (always visible, expandable)
                    howItWorksSection

                    // Intro text
                    introSection

                    // Duration selection
                    durationSection

                    // Schedule section
                    scheduleSection

                    // Reminders section
                    remindersSection

                    // Save button
                    saveButton

                    // Flexibility note
                    flexibilityNote

                    // Stop plan section (only if plan exists and is active)
                    if !isNewPlan {
                        stopPlanSection
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .background(AppAnimatedBackground())
            .navigationTitle("Fasting Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
                // Auto-expand how it works for new users
                if isNewPlan {
                    showingHowItWorks = true
                }
            }
            .alert("Stop fasting plan?", isPresented: $showingStopConfirmation) {
                Button("Keep plan", role: .cancel) { }
                Button("Stop plan", role: .destructive) {
                    Task {
                        await viewModel.stopRegime()
                        dismiss()
                    }
                }
            } message: {
                Text("This will stop your automatic fasting schedule. You can restart it anytime from this screen.")
            }
        }
    }

    // MARK: - How It Works Section
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingHowItWorks.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(palette.accent)

                    Text("How fasting works")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(showingHowItWorks ? 90 : 0))
                }
                .padding(DesignTokens.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expandable content
            if showingHowItWorks {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Divider()
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        howItWorksStep(
                            number: "1",
                            title: "Set your schedule",
                            description: "Choose your fasting duration and when you'd like your eating window to end each day."
                        )

                        howItWorksStep(
                            number: "2",
                            title: "Get gentle reminders",
                            description: "We'll send you a notification when your eating window ends and when it's time to break your fast."
                        )

                        howItWorksStep(
                            number: "3",
                            title: "Check in when you're ready",
                            description: "Tap the notification to confirm you've started or ended your fast. You can adjust the time if needed."
                        )

                        howItWorksStep(
                            number: "4",
                            title: "It runs automatically",
                            description: "Once started, your fasting schedule repeats daily until you choose to stop it."
                        )

                        // Tips section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tips")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            tipRow(icon: "fork.knife", text: "Log your last meal in the diary when you want to start early")
                            tipRow(icon: "clock.arrow.circlepath", text: "You can skip or end a fast early anytime — no judgement")
                            tipRow(icon: "gearshape", text: "Come back here to change your schedule or stop the plan")
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.md)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
        .clipped()
    }

    private func howItWorksStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(palette.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(palette.accent)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(palette.textSecondary)
                .lineSpacing(2)
        }
    }

    // MARK: - Intro Section
    private var introSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Your fasting schedule")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("Set up a routine that works for you. These are starting points — you can adjust them anytime based on how you feel.")
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
                .lineSpacing(4)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(palette.accent.opacity(0.08))
        )
    }

    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fasting duration")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                durationOption(hours: 12, name: "12:12", description: "Gentle start")
                durationOption(hours: 14, name: "14:10", description: "Moderate")
                durationOption(hours: 16, name: "16:8", description: "Popular choice")
                durationOption(hours: 18, name: "18:6", description: "Longer window")
            }

            // Custom duration option
            customDurationButton

            Text("Most people start with 12-14 hours and adjust from there.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .italic()
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
        .sheet(isPresented: $showingCustomDuration) {
            customDurationSheet
        }
    }

    // MARK: - Custom Duration Button
    private var customDurationButton: some View {
        Button {
            showingCustomDuration = true
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))

                if isCustomDuration {
                    Text("Custom: \(selectedDuration)h")
                        .font(.system(size: 15, weight: .semibold))
                } else {
                    Text("Custom duration")
                        .font(.system(size: 15, weight: .medium))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .foregroundColor(isCustomDuration ? .white : palette.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(isCustomDuration ?
                          LinearGradient(colors: [palette.accent, palette.primary], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Duration Sheet
    private var customDurationSheet: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Choose your duration")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text("Set any fasting window that works for your routine.")
                        .font(.system(size: 14))
                        .foregroundColor(palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, DesignTokens.Spacing.lg)

                // Duration picker
                VStack(spacing: 8) {
                    Text("\(customDurationHours) hours")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(palette.accent)

                    Text("fasting window")
                        .font(.system(size: 15))
                        .foregroundColor(palette.textSecondary)
                }

                // Slider
                VStack(spacing: 8) {
                    Slider(value: Binding(
                        get: { Double(customDurationHours) },
                        set: { customDurationHours = Int($0) }
                    ), in: 10...24, step: 1)
                    .tint(palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    HStack {
                        Text("10h")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textTertiary)
                        Spacer()
                        Text("24h")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textTertiary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }

                // Quick select buttons
                HStack(spacing: 12) {
                    ForEach([20, 22, 24], id: \.self) { hours in
                        Button {
                            customDurationHours = hours
                        } label: {
                            Text("\(hours)h")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(customDurationHours == hours ? .white : palette.textSecondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(customDurationHours == hours ? palette.accent : Color(.systemGray6))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Confirm button
                Button {
                    selectedDuration = customDurationHours
                    isCustomDuration = true
                    showingCustomDuration = false
                } label: {
                    Text("Set \(customDurationHours)-hour fast")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [palette.accent, palette.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .navigationTitle("Custom Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomDuration = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func durationOption(hours: Int, name: String, description: String) -> some View {
        let isSelected = selectedDuration == hours && !isCustomDuration

        return Button {
            withAnimation(DesignTokens.Animation.standard) {
                selectedDuration = hours
                isCustomDuration = false
            }
        } label: {
            VStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : palette.textPrimary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : palette.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(isSelected ?
                          LinearGradient(colors: [palette.accent, palette.primary], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color(.systemGray6)], startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Preferred start time")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textPrimary)

            HStack {
                Text("Start fasting at")
                    .foregroundColor(palette.textSecondary)

                Spacer()

                DatePicker("", selection: $selectedStartTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(Color(.systemGray6))
            )

            Text("Your eating window will end at this time. The exact schedule is flexible.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Reminders Section
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Reminders")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textPrimary)

            Toggle(isOn: $reminderEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gentle reminders")
                        .font(.system(size: 15))
                        .foregroundColor(palette.textPrimary)
                    Text("Optional notifications when your window is ending")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textTertiary)
                }
            }
            .tint(palette.accent)

            if reminderEnabled {
                HStack {
                    Text("Remind me")
                        .foregroundColor(palette.textSecondary)

                    Spacer()

                    Picker("", selection: $reminderMinutes) {
                        Text("15 min before").tag(15)
                        Text("30 min before").tag(30)
                        Text("1 hour before").tag(60)
                    }
                    .pickerStyle(.menu)
                }
                .padding(.top, 8)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button {
            saveSettings()
        } label: {
            Text("Save plan")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flexibility Note
    private var flexibilityNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb")
                .font(.system(size: 16))
                .foregroundColor(palette.accent)

            Text("Life happens. You can skip, shorten, or extend any session. This is your tool, not your boss.")
                .font(.system(size: 13))
                .foregroundColor(palette.textSecondary)
                .lineSpacing(3)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(palette.accent.opacity(0.05))
        )
    }

    // MARK: - Stop Plan Section
    private var stopPlanSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Manage plan")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)

            VStack(spacing: 12) {
                // Status indicator
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isRegimeActive ? SemanticColors.positive.opacity(0.15) : palette.textTertiary.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: isRegimeActive ? "checkmark.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(isRegimeActive ? SemanticColors.positive : palette.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isRegimeActive ? "Plan is active" : "Plan is paused")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(palette.textPrimary)

                        Text(isRegimeActive ? "Running automatically each day" : "Start the plan to begin tracking")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textSecondary)
                    }

                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.midnightCard : Color(.systemGray6))
                )

                // Stop button (only show if active)
                if isRegimeActive {
                    Button {
                        showingStopConfirmation = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 18))

                            Text("Stop fasting plan")
                                .font(.system(size: 15, weight: .medium))

                            Spacer()
                        }
                        .foregroundColor(.red.opacity(0.8))
                        .padding(DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(Color.red.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)

                    Text("Stopping the plan will end your current fast if one is in progress. You can restart anytime.")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Methods
    private func loadCurrentSettings() {
        if let plan = viewModel.activePlan {
            selectedDuration = plan.durationHours
            reminderEnabled = plan.reminderEnabled
            reminderMinutes = plan.reminderMinutesBeforeEnd

            let components = Calendar.current.dateComponents([.hour, .minute], from: plan.preferredStartTime)
            if let hour = components.hour, let minute = components.minute {
                selectedStartTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
            }
        }
    }

    private func saveSettings() {
        Task {
            if var plan = viewModel.activePlan {
                plan.durationHours = selectedDuration
                plan.preferredStartTime = selectedStartTime
                plan.reminderEnabled = reminderEnabled
                plan.reminderMinutesBeforeEnd = reminderMinutes
                await viewModel.updatePlan(plan)
            } else {
                // Create new plan with sensible defaults
                await viewModel.createFastingPlan(
                    name: "\(selectedDuration):8 Plan",
                    durationHours: selectedDuration,
                    daysOfWeek: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                    preferredStartTime: selectedStartTime,
                    allowedDrinks: .practical,
                    reminderEnabled: reminderEnabled,
                    reminderMinutesBeforeEnd: reminderMinutes
                )
            }
            dismiss()
        }
    }
}

// MARK: - History View (Redesigned)

struct FastingHistoryRedesigned: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var sessionToDelete: FastingSession?
    @State private var showDeleteAlert = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Summary card
                    summaryCard

                    // Sessions list
                    sessionsSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .background(AppAnimatedBackground())
            .navigationTitle("Fasting History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Remove this session?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let session = sessionToDelete {
                        Task {
                            await viewModel.deleteSession(session)
                        }
                    }
                }
            } message: {
                Text("This will remove the session from your history. This can't be undone.")
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Your patterns")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)

            HStack(spacing: 0) {
                statItem(
                    value: "\(viewModel.recentSessions.count)",
                    label: "Sessions"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    value: averageDuration,
                    label: "Avg duration"
                )

                Divider()
                    .frame(height: 40)

                statItem(
                    value: "\(consistentDays)",
                    label: "This week"
                )
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var averageDuration: String {
        guard !viewModel.recentSessions.isEmpty else { return "—" }
        let total = viewModel.recentSessions.reduce(0.0) { $0 + $1.actualDurationHours }
        let avg = total / Double(viewModel.recentSessions.count)
        return String(format: "%.1fh", avg)
    }

    private var consistentDays: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return viewModel.recentSessions.filter { $0.startTime >= weekAgo }.count
    }

    // MARK: - Sessions Section
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("All sessions")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)

            if viewModel.recentSessions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.recentSessions) { session in
                        sessionCard(session: session)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "clock")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(palette.textTertiary)

            Text("No sessions yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(palette.textSecondary)

            Text("Your fasting history will appear here")
                .font(.system(size: 14))
                .foregroundColor(palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func sessionCard(session: FastingSession) -> some View {
        HStack(spacing: 14) {
            // Date/time info
            VStack(alignment: .leading, spacing: 4) {
                Text(session.dateSpanDisplay)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Text(sessionDescription(session))
                    .font(.system(size: 13))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()

            // Duration
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.actualDurationHours, specifier: "%.1f")h")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                if session.targetDurationHours > 0 {
                    Text("of \(session.targetDurationHours)h")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                }
            }

            // Delete button
            Button {
                sessionToDelete = session
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textTertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                sessionToDelete = session
                showDeleteAlert = true
            } label: {
                Label("Remove session", systemImage: "trash")
            }
        }
    }

    private func sessionDescription(_ session: FastingSession) -> String {
        // Non-judgemental descriptions
        switch session.completionStatus {
        case .completed:
            return "Completed"
        case .overGoal:
            return "Extended"
        case .earlyEnd:
            return "Shorter session"
        case .active:
            return "In progress"
        case .skipped:
            return "Skipped"
        case .failed:
            return "Session"
        }
    }
}

// MARK: - Insights View (Redesigned)

struct FastingInsightsRedesigned: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Intro - reframing insights
                    introSection

                    // Pattern overview (not achievements)
                    patternCard

                    // Consistency patterns (not streaks)
                    if let analytics = viewModel.analytics {
                        consistencyCard(analytics: analytics)
                    }

                    // Educational note
                    educationalNote

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .background(AppAnimatedBackground())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Intro Section
    private var introSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Understanding your patterns")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("These numbers are just information — not goals or grades. Use them to notice what works for you.")
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
                .lineSpacing(4)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(palette.accent.opacity(0.08))
        )
    }

    // MARK: - Pattern Card
    private var patternCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("What you've tracked")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                patternMetric(
                    value: "\(viewModel.recentSessions.count)",
                    label: "Total sessions",
                    icon: "clock"
                )

                patternMetric(
                    value: averageDuration,
                    label: "Average duration",
                    icon: "timer"
                )

                patternMetric(
                    value: longestFast,
                    label: "Longest session",
                    icon: "arrow.up"
                )

                patternMetric(
                    value: mostCommonTime,
                    label: "Usual start time",
                    icon: "sun.horizon"
                )
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func patternMetric(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(palette.accent)
                Spacer()
            }

            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(palette.textTertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(palette.accent.opacity(0.06))
        )
    }

    // MARK: - Consistency Card (Not Streaks)
    private func consistencyCard(analytics: FastingAnalytics) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Consistency patterns")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(palette.textSecondary)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                if let mostConsistent = analytics.mostConsistentDay {
                    consistencyRow(
                        label: "Most common day",
                        value: mostConsistent
                    )
                }

                consistencyRow(
                    label: "Sessions this week",
                    value: "\(recentWeekCount)"
                )

                consistencyRow(
                    label: "Sessions this month",
                    value: "\(recentMonthCount)"
                )
            }

            // Note about consistency
            Text("Consistency is personal. Some weeks will have more sessions than others, and that's normal.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .italic()
                .padding(.top, 8)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func consistencyRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textPrimary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Educational Note
    private var educationalNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 18))
                .foregroundColor(palette.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text("Numbers aren't everything")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Text("How you feel is more important than any statistic. Use these insights as information, not judgement.")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textSecondary)
                    .lineSpacing(3)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(palette.accent.opacity(0.05))
        )
    }

    // MARK: - Computed Properties
    private var averageDuration: String {
        guard !viewModel.recentSessions.isEmpty else { return "—" }
        let total = viewModel.recentSessions.reduce(0.0) { $0 + $1.actualDurationHours }
        let avg = total / Double(viewModel.recentSessions.count)
        return String(format: "%.1fh", avg)
    }

    private var longestFast: String {
        guard let longest = viewModel.recentSessions.max(by: { $0.actualDurationHours < $1.actualDurationHours }) else {
            return "—"
        }
        return String(format: "%.1fh", longest.actualDurationHours)
    }

    private var mostCommonTime: String {
        guard !viewModel.recentSessions.isEmpty else { return "—" }
        // This would need more sophisticated calculation
        return "Evening"
    }

    private var recentWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return viewModel.recentSessions.filter { $0.startTime >= weekAgo }.count
    }

    private var recentMonthCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return viewModel.recentSessions.filter { $0.startTime >= monthAgo }.count
    }
}

// MARK: - Redesigned Confirmation Sheets

/// Redesigned start confirmation sheet - calm, supportive tone
struct FastingStartConfirmationRedesigned: View {
    let context: FastingConfirmationContext
    let onConfirmScheduledTime: () -> Void
    let onConfirmCustomTime: (Date) -> Void
    let onSkipFast: () -> Void
    let onSnoozeUntil: (Date) -> Void
    let onDismiss: () -> Void

    @State private var showingTimePicker = false
    @State private var showingSnoozePicker = false
    @State private var selectedTime = Date()
    @State private var snoozeTime = Date().addingTimeInterval(3600)
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header - gentle, inviting
                    headerSection

                    // Time card
                    timeCard

                    // Actions
                    if showingTimePicker {
                        customTimeSection
                    } else if showingSnoozePicker {
                        snoozeSection
                    } else {
                        mainActions
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            selectedTime = context.scheduledTime
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: "timer")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(palette.accent)
            }

            VStack(spacing: 4) {
                Text("Ready to start fasting?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(context.planName)
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
            }
        }
    }

    // MARK: - Time Card
    private var timeCard: some View {
        VStack(spacing: 8) {
            Text("Scheduled time")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)

            Text(context.formattedScheduledTime)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(palette.textPrimary)

            Text("\(context.durationHours)-hour fasting window")
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Main Actions
    private var mainActions: some View {
        VStack(spacing: 12) {
            // Confirm at scheduled time
            Button {
                onConfirmScheduledTime()
                onDismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))

                    Text("Yes, I started at \(context.formattedScheduledTime)")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)
            }
            .buttonStyle(.plain)

            // Different time
            Button {
                selectedTime = Date()
                showingTimePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 18))

                    Text("I started at a different time")
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(palette.textPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                )
            }
            .buttonStyle(.plain)

            // Remind later
            Button {
                snoozeTime = Date().addingTimeInterval(3600)
                showingSnoozePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))

                    Text("Remind me later")
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(palette.textPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                )
            }
            .buttonStyle(.plain)

            // Skip - non-judgemental
            Button {
                onSkipFast()
                onDismiss()
            } label: {
                Text("Skip for today")
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Supportive message
            Text("No pressure — do what feels right for you.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .italic()
                .padding(.top, 8)
        }
    }

    // MARK: - Custom Time Section
    private var customTimeSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("When did you start?")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(palette.textPrimary)

            DatePicker("", selection: $selectedTime, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()

            HStack(spacing: 12) {
                Button {
                    showingTimePicker = false
                } label: {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)

                Button {
                    onConfirmCustomTime(selectedTime)
                    onDismiss()
                } label: {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.accent)
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Snooze Section
    private var snoozeSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("When should we remind you?")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(palette.textPrimary)

            DatePicker("", selection: $snoozeTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()

            // Quick options
            HStack(spacing: 8) {
                ForEach([1, 2, 4], id: \.self) { hours in
                    Button {
                        snoozeTime = Date().addingTimeInterval(Double(hours) * 3600)
                    } label: {
                        Text("+\(hours)h")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(palette.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button {
                    showingSnoozePicker = false
                } label: {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)

                Button {
                    onSnoozeUntil(snoozeTime)
                    onDismiss()
                } label: {
                    Text("Set reminder")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.accent)
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Redesigned end confirmation sheet - calm, celebratory without pressure
struct FastingEndConfirmationRedesigned: View {
    let context: FastingConfirmationContext
    let actualStartTime: Date
    let onConfirmNow: () -> Void
    let onConfirmCustomTime: (Date) -> Void
    let onContinueFasting: () -> Void
    let onDismiss: () -> Void

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var currentDurationHours: Double {
        Date().timeIntervalSince(actualStartTime) / 3600
    }

    private var formattedDuration: String {
        let hours = Int(currentDurationHours)
        let minutes = Int((currentDurationHours - Double(hours)) * 60)
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    private var completionPercentage: Int {
        Int((currentDurationHours / Double(context.durationHours)) * 100)
    }

    private var isComplete: Bool {
        completionPercentage >= 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header
                    headerSection

                    // Duration card
                    durationCard

                    // Actions
                    if showingTimePicker {
                        customTimeSection
                    } else {
                        mainActions
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.xl)
                .padding(.bottom, 40)
            }
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            selectedTime = Date()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(isComplete ? SemanticColors.positive.opacity(0.12) : palette.accent.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(systemName: isComplete ? "checkmark.circle" : "timer")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(isComplete ? SemanticColors.positive : palette.accent)
            }

            VStack(spacing: 4) {
                Text(isComplete ? "Well done!" : "End your fast?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(context.planName)
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
            }
        }
    }

    // MARK: - Duration Card
    private var durationCard: some View {
        VStack(spacing: 12) {
            Text("You've fasted for")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)

            Text(formattedDuration)
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundColor(isComplete ? SemanticColors.positive : palette.textPrimary)

            // Progress bar - subtle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(palette.tertiary.opacity(0.2))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(isComplete ? SemanticColors.positive : palette.accent)
                        .frame(width: geometry.size.width * min(CGFloat(completionPercentage) / 100, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, DesignTokens.Spacing.md)

            Text("of \(context.durationHours)-hour goal")
                .font(.system(size: 14))
                .foregroundColor(palette.textSecondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
        )
    }

    // MARK: - Main Actions
    private var mainActions: some View {
        VStack(spacing: 12) {
            // End now
            Button {
                onConfirmNow()
                onDismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))

                    Text("End fasting window")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: isComplete ? [SemanticColors.positive, SemanticColors.positive.opacity(0.8)] : [palette.accent, palette.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(DesignTokens.Radius.md)
            }
            .buttonStyle(.plain)

            // Different time
            Button {
                selectedTime = Date()
                showingTimePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 18))

                    Text("I ended at a different time")
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                }
                .foregroundColor(palette.textPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                )
            }
            .buttonStyle(.plain)

            // Continue
            Button {
                onContinueFasting()
                onDismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))

                    Text("Keep going")
                        .font(.system(size: 15, weight: .medium))

                    Spacer()
                }
                .foregroundColor(palette.textPrimary)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                )
            }
            .buttonStyle(.plain)

            // Supportive message
            Text("Every session counts, no matter the duration.")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .italic()
                .padding(.top, 8)
        }
    }

    // MARK: - Custom Time Section
    private var customTimeSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("When did you break your fast?")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(palette.textPrimary)

            DatePicker("", selection: $selectedTime, in: actualStartTime...Date(), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()

            HStack(spacing: 12) {
                Button {
                    showingTimePicker = false
                } label: {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)

                Button {
                    onConfirmCustomTime(selectedTime)
                    onDismiss()
                } label: {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(palette.accent)
                        .cornerRadius(DesignTokens.Radius.md)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FastingMainViewRedesigned(viewModel: FastingViewModel.preview)
        .environmentObject(SubscriptionManager())
}
