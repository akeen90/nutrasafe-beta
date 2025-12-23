//
//  FastingHistoryDropdown.swift
//  NutraSafe Beta
//
//  Collapsible fasting history list with detail & notes
//

import SwiftUI

struct FastingHistoryDropdown: View {
    @EnvironmentObject var firebaseManager: FirebaseManager

    @State private var isExpanded = false
    @State private var isLoading = false
    @State private var sessions: [FastingSession] = []
    @State private var selectedSession: FastingSession?
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                Group {
                    if isLoading {
                        ProgressView("Loading history…")
                            .padding(.vertical, 8)
                    } else if sessions.isEmpty {
                        Text("No fasting history yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(sessions.prefix(10)) { session in
                                FastingHistoryRow(session: session, onTap: {
                                    selectedSession = session
                                    // Auto close dropdown on tap
                                    isExpanded = false
                                }, onDelete: {
                                    delete(session)
                                })
                                 .contentShape(Rectangle())
                                 .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                     Button(role: .destructive) {
                                         delete(session)
                                     } label: {
                                         Label("Delete", systemImage: "trash")
                                     }
                                 }
                                 .contextMenu {
                                     Button(role: .destructive) { delete(session) } label: {
                                         Label("Delete", systemImage: "trash")
                                     }
                                 }
                            }

                            if sessions.count > 10 {
                                Text("Showing most recent 10 fasts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text("Fasting History")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    if let errorText = errorText {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .help(errorText)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation { isExpanded.toggle() }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .fastHistoryUpdated)) { _ in
            reload()
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded && sessions.isEmpty {
                reload()
            }
        }
        .sheet(item: $selectedSession, onDismiss: { selectedSession = nil }) { session in
            FastingHistoryDetailSheet(session: session) { updated in
                Task { await save(updated) }
            }
            .environmentObject(firebaseManager)
        }
    }

    private func reload() {
        Task {
            await MainActor.run {
                isLoading = true
                errorText = nil
            }
            do {
                let sessions = try await firebaseManager.getFastingSessions()
                await MainActor.run {
                    self.sessions = sessions.sorted { $0.endTime ?? Date() > $1.endTime ?? Date() }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorText = error.localizedDescription
                }
            }
        }
    }

    private func delete(_ session: FastingSession) {
        Task {
            do {
                try await firebaseManager.deleteFastingSession(id: session.id ?? "")
                await MainActor.run {
                    sessions.removeAll { $0.id == session.id }
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                }
            }
        }
    }

    private func save(_ session: FastingSession) async {
        do {
            _ = try await firebaseManager.saveFastingSession(session)
            await MainActor.run { selectedSession = nil }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }
}

private struct FastingHistoryRow: View {
    let session: FastingSession
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString(session.endTime ?? Date()))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(durationString(session.actualDurationHours))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(width: 120, alignment: .leading)

            // Stage / completion status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(completionStatus(for: session))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(statusColor(for: session))

                    // Early-end visual indicator
                    if session.completionStatus == .earlyEnd {
                        Image(systemName: "moon.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }

                // Warm-up attempt subtext for very early ends
                if session.attemptType == .warmup {
                    Text("Warm-up attempt")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                }

                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
         }
         .padding(12)
         .background(Color(.systemGray6))
         .cornerRadius(10)
         .contentShape(Rectangle())
         .onTapGesture { onTap() }
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func durationString(_ hours: Double) -> String {
        String(format: "%.1f h", hours)
    }

    private func completionStatus(for session: FastingSession) -> String {
        switch session.completionStatus {
        case .completed:
            return "Completed"
        case .active:
            return "In Progress"
        case .earlyEnd:
            return "Ended Early"
        case .overGoal:
            return "Over Goal"
        case .failed:
            return "Not Completed"
        case .skipped:
            return "Skipped"
        }
    }

    private func statusColor(for session: FastingSession) -> Color {
        switch session.completionStatus {
        case .completed:
            return .green
        case .overGoal:
            return .blue
        case .earlyEnd:
            return .orange
        case .active:
            return .purple
        case .failed, .skipped:
            return .gray
        }
    }
}

struct FastingHistoryDetailSheet: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) private var dismiss

    let session: FastingSession
    var onSave: (FastingSession) -> Void

    @State private var notesText: String

    init(session: FastingSession, onSave: @escaping (FastingSession) -> Void) {
        self.session = session
        self.onSave = onSave
        _notesText = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(String(format: "%.1f h", session.actualDurationHours))
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(completionStatus(for: session))
                            .foregroundColor(session.completionStatus == .completed ? .green : .orange)
                    }
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(session.targetDurationHours) hours")
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Ended")
                        Spacer()
                        Text(dateString(session.endTime ?? Date()))
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Notes (how you felt)")) {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Fast Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        var updated = session
        updated.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(updated)
        dismiss()
    }

    private func completionStatus(for session: FastingSession) -> String {
        switch session.completionStatus {
        case .completed:
            return "Completed"
        case .active:
            return "In Progress"
        case .earlyEnd:
            return "Ended Early"
        case .overGoal:
            return "Over Goal"
        case .failed:
            return "Not Completed"
        case .skipped:
            return "Skipped"
        }
    }

    private func dateString(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func stageName(for hours: Double) -> String {
        switch hours {
        case ..<4: return "Digestion"
        case 4..<8: return "Early Fat Burning"
        case 8..<12: return "Fat Burning"
        case 12..<16: return "Ketosis Begins"
        default: return "Deep Ketosis"
        }
    }
}