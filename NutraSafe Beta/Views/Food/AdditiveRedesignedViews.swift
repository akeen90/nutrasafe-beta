//
//  AdditiveRedesignedViews.swift
//  NutraSafe Beta
//
//  Redesigned additive display system inspired by Yuka and Ivy.
//  Features: Safety badges, personal alerts, risk grouping, circular scores.
//

import SwiftUI

// MARK: - Additive Grade System

/// Additive rating system - honest about additive presence
/// Uses symbols/numbers to avoid conflict with NutraSafe nutrition grade (A+ to F)
enum AdditiveGrade: String, CaseIterable {
    case none = "✓"      // No additives - the only "good" outcome
    case average = "~"   // Has additives but low risk (tilde = "approximately okay")
    case belowAverage = "!"  // Has concerning additives (warning)
    case poor = "✕"      // Has high-risk additives (X mark)

    var label: String {
        switch self {
        case .none: return "No Additives"
        case .average: return "Average"
        case .belowAverage: return "Below Average"
        case .poor: return "Poor"
        }
    }

    var color: Color {
        switch self {
        case .none: return Color(red: 0.2, green: 0.75, blue: 0.4)      // Green - genuinely good
        case .average: return Color(red: 0.95, green: 0.75, blue: 0.2)  // Yellow - has additives
        case .belowAverage: return Color(red: 0.95, green: 0.5, blue: 0.2)   // Orange
        case .poor: return Color(red: 0.9, green: 0.25, blue: 0.2)      // Red
        }
    }

    var shortDescription: String {
        switch self {
        case .none: return "No additives detected"
        case .average: return "Contains additives (low risk)"
        case .belowAverage: return "Contains concerning additives"
        case .poor: return "Contains high-risk additives"
        }
    }

    /// Calculate grade based on additive counts - presence of ANY additives caps at average
    static func from(score: Int, hasAdditives: Bool) -> AdditiveGrade {
        // If no additives, that's the only way to get "good"
        if !hasAdditives {
            return .none
        }

        // With additives present, best possible is average
        switch score {
        case 70...100: return .average       // Low-risk additives only
        case 40..<70: return .belowAverage   // Some concerning additives
        default: return .poor                 // High-risk additives
        }
    }

    // Legacy support - maps old score-only calls
    static func from(score: Int) -> AdditiveGrade {
        return from(score: score, hasAdditives: score < 100)
    }
}

// MARK: - Additive Analysis Result

/// Complete analysis of a food's additives
struct AdditiveAnalysisResult {
    let score: Int  // 0-100
    let grade: AdditiveGrade
    let totalCount: Int
    let highRiskCount: Int
    let moderateRiskCount: Int
    let lowRiskCount: Int
    let safeCount: Int
    let personalAlerts: [PersonalAdditiveAlert]
    let groupedAdditives: [AdditiveRiskLevel: [AnalyzedAdditive]]

    var hasPersonalAlerts: Bool {
        !personalAlerts.isEmpty
    }

    var watchCount: Int {
        highRiskCount + moderateRiskCount
    }
}

/// Personal alert when an additive affects user's sensitivities
struct PersonalAdditiveAlert {
    let additiveName: String
    let eNumber: String
    let sensitivityName: String
    let reason: String
}

/// Fully analyzed additive with all display info
struct AnalyzedAdditive: Identifiable {
    let id = UUID()
    let name: String
    let eNumber: String
    let riskLevel: AdditiveRiskLevel
    let shortDescription: String
    let whatItIs: String
    let origin: String
    let whyFlagged: [String]
    let affectsUserSensitivity: Bool
    let sensitivityName: String?
    let isVitaminOrMineral: Bool
}

// MARK: - Safety Badge (Top of Food Detail)

