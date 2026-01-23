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
        var currentHours: Int
        var currentMinutes: Int
        var remainingHours: Int
        var remainingMinutes: Int
        var currentPhase: String
        var phaseEmoji: String
    }

    var fastingGoalHours: Int
}

// MARK: - Design Constants
private enum LiveActivityDesign {
    // Warm, muted palette matching app onboarding
    static let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.65, blue: 0.45),  // Warm peach
            Color(red: 0.90, green: 0.50, blue: 0.40)   // Soft coral
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accent = Color(red: 0.95, green: 0.60, blue: 0.42)
    static let accentLight = Color(red: 0.95, green: 0.75, blue: 0.60)
    static let textMuted = Color.white.opacity(0.55)
    static let textSecondary = Color.white.opacity(0.75)
}

// MARK: - Fasting Live Activity Widget
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // Lock screen / banner UI - Elegant horizontal layout
            HStack(spacing: 0) {
                // Left - Elapsed time with subtle ring
                HStack(spacing: 14) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(context.state.currentHours) / CGFloat(context.attributes.fastingGoalHours), 1.0))
                            .stroke(
                                LiveActivityDesign.accentGradient,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        Text(context.state.phaseEmoji)
                            .font(.system(size: 16))
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Elapsed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(LiveActivityDesign.textMuted)
                        Text("\(context.state.currentHours)h \(context.state.currentMinutes)m")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Right - Remaining time
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Remaining")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(LiveActivityDesign.textMuted)

                    if context.state.remainingHours <= 0 && context.state.remainingMinutes <= 0 {
                        Text("Complete")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        Text("\(context.state.remainingHours)h \(context.state.remainingMinutes)m")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(LiveActivityDesign.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        // Mini progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 2.5)
                            Circle()
                                .trim(from: 0, to: min(CGFloat(context.state.currentHours) / CGFloat(context.attributes.fastingGoalHours), 1.0))
                                .stroke(LiveActivityDesign.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Elapsed")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(LiveActivityDesign.textMuted)
                            Text("\(context.state.currentHours)h \(context.state.currentMinutes)m")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .fixedSize()
                        }
                    }
                }

                // Expanded UI - Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(LiveActivityDesign.textMuted)
                        Text("\(context.state.remainingHours)h \(context.state.remainingMinutes)m")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(LiveActivityDesign.accent)
                            .fixedSize()
                    }
                }

                // Expanded UI - Bottom (centered phase)
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Text(context.state.phaseEmoji)
                            .font(.system(size: 14))
                        Text(context.state.currentPhase)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(LiveActivityDesign.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }

            } compactLeading: {
                HStack(spacing: 5) {
                    // Tiny progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: min(CGFloat(context.state.currentHours) / CGFloat(context.attributes.fastingGoalHours), 1.0))
                            .stroke(LiveActivityDesign.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 12, height: 12)

                    Text("\(context.state.currentHours)h")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

            } compactTrailing: {
                Text("\(context.state.remainingHours)h")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(LiveActivityDesign.accent)

            } minimal: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: min(CGFloat(context.state.currentHours) / CGFloat(context.attributes.fastingGoalHours), 1.0))
                        .stroke(LiveActivityDesign.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .contentMargins(.leading, 32, for: .expanded)
            .contentMargins(.trailing, 32, for: .expanded)
            .contentMargins(.top, 14, for: .expanded)
            .contentMargins(.bottom, 14, for: .expanded)
        }
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
        FastingActivityAttributes.ContentState(
            fastingStartTime: Date().addingTimeInterval(-4 * 3600),
            currentHours: 4,
            currentMinutes: 30,
            remainingHours: 11,
            remainingMinutes: 30,
            currentPhase: "Fuel switching",
            phaseEmoji: "🔄"
        )
    }

    fileprivate static var midFast: FastingActivityAttributes.ContentState {
        FastingActivityAttributes.ContentState(
            fastingStartTime: Date().addingTimeInterval(-12 * 3600),
            currentHours: 12,
            currentMinutes: 15,
            remainingHours: 3,
            remainingMinutes: 45,
            currentPhase: "Mild ketosis",
            phaseEmoji: "🔥"
        )
    }

    fileprivate static var goalReached: FastingActivityAttributes.ContentState {
        FastingActivityAttributes.ContentState(
            fastingStartTime: Date().addingTimeInterval(-16 * 3600),
            currentHours: 16,
            currentMinutes: 30,
            remainingHours: 0,
            remainingMinutes: 0,
            currentPhase: "Autophagy",
            phaseEmoji: "✨"
        )
    }
}
