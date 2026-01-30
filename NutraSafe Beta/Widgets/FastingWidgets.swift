import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Data Model
// Duplicated here because widgets run in their own extension target

struct FastingWidgetData {
    let sessionId: String?
    let status: WidgetStatus
    let elapsedTime: String?
    let remainingTime: String?
    let currentPhase: String?
    let nextMilestone: String?
    let motivationalText: String
    let progressPercentage: Double?

    enum WidgetStatus {
        case idle
        case active
        case nearEnd
        case overGoal
        case skipped
    }
}

// MARK: - Widget Palette (Onboarding-Derived)
// Widgets have their own target, so we define colors inline matching onboarding.
// NO platform blue. Palette-aligned teal/accent throughout.

struct WidgetPalette {
    static let accent = Color(red: 0.00, green: 0.60, blue: 0.55)        // Teal (from onboarding)
    static let primary = Color(red: 0.20, green: 0.45, blue: 0.50)       // Deep teal
    static let secondary = Color(red: 0.15, green: 0.35, blue: 0.42)     // Darker teal
}

// MARK: - Shared Data Reader (App Group)

struct SharedFastingDataReader {
    private let appGroupId = "group.com.nutrasafe.beta"

    struct SharedFastingData {
        let isActive: Bool
        let startTime: Date?
        let targetDurationHours: Int?
        let currentPhase: String?
        let planName: String?
        let lastUpdated: Date
    }

    func loadData() -> SharedFastingData? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: "fastingSessionData"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let isActive = json["isActive"] as? Bool ?? false

        var startTime: Date?
        if let startTimeInterval = json["startTime"] as? TimeInterval {
            startTime = Date(timeIntervalSince1970: startTimeInterval)
        }

        let targetDurationHours = json["targetDurationHours"] as? Int
        let currentPhase = json["currentPhase"] as? String
        let planName = json["planName"] as? String

        var lastUpdated = Date()
        if let lastUpdatedInterval = json["lastUpdated"] as? TimeInterval {
            lastUpdated = Date(timeIntervalSince1970: lastUpdatedInterval)
        }

        return SharedFastingData(
            isActive: isActive,
            startTime: startTime,
            targetDurationHours: targetDurationHours,
            currentPhase: currentPhase,
            planName: planName,
            lastUpdated: lastUpdated
        )
    }
}

// MARK: - Widget Provider

struct FastingWidgetProvider: TimelineProvider {
    private let dataReader = SharedFastingDataReader()

