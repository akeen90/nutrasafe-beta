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
    @State private var history: [FastRecord] = []
    @State private var selectedRecord: FastRecord?
    @State private var errorText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup(isExpanded: $isExpanded) {
                Group {
                    if isLoading {
                        ProgressView("Loading history…")
                            .padding(.vertical, 8)
                    } else if history.isEmpty {
                        Text("No fasting history yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(history) { record in
                                    FastingHistoryRow(record: record, onTap: {
                                        selectedRecord = record
                                        // Auto close dropdown on tap
                                        isExpanded = false
                                    }, onDelete: {
                                        delete(record)
                                    })
                                     .contentShape(Rectangle())
                                     .contextMenu {
                                         Button(role: .destructive) { delete(record) } label: {
                                             Label("Delete", systemImage: "trash")
                                         }
                                     }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 300)
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
        .onChange(of: isExpanded) { expanded in
            if expanded && history.isEmpty {
                reload()
            }
        }
        .sheet(item: $selectedRecord, onDismiss: { selectedRecord = nil }) { rec in
            FastingHistoryDetailSheet(record: rec) { updated in
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
                let records = try await firebaseManager.getFastHistory()
                await MainActor.run {
                    history = records.sorted { $0.endTime > $1.endTime }
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

    private func delete(_ record: FastRecord) {
        Task {
            do {
                try await firebaseManager.deleteFastRecord(id: record.id)
                await MainActor.run {
                    history.removeAll { $0.id == record.id }
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                }
            }
        }
    }

    private func save(_ record: FastRecord) async {
        do {
            _ = try await firebaseManager.saveFastRecord(record)
            await MainActor.run { selectedRecord = nil }
        } catch {
            await MainActor.run { errorText = error.localizedDescription }
        }
    }
}

private struct FastingHistoryRow: View {
    let record: FastRecord
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString(record.endTime))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(durationString(record.durationHours))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(width: 120, alignment: .leading)

            // Stage / within target
            VStack(alignment: .leading, spacing: 4) {
                Text(stageName(for: record.durationHours))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(record.withinTarget ? .green : .orange)
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: { onDelete() }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete fast")
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

struct FastingHistoryDetailSheet: View {
    @EnvironmentObject var firebaseManager: FirebaseManager
    @Environment(\.dismiss) private var dismiss

    let record: FastRecord
    var onSave: (FastRecord) -> Void

    @State private var notesText: String

    init(record: FastRecord, onSave: @escaping (FastRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        _notesText = State(initialValue: record.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(String(format: "%.1f h", record.durationHours))
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Stage")
                        Spacer()
                        Text(stageName(for: record.durationHours))
                            .foregroundColor(.primary)
                    }
                    HStack {
                        Text("Target")
                        Spacer()
                        Text(record.withinTarget ? "Within target" : "Outside target")
                            .foregroundColor(record.withinTarget ? .green : .orange)
                    }
                    HStack {
                        Text("Ended")
                        Spacer()
                        Text(dateString(record.endTime))
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
        var updated = record
        updated.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(updated)
        dismiss()
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