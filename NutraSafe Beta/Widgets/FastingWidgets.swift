import WidgetKit
import SwiftUI

// MARK: - Widget Palette (Onboarding-Derived)
// Widgets have their own target, so we define colors inline matching onboarding.
// NO platform blue. Palette-aligned teal/accent throughout.

struct WidgetPalette {
    static let accent = Color(red: 0.00, green: 0.60, blue: 0.55)        // Teal (from onboarding)
    static let primary = Color(red: 0.20, green: 0.45, blue: 0.50)       // Deep teal
    static let secondary = Color(red: 0.15, green: 0.35, blue: 0.42)     // Darker teal
}

// MARK: - Widget Provider

struct FastingWidgetProvider: TimelineProvider {
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
        let entry = FastingWidgetEntry(
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
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingWidgetEntry>) -> ()) {
        var entries: [FastingWidgetEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset * 30, to: currentDate)!

            // In a real app, you would fetch actual data here
            let widgetData = getCurrentWidgetData()

            let entry = FastingWidgetEntry(
                date: entryDate,
                widgetData: widgetData
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func getCurrentWidgetData() -> FastingWidgetData {
        // This would typically fetch from UserDefaults, Core Data, or make an API call
        // For now, return placeholder data
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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fasting Status")
        .description("Quick view of your current fasting status and progress.")
        .supportedFamilies([.systemSmall])
    }
}

struct FastingSmallStatusWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            // Header - use palette accent instead of .blue
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(WidgetPalette.accent)

                Text("Fasting")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()
            }

            // Main content based on status
            if entry.widgetData.status == .idle {
                IdleStateView()
            } else if entry.widgetData.status == .active {
                ActiveStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .nearEnd {
                NearEndStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .overGoal {
                OverGoalStateView(widgetData: entry.widgetData)
            } else if entry.widgetData.status == .skipped {
                SkippedStateView()
            }

            Spacer()

            // Motivational text
            Text(entry.widgetData.motivationalText)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
    }
}

// MARK: - Medium Progress Widget

struct FastingMediumProgressWidget: Widget {
    let kind: String = "FastingMediumProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingWidgetProvider()) { entry in
            FastingMediumProgressWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fasting Progress")
        .description("Detailed view of your fasting progress with timeline.")
        .supportedFamilies([.systemMedium])
    }
}

struct FastingMediumProgressWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Progress ring with palette gradient
            VStack(spacing: 8) {
                if let progress = entry.widgetData.progressPercentage {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                            .frame(width: 60, height: 60)

                        Circle()
                            .trim(from: 0, to: CGFloat(progress))
                            .stroke(
                                AngularGradient(
                                    gradient: Gradient(colors: [WidgetPalette.accent, WidgetPalette.primary]),
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 60, height: 60)

                        VStack(spacing: 0) {
                            if let elapsed = entry.widgetData.elapsedTime {
                                Text(elapsed)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }

                            if let phase = entry.widgetData.currentPhase {
                                Text(phase)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    Image(systemName: "timer")
                        .font(.largeTitle)
                        .foregroundColor(WidgetPalette.accent)
                        .frame(width: 60, height: 60)
                }
            }

            // Right side - Details
            VStack(alignment: .leading, spacing: 8) {
                if entry.widgetData.status == .idle {
                    Text("Ready to Start")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Tap to begin your next fast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Text(entry.widgetData.status == .overGoal ? "Goal Achieved!" : "Fasting Active")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Spacer()

                        if entry.widgetData.status == .nearEnd {
                            Image(systemName: "flag.checkered")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    if let elapsed = entry.widgetData.elapsedTime,
                       let remaining = entry.widgetData.remainingTime {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Elapsed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(elapsed)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Remaining")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(remaining)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    if let milestone = entry.widgetData.nextMilestone {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.forward.circle")
                                .font(.caption2)
                                .foregroundColor(WidgetPalette.accent)

                            Text(milestone)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text(entry.widgetData.motivationalText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Quick Action Widget

struct FastingQuickActionWidget: Widget {
    let kind: String = "FastingQuickActionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingWidgetProvider()) { entry in
            FastingQuickActionWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fasting Actions")
        .description("Quick actions to control your fasting sessions.")
        .supportedFamilies([.systemMedium])
    }
}

struct FastingQuickActionWidgetEntryView: View {
    var entry: FastingWidgetEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header - use palette accent
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(WidgetPalette.accent)

                Text("Fasting Actions")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()
            }

            if entry.widgetData.status == .idle {
                // Start fasting action - palette accent instead of .blue
                Button(intent: StartFastingIntent()) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Fasting")
                                .font(.headline)
                                .fontWeight(.semibold)

                            Text("Begin your next session")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [WidgetPalette.accent, WidgetPalette.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                // Active session actions
                HStack(spacing: 12) {
                    // End Fast Action
                    Button(intent: EndFastingIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.title3)

                            Text("End")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    // Edit Times Action
                    Button(intent: EditFastingTimesIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.title3)

                            Text("Edit")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    // Skip Today Action
                    Button(intent: SkipFastingIntent()) {
                        VStack(spacing: 4) {
                            Image(systemName: "forward.fill")
                                .font(.title3)

                            Text("Skip")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Current status
            if entry.widgetData.status != .idle {
                HStack {
                    if let elapsed = entry.widgetData.elapsedTime {
                        Label(elapsed, systemImage: "clock")
                            .font(.caption)
                    }

                    Spacer()

                    if let phase = entry.widgetData.currentPhase {
                        Label(phase, systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
    }
}

// MARK: - Widget Views Components

struct IdleStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundColor(WidgetPalette.accent)

            Text("Ready")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Tap to start")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ActiveStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()

                Spacer()

                if let phase = widgetData.currentPhase {
                    Text(phase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let remaining = widgetData.remainingTime {
                HStack {
                    Text("Remaining:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(remaining)
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        }
    }
}

struct NearEndStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                    .foregroundColor(.orange)

                Spacer()

                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            Text("Almost there!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
        }
    }
}

struct OverGoalStateView: View {
    let widgetData: FastingWidgetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(WidgetPalette.accent)

                Spacer()

                Text(widgetData.elapsedTime ?? "--:--")
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }

            Text("Goal achieved!")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(WidgetPalette.accent)
        }
    }
}

struct SkippedStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "forward.fill")
                .font(.title2)
                .foregroundColor(.gray)

            Text("Skipped Today")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text("Reset tomorrow")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
