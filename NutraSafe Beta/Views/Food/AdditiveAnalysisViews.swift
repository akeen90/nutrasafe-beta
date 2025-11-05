//
//  AdditiveAnalysisViews.swift
//  NutraSafe Beta
//
//  Comprehensive Additive Analysis System
//  Components extracted from ContentView.swift to improve code organization
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Additive Analysis Component

struct AdditiveWatchView: View {
    let ingredients: [String]
    @State private var additiveResult: AdditiveDetectionResult?
    @State private var showingSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Show content directly without collapsible header
            if let result = additiveResult {
                additiveContent(result: result)
            } else {
                loadingContent
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .sheet(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                        Text(warningMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                            .lineLimit(nil)
                    }

                    // Citation button for child hyperactivity research
                    Button(action: {
                        showingSources = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 11))
                            Text("View Research & Sources")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.15))
                        )
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Detected additives and ultra-processed ingredients combined
            let totalIssues = result.detectedAdditives.count + result.ultraProcessedIngredients.count

            if totalIssues > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    // Regular additives (E-numbers)
                    ForEach(result.detectedAdditives, id: \.eNumber) { additive in
                        AdditiveCard(additive: additive)
                    }

                    // Ultra-processed ingredients
                    ForEach(result.ultraProcessedIngredients) { ingredient in
                        UltraProcessedIngredientCard(ingredient: ingredient)
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

            // Educational footer with citation link
            VStack(alignment: .leading, spacing: 8) {
                Text("This information is provided for educational purposes to help you understand food additives. All listed additives are approved for use in food.")
                    .font(.system(size: 11).italic())
                    .foregroundColor(.secondary)

                Button(action: {
                    showingSources = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 10))
                        Text("View All Sources & Citations")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
            }
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

            print("🏭 [AdditiveWatchView] Ultra-processed ingredients count: \(result.ultraProcessedIngredients.count)")
            if !result.ultraProcessedIngredients.isEmpty {
                print("🏭 [AdditiveWatchView] Detected ultra-processed ingredients:")
                for ingredient in result.ultraProcessedIngredients {
                    print("   - \(ingredient.name) (penalty: \(ingredient.processingPenalty))")
                }
            } else {
                print("🏭 [AdditiveWatchView] ⚠️ NO ULTRA-PROCESSED INGREDIENTS DETECTED")
            }

            self.additiveResult = result
        }
    }
}

// MARK: - Additive Card Component

struct AdditiveCard: View {
    let additive: AdditiveInfo
    @State private var isExpanded = false
    @State private var showingSources = false

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

                    HStack(spacing: 6) {
                        // Display only actual E-numbers in purple boxes (consolidated database)
                        let actualENumbers = additive.eNumbers.filter { $0.hasPrefix("E") }
                        if !actualENumbers.isEmpty {
                            ForEach(actualENumbers, id: \.self) { eNumber in
                                Text(eNumber)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                            }
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
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
                                Text(originIcon(for: additive.origin.rawValue))
                                    .font(.system(size: 11))
                                Text("Origin: \(originDisplayName(for: additive.origin.rawValue))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            // Safety message
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: safetyIcon(verdict: additive.effectsVerdict.rawValue))
                                    .foregroundColor(verdictColor(for: additive.effectsVerdict.rawValue))
                                    .font(.system(size: 11))
                                Text(additive.effectsSummary)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(nil)
                            }
                        }
                    }

                    // Sources section
                    if !additive.sources.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSources.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("Sources (\(additive.sources.count))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showingSources ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if showingSources {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(additive.sources.enumerated()), id: \.offset) { index, source in
                                        Button(action: {
                                            if let url = URL(string: source.url) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(source.title)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(2)

                                                Text(source.url)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private func safetyIndicator(verdict: String) -> some View {
        let color: Color = {
            switch verdict.lowercased() {
            case "avoid": return .red
            case "caution": return .orange
            case "neutral": return .green
            default: return .gray
            }
        }()

        return Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
    
    private func safetyIcon(verdict: String) -> String {
        switch verdict.lowercased() {
        case "neutral": return "checkmark.circle"
        case "caution": return "exclamationmark.triangle"
        case "avoid": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private func verdictColor(for verdict: String) -> Color {
        switch verdict.lowercased() {
        case "avoid": return .red
        case "caution": return .orange
        case "neutral": return .green
        default: return .gray
        }
    }

    private func originIcon(for origin: String) -> String {
        switch origin.lowercased() {
        case "natural": return "🌿"
        case "plant": return "🌱"
        case "synthetic": return "🧪"
        case "semi-synthetic": return "⚗️"
        default: return "❓"
        }
    }

    private func originDisplayName(for origin: String) -> String {
        return origin.capitalized
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
    let sources: [AdditiveSource]
}

struct AdditiveCardView: View {
    let additive: DetailedAdditive
    @State private var isExpanded = false
    @State private var showingSources = false

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
                                .font(.system(size: 16, weight: .semibold))
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
                                    .font(.system(size: 12, weight: .medium))
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

                    // Sources section (collapsible)
                    if !additive.sources.isEmpty {
                        Divider()
                            .padding(.horizontal, 14)

                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingSources.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("Sources (\(additive.sources.count))")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showingSources ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }

                            if showingSources {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(additive.sources.enumerated()), id: \.offset) { _, source in
                                        Button(action: {
                                            if let url = URL(string: source.url) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(source.title)
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(2)

                                                Text(source.url)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(8)
                                            .background(Color(.systemGray6))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(6)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 14)
                    }
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
            return "Some studies have raised questions about this additive for sensitive individuals."
        case "Moderate":
            return "This additive has a moderate safety rating in food safety databases."
        default:
            return "This additive is generally recognised as safe when used in food."
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
// MARK: - Ultra-Processed Ingredient Card Component

struct UltraProcessedIngredientCard: View {
    let ingredient: UltraProcessedIngredientDisplay
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ingredient header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ingredient.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(ingredient.category.capitalized)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        // Display only actual E-numbers in purple boxes
                        let actualENumbers = ingredient.eNumbers.filter { $0.hasPrefix("E") }
                        if !actualENumbers.isEmpty {
                            ForEach(actualENumbers, id: \.self) { eNumber in
                                Text(eNumber)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                            }
                        }

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    // What it is
                    if let whatItIs = ingredient.whatItIs {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("What it is")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whatItIs)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Why it's used
                    if let whyItsUsed = ingredient.whyItsUsed {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "cube.box")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Why it's used")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whyItsUsed)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Where it comes from
                    if let whereItComesFrom = ingredient.whereItComesFrom {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Where it comes from")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text(whereItComesFrom)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }

                    // Concerns section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            Text("Why it matters")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Text(ingredient.concerns)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }

                    // NOVA classification
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        Text("NOVA Group \(ingredient.novaGroup)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(novaGroupLabel(ingredient.novaGroup))
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(4)
                    }

                    // Sources section
                    if !ingredient.sources.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text("Scientific Sources (\(ingredient.sources.count))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            ForEach(ingredient.sources, id: \.url) { source in
                                Button(action: {
                                    if let url = URL(string: source.url) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(source.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.blue)
                                            .lineLimit(2)

                                        Text(source.covers)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }

    private func novaGroupLabel(_ group: Int) -> String {
        switch group {
        case 1: return "Unprocessed"
        case 2: return "Minimally Processed"
        case 3: return "Processed"
        case 4: return "Ultra-Processed"
        default: return "Unknown"
        }
    }
}
