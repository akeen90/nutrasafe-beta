//
//  SourcesAndCitationsView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-30.
//  Displays all data sources and citations used in the app
//

import SwiftUI

struct SourcesAndCitationsView: View {
    @Environment(\.dismiss) private var dismiss
    private let citationManager = CitationManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Sources & Citations")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("All nutrition data, daily values, and ingredient information in this app is sourced from official government databases and health organizations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Citations by category
                    ForEach(CitationManager.CitationCategory.allCases, id: \.self) { category in
                        let citations = citationManager.citations(for: category)

                        if !citations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                // Category header
                                HStack(spacing: 8) {
                                    Image(systemName: category.icon)
                                        .foregroundColor(AppPalette.standard.accent)
                                        .font(.system(size: 16, weight: .semibold))

                                    Text(category.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal)

                                // Citations in this category
                                VStack(spacing: 12) {
                                    ForEach(citations) { citation in
                                        CitationCard(citation: citation)
                                    }
                                }
                            }
                        }
                    }

                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Note")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("While we source data from official databases, individual food products may vary. Always verify nutrition labels on actual food packaging, especially if you have allergies or medical dietary requirements.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct CitationCard: View {
    let citation: CitationManager.Citation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Organization
            Text(citation.organization)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.standard.accent)

            // Title
            Text(citation.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            // Description
            Text(citation.description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Link button
            Button(action: {
                if let url = URL(string: citation.url) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.system(size: 12, weight: .medium))

                    Text("View Source")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppPalette.standard.accent)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.adaptiveCard)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Preview
struct SourcesAndCitationsView_Previews: PreviewProvider {
    static var previews: some View {
        SourcesAndCitationsView()
    }
}
