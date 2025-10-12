//
//  AdditiveAnalysisViews.swift
//  NutraSafe Beta
//
//  Comprehensive Additive Analysis System
//  Components extracted from ContentView.swift to improve code organization
//

import SwiftUI
import Foundation

// MARK: - Additive Watch Component

struct AdditiveWatchView: View {
    let ingredients: [String]
    @State private var isExpanded = false
    @State private var additiveResult: AdditiveDetectionResult?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
                if additiveResult == nil {
                    analyzeAdditives()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Text("Additive Watch")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Child warning badge if present
                    if let result = additiveResult, result.hasChildConcernAdditives {
                        childWarningBadge(result.childWarnings.count)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded {
                if let result = additiveResult {
                    additiveContent(result: result)
                } else {
                    loadingContent
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            if additiveResult == nil {
                analyzeAdditives()
            }
        }
    }
    
    private func childWarningBadge(_ count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.orange)
        .cornerRadius(8)
    }
    
    private var loadingContent: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("Analyzing additives...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func additiveContent(result: AdditiveDetectionResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Child warning message if present
            if let warningMessage = result.childWarningMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(warningMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.orange)
                        .lineLimit(nil)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Detected additives
            if !result.detectedAdditives.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Identified Additives (\(result.detectedAdditives.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    ForEach(result.detectedAdditives, id: \.eNumber) { additive in
                        AdditiveCard(additive: additive)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        Text("No identifiable additives found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Text("This food appears to contain only natural ingredients.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Educational footer
            Text("This information is provided for educational purposes to help you understand food additives. All listed additives are approved for use in food.")
                .font(.system(size: 11).italic())
                .foregroundColor(.secondary)
        }
    }
    
    private func analyzeAdditives() {
        print("🧪 Starting enhanced additive analysis for ingredients: \(ingredients)")
        // TODO: Fix AdditiveWatchService when available
        // AdditiveWatchService.shared.analyzeIngredients(ingredients) { result in
        //     DispatchQueue.main.async {
        //         print("🧪 Enhanced additive analysis complete - found \(result.detectedAdditives.count) additives")
        //         self.additiveResult = result
        //     }
        // }
    }
}

// MARK: - Additive Card Component

struct AdditiveCard: View {
    let additive: AdditiveInfo
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Additive header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("⚗️")
                                .font(.system(size: 14))
                            
                            Text(additive.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            // TODO: Fix when hasChildWarning is available
                            // if additive.hasChildWarning {
                            //     Image(systemName: "exclamationmark.triangle.fill")
                            //         .foregroundColor(.orange)
                            //         .font(.system(size: 10))
                            // }
                        }
                        
                        Text(additive.group.displayName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Safety indicator
                    safetyIndicator(verdict: additive.effectsVerdict)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Overview
                    if !additive.overview.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What is it?")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(additive.overview)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Typical uses
                    if !additive.typicalUses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Typical uses:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(additive.typicalUses)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Comprehensive Consumer Information
                    if let consumerInfo = additive.consumerInfo, !consumerInfo.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // Display consumer guide with markdown formatting
                            Text(LocalizedStringKey(consumerInfo))
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                        }
                    } else {
                        // Fallback to basic information if consumer info not available
                        VStack(alignment: .leading, spacing: 6) {
                            // Origin
                            HStack(spacing: 6) {
                                Text(additive.origin.icon)
                                    .font(.system(size: 11))
                                Text("Origin: \(additive.origin.displayName)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Safety message
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: safetyIcon(verdict: additive.effectsVerdict))
                                    .foregroundColor(additive.effectsVerdict.color)
                                    .font(.system(size: 11))
                                Text(additive.effectsSummary)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func safetyIndicator(verdict: AdditiveVerdict) -> some View {
        Circle()
            .fill(Color.gray) // TODO: Fix when verdict.color is available
            .frame(width: 8, height: 8)
    }
    
    private func safetyIcon(verdict: AdditiveVerdict) -> String {
        // TODO: Fix when verdict cases are available
        return "checkmark.circle"
        // switch verdict {
        // case .neutral: return "checkmark.circle"
        // case .caution: return "exclamationmark.triangle"
        // case .avoid: return "xmark.circle"
        // }
    }
}

// MARK: - Detailed Additive Components

struct DetailedAdditive {
    let name: String
    let code: String?
    let purpose: String
    let origin: String
    let childWarning: Bool
    let riskLevel: String
    let description: String
}

struct AdditiveCardView: View {
    let additive: DetailedAdditive
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header - always visible (tap to expand/collapse)
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)

                            if let code = additive.code {
                                Text(code)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                            }
                        }

                        HStack(spacing: 8) {
                            Text(additive.purpose)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.blue)

                            Text("•")
                                .foregroundColor(.secondary)
                                .font(.system(size: 8))

                            Text(getOriginLabel(additive.origin))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(getOriginColor(additive.origin))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        // Usage guidance indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(getUsageColor())
                                .frame(width: 6, height: 6)

                            Text(getUsageGuidance(additive.riskLevel))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(getUsageColor())
                        }

                        if additive.childWarning {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.orange)
                                Text("May affect children's behavior")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(12)

            // Expanded details - only show when tapped
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 12)

                    AdditiveDescriptionView(text: additive.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func getUsageColor() -> Color {
        switch additive.riskLevel {
        case "High": return .red
        case "Moderate": return .orange
        default: return .green
        }
    }
    
    private func getUsageGuidance(_ level: String) -> String {
        switch level {
        case "High": return "Best avoided"
        case "Moderate": return "Use in moderation"
        case "Low": return "Generally fine"
        default: return "Generally fine"
        }
    }

    private func getOriginLabel(_ origin: String) -> String {
        let lowercased = origin.lowercased()
        switch lowercased {
        case "synthetic": return "synthetic"
        case "natural": return "natural"
        case "plant": return "plant-based"
        case "animal": return "animal-derived"
        case "mineral": return "mineral"
        case "insect": return "insect-derived"
        case "fish": return "fish-derived"
        case "dairy": return "dairy-derived"
        case "mixed": return "natural & synthetic"
        case "plant/animal": return "plant or animal"
        case "natural/synthetic": return "natural or synthetic"
        default: return origin
        }
    }

    private func getOriginColor(_ origin: String) -> Color {
        let lowercased = origin.lowercased()
        switch lowercased {
        case "synthetic": return .orange
        case "natural", "plant": return .green
        case "animal", "insect", "fish", "dairy": return .purple
        case "mineral": return .blue
        case "mixed", "plant/animal", "natural/synthetic": return .secondary
        default: return .secondary
        }
    }
}

// MARK: - Additive Description Component

struct AdditiveDescriptionView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parse and display the consumer guide sections
            ForEach(getParsedSections(), id: \.title) { section in
                if !section.content.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        if !section.title.isEmpty {
                            Text(section.title)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        Text(section.content)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private struct ConsumerGuideSection {
        let title: String
        let content: String
    }

    private func getParsedSections() -> [ConsumerGuideSection] {
        var sections: [ConsumerGuideSection] = []
        let lines = text.components(separatedBy: "\n")
        var currentTitle = ""
        var currentContent = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }

            // Check if it's a header (e.g., "**What is it?**")
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                // Save previous section if we have one
                if !currentTitle.isEmpty || !currentContent.isEmpty {
                    sections.append(ConsumerGuideSection(title: currentTitle, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                // Start new section
                currentTitle = trimmed.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: ":", with: "")
                currentContent = ""
            } else {
                // Add content to current section
                if !currentContent.isEmpty {
                    currentContent += " "
                }
                currentContent += trimmed
            }
        }

        // Add the last section
        if !currentTitle.isEmpty || !currentContent.isEmpty {
            sections.append(ConsumerGuideSection(title: currentTitle, content: currentContent.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        // If no sections were parsed, return the raw text as a single section
        if sections.isEmpty {
            let cleanText = text.replacingOccurrences(of: "**", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(ConsumerGuideSection(title: "", content: cleanText))
        }

        return sections
    }
    
    private var parsedSections: [AdditiveSection] {
        // Parse markdown-style **headers** and regular content
        let lines = text.components(separatedBy: "\n")
        var sections: [AdditiveSection] = []
        var currentSection = AdditiveSection(id: UUID(), header: "", content: "")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            // Check if line contains **bold** text
            if trimmedLine.hasPrefix("**") && trimmedLine.contains("**") {
                // Save previous section if it has content
                if !currentSection.header.isEmpty || !currentSection.content.isEmpty {
                    sections.append(currentSection)
                }
                
                // Create new section with header
                let cleanHeader = trimmedLine.replacingOccurrences(of: "**", with: "")
                currentSection = AdditiveSection(id: UUID(), header: cleanHeader, content: "")
            } else {
                // Add to current section content
                if !currentSection.content.isEmpty {
                    currentSection.content += " "
                }
                currentSection.content += trimmedLine
            }
        }
        
        // Add final section
        if !currentSection.header.isEmpty || !currentSection.content.isEmpty {
            sections.append(currentSection)
        }
        
        return sections
    }
}

// MARK: - Supporting Data Models

struct AdditiveSection {
    let id: UUID
    var header: String
    var content: String
}