/// Prominent badge showing additive safety grade at top of food detail
struct AdditiveSafetyBadge: View {
    let analysis: AdditiveAnalysisResult?
    let hasIngredients: Bool
    var onTap: (() -> Void)? = nil

    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        if !hasIngredients {
            // No ingredients - show subtle "no data" badge
            noDataBadge
        } else if let analysis = analysis {
            // Show grade badge
            gradeBadge(analysis: analysis)
        } else {
            // Loading state
            loadingBadge
        }
    }

    // MARK: - Grade Badge

    private func gradeBadge(analysis: AdditiveAnalysisResult) -> some View {
        HStack(spacing: 12) {
            // Grade indicator - color-coded circle with icon or letter
            ZStack {
                Circle()
                    .fill(analysis.grade.color)
                    .frame(width: 44, height: 44)

                if analysis.grade == .none {
                    // Checkmark for no additives
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // Letter grade for products with additives
                    Text(analysis.grade.rawValue)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(analysis.grade.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                HStack(spacing: 4) {
                    if analysis.totalCount == 0 {
                        Text("No additives detected")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textSecondary)
                    } else {
                        Text("\(analysis.totalCount) additive\(analysis.totalCount == 1 ? "" : "s")")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textSecondary)

                        if analysis.watchCount > 0 {
                            Text("•")
                                .foregroundColor(palette.textTertiary)
                            Text("\(analysis.watchCount) to watch")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(analysis.grade.color)
                        }
                    }
                }

                // Personal alert indicator
                if analysis.hasPersonalAlerts {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("\(analysis.personalAlerts.count) affects your sensitivities")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(SemanticColors.caution)
                }
            }

            Spacer()

            // Chevron to indicate tappable
            Image(systemName: "chevron.down.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(analysis.grade.color.opacity(0.6))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(analysis.grade.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(analysis.grade.color.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    // MARK: - No Data Badge

    private var noDataBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.textTertiary.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "questionmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(palette.textTertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("No Ingredient Data")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
                Text("Unable to analyze additives")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(0.1))
        )
    }

    // MARK: - Loading Badge

    private var loadingBadge: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(palette.tertiary.opacity(0.2))
                    .frame(width: 44, height: 44)

                ProgressView()
                    .scaleEffect(0.8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.textSecondary)
                Text("Checking additives")
                    .font(.system(size: 13))
                    .foregroundColor(palette.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.tertiary.opacity(0.1))
        )
    }
}

// MARK: - Circular Score Display (Yuka-style)