    func placeholder(in context: Context) -> FastingWidgetEntry {
        FastingWidgetEntry(
            date: Date(),
            widgetData: FastingWidgetData(
                sessionId: "preview",
                status: .active,
                elapsedTime: "6h 22m",
                remainingTime: "9h 38m",
                currentPhase: "Mild Ketosis",
                nextMilestone: "Autophagy in 1h 38m",
                motivationalText: "You're doing great — stay steady.",
                progressPercentage: 0.65
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingWidgetEntry) -> ()) {
        let widgetData = computeWidgetData(for: Date())
        let entry = FastingWidgetEntry(date: Date(), widgetData: widgetData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingWidgetEntry>) -> ()) {
        var entries: [FastingWidgetEntry] = []
        let currentDate = Date()

        // Generate entries every 5 minutes for the next 2 hours for smooth countdown
        for minuteOffset in stride(from: 0, to: 120, by: 5) {
            guard let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) else {
                continue
            }
            let widgetData = computeWidgetData(for: entryDate)
            let entry = FastingWidgetEntry(date: entryDate, widgetData: widgetData)
            entries.append(entry)
        }

        // Refresh after 5 minutes for live updates
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate.addingTimeInterval(300)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func computeWidgetData(for date: Date) -> FastingWidgetData {
        guard let sharedData = dataReader.loadData(),
              sharedData.isActive,
              let startTime = sharedData.startTime,
              let targetHours = sharedData.targetDurationHours else {
            // No active session
            return FastingWidgetData(
                sessionId: nil,
                status: .idle,
                elapsedTime: nil,
                remainingTime: nil,
                currentPhase: nil,
                nextMilestone: nil,
                motivationalText: "Tap to begin your next fast",
                progressPercentage: nil
            )
        }

        // Calculate elapsed time
        let elapsedSeconds = date.timeIntervalSince(startTime)
        let elapsedHours = elapsedSeconds / 3600
        let targetSeconds = Double(targetHours) * 3600
        let remainingSeconds = max(0, targetSeconds - elapsedSeconds)

        // Format elapsed time
        let elapsedH = Int(elapsedSeconds) / 3600
        let elapsedM = (Int(elapsedSeconds) % 3600) / 60
        let elapsedTimeString = "\(elapsedH)h \(elapsedM)m"

        // Format remaining time
        let remainingH = Int(remainingSeconds) / 3600
        let remainingM = (Int(remainingSeconds) % 3600) / 60
        let remainingTimeString = remainingSeconds > 0 ? "\(remainingH)h \(remainingM)m" : "0h 0m"

        // Calculate progress percentage
        let progress = min(1.0, elapsedSeconds / targetSeconds)

        // Determine status
        let status: FastingWidgetData.WidgetStatus
        if elapsedHours >= Double(targetHours) {
            status = .overGoal
        } else if progress >= 0.9 {
            status = .nearEnd
        } else {
            status = .active
        }

        // Determine phase and milestone based on elapsed hours
        let (phase, milestone) = getPhaseInfo(elapsedHours: elapsedHours)

        // Get motivational text
        let motivationalText = getMotivationalText(status: status, progress: progress)

        return FastingWidgetData(
            sessionId: "active",
            status: status,
            elapsedTime: elapsedTimeString,
            remainingTime: remainingTimeString,
            currentPhase: sharedData.currentPhase ?? phase,
            nextMilestone: milestone,
            motivationalText: motivationalText,
            progressPercentage: progress
        )
    }

    private func getPhaseInfo(elapsedHours: Double) -> (phase: String, milestone: String?) {
        switch elapsedHours {
        case 0..<4:
            return ("Fed State", "Fat Burning in \(Int(4 - elapsedHours))h")
        case 4..<8:
            return ("Fat Burning", "Ketosis in \(Int(8 - elapsedHours))h")
        case 8..<12:
            return ("Mild Ketosis", "Deep Ketosis in \(Int(12 - elapsedHours))h")
        case 12..<16:
            return ("Deep Ketosis", "Autophagy in \(Int(16 - elapsedHours))h")
        case 16..<24:
            return ("Autophagy", "Deep Autophagy in \(Int(24 - elapsedHours))h")
        default:
            return ("Deep Autophagy", nil)
        }
    }

    private func getMotivationalText(status: FastingWidgetData.WidgetStatus, progress: Double) -> String {
        switch status {
        case .overGoal:
            return "Amazing! You exceeded your goal!"
        case .nearEnd:
            return "Almost there - stay strong!"
        case .active:
            if progress < 0.25 {
                return "Great start - keep going!"
            } else if progress < 0.5 {
                return "You're doing great!"
            } else if progress < 0.75 {
                return "Halfway there - stay steady!"
            } else {
                return "So close - push through!"
            }
        case .idle, .skipped:
            return "Tap to begin your next fast"
        }
    }
}

// MARK: - Widget Entry

struct FastingWidgetEntry: TimelineEntry {
    let date: Date
    let widgetData: FastingWidgetData
}

// MARK: - Small Status Widget

struct FastingSmallStatusWidget: Widget {
    let kind: String = "FastingSmallStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingWidgetProvider()) { entry in
            FastingSmallStatusWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.12, blue: 0.14),
                            Color(red: 0.08, green: 0.18, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("NutraSafe Fasting")
        .description("Quick view of your current fasting status and progress.")
        .supportedFamilies([.systemSmall])
    }
}

