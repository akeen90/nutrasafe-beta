import SwiftUI
import UIKit

// MARK: - Nutrient Detail Modal
// Redesigned as a micro health insight experience with calm intelligence

@available(iOS 16.0, *)
struct NutrientDetailModal: View {
    let row: CoverageRow
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var nutrientInfo: NutrientInfo?
    @State private var showingCitations = false
    @State private var showingHealthClaims = false
    @State private var appearAnimation = false

    // Design system palette
    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // Get nutrient metadata for styling
    private var trackedNutrient: TrackedNutrient? {
        NutrientDatabase.nutrient(for: row.id)
    }

    private var nutrientColor: Color {
        trackedNutrient?.glowColor ?? Color(hex: "#3FD17C")
    }

    private var nutrientIcon: String {
        trackedNutrient?.icon ?? "leaf.fill"
    }

    private var totalFoods: Int {
        row.segments.compactMap { $0.foods?.count }.reduce(0, +)
    }

    private var daysWithFood: Int {
        row.segments.filter { ($0.foods?.count ?? 0) > 0 }.count
    }

    private var coveragePercent: Int {
        Int((Double(daysWithFood) / 7.0) * 100)
    }

    /// Observational coverage insight message
    private var coverageInsight: String {
        if coveragePercent >= 85 {
            return "You've had \(row.name) nearly every day this week"
        } else if coveragePercent >= 70 {
            return "Good variety of \(row.name) sources this week"
        } else if coveragePercent >= 40 {
            return "Some \(row.name) intake this week"
        } else if daysWithFood > 0 {
            return "\(row.name) appeared on \(daysWithFood) day\(daysWithFood == 1 ? "" : "s") this week"
        } else {
            return "No \(row.name) sources logged this week"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header with layered translucent symbol
                    heroHeader

                    // Content sections
                    VStack(spacing: 20) {
                        // Primary insight strip
                        primaryInsightStrip

                        // Refined weekly timeline
                        weeklyTimeline

                        // Good food sources (elegant list, not chips)
                        if nutrientInfo != nil {
                            goodFoodSourcesSection
                        }

                        // Health benefits with matching iconography
                        if let claims = getOfficialHealthClaims(for: row.name), !claims.isEmpty {
                            healthBenefitsSection(claims: claims)
                        }

                        // Your sources this week
                        if !allFoods.isEmpty {
                            yourSourcesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.adaptiveBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(nutrientColor)
                }
            }
            .task {
                await loadNutrientInfo()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                    appearAnimation = true
                }
            }
            .fullScreenCover(isPresented: $showingCitations) {
                citationsSheet
            }
        }
    }

    // MARK: - Hero Header (Layered Translucent Design)

    private var heroHeader: some View {
        ZStack {
            // Soft radial backdrop glow
            RadialGradient(
                colors: [
                    nutrientColor.opacity(0.15),
                    nutrientColor.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .frame(height: 240)

            VStack(spacing: 20) {
                // Layered translucent vitamin symbol
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [nutrientColor.opacity(0.12), nutrientColor.opacity(0.02)],
                                center: .center,
                                startRadius: 40,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(appearAnimation ? 1.0 : 0.8)
                        .opacity(appearAnimation ? 1.0 : 0)

                    // Middle frosted layer
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 88, height: 88)
                        .overlay(
                            Circle()
                                .stroke(nutrientColor.opacity(0.2), lineWidth: 1)
                        )
                        .scaleEffect(appearAnimation ? 1.0 : 0.9)
                        .opacity(appearAnimation ? 1.0 : 0)

                    // Inner gradient core
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    nutrientColor.opacity(colorScheme == .dark ? 0.35 : 0.25),
                                    nutrientColor.opacity(colorScheme == .dark ? 0.15 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)

                    // Icon with gradient
                    Image(systemName: nutrientIcon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [nutrientColor, nutrientColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(appearAnimation ? 1.0 : 0.7)
                        .opacity(appearAnimation ? 1.0 : 0)
                }

                // Nutrient name with refined typography
                VStack(spacing: 8) {
                    Text(row.name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(palette.textPrimary)

                    // Refined category badge with signal icon
                    if let nutrient = trackedNutrient {
                        HStack(spacing: 6) {
                            NutraSafeSignalIcon(color: nutrientColor, size: 12)

                            Text(nutrient.category == .vitamin ? "Vitamin" : nutrient.category == .mineral ? "Mineral" : "Nutrient")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(nutrientColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(nutrientColor.opacity(0.10))
                                .overlay(
                                    Capsule()
                                        .stroke(nutrientColor.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
                .opacity(appearAnimation ? 1.0 : 0)
                .offset(y: appearAnimation ? 0 : 10)
            }
            .padding(.vertical, 28)
        }
    }

    // MARK: - Primary Insight Strip

    private var primaryInsightStrip: some View {
        VStack(spacing: 16) {
            // Main insight message with signal icon
            HStack(spacing: 12) {
                NutraSafeSignalIcon(color: insightColor, size: 20)

                Text(coverageInsight)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(palette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }

            // Elegant stat capsules row
            HStack(spacing: 10) {
                insightCapsule(
                    value: "\(totalFoods)",
                    label: totalFoods == 1 ? "source" : "sources",
                    icon: "fork.knife"
                )

                insightCapsule(
                    value: "\(daysWithFood)",
                    label: daysWithFood == 1 ? "day" : "days",
                    icon: "calendar"
                )

                insightCapsule(
                    value: "\(coveragePercent)%",
                    label: "coverage",
                    icon: "chart.pie.fill"
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            insightColor.opacity(colorScheme == .dark ? 0.12 : 0.08),
                            insightColor.opacity(colorScheme == .dark ? 0.06 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(insightColor.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var insightColor: Color {
        if coveragePercent >= 70 {
            return Color(hex: "#3FD17C") // Green
        } else if coveragePercent >= 40 {
            return .orange
        } else if daysWithFood > 0 {
            return palette.textTertiary
        } else {
            return palette.textTertiary.opacity(0.6)
        }
    }

    private func insightCapsule(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(nutrientColor.opacity(0.8))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(palette.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(palette.textTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Refined Weekly Timeline

    private var weeklyTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "This Week", icon: "calendar", color: nutrientColor)

            // Elegant timeline grid
            HStack(spacing: 6) {
                ForEach(row.segments.reversed(), id: \.date) { segment in
                    let foodCount = segment.foods?.count ?? 0
                    let isToday = Calendar.current.isDateInToday(segment.date)
                    let hasFood = foodCount > 0

                    VStack(spacing: 8) {
                        // Day label
                        Text(shortDayLabel(segment.date))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(isToday ? nutrientColor : palette.textTertiary)
                            .textCase(.uppercase)

                        // Circle indicator with gentle styling
                        ZStack {
                            // Today pulse ring
                            if isToday {
                                Circle()
                                    .stroke(nutrientColor.opacity(0.3), lineWidth: 2)
                                    .frame(width: 42, height: 42)
                            }

                            // Main circle
                            Circle()
                                .fill(
                                    hasFood
                                        ? LinearGradient(
                                            colors: [nutrientColor, nutrientColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [
                                                palette.tertiary.opacity(colorScheme == .dark ? 0.15 : 0.08),
                                                palette.tertiary.opacity(colorScheme == .dark ? 0.10 : 0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            hasFood
                                                ? nutrientColor.opacity(0.3)
                                                : palette.tertiary.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )

                            // Content
                            if hasFood {
                                Text("\(foodCount)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .fill(palette.textTertiary.opacity(0.3))
                                    .frame(width: 4, height: 4)
                            }
                        }

                        // Date number
                        Text(dayNumber(segment.date))
                            .font(.system(size: 11, weight: isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(isToday ? palette.textPrimary : palette.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.adaptiveCard)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Good Food Sources Section (Elegant List)

    private var goodFoodSourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "Good Sources", icon: "leaf.fill", color: nutrientColor)
                Spacer()
                Button(action: { showingCitations = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 11, weight: .medium))
                        Text("Sources")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(palette.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(palette.accent.opacity(0.1))
                    )
                }
            }

            if let info = nutrientInfo {
                let sources = parseArrayContent(info.commonSources)
                if !sources.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                            HStack(spacing: 14) {
                                // Elegant food icon container
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    nutrientColor.opacity(0.15),
                                                    nutrientColor.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 36, height: 36)

                                    Image(systemName: foodIcon(for: source))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(nutrientColor)
                                }

                                Text(source)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(palette.textPrimary)

                                Spacer()

                                // Subtle indicator
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(nutrientColor.opacity(0.6))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)

                            if index < sources.count - 1 {
                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.adaptiveCard)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                }
            }
        }
    }

    // MARK: - Health Benefits Section (Refined Design)

    private func healthBenefitsSection(claims: [HealthClaim]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button with elegant styling
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingHealthClaims.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Benefit icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#3FD17C").opacity(0.15),
                                        Color(hex: "#3FD17C").opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        NutraSafeSignalIcon(color: Color(hex: "#3FD17C"), size: 16)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Health Benefits")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(palette.textPrimary)

                        Text("\(claims.count) verified claim\(claims.count == 1 ? "" : "s")")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(palette.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(showingHealthClaims ? -180 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: showingHealthClaims ? 0 : 16)
                        .fill(Color.adaptiveCard)
                )
                .clipShape(
                    RoundedCorners(
                        topLeft: 16,
                        topRight: 16,
                        bottomLeft: showingHealthClaims ? 0 : 16,
                        bottomRight: showingHealthClaims ? 0 : 16
                    )
                )
                .shadow(color: Color.black.opacity(showingHealthClaims ? 0 : 0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())

            // Expandable content with elegant claim cards
            if showingHealthClaims {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(claims.enumerated()), id: \.offset) { index, claim in
                        HStack(alignment: .top, spacing: 14) {
                            // Icon matching the benefit type
                            ZStack {
                                Circle()
                                    .fill(benefitColor(for: claim.text).opacity(0.12))
                                    .frame(width: 32, height: 32)

                                Image(systemName: benefitIcon(for: claim.text))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(benefitColor(for: claim.text))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(claim.text)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(palette.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                // Source badge
                                HStack(spacing: 4) {
                                    Image(systemName: claim.source == "NHS" ? "heart.fill" : "checkmark.seal.fill")
                                        .font(.system(size: 9, weight: .medium))
                                    Text(claim.source)
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(claim.source == "NHS" ? .pink : palette.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill((claim.source == "NHS" ? Color.pink : palette.accent).opacity(0.1))
                                )
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)

                        if index < claims.count - 1 {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .background(
                    RoundedCorners(topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16)
                        .fill(Color.adaptiveCard)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
        }
    }

    /// Map benefit text to appropriate icon
    private func benefitIcon(for text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("immune") { return "shield.fill" }
        if lower.contains("bone") || lower.contains("teeth") { return "figure.stand" }
        if lower.contains("energy") || lower.contains("metabolism") { return "bolt.fill" }
        if lower.contains("blood") || lower.contains("red blood") { return "drop.fill" }
        if lower.contains("skin") || lower.contains("collagen") { return "sparkles" }
        if lower.contains("vision") || lower.contains("eye") { return "eye.fill" }
        if lower.contains("muscle") { return "figure.strengthtraining.traditional" }
        if lower.contains("nervous") || lower.contains("brain") { return "brain.head.profile" }
        if lower.contains("heart") || lower.contains("blood pressure") { return "heart.fill" }
        if lower.contains("tiredness") || lower.contains("fatigue") { return "battery.75percent" }
        if lower.contains("iron absorption") { return "arrow.down.circle.fill" }
        if lower.contains("thyroid") { return "waveform.path.ecg" }
        if lower.contains("wound") || lower.contains("healing") { return "bandage.fill" }
        if lower.contains("hair") || lower.contains("nails") { return "leaf.fill" }
        if lower.contains("cell") || lower.contains("oxidative") { return "shield.lefthalf.filled" }
        return "checkmark.circle.fill"
    }

    /// Map benefit text to appropriate color
    private func benefitColor(for text: String) -> Color {
        let lower = text.lowercased()
        if lower.contains("immune") { return .blue }
        if lower.contains("bone") || lower.contains("teeth") { return .purple }
        if lower.contains("energy") || lower.contains("metabolism") { return .orange }
        if lower.contains("blood") { return .red }
        if lower.contains("skin") || lower.contains("collagen") { return .pink }
        if lower.contains("vision") || lower.contains("eye") { return .cyan }
        if lower.contains("muscle") { return .indigo }
        if lower.contains("nervous") || lower.contains("brain") { return .purple }
        if lower.contains("heart") { return .red }
        if lower.contains("tiredness") || lower.contains("fatigue") { return .yellow }
        if lower.contains("thyroid") { return .teal }
        return Color(hex: "#3FD17C")
    }

    // Custom shape for rounded corners on specific sides
    private struct RoundedCorners: Shape {
        var topLeft: CGFloat
        var topRight: CGFloat
        var bottomLeft: CGFloat
        var bottomRight: CGFloat

        func path(in rect: CGRect) -> Path {
            var path = Path()
            let w = rect.size.width
            let h = rect.size.height

            path.move(to: CGPoint(x: topLeft, y: 0))
            path.addLine(to: CGPoint(x: w - topRight, y: 0))
            path.addArc(center: CGPoint(x: w - topRight, y: topRight), radius: topRight, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: w, y: h - bottomRight))
            path.addArc(center: CGPoint(x: w - bottomRight, y: h - bottomRight), radius: bottomRight, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: bottomLeft, y: h))
            path.addArc(center: CGPoint(x: bottomLeft, y: h - bottomLeft), radius: bottomLeft, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: topLeft))
            path.addArc(center: CGPoint(x: topLeft, y: topLeft), radius: topLeft, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()

            return path
        }
    }

    // MARK: - Your Sources Section (Refined)

    private var yourSourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Your Sources", icon: "fork.knife", color: nutrientColor)

            VStack(spacing: 0) {
                ForEach(Array(foodsWithCounts.prefix(8).enumerated()), id: \.element.name) { index, foodItem in
                    HStack(spacing: 14) {
                        // Elegant food icon container
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            nutrientColor.opacity(0.15),
                                            nutrientColor.opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)

                            Image(systemName: foodIcon(for: foodItem.name))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(nutrientColor)
                        }

                        Text(foodItem.name)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Serving count badge with refined styling
                        if foodItem.count > 1 {
                            Text("×\(foodItem.count)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(nutrientColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(nutrientColor.opacity(0.12))
                                        .overlay(
                                            Capsule()
                                                .stroke(nutrientColor.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(nutrientColor.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)

                    if index < min(foodsWithCounts.count - 1, 7) {
                        Divider()
                            .padding(.leading, 64)
                    }
                }

                if foodsWithCounts.count > 8 {
                    HStack(spacing: 6) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .medium))
                        Text("\(foodsWithCounts.count - 8) more")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.adaptiveCard)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    // MARK: - Citations Sheet

    private var citationsSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Food Sources Data")) {
                    Text("Food sources listed in this app are based on official nutrition databases.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach([
                    CitationManager.Citation(
                        title: "FoodData Central",
                        organization: "U.S. Department of Agriculture (USDA)",
                        url: "https://fdc.nal.usda.gov/",
                        description: "Official USDA nutrient database providing comprehensive food composition data.",
                        category: .nutritionData
                    ),
                    CitationManager.Citation(
                        title: "UK Composition of Foods Integrated Dataset (CoFID)",
                        organization: "UK Food Standards Agency & Public Health England",
                        url: "https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid",
                        description: "UK's official database of nutrient content in foods.",
                        category: .nutritionData
                    )
                ]) { citation in
                    Button(action: {
                        if let url = URL(string: citation.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(citation.organization)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(citation.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(AppPalette.standard.accent)
                        }
                    }
                }
            }
            .navigationTitle("Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingCitations = false }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.adaptiveBackground)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String, color: Color? = nil) -> some View {
        HStack(spacing: 10) {
            // Signal icon container
            ZStack {
                Circle()
                    .fill((color ?? nutrientColor).opacity(0.12))
                    .frame(width: 28, height: 28)

                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color ?? nutrientColor)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(palette.textPrimary)
        }
    }

    // MARK: - Helper Functions

    private var allFoods: [String] {
        foodsWithCounts.map { $0.name }
    }

    /// Foods with their serving counts, sorted by count (highest first)
    private var foodsWithCounts: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for segment in row.segments {
            if let segmentFoods = segment.foods {
                for food in segmentFoods {
                    counts[food, default: 0] += 1
                }
            }
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func shortDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(3))
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func foodIcon(for food: String) -> String {
        let lower = food.lowercased()
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") { return "fish.fill" }
        if lower.contains("egg") { return "oval.fill" }
        if lower.contains("milk") || lower.contains("dairy") || lower.contains("yogurt") { return "cup.and.saucer.fill" }
        if lower.contains("meat") || lower.contains("beef") || lower.contains("chicken") || lower.contains("pork") { return "fork.knife" }
        if lower.contains("nut") || lower.contains("almond") || lower.contains("walnut") { return "leaf.fill" }
        if lower.contains("fruit") || lower.contains("orange") || lower.contains("berry") { return "apple.logo" }
        if lower.contains("vegetable") || lower.contains("spinach") || lower.contains("broccoli") { return "leaf.fill" }
        if lower.contains("cereal") || lower.contains("bread") || lower.contains("grain") { return "birthday.cake.fill" }
        return "circle.fill"
    }

    private func loadNutrientInfo() async {
        // Map display name to database ID
        let nutrientId = row.id
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        let info = MicronutrientDatabase.shared.getNutrientInfo(nutrientId)
        self.nutrientInfo = info
    }

    private func parseArrayContent(_ content: String?) -> [String] {
        guard let content = content else { return [] }

        // Try to decode as JSON array first
        if let data = content.data(using: .utf8),
           let array = try? JSONDecoder().decode([String].self, from: data) {
            return array.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }

        // Fallback: manually parse array format
        let trimmed = content.trimmingCharacters(in: CharacterSet(charactersIn: "[]\""))
        if trimmed.contains(",") {
            return trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
                .filter { !$0.isEmpty }
        }

        // Return as single item if not parseable and not empty
        return trimmed.isEmpty ? [] : [trimmed]
    }

    /// Get official health claims (EFSA/NHS verbatim wording) for a nutrient
    private func getOfficialHealthClaims(for nutrientName: String) -> [HealthClaim]? {
        let name = nutrientName.lowercased()

        if name.contains("vitamin c") || name.contains("ascorbic acid") {
            return [
                HealthClaim(text: "Vitamin C contributes to normal collagen formation for the normal function of blood vessels, bones, cartilage, gums, skin and teeth", source: "EFSA"),
                HealthClaim(text: "Vitamin C contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin C increases iron absorption", source: "EFSA"),
                HealthClaim(text: "Helps protect cells and keep them healthy", source: "NHS")
            ]
        }

        if name.contains("vitamin a") || name.contains("retinol") {
            return [
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin A contributes to the maintenance of normal skin", source: "EFSA"),
                HealthClaim(text: "Important for healthy skin and eyes", source: "NHS")
            ]
        }

        if name.contains("vitamin d") || name.contains("cholecalciferol") {
            return [
                HealthClaim(text: "Vitamin D contributes to normal absorption/utilisation of calcium and phosphorus", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Vitamin D contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Helps regulate calcium and phosphate in the body", source: "NHS")
            ]
        }

        if name.contains("vitamin e") || name.contains("tocopherol") {
            return [
                HealthClaim(text: "Vitamin E contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps protect cell membranes", source: "NHS")
            ]
        }

        if name.contains("vitamin k") || name.contains("phylloquinone") {
            return [
                HealthClaim(text: "Vitamin K contributes to normal blood clotting", source: "EFSA"),
                HealthClaim(text: "Vitamin K contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Needed for blood clotting and wound healing", source: "NHS")
            ]
        }

        if name.contains("vitamin b1") || name.contains("thiamin") {
            return [
                HealthClaim(text: "Thiamin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Thiamin contributes to normal function of the nervous system", source: "EFSA"),
                HealthClaim(text: "Thiamin contributes to normal psychological function", source: "EFSA"),
                HealthClaim(text: "Helps the body break down and release energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b2") || name.contains("riboflavin") {
            return [
                HealthClaim(text: "Riboflavin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to the maintenance of normal vision", source: "EFSA"),
                HealthClaim(text: "Riboflavin contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps keep skin, eyes and the nervous system healthy", source: "NHS")
            ]
        }

        if name.contains("vitamin b3") || name.contains("niacin") {
            return [
                HealthClaim(text: "Niacin contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Niacin contributes to normal function of the nervous system", source: "EFSA"),
                HealthClaim(text: "Niacin contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body release energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b6") || name.contains("pyridoxine") {
            return [
                HealthClaim(text: "Vitamin B6 contributes to normal protein and glycogen metabolism", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin B6 contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body use and store energy from food", source: "NHS")
            ]
        }

        if name.contains("vitamin b12") || name.contains("cobalamin") {
            return [
                HealthClaim(text: "Vitamin B12 contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Vitamin B12 contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps make red blood cells and keeps the nervous system healthy", source: "NHS")
            ]
        }

        if name.contains("folate") || name.contains("folic acid") || name.contains("vitamin b9") {
            return [
                HealthClaim(text: "Folate contributes to normal blood formation", source: "EFSA"),
                HealthClaim(text: "Folate contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Folate contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps the body form healthy red blood cells", source: "NHS")
            ]
        }

        if name.contains("calcium") {
            return [
                HealthClaim(text: "Calcium is needed for the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Calcium contributes to normal blood clotting", source: "EFSA"),
                HealthClaim(text: "Calcium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Needed for normal growth and development of bone in children", source: "NHS")
            ]
        }

        if name.contains("iron") {
            return [
                HealthClaim(text: "Iron contributes to normal formation of red blood cells and haemoglobin", source: "EFSA"),
                HealthClaim(text: "Iron contributes to normal oxygen transport in the body", source: "EFSA"),
                HealthClaim(text: "Iron contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Essential for making red blood cells which carry oxygen around the body", source: "NHS")
            ]
        }

        if name.contains("magnesium") {
            return [
                HealthClaim(text: "Magnesium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Magnesium contributes to the reduction of tiredness and fatigue", source: "EFSA"),
                HealthClaim(text: "Helps turn food into energy and supports normal muscle function", source: "NHS")
            ]
        }

        if name.contains("zinc") {
            return [
                HealthClaim(text: "Zinc contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the maintenance of normal skin, hair and nails", source: "EFSA"),
                HealthClaim(text: "Zinc contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps with wound healing and supports the immune system", source: "NHS")
            ]
        }

        if name.contains("potassium") {
            return [
                HealthClaim(text: "Potassium contributes to normal functioning of the nervous system", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to normal muscle function", source: "EFSA"),
                HealthClaim(text: "Potassium contributes to the maintenance of normal blood pressure", source: "EFSA"),
                HealthClaim(text: "Helps control the balance of fluids in the body", source: "NHS")
            ]
        }

        if name.contains("selenium") {
            return [
                HealthClaim(text: "Selenium contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Selenium contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Selenium contributes to the maintenance of normal hair and nails", source: "EFSA"),
                HealthClaim(text: "Helps the immune system work properly", source: "NHS")
            ]
        }

        if name.contains("iodine") {
            return [
                HealthClaim(text: "Iodine contributes to normal production of thyroid hormones and normal thyroid function", source: "EFSA"),
                HealthClaim(text: "Iodine contributes to normal cognitive function", source: "EFSA"),
                HealthClaim(text: "Iodine contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Helps make thyroid hormones which keep cells and metabolic rate healthy", source: "NHS")
            ]
        }

        if name.contains("phosphorus") {
            return [
                HealthClaim(text: "Phosphorus contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to the maintenance of normal bones and teeth", source: "EFSA"),
                HealthClaim(text: "Phosphorus contributes to normal function of cell membranes", source: "EFSA"),
                HealthClaim(text: "Helps build strong bones and teeth", source: "NHS")
            ]
        }

        if name.contains("copper") {
            return [
                HealthClaim(text: "Copper contributes to normal function of the immune system", source: "EFSA"),
                HealthClaim(text: "Copper contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Copper contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Helps produce red and white blood cells", source: "NHS")
            ]
        }

        if name.contains("manganese") {
            return [
                HealthClaim(text: "Manganese contributes to normal energy-yielding metabolism", source: "EFSA"),
                HealthClaim(text: "Manganese contributes to the maintenance of normal bones", source: "EFSA"),
                HealthClaim(text: "Manganese contributes to the protection of cells from oxidative stress", source: "EFSA"),
                HealthClaim(text: "Helps make and activate some enzymes in the body", source: "NHS")
            ]
        }

        return nil
    }
}