struct AdditiveCircularScore: View {
    let score: Int
    let grade: AdditiveGrade

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(grade.color.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(
                    grade.color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            // Score text
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(grade.color)
                Text("/100")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Personal Sensitivity Alert Card

struct PersonalSensitivityAlertCard: View {
    let alerts: [PersonalAdditiveAlert]

    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.caution)

                Text("Personal Alert")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(SemanticColors.caution)
            }

            // Alert items
            ForEach(alerts, id: \.eNumber) { alert in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(SemanticColors.caution)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(alert.additiveName) (\(alert.eNumber))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.textPrimary)

                        Text(alert.reason)
                            .font(.system(size: 13))
                            .foregroundColor(palette.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(SemanticColors.caution.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(SemanticColors.caution.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Additive Score Card (Main Section)

struct AdditiveScoreCard: View {
    let analysis: AdditiveAnalysisResult
    @Binding var expandedAdditiveId: UUID?
    @State private var showingSources = false

    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with score
            HStack(alignment: .top, spacing: 16) {
                // Circular score
                AdditiveCircularScore(score: analysis.score, grade: analysis.grade)

                // Summary text
                VStack(alignment: .leading, spacing: 6) {
                    Text(analysis.grade.label)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(palette.textPrimary)

                    if analysis.totalCount == 0 {
                        Text("No additives detected")
                            .font(.system(size: 14))
                            .foregroundColor(palette.textSecondary)
                    } else {
                        Text("\(analysis.totalCount) additive\(analysis.totalCount == 1 ? "" : "s") detected")
                            .font(.system(size: 14))
                            .foregroundColor(palette.textSecondary)

                        if analysis.watchCount > 0 {
                            Text("\(analysis.watchCount) worth noting")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(analysis.grade.color)
                        }
                    }
                }

                Spacer()
            }

            // Personal alerts (if any)
            if analysis.hasPersonalAlerts {
                PersonalSensitivityAlertCard(alerts: analysis.personalAlerts)
            }

            // Grouped additive lists
            if analysis.totalCount > 0 {
                Divider()
                    .padding(.vertical, 4)

                // High risk (Worth Noting)
                if analysis.highRiskCount > 0, let additives = analysis.groupedAdditives[.highRisk] {
                    AdditiveRiskGroup(
                        title: "Worth Noting",
                        subtitle: "Some studies suggest limiting",
                        riskLevel: .highRisk,
                        additives: additives,
                        expandedId: $expandedAdditiveId
                    )
                }

                // Moderate risk
                if analysis.moderateRiskCount > 0, let additives = analysis.groupedAdditives[.moderateRisk] {
                    AdditiveRiskGroup(
                        title: "In Moderation",
                        subtitle: "Generally fine in small amounts",
                        riskLevel: .moderateRisk,
                        additives: additives,
                        expandedId: $expandedAdditiveId
                    )
                }

                // Low risk
                if analysis.lowRiskCount > 0, let additives = analysis.groupedAdditives[.lowRisk] {
                    AdditiveRiskGroup(
                        title: "Low Concern",
                        subtitle: "Minimal concerns noted",
                        riskLevel: .lowRisk,
                        additives: additives,
                        expandedId: $expandedAdditiveId,
                        startCollapsed: true
                    )
                }

                // Safe (vitamins, natural)
                if analysis.safeCount > 0, let additives = analysis.groupedAdditives[.noRisk] {
                    AdditiveRiskGroup(
                        title: "Generally Safe",
                        subtitle: "No significant concerns",
                        riskLevel: .noRisk,
                        additives: additives,
                        expandedId: $expandedAdditiveId,
                        startCollapsed: true
                    )
                }
            }

            // Sources link
            Button(action: { showingSources = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 12))
                    Text("Sources: EFSA, FSA, FDA")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(palette.accent)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fullScreenCover(isPresented: $showingSources) {
            SourcesAndCitationsView()
        }
    }
}

// MARK: - Risk Group Section

struct AdditiveRiskGroup: View {
    let title: String
    let subtitle: String
    let riskLevel: AdditiveRiskLevel
    let additives: [AnalyzedAdditive]
    @Binding var expandedId: UUID?
    var startCollapsed: Bool = false

    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header - always expanded, no collapse functionality to avoid animation issues
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(riskLevel.color)
                            .frame(width: 10, height: 10)

                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.textPrimary)

                        Text("(\(additives.count))")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textTertiary)
                    }

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.textTertiary)
            }

            // Additive rows - always visible
            if true {
                VStack(spacing: 0) {
                    ForEach(additives) { additive in
                        RedesignedAdditiveRow(
                            additive: additive,
                            isExpanded: expandedId == additive.id,
                            onTap: {
                                if expandedId == additive.id {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedId = nil
                                    }
                                } else {
                                    // Collapse previous instantly to avoid double-animate jump
                                    var tx = Transaction()
                                    tx.disablesAnimations = true
                                    withTransaction(tx) {
                                        expandedId = nil
                                    }
                                    // Animate opening the new row
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedId = additive.id
                                    }
                                }
                            }
                        )

                        if additive.id != additives.last?.id {
                            Divider()
                                .padding(.leading, 28)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(palette.tertiary.opacity(0.05))
                )
            }
        }
    }
}

// MARK: - Expandable Additive Row