struct FastingSmallStatusWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header with NutraSafe branding
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(WidgetPalette.accent)

                Text("NUTRASAFE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
            }
            .padding(.bottom, 6)

            // Fasting label
            HStack {
                Text("Fasting")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.bottom, 10)

            // Main content based on status
            if entry.widgetData.status == .idle {
                SmallIdleStateView()
            } else if entry.widgetData.status == .active {
                SmallActiveStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .nearEnd {
                SmallNearEndStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .overGoal {
                SmallOverGoalStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .skipped {
                SmallSkippedStateView()
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

// MARK: - Medium Progress Widget

struct FastingMediumProgressWidget: Widget {
    let kind: String = "FastingMediumProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingWidgetProvider()) { entry in
            FastingMediumProgressWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.12, blue: 0.14),
                            Color(red: 0.08, green: 0.18, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("NutraSafe Fasting")
        .description("Detailed view of your fasting progress with timeline.")
        .supportedFamilies([.systemMedium])
    }
}

struct FastingMediumProgressWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Header with NutraSafe branding
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(WidgetPalette.accent)

                Text("NUTRASAFE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.6))

                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))

                Text("Fasting")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                if entry.widgetData.status == .active || entry.widgetData.status == .nearEnd {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(WidgetPalette.accent)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(WidgetPalette.accent)
                    }
                }
            }
            .padding(.bottom, 12)

            HStack(spacing: 16) {
                // Left side - Progress ring
                if entry.widgetData.status != .idle {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 72, height: 72)

                        Circle()
                            .trim(from: 0, to: CGFloat(entry.widgetData.progressPercentage ?? 0))
                            .stroke(
                                LinearGradient(
                                    colors: [WidgetPalette.accent, WidgetPalette.accent.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 72, height: 72)

                        VStack(spacing: 2) {
                            Text(entry.widgetData.elapsedTime ?? "--:--")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()

                            Text("elapsed")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .textCase(.uppercase)
                        }
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)
                            .frame(width: 72, height: 72)

                        Image(systemName: "timer")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(WidgetPalette.accent)
                    }
                }

                // Right side - Details
                VStack(alignment: .leading, spacing: 8) {
                    if entry.widgetData.status == .idle {
                        Text("Ready to Fast")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Tap to begin your next session")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))

                        Spacer(minLength: 0)

                        Text(entry.widgetData.motivationalText)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .italic()
                            .lineLimit(2)
                    } else {
                        // Status title
                        HStack(spacing: 6) {
                            if entry.widgetData.status == .overGoal {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                                Text("Goal Achieved!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.yellow)
                            } else if entry.widgetData.status == .nearEnd {
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                Text("Almost There!")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.orange)
                            } else if let phase = entry.widgetData.currentPhase {
                                Text(phase)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        // Time remaining
                        if let remaining = entry.widgetData.remainingTime {
                            HStack(spacing: 4) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("\(remaining) remaining")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        Spacer(minLength: 0)

                        // Next milestone
                        if let milestone = entry.widgetData.nextMilestone {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(WidgetPalette.accent)
                                Text(milestone)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
    }
}

// MARK: - Quick Action Widget

struct FastingQuickActionWidget: Widget {
    let kind: String = "FastingQuickActionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingWidgetProvider()) { entry in
            FastingQuickActionWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.12, blue: 0.14),
                            Color(red: 0.08, green: 0.18, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("NutraSafe Fasting Actions")
        .description("Quick actions to control your fasting sessions.")
        .supportedFamilies([.systemMedium])
    }
}

struct FastingQuickActionWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        VStack(spacing: 12) {
            // Header with NutraSafe branding
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(WidgetPalette.accent)

                Text("NUTRASAFE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.6))

                Text("•")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.3))

                Text("Fasting")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            if entry.widgetData.status == .idle {
                // Start fasting action
                Button(intent: StartFastingIntent()) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(WidgetPalette.accent.opacity(0.2))
                                .frame(width: 44, height: 44)
                            Image(systemName: "play.fill")
                                .font(.system(size: 18))
                                .foregroundColor(WidgetPalette.accent)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start Fasting")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Begin your next session")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(WidgetPalette.accent.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Active session - show status and actions
                HStack(spacing: 12) {
                    // Status info
                    VStack(alignment: .leading, spacing: 6) {
                        if let elapsed = entry.widgetData.elapsedTime {
                            Text(elapsed)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }

                        if let phase = entry.widgetData.currentPhase {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                                    .foregroundColor(WidgetPalette.accent)
                                Text(phase)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 8) {
                        Button(intent: EndFastingIntent()) {
                            VStack(spacing: 4) {
                                Image(systemName: "stop.fill")
                                    .font(.system(size: 16))
                                Text("End")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(width: 52, height: 52)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button(intent: EditFastingTimesIntent()) {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                Text("Edit")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(width: 52, height: 52)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        Button(intent: SkipFastingIntent()) {
                            VStack(spacing: 4) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 16))
                                Text("Skip")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .frame(width: 52, height: 52)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(16)
    }
}

// MARK: - Small Widget State Views

struct SmallIdleStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(WidgetPalette.accent)
            }

            VStack(spacing: 3) {
                Text("Ready")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Tap to start")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SmallActiveStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            // Progress ring with time
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 5)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(widgetData.progressPercentage ?? 0))
                    .stroke(WidgetPalette.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)

                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            // Phase & remaining
            VStack(spacing: 3) {
                if let phase = widgetData.currentPhase {
                    Text(phase)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }

                if let remaining = widgetData.remainingTime {
                    Text("\(remaining) left")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
}

struct SmallNearEndStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.3), lineWidth: 5)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(widgetData.progressPercentage ?? 0.95))
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)

                Image(systemName: "flag.checkered")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 3) {
                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("Almost there!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }
}

struct SmallOverGoalStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(WidgetPalette.accent.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.yellow)
            }

            VStack(spacing: 3) {
                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text("Goal achieved!")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(WidgetPalette.accent)
            }
        }
    }
}

struct SmallSkippedStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 56, height: 56)

                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.4))
            }

            VStack(spacing: 3) {
                Text("Skipped")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text("Reset tomorrow")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Intents

struct StartFastingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Fasting"
    static var description = IntentDescription("Begin a new fasting session")

    func perform() async throws -> some IntentResult {
        // In a real app, this would trigger the fasting service
        return .result()
    }
}

struct EndFastingIntent: AppIntent {
    static var title: LocalizedStringResource = "End Fast"
    static var description = IntentDescription("End the current fasting session")

    func perform() async throws -> some IntentResult {
        // In a real app, this would trigger the fasting service
        return .result()
    }
}

struct EditFastingTimesIntent: AppIntent {
    static var title: LocalizedStringResource = "Edit Times"
    static var description = IntentDescription("Edit fasting session times")

    func perform() async throws -> some IntentResult {
        // In a real app, this would open the edit times view
        return .result()
    }
}

struct SkipFastingIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Today"
    static var description = IntentDescription("Skip today's fasting session")

    func perform() async throws -> some IntentResult {
        // In a real app, this would trigger the fasting service
        return .result()
    }
}

// MARK: - Widget Configuration (Home Screen Widgets - Future Feature)
// Note: These home screen widgets require the NutraSafeWidgets extension target.
// Currently only the Live Activity is implemented in the widget extension.

struct FastingWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastingSmallStatusWidget()
        FastingMediumProgressWidget()
        FastingQuickActionWidget()
    }
}
