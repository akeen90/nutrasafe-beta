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
        print("🧪 [AdditiveWatchView] Starting enhanced additive analysis")
        print("🧪 [AdditiveWatchView] Ingredients array count: \(ingredients.count)")
        print("🧪 [AdditiveWatchView] Ingredients: \(ingredients)")

        // Use AdditiveWatchService which now uses local comprehensive database
        AdditiveWatchService.shared.analyzeIngredients(ingredients) { result in
            print("🧪 [AdditiveWatchView] Analysis complete!")
            print("🧪 [AdditiveWatchView] Detected additives count: \(result.detectedAdditives.count)")
            if !result.detectedAdditives.isEmpty {
                print("🧪 [AdditiveWatchView] Detected additives:")
                for additive in result.detectedAdditives {
                    print("   - \(additive.eNumber): \(additive.name)")
                }
            } else {
                print("🧪 [AdditiveWatchView] ⚠️ NO ADDITIVES DETECTED")
            }
            self.additiveResult = result
        }
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

                            if additive.hasChildWarning {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 10))
                            }
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
            .fill(verdict.color)
            .frame(width: 8, height: 8)
    }
    
    private func safetyIcon(verdict: AdditiveVerdict) -> String {
        switch verdict {
        case .neutral: return "checkmark.circle"
        case .caution: return "exclamationmark.triangle"
        case .avoid: return "xmark.circle"
        }
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
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Name and code
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)

                            if let code = additive.code {
                                Text(code)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.purple.opacity(0.7))
                                    .cornerRadius(6)
                            }
                        }

                        // User-friendly information row
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: getOriginIcon(additive.origin))
                                    .font(.system(size: 10))
                                    .foregroundColor(getOriginColor(additive.origin))
                                Text(getOriginLabel(additive.origin))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            if additive.childWarning {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.orange)
                                    Text("May affect children")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Safety indicator
                    VStack(spacing: 4) {
                        Circle()
                            .fill(getUsageColor())
                            .frame(width: 10, height: 10)

                        Text(getUsageGuidance(additive.riskLevel))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(getUsageColor())
                            .multilineTextAlignment(.center)
                    }

                    // Chevron indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.purple)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(14)

            // Expanded details - only show when tapped
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal, 14)

                    VStack(alignment: .leading, spacing: 12) {
                        // What is it (Purpose)
                        AdditiveInfoRow(icon: "info.circle.fill", title: "What is it?", content: getPurposeDescription(additive.purpose), color: .blue)

                        // Where is it from
                        AdditiveInfoRow(icon: "leaf.fill", title: "Where is it from?", content: getOriginDescription(additive.origin), color: getOriginColor(additive.origin))

                        // Any risks
                        AdditiveInfoRow(icon: getRiskIcon(), title: "Any risks?", content: getRiskDescription(), color: getUsageColor())
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.purple.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1.5)
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

        // Handle complex origin strings (e.g., "Synthetic/Plant/Mineral (Varies By Specification)")
        if lowercased.contains("varies by specification") || lowercased.contains("syntheticplantmineral") {
            return "Varied origin"
        }

        switch lowercased {
        case "synthetic": return "Synthetic"
        case "natural": return "Natural"
        case "plant": return "Plant-based"
        case "animal": return "Animal-derived"
        case "mineral": return "Mineral"
        case "insect": return "Insect-derived"
        case "fish": return "Fish-derived"
        case "dairy": return "Dairy-derived"
        case "mixed": return "Natural & synthetic"
        case "plant/animal": return "Plant or animal"
        case "natural/synthetic": return "Natural or synthetic"
        case "plant (turmeric)": return "Plant (turmeric)"
        case "synthetic/microbial": return "Synthetic/Microbial"
        default:
            // Clean up long complex strings
            if origin.count > 30 {
                if origin.contains("Synthetic") {
                    return "Synthetic"
                }
                if origin.contains("Plant") {
                    return "Plant-based"
                }
                if origin.contains("Natural") {
                    return "Natural"
                }
                return "Varied origin"
            }
            return origin
        }
    }

    private func getOriginColor(_ origin: String) -> Color {
        let lowercased = origin.lowercased()

        // Handle complex origin strings
        if lowercased.contains("varies") || lowercased.contains("syntheticplantmineral") {
            return .secondary
        }

        switch lowercased {
        case "synthetic": return .orange
        case "natural", "plant": return .green
        case "animal", "insect", "fish", "dairy": return .purple
        case "mineral": return .blue
        case "mixed", "plant/animal", "natural/synthetic": return .secondary
        default:
            // Determine color based on content
            if origin.contains("Synthetic") {
                return .orange
            }
            if origin.contains("Plant") || origin.contains("Natural") {
                return .green
            }
            if origin.contains("Animal") {
                return .purple
            }
            if origin.contains("Mineral") {
                return .blue
            }
            return .secondary
        }
    }

    private func getOriginIcon(_ origin: String) -> String {
        let lowercased = origin.lowercased()

        if lowercased.contains("plant") || lowercased.contains("natural") {
            return "leaf.fill"
        } else if lowercased.contains("synthetic") {
            return "flask.fill"
        } else if lowercased.contains("animal") {
            return "pawprint.fill"
        } else if lowercased.contains("mineral") {
            return "circle.hexagongrid.fill"
        } else {
            return "questionmark.circle.fill"
        }
    }

    private func getPurposeDescription(_ purpose: String) -> String {
        let lower = purpose.lowercased()

        if lower.contains("emulsifier") {
            return "Helps mix ingredients that normally don't combine (like oil and water)"
        } else if lower.contains("colour") || lower.contains("color") {
            return "Adds or enhances color to make food more visually appealing"
        } else if lower.contains("preserv") {
            return "Helps food stay fresh longer by preventing spoilage"
        } else if lower.contains("antioxidant") {
            return "Prevents food from going rancid and extends shelf life"
        } else if lower.contains("stabil") {
            return "Helps maintain food texture and prevents separation"
        } else if lower.contains("thick") {
            return "Increases thickness and improves texture"
        } else if lower.contains("sweet") {
            return "Provides sweetness with fewer or no calories"
        } else if lower.contains("flavour") || lower.contains("flavor") {
            return "Enhances or adds flavor to food"
        } else if lower.contains("acid") {
            return "Controls acidity and adds tartness"
        } else {
            return purpose
        }
    }

    private func getOriginDescription(_ origin: String) -> String {
        let lower = origin.lowercased()

        if lower.contains("plant") {
            return "Derived from plants - a natural source"
        } else if lower.contains("synthetic") {
            return "Made in a laboratory using chemical processes"
        } else if lower.contains("animal") {
            return "Derived from animals"
        } else if lower.contains("mineral") {
            return "Extracted from minerals or rocks"
        } else if lower.contains("ferment") {
            return "Produced through fermentation - a natural process"
        } else if lower.contains("varied") {
            return "Can come from multiple sources depending on manufacturer"
        } else {
            return origin
        }
    }

    private func getRiskIcon() -> String {
        switch additive.riskLevel {
        case "High": return "exclamationmark.triangle.fill"
        case "Moderate": return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private func getRiskDescription() -> String {
        if additive.childWarning {
            return "Some studies suggest this may affect children's behavior. " + getUsageGuidance(additive.riskLevel) + "."
        }

        switch additive.riskLevel {
        case "High":
            return "Best avoided if possible. May have health concerns for sensitive individuals."
        case "Moderate":
            return "Generally safe in small amounts. Consider limiting regular consumption."
        default:
            return "Generally recognized as safe for most people when consumed as part of food."
        }
    }
}

// MARK: - Additive Info Row Component

struct AdditiveInfoRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)

                Text(content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
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