struct RedesignedAdditiveRow: View {
    let additive: AnalyzedAdditive
    let isExpanded: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row (always visible)
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 10) {
                    // Risk indicator
                    Circle()
                        .fill(additive.riskLevel.color)
                        .frame(width: 12, height: 12)

                    // Name and short description
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(additive.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(palette.textPrimary)

                            if !additive.eNumber.isEmpty {
                                Text("(\(additive.eNumber))")
                                    .font(.system(size: 12))
                                    .foregroundColor(palette.textTertiary)
                            }

                            // Personal sensitivity indicator
                            if additive.affectsUserSensitivity {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(SemanticColors.caution)
                            }

                            // Vitamin/mineral indicator
                            if additive.isVitaminOrMineral {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(SemanticColors.nutrient)
                            }
                        }

                        Text(additive.shortDescription)
                            .font(.system(size: 12))
                            .foregroundColor(palette.textSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // What it is
                    detailSection(title: "What It Is", content: additive.whatItIs)

                    // Origin
                    if !additive.origin.isEmpty {
                        detailSection(title: "Origin", content: additive.origin)
                    }

                    // Why flagged
                    if !additive.whyFlagged.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why It's Flagged")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textSecondary)

                            ForEach(additive.whyFlagged, id: \.self) { reason in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(additive.riskLevel.color)
                                    Text(reason)
                                        .font(.system(size: 13))
                                        .foregroundColor(palette.textPrimary)
                                }
                            }
                        }
                    }

                    // Personal sensitivity warning
                    if additive.affectsUserSensitivity, let sensitivity = additive.sensitivityName {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                                .foregroundColor(SemanticColors.caution)

                            Text("Affects your \(sensitivity) sensitivity")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SemanticColors.caution)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(SemanticColors.caution.opacity(0.1))
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.leading, 22) // Indent to align with text above
            }
        }
    }

    private func detailSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.textSecondary)

            Text(content)
                .font(.system(size: 13))
                .foregroundColor(palette.textPrimary)
        }
    }
}

// MARK: - Mini Badge for Search Results

struct AdditiveMiniGradeBadge: View {
    let grade: AdditiveGrade
    let watchCount: Int
    let hasPersonalAlert: Bool

    var body: some View {
        HStack(spacing: 4) {
            // Grade letter in colored circle
            ZStack {
                Circle()
                    .fill(grade.color)
                    .frame(width: 20, height: 20)

                Text(grade.rawValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }

            // Summary text
            if watchCount > 0 || hasPersonalAlert {
                Text(summaryText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(grade.color)
            }

            // Personal alert indicator
            if hasPersonalAlert {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 9))
                    .foregroundColor(SemanticColors.caution)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(grade.color.opacity(0.12))
        )
    }

    private var summaryText: String {
        if watchCount == 0 {
            return grade == .none ? "Clean" : "Safe"
        } else {
            return "\(watchCount) to watch"
        }
    }
}

// MARK: - Additive Analyzer Service

class AdditiveAnalyzer {
    static let shared = AdditiveAnalyzer()

    private init() {}

    /// Build analysis from a raw detection result (exposed for reuse)
    func buildAnalysis(
        from detectionResult: AdditiveDetectionResult,
        userSensitivities: Set<String> = []
    ) -> AdditiveAnalysisResult {
        return processDetectionResult(detectionResult, userSensitivities: userSensitivities)
    }

    /// Analyze ingredients asynchronously and return complete analysis result
    func analyze(
        ingredients: [String],
        userSensitivities: Set<String> = []
    ) async -> AdditiveAnalysisResult {
        return await withCheckedContinuation { continuation in
            AdditiveWatchService.shared.analyzeIngredients(ingredients) { detectionResult in
                let result = self.processDetectionResult(
                    detectionResult,
                    userSensitivities: userSensitivities
                )
                continuation.resume(returning: result)
            }
        }
    }

    /// Synchronous version that uses completion handler
    func analyze(
        ingredients: [String],
        userSensitivities: Set<String> = [],
        completion: @escaping (AdditiveAnalysisResult) -> Void
    ) {
        AdditiveWatchService.shared.analyzeIngredients(ingredients) { detectionResult in
            let result = self.processDetectionResult(
                detectionResult,
                userSensitivities: userSensitivities
            )
            completion(result)
        }
    }

