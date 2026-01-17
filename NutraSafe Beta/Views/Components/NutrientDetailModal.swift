import SwiftUI
import UIKit

// MARK: - Nutrient Detail Modal
// Note: Uses HealthClaim from FoodDetailViewFromSearch.swift

@available(iOS 16.0, *)
struct NutrientDetailModal: View {
    let row: CoverageRow
    @Environment(\.dismiss) private var dismiss
    @State private var nutrientInfo: NutrientInfo?
    @State private var showingCitations = false
    @State private var showingHealthClaims = false

    // Get nutrient metadata for styling
    private var trackedNutrient: TrackedNutrient? {
        NutrientDatabase.nutrient(for: row.id)
    }

    private var nutrientColor: Color {
        trackedNutrient?.glowColor ?? .blue
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero header with gradient
                    heroHeader

                    // Content sections
                    VStack(spacing: 20) {
                        // Quick stats row
                        quickStatsRow

                        // Week calendar view
                        weekCalendarView

                        // Good food sources (from database)
                        if nutrientInfo != nil {
                            goodFoodSourcesSection
                        }

                        // Official health claims (collapsible)
                        if let claims = getOfficialHealthClaims(for: row.name), !claims.isEmpty {
                            healthClaimsSection(claims: claims)
                        }

                        // Contributing foods you ate
                        if !allFoods.isEmpty {
                            foodsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.adaptiveBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await loadNutrientInfo()
            }
            .fullScreenCover(isPresented: $showingCitations) {
                citationsSheet
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [nutrientColor.opacity(0.3), nutrientColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: nutrientIcon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [nutrientColor, nutrientColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Nutrient name
            Text(row.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            // Category badge
            if let nutrient = trackedNutrient {
                Text(nutrient.category == .vitamin ? "Vitamin" : nutrient.category == .mineral ? "Mineral" : "Nutrient")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(nutrientColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(nutrientColor.opacity(0.12))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [nutrientColor.opacity(0.08), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header explaining the stats
            Text("Sources of \(row.name) This Week")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                // Foods count stat
                statCard(
                    value: "\(totalFoods)",
                    label: totalFoods == 1 ? "Food" : "Foods",
                    icon: "fork.knife",
                    color: totalFoods > 0 ? .green : .gray
                )

                // Days count stat
                statCard(
                    value: "\(daysWithFood)",
                    label: daysWithFood == 1 ? "Day" : "Days",
                    icon: "calendar",
                    color: daysWithFood >= 5 ? .green : daysWithFood >= 3 ? .orange : .gray
                )

                // Coverage stat
                let coveragePercent = Int((Double(daysWithFood) / 7.0) * 100)
                statCard(
                    value: "\(coveragePercent)%",
                    label: "Coverage",
                    icon: "chart.pie.fill",
                    color: coveragePercent >= 70 ? .green : coveragePercent >= 40 ? .orange : .gray
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Week Calendar View

    private var weekCalendarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "This Week", icon: "calendar")

            // Calendar grid
            HStack(spacing: 8) {
                ForEach(row.segments.reversed(), id: \.date) { segment in
                    let foodCount = segment.foods?.count ?? 0
                    let isToday = Calendar.current.isDateInToday(segment.date)

                    VStack(spacing: 6) {
                        // Day label
                        Text(shortDayLabel(segment.date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isToday ? nutrientColor : .secondary)

                        // Circle indicator
                        ZStack {
                            Circle()
                                .fill(foodCount > 0 ? nutrientColor : Color(.systemGray5))
                                .frame(width: 36, height: 36)

                            if foodCount > 0 {
                                Text("\(foodCount)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            } else {
                                Text("–")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Date number
                        Text(dayNumber(segment.date))
                            .font(.system(size: 12, weight: isToday ? .bold : .regular))
                            .foregroundColor(isToday ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: - Food Sources Section

    private var goodFoodSourcesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "Good Sources", icon: "leaf.fill")
                Spacer()
                Button(action: { showingCitations = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }

            if let info = nutrientInfo {
                let sources = parseArrayContent(info.commonSources)
                if !sources.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(sources, id: \.self) { source in
                            HStack(spacing: 6) {
                                Image(systemName: foodIcon(for: source))
                                    .font(.system(size: 12))
                                Text(source)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(nutrientColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(nutrientColor.opacity(0.1))
                            )
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
    }

    // MARK: - Health Claims Section

    private func healthClaimsSection(claims: [HealthClaim]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button (always visible)
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showingHealthClaims.toggle() } }) {
                HStack {
                    sectionHeader(title: "Health Benefits", icon: "checkmark.seal.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingHealthClaims ? 90 : 0))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: showingHealthClaims ? 0 : 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .clipShape(
                    RoundedCorners(
                        topLeft: 16,
                        topRight: 16,
                        bottomLeft: showingHealthClaims ? 0 : 16,
                        bottomRight: showingHealthClaims ? 0 : 16
                    )
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Expandable content
            if showingHealthClaims {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(claims.enumerated()), id: \.offset) { _, claim in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(claim.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(claim.source)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedCorners(topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
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

    // MARK: - Foods Section

    private var foodsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Your Sources This Week", icon: "fork.knife")

            VStack(spacing: 0) {
                ForEach(Array(foodsWithCounts.prefix(8).enumerated()), id: \.element.name) { index, foodItem in
                    HStack(spacing: 12) {
                        // Food icon
                        ZStack {
                            Circle()
                                .fill(nutrientColor.opacity(0.15))
                                .frame(width: 32, height: 32)

                            Image(systemName: foodIcon(for: foodItem.name))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(nutrientColor)
                        }

                        Text(foodItem.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        // Serving count badge
                        if foodItem.count > 1 {
                            Text("×\(foodItem.count)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(nutrientColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(nutrientColor.opacity(0.12))
                                )
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)

                    if index < min(foodsWithCounts.count - 1, 7) {
                        Divider()
                            .padding(.leading, 56)
                    }
                }

                if foodsWithCounts.count > 8 {
                    HStack {
                        Spacer()
                        Text("+ \(foodsWithCounts.count - 8) more")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
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
                                .foregroundColor(.blue)
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

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(nutrientColor)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
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
