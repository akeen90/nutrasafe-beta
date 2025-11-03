//
//  FastingCitationsView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-30.
//  Displays fasting-specific citations and sources
//

import SwiftUI

struct FastingCitationsView: View {
    @Environment(\.dismiss) private var dismiss
    private let citationManager = CitationManager.shared

    // Get only fasting citations
    private var fastingCitations: [CitationManager.Citation] {
        citationManager.citations(for: .fasting)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fasting Research Sources")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("All fasting information in this app is sourced from peer-reviewed research and official medical organizations.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Fasting citations
                    VStack(spacing: 12) {
                        ForEach(fastingCitations) { citation in
                            FastingCitationCard(citation: citation)
                        }
                    }

                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Disclaimer")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("This information is for educational purposes only. Consult with a healthcare provider before starting any fasting protocol, especially if you have medical conditions or take medications.")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FastingCitationCard: View {
    let citation: CitationManager.Citation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Organization
            Text(citation.organization)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)

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
                        .fill(Color.blue)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
}

// Preview
struct FastingCitationsView_Previews: PreviewProvider {
    static var previews: some View {
        FastingCitationsView()
    }
}