    /// Process detection result into our analysis format
    private func processDetectionResult(
        _ detectionResult: AdditiveDetectionResult,
        userSensitivities: Set<String>
    ) -> AdditiveAnalysisResult {
        // Build analyzed additives with full info
        var groupedAdditives: [AdditiveRiskLevel: [AnalyzedAdditive]] = [
            .noRisk: [],
            .lowRisk: [],
            .moderateRisk: [],
            .highRisk: []
        ]

        var personalAlerts: [PersonalAdditiveAlert] = []
        var totalCount = 0
        var highRiskCount = 0
        var moderateRiskCount = 0
        var lowRiskCount = 0
        var safeCount = 0

        // Process detected E-number additives
        for additive in detectionResult.detectedAdditives {
            let riskLevel = AdditiveOverrides.getRiskLevel(for: additive)
            let override = AdditiveOverrides.override(for: additive)

            // Check for personal sensitivity match
            let (affectsSensitivity, sensitivityName) = checkSensitivity(
                additive: additive,
                userSensitivities: userSensitivities
            )

            // Build why flagged reasons - ALWAYS provide a clear reason
            var whyFlagged: [String] = []

            // Add specific warnings first
            if additive.hasChildWarning {
                whyFlagged.append("Not recommended for children")
            }
            if additive.hasSulphitesAllergenLabel {
                whyFlagged.append("Contains sulphites (allergen)")
            }

            // Add the risk summary from overrides (most accurate info)
            if let riskSummary = override?.riskSummary, !riskSummary.isEmpty {
                whyFlagged.append(riskSummary)
            }

            // If still no reason, add one based on risk level (ensure every additive has info)
            if whyFlagged.isEmpty {
                switch riskLevel {
                case .highRisk:
                    whyFlagged.append("Studies suggest limiting intake of this additive")
                case .moderateRisk:
                    whyFlagged.append("Safe in small amounts, but worth being aware of")
                case .lowRisk:
                    whyFlagged.append("Generally considered safe for most people")
                case .noRisk:
                    if isVitaminOrMineral(additive) {
                        whyFlagged.append("A vitamin or mineral - beneficial to health")
                    } else {
                        whyFlagged.append("Natural or well-studied with no known concerns")
                    }
                }
            }

            let analyzed = AnalyzedAdditive(
                name: override?.displayName ?? additive.name,
                eNumber: additive.eNumber,
                riskLevel: riskLevel,
                shortDescription: override?.originSummary ?? additive.origin.rawValue,
                whatItIs: override?.whatItIs ?? "A food additive used in processing.",
                origin: additive.origin.rawValue,
                whyFlagged: whyFlagged,
                affectsUserSensitivity: affectsSensitivity,
                sensitivityName: sensitivityName,
                isVitaminOrMineral: isVitaminOrMineral(additive)
            )

            groupedAdditives[riskLevel, default: []].append(analyzed)
            totalCount += 1

            switch riskLevel {
            case .noRisk: safeCount += 1
            case .lowRisk: lowRiskCount += 1
            case .moderateRisk: moderateRiskCount += 1
            case .highRisk: highRiskCount += 1
            }

            // Add personal alert if applicable
            if affectsSensitivity, let sensitivity = sensitivityName {
                personalAlerts.append(PersonalAdditiveAlert(
                    additiveName: override?.displayName ?? additive.name,
                    eNumber: additive.eNumber,
                    sensitivityName: sensitivity,
                    reason: "You've marked \(sensitivity) as a sensitivity"
                ))
            }
        }

        // ALSO process ultra-processed ingredients (palm oil, hydrogenated fats, etc.)
        for ultraProcessed in detectionResult.ultraProcessedIngredients {
            // Determine risk level based on processing penalty and NOVA group
            let riskLevel: AdditiveRiskLevel
            if ultraProcessed.novaGroup == 4 || ultraProcessed.processingPenalty >= 8 {
                riskLevel = .highRisk
                highRiskCount += 1
            } else if ultraProcessed.processingPenalty >= 5 {
                riskLevel = .moderateRisk
                moderateRiskCount += 1
            } else if ultraProcessed.processingPenalty >= 2 {
                riskLevel = .lowRisk
                lowRiskCount += 1
            } else {
                riskLevel = .noRisk
                safeCount += 1
            }

            // Build why flagged for ultra-processed
            var whyFlagged: [String] = []
            if !ultraProcessed.concerns.isEmpty {
                whyFlagged.append(ultraProcessed.concerns)
            }
            if ultraProcessed.novaGroup == 4 {
                whyFlagged.append("Highly processed (NOVA Group 4)")
            }
            if whyFlagged.isEmpty {
                whyFlagged.append("An industrially processed ingredient")
            }

            let analyzed = AnalyzedAdditive(
                name: ultraProcessed.name,
                eNumber: ultraProcessed.eNumbers.first ?? "",
                riskLevel: riskLevel,
                shortDescription: ultraProcessed.category,
                whatItIs: ultraProcessed.whatItIs ?? "A processed ingredient used in food manufacturing.",
                origin: ultraProcessed.whereItComesFrom ?? "Industrial processing",
                whyFlagged: whyFlagged,
                affectsUserSensitivity: false,
                sensitivityName: nil,
                isVitaminOrMineral: false
            )

            groupedAdditives[riskLevel, default: []].append(analyzed)
            totalCount += 1
        }

        // Calculate score (100 = no additives or all safe, 0 = many high risk)
        let score = calculateScore(
            highRisk: highRiskCount,
            moderate: moderateRiskCount,
            low: lowRiskCount,
            safe: safeCount
        )

        let grade = AdditiveGrade.from(score: score, hasAdditives: totalCount > 0)

        return AdditiveAnalysisResult(
            score: score,
            grade: grade,
            totalCount: totalCount,
            highRiskCount: highRiskCount,
            moderateRiskCount: moderateRiskCount,
            lowRiskCount: lowRiskCount,
            safeCount: safeCount,
            personalAlerts: personalAlerts,
            groupedAdditives: groupedAdditives
        )
    }

