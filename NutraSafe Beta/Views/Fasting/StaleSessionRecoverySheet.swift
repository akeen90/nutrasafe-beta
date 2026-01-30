//
//  StaleSessionRecoverySheet.swift
//  NutraSafe Beta
//
//  Recovery UI for handling orphaned/stale fasting sessions
//

import SwiftUI

struct StaleSessionRecoverySheet: View {
    let session: FastingSession
    @EnvironmentObject var viewModel: FastingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 20)

                // Icon
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                // Title
                Text("Fasting Session Found")
                    .font(.title2.bold())

                // Description
                VStack(spacing: 8) {
                    Text("A fasting session from \(session.startTime.formatted(date: .abbreviated, time: .shortened)) appears to still be running.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Text("This happens when the app was closed during a fast. Please choose how to record this session:")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.horizontal)

                // Session info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Started:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                            .fontWeight(.medium)
                    }

                    Divider()

                    HStack {
                        Text("Target:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(session.targetDurationHours) hours")
                            .fontWeight(.medium)
                    }

                    Divider()

                    HStack {
                        Text("Time elapsed:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDuration(session.actualDurationHours))
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()

                // Action buttons with explanations
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Button {
                            Task {
                                await viewModel.resolveStaleSessionAsCompleted(session)
                                dismiss()
                            }
                        } label: {
                            Label("I completed this fast", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Text("Records as completed for the full \(session.targetDurationHours) hours")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 4) {
                        Button {
                            Task {
                                await viewModel.resolveStaleSessionAsEarlyEnd(session)
                                dismiss()
                            }
                        } label: {
                            Label("I ended early", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Text("Records that you stopped before reaching your goal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 4) {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.resolveStaleSessionAsDiscarded(session)
                                dismiss()
                            }
                        } label: {
                            Label("Discard this session", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }

                        Text("Deletes this session from your history entirely")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Session Recovery")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formatDuration(_ hours: Double) -> String {
        let totalHours = Int(hours)
        let days = totalHours / 24
        let remainingHours = totalHours % 24

        if days > 0 {
            return "\(days)d \(remainingHours)h"
        } else {
            return "\(totalHours)h"
        }
    }
}

#Preview {
    StaleSessionRecoverySheet(
        session: FastingSession(
            userId: "preview",
            planId: "plan1",
            startTime: Date().addingTimeInterval(-72 * 3600), // 72 hours ago
            endTime: nil,
            manuallyEdited: false,
            skipped: false,
            completionStatus: .active,
            targetDurationHours: 16,
            notes: nil,
            createdAt: Date()
        )
    )
    .environmentObject(FastingViewModel.preview)
}
