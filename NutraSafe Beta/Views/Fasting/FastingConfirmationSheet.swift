//
//  FastingConfirmationSheet.swift
//  NutraSafe Beta
//
//  Clock-in/clock-out confirmation flow for fasting sessions
//  Triggered when user taps a fasting notification
//

import SwiftUI

// FastingConfirmationContext is defined in FastingModels.swift

// MARK: - Start Confirmation Sheet

/// Confirmation sheet for starting a fast (clock-in)
struct FastingStartConfirmationSheet: View {
    let context: FastingConfirmationContext
    let onConfirmScheduledTime: () -> Void
    let onConfirmCustomTime: (Date) -> Void
    let onNotStartedYet: () -> Void
    let onDismiss: () -> Void

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "clock.badge.checkmark.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.green, .green.opacity(0.7))
                            }

                            Text("Time to Start Fasting")
                            .font(.system(size: 24, weight: .bold))

                        Text(context.planName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Scheduled time card
                    VStack(spacing: 8) {
                        Text("Scheduled Start Time")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(context.formattedScheduledTime)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("\(context.durationHours) hour fast")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    .padding(.horizontal)

                    if showingTimePicker {
                        // Custom time picker view
                        timePickerView
                    } else {
                        // Main actions
                        mainActionsView
                    }
                }
                .padding(.bottom, 40)
                }
            }
            .background(Color.adaptiveCard)
            .onAppear {
                selectedTime = context.scheduledTime
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Main Actions View

    private var mainActionsView: some View {
        VStack(spacing: 12) {
            // Confirm at scheduled time
            Button(action: {
                onConfirmScheduledTime()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Yes, I Started at \(context.formattedScheduledTime)")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Confirm scheduled start time")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(14)
            }

            // I started at a different time
            Button(action: {
                selectedTime = Date()
                showingTimePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("I Started at a Different Time")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Enter when you actually began")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(14)
            }

            // Not started yet
            Button(action: {
                onNotStartedYet()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark.fill")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Not Started Yet")
                            .font(.system(size: 17, weight: .semibold))
                        Text("I'll start later")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray5))
                .cornerRadius(14)
            }

            // Cancel
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Time Picker View

    private var timePickerView: some View {
        VStack(spacing: 16) {
            Text("When did you start?")
                .font(.system(size: 18, weight: .semibold))

            DatePicker(
                "Start Time",
                selection: $selectedTime,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            HStack(spacing: 12) {
                Button(action: {
                    showingTimePicker = false
                }) {
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }

                Button(action: {
                    onConfirmCustomTime(selectedTime)
                    onDismiss()
                }) {
                    Text("Confirm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - End Confirmation Sheet

/// Confirmation sheet for ending a fast (clock-out)
struct FastingEndConfirmationSheet: View {
    let context: FastingConfirmationContext
    let actualStartTime: Date
    let onConfirmNow: () -> Void
    let onConfirmCustomTime: (Date) -> Void
    let onContinueFasting: () -> Void
    let onDismiss: () -> Void

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @Environment(\.colorScheme) private var colorScheme

    private var currentDuration: TimeInterval {
        Date().timeIntervalSince(actualStartTime)
    }

    private var currentDurationHours: Double {
        currentDuration / 3600
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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(completionPercentage >= 100 ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    .frame(width: 80, height: 80)

                                Image(systemName: completionPercentage >= 100 ? "trophy.fill" : "clock.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(completionPercentage >= 100 ? .green : .orange)
                            }

                            Text(completionPercentage >= 100 ? "Fast Complete!" : "End Your Fast?")
                            .font(.system(size: 24, weight: .bold))

                        Text(context.planName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Duration card
                    VStack(spacing: 12) {
                        Text("Current Duration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(formattedDuration)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(completionPercentage >= 100 ? .green : .primary)

                        // Progress indicator
                        HStack(spacing: 8) {
                            ProgressView(value: min(currentDurationHours / Double(context.durationHours), 1.0))
                                .progressViewStyle(LinearProgressViewStyle(tint: completionPercentage >= 100 ? .green : .blue))
                                .frame(maxWidth: .infinity)

                            Text("\(completionPercentage)%")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(completionPercentage >= 100 ? .green : .blue)
                        }

                        Text("of \(context.durationHours) hour target")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    .padding(.horizontal)

                    if showingTimePicker {
                        endTimePickerView
                    } else {
                        endActionsView
                    }
                }
                .padding(.bottom, 40)
                }
            }
            .background(Color.adaptiveCard)
            .onAppear {
                selectedTime = Date()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - End Actions View

    private var endActionsView: some View {
        VStack(spacing: 12) {
            // End now
            Button(action: {
                onConfirmNow()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("End Fast Now")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Record \(formattedDuration) fasted")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(completionPercentage >= 100 ? Color.green : Color.blue)
                .cornerRadius(14)
            }

            // I ended at a different time
            Button(action: {
                selectedTime = Date()
                showingTimePicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("I Ended at a Different Time")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Enter when you actually broke fast")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.systemGray5))
                .cornerRadius(14)
            }

            // Continue fasting
            Button(action: {
                onContinueFasting()
                onDismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 22))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep Going")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Continue fasting")
                            .font(.system(size: 13))
                            .opacity(0.8)
                    }

                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.purple)
                .cornerRadius(14)
            }

            // Cancel
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - End Time Picker View

    private var endTimePickerView: some View {
        VStack(spacing: 16) {
            Text("When did you break your fast?")
                .font(.system(size: 18, weight: .semibold))

            DatePicker(
                "End Time",
                selection: $selectedTime,
                in: actualStartTime...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            HStack(spacing: 12) {
                Button(action: {
                    showingTimePicker = false
                }) {
                    Text("Back")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }

                Button(action: {
                    onConfirmCustomTime(selectedTime)
                    onDismiss()
                }) {
                    Text("Confirm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Start Confirmation") {
    FastingStartConfirmationSheet(
        context: FastingConfirmationContext(
            fastingType: "start",
            planId: "test",
            planName: "16:8 Intermittent Fasting",
            durationHours: 16,
            scheduledTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        ),
        onConfirmScheduledTime: {},
        onConfirmCustomTime: { _ in },
        onNotStartedYet: {},
        onDismiss: {}
    )
}

#Preview("End Confirmation") {
    FastingEndConfirmationSheet(
        context: FastingConfirmationContext(
            fastingType: "end",
            planId: "test",
            planName: "16:8 Intermittent Fasting",
            durationHours: 16,
            scheduledTime: Date()
        ),
        actualStartTime: Date().addingTimeInterval(-16 * 3600),
        onConfirmNow: {},
        onConfirmCustomTime: { _ in },
        onContinueFasting: {},
        onDismiss: {}
    )
}
