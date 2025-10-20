//
//  FastingLiveActivity.swift
//  NutraSafe Beta
//
//  Live Activity widget for displaying fasting status in Dynamic Island
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget
@available(iOS 16.1, *)
struct FastingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FastingActivityAttributes.self) { context in
            // Lock screen / banner UI
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Fasting")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(context.state.currentHours)h \(context.state.currentMinutes)m")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(context.attributes.fastingGoalHours)h")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.3))
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fasting")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(context.state.currentHours)h \(context.state.currentMinutes)m")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Goal: \(context.attributes.fastingGoalHours)h")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ProgressView(value: Double(context.state.currentHours), total: Double(context.attributes.fastingGoalHours))
                            .tint(.orange)
                            .frame(width: 60)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // Center region - time elapsed since start
                    Text("Started \(context.state.fastingStartTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                        Text("Stay strong! You're doing great.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }

            } compactLeading: {
                // Compact leading (left side of Dynamic Island pill)
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)

            } compactTrailing: {
                // Compact trailing (right side of Dynamic Island pill)
                Text("\(context.state.currentHours)h")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

            } minimal: {
                // Minimal (when multiple activities are active)
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            }
            .contentMargins(.all, 8, for: .expanded)
        }
    }
}
