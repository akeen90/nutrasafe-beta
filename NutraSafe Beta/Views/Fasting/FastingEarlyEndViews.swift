import SwiftUI

// MARK: - Early End Modal
struct EarlyEndModal: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FastingViewModel
    let session: FastingSession

    @State private var selectedReason: EarlyEndReason?
    @State private var customNote = ""
    @State private var showingRestartDecision = false

    var elapsedTime: String {
        let hours = Int(session.actualDurationHours)
        let minutes = Int((session.actualDurationHours - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header Icon
                Image(systemName: "moon.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 20)

                // Title & Supportive Message
                VStack(spacing: 12) {
                    Text("Fast ended early — that's okay")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Small attempts help build rhythm — you can try again any time.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Elapsed Time
                VStack(spacing: 8) {
                    Text("Time completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Text(elapsedTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .cardBackground(cornerRadius: 12)
                .padding(.horizontal)

                // Optional Reason Dropdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why did you stop? (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Menu {
                        ForEach(EarlyEndReason.allCases, id: \.self) { reason in
                            Button(action: { selectedReason = reason }) {
                                Label(reason.displayName, systemImage: reason.iconName)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedReason?.displayName ?? "Select a reason")
                                .foregroundColor(selectedReason == nil ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // Start Again Button
                    Button {
                        showingRestartDecision = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Start Again")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppPalette.standard.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Done Button
                    Button {
                        Task {
                            await finaliseEarlyEnd()
                        }
                    } label: {
                        Text("Done")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(AppPalette.standard.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Early End")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showingRestartDecision) {
            RestartDecisionModal(viewModel: viewModel, previousSession: session)
        }
    }

    private func finaliseEarlyEnd() async {
        // Save the reason if selected
        var updatedSession = session
        updatedSession.earlyEndReason = selectedReason?.rawValue

        // Update session in Firebase
        do {
            try await viewModel.firebaseManager.updateFastingSession(updatedSession)
        } catch {
                    }

        dismiss()
    }
}

// MARK: - Restart Decision Modal
struct RestartDecisionModal: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FastingViewModel
    let previousSession: FastingSession

    @State private var showingEditStartTime = false
    @State private var newStartTime = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header Icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(AppPalette.standard.accent)
                    .padding(.top, 20)

                // Title & Message
                VStack(spacing: 12) {
                    Text("How would you like to restart?")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("You can continue your previous fast or begin a fresh one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Options
                VStack(spacing: 16) {
                    // Option A: Continue Previous
                    Button {
                        Task {
                            await continuePreviousFast()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.green)
                                Text("Continue previous fast")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }

                            Text("Resume from where you left off — your progress will be preserved.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cardBackground(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)

                    // Option B: Start Fresh
                    Button {
                        Task {
                            await startFreshSession()
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppPalette.standard.accent)
                                Text("Start new session")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }

                            Text("Begin a brand new fast — previous attempt will remain in history.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cardBackground(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()

                // Cancel Button
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }
            .navigationTitle("Restart Fast")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func continuePreviousFast() async {
        await viewModel.continuePreviousFast(previousSession)
        dismiss()
    }

    private func startFreshSession() async {
        await viewModel.startFastingSession()
        dismiss()
    }
}

// MARK: - Early End Reason Enum
enum EarlyEndReason: String, CaseIterable, Codable {
    case hungry = "hungry"
    case social = "social"
    case tired = "tired"
    case unwell = "unwell"
    case schedule = "schedule"
    case other = "other"

    var displayName: String {
        switch self {
        case .hungry: return "Feeling hungry"
        case .social: return "Social event"
        case .tired: return "Feeling tired"
        case .unwell: return "Not feeling well"
        case .schedule: return "Schedule change"
        case .other: return "Other reason"
        }
    }

    var iconName: String {
        switch self {
        case .hungry: return "fork.knife"
        case .social: return "person.2.fill"
        case .tired: return "moon.zzz.fill"
        case .unwell: return "heart.text.square.fill"
        case .schedule: return "calendar"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Previews
#Preview {
    EarlyEndModal(
        viewModel: FastingViewModel.preview,
        session: FastingSession(
            userId: "preview",
            planId: "preview_plan",
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            manuallyEdited: false,
            skipped: false,
            completionStatus: .earlyEnd,
            targetDurationHours: 16,
            notes: nil,
            createdAt: Date()
        )
    )
}

#Preview {
    RestartDecisionModal(
        viewModel: FastingViewModel.preview,
        previousSession: FastingSession(
            userId: "preview",
            planId: "preview_plan",
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date(),
            manuallyEdited: false,
            skipped: false,
            completionStatus: .earlyEnd,
            targetDurationHours: 16,
            notes: nil,
            createdAt: Date()
        )
    )
}
