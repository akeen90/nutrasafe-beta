//
//  NutrientActivityDashboard.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Main dashboard for nutrient activity tracking with visionOS aesthetic
//

import SwiftUI
import FirebaseAuth

// Filter type for nutrient performance
enum NutrientPerformanceFilter {
    case all
    case strong       // 70-100%
    case needsAttention  // 0-69%
}

@available(iOS 16.0, *)
struct NutrientActivityDashboard: View {
    @StateObject private var trackingManager = NutrientTrackingManager.shared
    @EnvironmentObject var diaryDataManager: DiaryDataManager
    @State private var selectedNutrient: TrackedNutrient?
    @State private var showingDetailView = false
    @State private var filterCategory: NutrientCategory?
    @State private var performanceFilter: NutrientPerformanceFilter = .all
    @State private var searchText = ""
    @State private var hasProcessedInitialData = false

    private var userId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        VStack(spacing: 24) {
            // Show content immediately - cached data should be available
            // Header
            headerSection

            // All Nutrients Grid (with rings showing 30-day progress)
            allNutrientsGridView

            // Dormant Nutrients
            if !dormantNutrients.isEmpty {
                dormantSectionView
            }
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.96, blue: 1.0),
                        Color(red: 0.93, green: 0.88, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                RadialGradient(
                    colors: [Color.blue.opacity(0.10), Color.clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 300
                )
                RadialGradient(
                    colors: [Color.purple.opacity(0.08), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 280
                )
            }
        )
        .sheet(isPresented: $showingDetailView) {
            if let nutrient = selectedNutrient {
                NutrientDetailView(nutrient: nutrient)
            }
        }
        .onAppear {
        // DEBUG LOG: print("🎯 NutrientActivityDashboard appeared")
            // Cached data is already loaded by NutrientTrackingManager, display it immediately
            // Only process fresh data in background to update cache
            if !hasProcessedInitialData {
                hasProcessedInitialData = true

                // If we have cached data, just refresh in background after a delay
                // If no cached data, process immediately
                if trackingManager.hasCachedData {
                    // Background refresh - don't block UI
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds delay
                        processCurrentDiaryData()
                    }
                } else {
                    // No cache, need to process now
                    processCurrentDiaryData()
                }
            }
        }
        .onChange(of: diaryDataManager.dataReloadTrigger) { _ in
        // DEBUG LOG: print("🔄 Diary data changed, reprocessing nutrients...")
            // Reprocess when diary data changes
            processCurrentDiaryData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Centered header
            VStack(spacing: 8) {
                Text("Nutrient Activity")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Last 30 days overview — consistency of nutrients in your logged meals")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 20)

                // Timeline button centered below description
                NavigationLink(destination: NutrientTimelineView()) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                        Text("Timeline")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }

            // Performance filter buttons
            performanceFilterView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var performanceFilterView: some View {
        HStack(spacing: 12) {
            FilterChip(
                title: "All",
                isSelected: performanceFilter == .all,
                action: { performanceFilter = .all }
            )

            FilterChip(
                title: "Needs attention",
                isSelected: performanceFilter == .needsAttention,
                action: { performanceFilter = .needsAttention }
            )
        }
    }

    private var categoryFilterView: some View {
        EmptyView()
    }

    // MARK: - Active Nutrients Section

    private var activeSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
                Text("Active Nutrients")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(activeNutrients.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(activeNutrients) { nutrient in
                        NutrientRingCard(
                            nutrient: nutrient,
                            frequency: trackingManager.getFrequency(for: nutrient.id)
                        )
                        .onTapGesture {
                            selectedNutrient = nutrient
                            showingDetailView = true
                            triggerHaptic()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - All Nutrients List

    private var allNutrientsGridView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Nutrients")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(filteredNutrients) { nutrient in
                    NutrientGridItem(
                        nutrient: nutrient,
                        frequency: trackingManager.getFrequency(for: nutrient.id)
                    )
                    .onTapGesture {
                        selectedNutrient = nutrient
                        showingDetailView = true
                        triggerHaptic()
                    }

                    if nutrient.id != filteredNutrients.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Dormant Nutrients Section

    private var dormantSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.fill")
                    .foregroundColor(.secondary)
                Text("Dormant Nutrients")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Text("\(dormantNutrients.count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                    )
            }

            VStack(spacing: 12) {
                ForEach(dormantNutrients) { nutrient in
                    DormantNutrientRow(
                        nutrient: nutrient,
                        frequency: trackingManager.getFrequency(for: nutrient.id)
                    )
                    .onTapGesture {
                        selectedNutrient = nutrient
                        showingDetailView = true
                        triggerHaptic()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Computed Properties

    private var activeNutrients: [TrackedNutrient] {
        trackingManager.getActiveNutrients()
    }

    private var dormantNutrients: [TrackedNutrient] {
        trackingManager.getDormantNutrients()
    }

    private var filteredNutrients: [TrackedNutrient] {
        var nutrients = NutrientDatabase.allNutrients

        // Filter by category
        if let category = filterCategory {
            nutrients = nutrients.filter { $0.category == category }
        }

        // Filter by performance
        switch performanceFilter {
        case .all:
            break // Show all
        case .strong:
            // Show nutrients with 70-100% consistency
            nutrients = nutrients.filter { nutrient in
                guard let freq = trackingManager.getFrequency(for: nutrient.id) else { return false }
                return freq.consistencyPercentage >= 70
            }
        case .needsAttention:
            // Show nutrients with 0-69% consistency
            nutrients = nutrients.filter { nutrient in
                guard let freq = trackingManager.getFrequency(for: nutrient.id) else { return false }
                return freq.consistencyPercentage < 70
            }
        }

        // Search filter
        if !searchText.isEmpty {
            nutrients = nutrients.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }

        // Sort alphabetically by display name
        return nutrients.sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Helpers

    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)

        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }

    private func triggerHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func processCurrentDiaryData() {
        // DEBUG LOG: print("🔄 Processing nutrients from diary...")
        Task {
            // Get food data for the last 30 days in parallel
            let calendar = Calendar.current
            let today = Date()
            var totalNutrientsTracked = 0

            // Create array of dates to process
            let dates = (0..<30).compactMap { daysAgo -> Date? in
                calendar.date(byAdding: .day, value: -daysAgo, to: today)
            }

            // Process all dates in parallel using TaskGroup
            await withTaskGroup(of: (Date, Set<String>)?.self) { group in
                for date in dates {
                    group.addTask {
                        do {
                            let (breakfast, lunch, dinner, snacks) = try await self.diaryDataManager.getFoodDataAsync(for: date)
                            let allFoods = breakfast + lunch + dinner + snacks

                            guard !allFoods.isEmpty else { return nil }

                            var nutrientsPresent: Set<String> = []

                            // Process all foods for this date
                            for food in allFoods {
                                if let micronutrients = food.micronutrientProfile {
                                    // Process vitamins
                                    for (vitaminKey, amount) in micronutrients.vitamins where amount > 0 {
                                        let nutrientId = self.mapVitaminKey(vitaminKey)
                                        if !nutrientId.isEmpty {
                                            nutrientsPresent.insert(nutrientId)
                                        }
                                    }

                                    // Process minerals
                                    for (mineralKey, amount) in micronutrients.minerals where amount > 0 {
                                        let nutrientId = self.mapMineralKey(mineralKey)
                                        if !nutrientId.isEmpty {
                                            nutrientsPresent.insert(nutrientId)
                                        }
                                    }
                                }
                            }

                            return nutrientsPresent.isEmpty ? nil : (date, nutrientsPresent)
                        } catch {
                            return nil
                        }
                    }
                }

                // Collect all results and update tracking manager
                for await result in group {
                    if let (date, nutrientsPresent) = result {
                        totalNutrientsTracked += nutrientsPresent.count
                        await trackingManager.updateNutrientsForDate(date: date, nutrients: Array(nutrientsPresent))
                    }
                }
            }

            await MainActor.run {
                trackingManager.objectWillChange.send()
                #if DEBUG
                print("✅ Processed diary: \(totalNutrientsTracked) unique nutrient occurrences tracked")
                #endif
            }
        }
    }

    private func formatDateId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func mapVitaminKey(_ key: String) -> String {
        let mapping: [String: String] = [
            "vitaminA": "vitamin_a",
            "vitaminC": "vitamin_c",
            "vitaminD": "vitamin_d",
            "vitaminE": "vitamin_e",
            "vitaminK": "vitamin_k",
            "thiamine": "vitamin_b1",
            "riboflavin": "vitamin_b2",
            "niacin": "vitamin_b3",
            "vitaminB6": "vitamin_b6",
            "vitaminB12": "vitamin_b12",
            "folate": "folate",
            "biotin": "biotin"
        ]
        return mapping[key] ?? ""
    }

    private func mapMineralKey(_ key: String) -> String {
        let mapping: [String: String] = [
            "calcium": "calcium",
            "iron": "iron",
            "magnesium": "magnesium",
            "phosphorus": "phosphorus",
            "potassium": "potassium",
            "zinc": "zinc",
            "selenium": "selenium",
            "copper": "copper",
            "manganese": "manganese",
            "iodine": "iodine"
        ]
        return mapping[key] ?? ""
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
    }
}

struct DormantNutrientRow: View {
    let nutrient: TrackedNutrient
    let frequency: NutrientFrequency?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: nutrient.icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(nutrient.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                if let freq = frequency, let lastSeen = freq.lastAppearance {
                    Text("Last seen \(daysAgo(from: lastSeen))")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else {
                    Text("Never tracked")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func daysAgo(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 {
            return "today"
        } else if days == 1 {
            return "yesterday"
        } else {
            return "\(days) days ago"
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        NavigationView {
            NutrientActivityDashboard()
        }
    }
}