    private func calculateScore(highRisk: Int, moderate: Int, low: Int, safe: Int) -> Int {
        let total = highRisk + moderate + low + safe

        if total == 0 {
            return 100 // No additives = perfect score
        }

        // Start with base 100
        var score = 100

        // Heavy penalties for risk levels (more aggressive than before)
        // High risk: -20 each (e.g., 3 high risk = -60 = score 40)
        // Moderate: -10 each
        // Low risk: -5 each
        // Safe/vitamins: -1 each (still counts against perfect score)
        let riskPenalty = (highRisk * 20) + (moderate * 10) + (low * 5) + (safe * 1)
        score -= riskPenalty

        // Additional penalty for sheer quantity (more than 3 additives starts hurting)
        // This ensures even "safe" additives lower the score when there are many
        if total > 3 {
            let quantityPenalty = (total - 3) * 3  // -3 per additive over 3
            score -= quantityPenalty
        }

        // Extra penalty if more than half are high/moderate risk
        let concerningCount = highRisk + moderate
        if concerningCount > 0 && Double(concerningCount) / Double(total) > 0.5 {
            score -= 10  // Additional -10 if majority are concerning
        }

        // Clamp to 0-100
        return max(0, min(100, score))
    }

    private func checkSensitivity(
        additive: AdditiveInfo,
        userSensitivities: Set<String>
    ) -> (Bool, String?) {
        let nameLower = additive.name.lowercased()
        let eNumberLower = additive.eNumber.lowercased()

        // Check sulphites
        if userSensitivities.contains("sulphites") || userSensitivities.contains("sulfites") {
            if additive.hasSulphitesAllergenLabel ||
               nameLower.contains("sulphite") ||
               nameLower.contains("sulfite") ||
               eNumberLower == "e150b" ||
               eNumberLower == "e150d" ||
               (eNumberLower >= "e220" && eNumberLower <= "e228") {
                return (true, "sulphites")
            }
        }

        // Check MSG sensitivity
        if userSensitivities.contains("msg") || userSensitivities.contains("glutamate") {
            if eNumberLower == "e621" ||
               nameLower.contains("monosodium glutamate") ||
               nameLower.contains("msg") {
                return (true, "MSG")
            }
        }

        // Check nitrates/nitrites
        if userSensitivities.contains("nitrates") || userSensitivities.contains("nitrites") {
            if (eNumberLower >= "e249" && eNumberLower <= "e252") ||
               nameLower.contains("nitrate") ||
               nameLower.contains("nitrite") {
                return (true, "nitrates")
            }
        }

        return (false, nil)
    }

