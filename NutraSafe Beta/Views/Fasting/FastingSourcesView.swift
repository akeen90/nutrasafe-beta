//
//  FastingSourcesView.swift
//  NutraSafe Beta
//
//  Created by Claude
//

import SwiftUI

struct FastingSourcesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let sources = [
        Source(
            title: "Intermittent Fasting and Human Metabolic Health",
            authors: "Rafael de Cabo, Mark P. Mattson",
            journal: "Journal of the Academy of Nutrition and Dietetics",
            year: "2019",
            url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6314618/"
        ),
        Source(
            title: "Effects of Intermittent Fasting on Health Markers",
            authors: "Stephen D. Anton et al.",
            journal: "Obesity Reviews",
            year: "2018",
            url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5783752/"
        ),
        Source(
            title: "Autophagy and Fasting: Clinical Applications",
            authors: "Takeshi Noda, Yoshinori Ohsumi",
            journal: "Nature Reviews Molecular Cell Biology",
            year: "2016",
            url: "https://www.nature.com/articles/nrm.2016.73"
        )
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("The information provided in this app is based on scientific research and clinical studies. Below are some key references:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                ForEach(sources) { source in
                    SourceRow(source: source)
                }
            }
            .navigationTitle("Scientific Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct Source: Identifiable {
    let id = UUID()
    let title: String
    let authors: String
    let journal: String
    let year: String
    let url: String
}

struct SourceRow: View {
    let source: Source
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(source.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(source.authors)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(source.journal)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(source.year)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let url = URL(string: source.url) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text("View Source")
                            .font(.caption)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FastingSourcesView()
}
