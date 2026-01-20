//
//  FastingActionSheet.swift
//  NutraSafe Beta
//
//  Fasting management actions: snooze, skip, adjust start time
//

import SwiftUI

struct FastingActionSheet: View {
    let session: FastingSession
    let onSnooze: (Int) -> Void
    let onSkip: () -> Void
    let onStartNow: () -> Void
    let onAdjustTime: (Date) -> Void
    let onDismiss: () -> Void

    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    @State private var showingSnoozeOptions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                Text("Fast Not Started Yet?")
                    .font(.system(size: 22, weight: .bold))

                Text("Your fast was scheduled to start, but you haven't begun yet. What would you like to do?")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 30)
            .padding(.bottom, 24)

            if showingTimePicker {
                timePickerView
            } else if showingSnoozeOptions {
                snoozeOptionsView
            } else {
                mainActionsView
            }
            }
            .frame(maxWidth: .infinity)
            .background(Color.adaptiveCard)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(radius: 10)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Main Actions View

    private var mainActionsView: some View {
        VStack(spacing: 12) {
            // Start Now
            actionButton(
                title: "Start From Now",
                subtitle: "Begin your fast immediately",
                icon: "play.circle.fill",
                iconColor: .green
            ) {
                onStartNow()
                onDismiss()
            }

            // Snooze
            actionButton(
                title: "Snooze",
                subtitle: "Remind me in 15-60 minutes",
                icon: "moon.zzz.fill",
                iconColor: .blue
            ) {
                showingSnoozeOptions = true
            }

            // Enter Actual Start Time
            actionButton(
                title: "I Already Started",
                subtitle: "Enter when you actually began",
                icon: "clock.arrow.2.circlepath",
                iconColor: .purple
            ) {
                selectedTime = Date()
                showingTimePicker = true
            }

            // Skip
            actionButton(
                title: "Skip This Fast",
                subtitle: "Not fasting today",
                icon: "xmark.circle.fill",
                iconColor: .red
            ) {
                onSkip()
                onDismiss()
            }

            // Cancel
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Snooze Options View

    private var snoozeOptionsView: some View {
        VStack(spacing: 12) {
            Text("Snooze For")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 8)

            snoozeOption(minutes: 15)
            snoozeOption(minutes: 30)
            snoozeOption(minutes: 45)
            snoozeOption(minutes: 60)

            Button(action: { showingSnoozeOptions = false }) {
                Text("Back")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    private func snoozeOption(minutes: Int) -> some View {
        Button(action: {
            onSnooze(minutes)
            onDismiss()
        }) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppPalette.standard.accent)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(minutes) minutes")
                        .font(.system(size: 17, weight: .medium))
                    Text("Remind me at \(reminderTime(minutes: minutes))")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Time Picker View

    private var timePickerView: some View {
        VStack(spacing: 16) {
            Text("When Did You Start?")
                .font(.system(size: 18, weight: .semibold))
                .padding(.top, 8)

            DatePicker(
                "Start Time",
                selection: $selectedTime,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .padding(.horizontal)

            HStack(spacing: 12) {
                Button(action: { showingTimePicker = false }) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Button(action: {
                    onAdjustTime(selectedTime)
                    onDismiss()
                }) {
                    Text("Confirm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.purple)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    // MARK: - Helper Views

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods

    private func reminderTime(minutes: Int) -> String {
        let futureTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        // PERFORMANCE: Use cached static formatter
        return DateHelper.shortTimeFormatter.string(from: futureTime)
    }
}
