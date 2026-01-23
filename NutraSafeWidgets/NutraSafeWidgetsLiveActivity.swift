//
//  NutraSafeWidgetsLiveActivity.swift
//  NutraSafeWidgets
//
//  Fasting Live Activity for Dynamic Island and Lock Screen
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var fastingStartTime: Date
        var fastingEndTime: Date
        var currentHours: Int
        var currentMinutes: Int
        var currentSeconds: Int
        var remainingHours: Int
        var remainingMinutes: Int
        var remainingSeconds: Int
        var currentPhase: String
        var phaseEmoji: String
    }

    var fastingGoalHours: Int
}

// MARK: - Fasting Phase Calculator
private struct FastingPhase {
    let name: String
    let emoji: String

    static func calculate(from startTime: Date) -> FastingPhase {
        let elapsed = Date().timeIntervalSince(startTime)
        let hours = Int(elapsed / 3600)

        switch hours {
        case 0..<4:
            return FastingPhase(name: "Post-meal", emoji: "🍽️")
        case 4..<8:
            return FastingPhase(name: "Fuel switch", emoji: "🔄")
        case 8..<12:
            return FastingPhase(name: "Fat burning", emoji: "💪")
        case 12..<16:
            return FastingPhase(name: "Ketosis", emoji: "🔥")
        case 16..<20:
            return FastingPhase(name: "Autophagy", emoji: "✨")
        default:
            return FastingPhase(name: "Deep fast", emoji: "🧘")
        }
    }
}

// MARK: - Design System
private enum Design {
    static let teal = Color(red: 0.0, green: 0.78, blue: 0.73)
    static let tealLight = Color(red: 0.4, green: 0.9, blue: 0.85)

    static let ringTrack = Color.white.opacity(0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textMuted = Color.white.opacity(0.45)
}

// MARK: - Fasting Live Activity Widget
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // Lock Screen UI
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded - Leading
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeading(context: context)
                }

                // Expanded - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailing(context: context)
                }

                // Expanded - Center
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenter(context: context)
                }

                // Expanded - Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottom(context: context)
                }

            } compactLeading: {
                CompactLeading(context: context)
            } compactTrailing: {
                CompactTrailing(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Expanded Views

private struct ExpandedLeading: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        EmptyView()
    }
}

private struct ExpandedTrailing: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        EmptyView()
    }
}

private struct ExpandedCenter: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Title row
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Design.teal)
                Text("NutraSafe - Fasting")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Design.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("REMAINING")
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.5)
                        .foregroundColor(Design.textMuted)
                        .multilineTextAlignment(.center)

                    if context.state.fastingEndTime > Date() {
                        Text(timerInterval: Date()...context.state.fastingEndTime, countsDown: true)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(Design.teal)
                            .monospacedDigit()
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Done!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 6)
    }
}

private struct ExpandedBottom: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    private var phase: FastingPhase {
        FastingPhase.calculate(from: context.state.fastingStartTime)
    }

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(context.state.fastingStartTime)
        let goal = Double(context.attributes.fastingGoalHours) * 3600
        return min(max(elapsed / goal, 0.02), 1.0)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Phase text only (ring is in center)
            HStack(spacing: 4) {
                Text(phase.emoji)
                    .font(.system(size: 11))
                Text(phase.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Design.textSecondary)
                    .lineLimit(1).truncationMode(.tail).minimumScaleFactor(0.8).allowsTightening(true)
            }

            // Progress bar (full width)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Design.ringTrack)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Design.teal, Design.tealLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * CGFloat(progress), 4))
                }
            }
            .frame(height: 3)
            .clipped()
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }
}

// MARK: - Compact Views

private struct CompactLeading: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Design.teal)
            Text(context.state.fastingStartTime, style: .timer)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.6).allowsTightening(true)
        }
    }
}

