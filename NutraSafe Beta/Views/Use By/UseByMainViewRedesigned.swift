//
//  UseByMainViewRedesigned.swift
//  NutraSafe Beta
//
//  Premium emotion-first redesign of Use By Tracker
//  Follows onboarding design philosophy: warm, clear, trust-building
//

import SwiftUI

// MARK: - Main Use By View (Redesigned)

struct UseByMainViewRedesigned: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var dataManager = UseByDataManager.shared
    @Binding var selectedTab: TabItem

    // User intent palette
    private var palette: OnboardingPalette {
        let savedIntent = UserDefaults.standard.string(forKey: "userIntent")
        let intent = UserIntent(rawValue: savedIntent ?? "safer")
        return OnboardingPalette.forIntent(intent)
    }

    // Text colors based on color scheme
    private var textPrimary: Color {
        colorScheme == .dark ? Color.white : Color.black
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }

    private var textTertiary: Color {
        colorScheme == .dark ? Color.white.opacity(0.5) : Color.black.opacity(0.4)
    }

    // Search state
    @State private var searchQuery = ""
    @State private var searchResults: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var showingFoodDetail: FoodSearchResult?
    @FocusState private var isSearchFocused: Bool

    // Scanner state
    @State private var showingBarcodeScanner = false

    // MARK: - Computed Stats

    private var sortedItems: [UseByInventoryItem] {
        dataManager.items.sorted { $0.expiryDate < $1.expiryDate }
    }

    private var urgentItems: [UseByInventoryItem] {
        sortedItems.filter { $0.daysUntilExpiry <= 2 }
    }

    private var thisWeekItems: [UseByInventoryItem] {
        sortedItems.filter { (3...7).contains($0.daysUntilExpiry) }
    }

    // MARK: - Hero Search Bar (Premium Design)

    private var heroSearchBar: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Warm headline with serif
            VStack(alignment: .leading, spacing: 6) {
                Text("Track what you have")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [textPrimary, textPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Never waste food. Know what needs eating soon.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textSecondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 24)

            // Premium search field with glassmorphic effect
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        isSearchFocused ? palette.accent : textTertiary
                    )

                TextField("Search to add...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(textPrimary)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchQuery) { _, newValue in
                        performSearch(query: newValue)
                    }

                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(textTertiary)
                    }
                }

                Divider()
                    .frame(height: 24)
                    .background(palette.tertiary.opacity(0.3))

                Button(action: { showingBarcodeScanner = true }) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSearchFocused
                                    ? palette.accent.opacity(0.5)
                                    : palette.tertiary.opacity(0.2),
                                lineWidth: isSearchFocused ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSearchFocused
                            ? palette.accent.opacity(0.15)
                            : .black.opacity(0.04),
                        radius: isSearchFocused ? 20 : 10,
                        y: isSearchFocused ? 8 : 4
                    )
            )
            .scaleEffect(isSearchFocused ? 1.01 : 1.0)
            .animation(.smooth(duration: 0.3), value: isSearchFocused)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Insight Cards (Emotional Context, Not Data Dump)

    private var insightCards: some View {
        HStack(spacing: 12) {
            // Total items - clean stat
            UseByInsightCard(
                value: "\(sortedItems.count)",
                label: sortedItems.count == 1 ? "item" : "items",
                icon: "refrigerator.fill",
                gradient: [palette.accent, palette.accent.opacity(0.7)]
            )

            // Urgent/this week - adaptive messaging
            if !urgentItems.isEmpty {
                UseByInsightCard(
                    value: "\(urgentItems.count)",
                    label: urgentItems.count == 1 ? "needs using" : "need using",
                    icon: "exclamationmark.triangle.fill",
                    gradient: [.red, .orange],
                    subtitle: "Use today"
                )
            } else if !thisWeekItems.isEmpty {
                UseByInsightCard(
                    value: "\(thisWeekItems.count)",
                    label: "this week",
                    icon: "clock.fill",
                    gradient: [.orange, .yellow],
                    subtitle: "Plan ahead"
                )
            } else if !sortedItems.isEmpty {
                UseByInsightCard(
                    value: "✓",
                    label: "all good",
                    icon: "checkmark.circle.fill",
                    gradient: [.green, .mint],
                    subtitle: "Nothing urgent"
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Items List (Clean, Minimal)

    private var itemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with serif
            HStack(alignment: .bottom) {
                Text("Your Items")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundColor(textPrimary)

                Spacer()

                // Subtle count badge
                if !sortedItems.isEmpty {
                    Text("\(sortedItems.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(palette.accent.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, 24)

            // Items or empty state
            if sortedItems.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(sortedItems, id: \.id) { item in
                        PremiumUseByItemRow(
                            item: item,
                            palette: palette,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textTertiary: textTertiary
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Empty State (Encouraging, Not Clinical)

    private var emptyState: some View {
        VStack(spacing: 20) {
            // Friendly icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.accent.opacity(0.1), palette.accent.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "refrigerator.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [palette.accent, palette.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            VStack(spacing: 8) {
                Text("Your fresh start")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(textPrimary)

                Text("Search above to add items and track\nwhat needs eating soon")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            // Subtle hint chip
            HStack(spacing: 6) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                Text("Search or scan to start")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(palette.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(palette.accent.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(palette.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search Results Overlay

    @ViewBuilder
    private var searchResultsOverlay: some View {
        if isSearchFocused && searchQuery.count >= 2 {
            VStack(spacing: 0) {
                // Subtle divider
                Rectangle()
                    .fill(palette.tertiary.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                if isSearching {
                    // Loading state
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(palette.accent)
                        Text("Searching...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else if searchResults.isEmpty {
                    // No results
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(textTertiary.opacity(0.5))

                        Text("No foods found")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textSecondary)

                        Text("Try a different search term")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    // Results list (max 6 results)
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults.prefix(6), id: \.id) { food in
                            Button {
                                showingFoodDetail = food
                                isSearchFocused = false
                            } label: {
                                SearchResultRow(
                                    food: food,
                                    palette: palette,
                                    textPrimary: textPrimary,
                                    textTertiary: textTertiary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(palette.tertiary.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient (user-adaptive)
            LinearGradient(
                colors: [
                    palette.background,
                    palette.background.opacity(0.95),
                    colorScheme == .dark ? Color.black : Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 24) {
                    // Hero search
                    heroSearchBar
                        .padding(.top, 8)

                    // Insight cards (only if items exist)
                    if !sortedItems.isEmpty {
                        insightCards
                    }

                    // Items list
                    itemsList
                }
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)

            // Search results overlay (appears above scroll content)
            if isSearchFocused && searchQuery.count >= 2 {
                VStack(spacing: 0) {
                    // Spacer for search bar
                    Color.clear
                        .frame(height: 140)

                    searchResultsOverlay

                    Spacer()
                }
            }
        }
        .animation(.smooth(duration: 0.3), value: isSearchFocused)
        .animation(.smooth(duration: 0.3), value: searchResults.count)
        .fullScreenCover(item: $showingFoodDetail) { food in
            UseByFoodDetailSheetRedesigned(
                food: food,
                onComplete: {
                    showingFoodDetail = nil
                    searchQuery = ""
                    searchResults = []
                }
            )
        }
        .id(showingFoodDetail?.id ?? "use-by-main") // Stable identity prevents dismissal on network issues
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            UseByBarcodeScannerSheet(
                onFoodFound: { food in
                    showingBarcodeScanner = false
                    showingFoodDetail = food
                },
                onCancel: {
                    showingBarcodeScanner = false
                }
            )
        }
        .onAppear {
            Task {
                if !dataManager.isLoaded {
                    await dataManager.loadItems()
                }
            }
        }
    }

    // MARK: - Search Logic

    private func performSearch(query: String) {
        guard query.count >= 2 else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            do {
                // Use existing search manager
                let manager = AlgoliaSearchManager.shared
                let results = try await manager.search(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

// MARK: - Insight Card (Clean Stat Display)

private struct UseByInsightCard: View {
    let value: String
    let label: String
    let icon: String
    let gradient: [Color]
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [gradient[0].opacity(0.15), gradient[1].opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Spacer()

            // Value and label
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.2), gradient[1].opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: gradient[0].opacity(0.1), radius: 15, y: 8)
    }
}

// MARK: - Premium Use By Row (Clean Item Card)

private struct PremiumUseByItemRow: View {
    let item: UseByInventoryItem
    let palette: OnboardingPalette
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    @State private var showingDetail = false

    private var freshnessColor: Color {
        let days = item.daysUntilExpiry
        if days <= 0 { return .red }
        if days <= 2 { return .orange }
        if days <= 7 { return .yellow }
        return .green
    }

    private var freshnessText: String {
        let days = item.daysUntilExpiry
        if days < 0 { return "Expired" }
        if days == 0 { return "Use today" }
        if days == 1 { return "1 day left" }
        if days <= 2 { return "Use very soon" }
        if days <= 7 { return "\(days) days left" }
        return "Plenty of time"
    }

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 14) {
                // Food icon placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [palette.accent.opacity(0.15), palette.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(palette.accent.opacity(0.6))
                    )

                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)

                    // Freshness indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(freshnessColor)
                            .frame(width: 8, height: 8)

                        Text(freshnessText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textSecondary)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(palette.tertiary.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(UseByScaleButtonStyle())
        .fullScreenCover(isPresented: $showingDetail) {
            // Detail view for editing/deleting item
            UseByDetailSheet(item: item)
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let food: FoodSearchResult
    let palette: OnboardingPalette
    let textPrimary: Color
    let textTertiary: Color

    var body: some View {
        HStack(spacing: 12) {
            // Food icon or image
            Circle()
                .fill(palette.accent.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(palette.accent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)

                if let brand = food.brand {
                    Text(brand)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [palette.accent, palette.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Scale Button Style

private struct UseByScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Use By Item Detail View (Placeholder)

private struct UseByDetailSheet: View {
    let item: UseByInventoryItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Item Detail")
                Text(item.name)
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}
