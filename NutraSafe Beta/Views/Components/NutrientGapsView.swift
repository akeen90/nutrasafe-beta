import SwiftUI
import UIKit

// MARK: - Nutrient Gaps View

@available(iOS 16.0, *)
struct NutrientGapsView: View {
    let rows: [CoverageRow]
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: Set<String> = []

    private var lowRows: [CoverageRow] {
        rows.filter { $0.status == .missing }
    }
    private var variableRows: [CoverageRow] {
        rows.filter { $0.status == .occasional }
    }

    var body: some View {
        NavigationView {
            List {
                if !lowRows.isEmpty {
                    Section(header: sectionHeader(title: "Low This Week", color: Color(hex: "#57A5FF"))) {
                        ForEach(lowRows) { row in
                            nutrientRow(row)
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }

                if !variableRows.isEmpty {
                    Section(header: sectionHeader(title: "Variable Coverage", color: Color(hex: "#FFA93A"))) {
                        ForEach(variableRows) { row in
                            nutrientRow(row)
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                }

                if lowRows.isEmpty && variableRows.isEmpty {
                    Text("Great coverage this week — all nutrients looking good!")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                        .listRowSeparator(.hidden)
                }

                // Citations Section
                Section(header: Text("Research Sources").font(.system(size: 14, weight: .semibold))) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrient recommendations and health benefits based on:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)

                        ForEach(CitationManager.shared.citations(for: .dailyValues).prefix(3)) { citation in
                            Button(action: {
                                if let url = URL(string: citation.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppPalette.standard.accent)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(citation.organization)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.primary)
                                        Text(citation.title)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppPalette.standard.accent)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Nutrient Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Components

    private func sectionHeader(title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.9))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func nutrientRow(_ row: CoverageRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(row.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text(row.status.rawValue)
                    .font(.caption).bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(row.status.color.opacity(0.15))
                    .foregroundColor(row.status.color)
                    .clipShape(Capsule())
            }

            if expanded.contains(row.id) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(row.segments, id: \.date) { seg in
                        HStack(alignment: .top, spacing: 8) {
                            Text(shortDate(seg.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 68, alignment: .leading)
                            if let foods = seg.foods, !foods.isEmpty {
                                Text(foods.prefix(5).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("—")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }

            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expanded.contains(row.id) { expanded.remove(row.id) } else { expanded.insert(row.id) }
                }
            }) {
                HStack(spacing: 6) {
                    Text(expanded.contains(row.id) ? "Hide days & foods" : "Show days & foods")
                    Image(systemName: expanded.contains(row.id) ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(AppPalette.standard.accent)
            }
        }
        .contentShape(Rectangle())
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    // MARK: - Helpers

    private func shortDate(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.dayDateMonthFormatter.string(from: date)
    }
}