    private func isVitaminOrMineral(_ additive: AdditiveInfo) -> Bool {
        let nameLower = additive.name.lowercased()
        let eNumberLower = additive.eNumber.lowercased()

        let vitaminENumbers = ["e300", "e301", "e302", "e303", "e304",
                               "e306", "e307", "e308", "e309",
                               "e101", "e160a", "e375"]

        let vitaminKeywords = ["vitamin", "ascorbic", "riboflavin", "thiamin",
                               "niacin", "tocopherol", "beta-carotene", "folate",
                               "folic acid"]

        for e in vitaminENumbers {
            if eNumberLower == e { return true }
        }

        for keyword in vitaminKeywords {
            if nameLower.contains(keyword) { return true }
        }

        return false
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Safety badge examples - No additives (good)
            AdditiveSafetyBadge(
                analysis: AdditiveAnalysisResult(
                    score: 100,
                    grade: .none,
                    totalCount: 0,
                    highRiskCount: 0,
                    moderateRiskCount: 0,
                    lowRiskCount: 0,
                    safeCount: 0,
                    personalAlerts: [],
                    groupedAdditives: [:]
                ),
                hasIngredients: true
            )
            .padding(.horizontal)

            // Has low-risk additives (average)
            AdditiveSafetyBadge(
                analysis: AdditiveAnalysisResult(
                    score: 85,
                    grade: .average,
                    totalCount: 2,
                    highRiskCount: 0,
                    moderateRiskCount: 0,
                    lowRiskCount: 1,
                    safeCount: 1,
                    personalAlerts: [],
                    groupedAdditives: [:]
                ),
                hasIngredients: true
            )
            .padding(.horizontal)

            // Has concerning additives (below average)
            AdditiveSafetyBadge(
                analysis: AdditiveAnalysisResult(
                    score: 58,
                    grade: .belowAverage,
                    totalCount: 5,
                    highRiskCount: 1,
                    moderateRiskCount: 2,
                    lowRiskCount: 1,
                    safeCount: 1,
                    personalAlerts: [
                        PersonalAdditiveAlert(
                            additiveName: "Sulphite Ammonia Caramel",
                            eNumber: "E150d",
                            sensitivityName: "sulphites",
                            reason: "You've marked sulphites as a sensitivity"
                        )
                    ],
                    groupedAdditives: [:]
                ),
                hasIngredients: true
            )
            .padding(.horizontal)

            // Mini badges
            HStack(spacing: 12) {
                AdditiveMiniGradeBadge(grade: .none, watchCount: 0, hasPersonalAlert: false)
                AdditiveMiniGradeBadge(grade: .average, watchCount: 1, hasPersonalAlert: false)
                AdditiveMiniGradeBadge(grade: .poor, watchCount: 3, hasPersonalAlert: true)
            }
            .padding(.horizontal)

            // Circular score
            HStack(spacing: 20) {
                AdditiveCircularScore(score: 100, grade: .none)
                AdditiveCircularScore(score: 58, grade: .belowAverage)
                AdditiveCircularScore(score: 28, grade: .poor)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