private struct CompactTrailing: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            if context.state.fastingEndTime > Date() {
                Image(systemName: "hourglass")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Design.teal)
                Text(timerInterval: Date()...context.state.fastingEndTime, countsDown: true)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Design.teal)
                    .monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.6).allowsTightening(true)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Minimal View

private struct MinimalView: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(context.state.fastingStartTime)
        let goal = Double(context.attributes.fastingGoalHours) * 3600
        return min(max(elapsed / goal, 0.02), 1.0)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Design.ringTrack)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Design.teal, Design.tealLight],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(22 * CGFloat(progress), 4))
        }
        .frame(width: 22, height: 3)
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<FastingActivityAttributes>

    private var progress: Double {
        let elapsed = Date().timeIntervalSince(context.state.fastingStartTime)
        let goal = Double(context.attributes.fastingGoalHours) * 3600
        return min(max(elapsed / goal, 0.02), 1.0)
    }

    private var phase: FastingPhase {
        FastingPhase.calculate(from: context.state.fastingStartTime)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Design.teal)
                    Text("NutraSafe - Fasting")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Design.textSecondary)
                        .lineLimit(1).truncationMode(.tail).minimumScaleFactor(0.8).allowsTightening(true)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(phase.emoji)
                        .font(.system(size: 11))
                    Text(phase.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Design.textSecondary)
                        .lineLimit(1).truncationMode(.tail).minimumScaleFactor(0.8).allowsTightening(true)
                }
            }

            // Main timers
            HStack {
                // Elapsed
                VStack(alignment: .leading, spacing: 4) {
                    Text("ELAPSED")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.5)
                        .foregroundColor(Design.textMuted)
                        .lineLimit(1).minimumScaleFactor(0.8).allowsTightening(true)

                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(Design.ringTrack, lineWidth: 3)
                            Circle()
                                .trim(from: 0, to: CGFloat(progress))
                                .stroke(Design.teal, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 34, height: 34)

                        Text(context.state.fastingStartTime, style: .timer)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(Design.textPrimary)
                            .monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.6).allowsTightening(true)
                    }
                }

                Spacer()

                // Remaining
                VStack(alignment: .trailing, spacing: 4) {
                    Text("REMAINING")
                        .font(.system(size: 9, weight: .bold))
                        .kerning(0.5)
                        .foregroundColor(Design.textMuted)
                        .lineLimit(1).minimumScaleFactor(0.8).allowsTightening(true)

                    HStack(spacing: 8) {
                        if context.state.fastingEndTime > Date() {
                            Text(timerInterval: Date()...context.state.fastingEndTime, countsDown: true)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .foregroundColor(Design.teal)
                                .monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.6).allowsTightening(true)
                        } else {
                            Text("DONE!")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.green)
                                .lineLimit(1).minimumScaleFactor(0.8).allowsTightening(true)
                        }

                        ZStack {
                            Circle()
                                .stroke(Design.ringTrack, lineWidth: 3)
                            Circle()
                                .trim(from: 0, to: CGFloat(1.0 - progress))
                                .stroke(Design.teal, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 34, height: 34)
                    }
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Design.ringTrack)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Design.teal, Design.tealLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * CGFloat(progress), 4))
                }
            }
            .frame(height: 3)
            .clipped()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Previews
extension FastingActivityAttributes {
    fileprivate static var preview: FastingActivityAttributes {
        FastingActivityAttributes(fastingGoalHours: 16)
    }
}

extension FastingActivityAttributes.ContentState {
    fileprivate static var earlyFast: FastingActivityAttributes.ContentState {
        let startTime = Date().addingTimeInterval(-29 * 60)
        let endTime = startTime.addingTimeInterval(16 * 3600)
        return FastingActivityAttributes.ContentState(
            fastingStartTime: startTime,
            fastingEndTime: endTime,
            currentHours: 0,
            currentMinutes: 29,
            currentSeconds: 0,
            remainingHours: 15,
            remainingMinutes: 31,
            remainingSeconds: 0,
            currentPhase: "Post-meal",
            phaseEmoji: "🍽️"
        )
    }
}

