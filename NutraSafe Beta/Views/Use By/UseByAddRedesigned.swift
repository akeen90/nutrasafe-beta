//
//  UseByAddRedesigned.swift
//  NutraSafe Beta
//
//  Redesigned "Add to Use By" screen matching premium onboarding aesthetic
//  Design philosophy: Emotion-first, calm, trust-building, minimal friction
//

import SwiftUI
import UIKit

// MARK: - Premium Add to Use By Screen

struct AddUseByItemSheetRedesigned: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var onComplete: (() -> Void)? = nil

    @State private var selectedMethod: AddMethod? = nil
    @State private var showingHelp = false
    @State private var showingSearch = false
    @State private var showingManual = false
    @State private var showingBarcode = false

    // User intent from onboarding (determines color palette)
    @AppStorage("userIntent") private var userIntentRaw: String = "safer"
    private var userIntent: UserIntent {
        UserIntent(rawValue: userIntentRaw) ?? .safer
    }

    private var palette: OnboardingPalette {
        OnboardingPalette.forIntent(userIntent)
    }

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    enum AddMethod: String, CaseIterable {
        case search = "Search"
        case manual = "Manual entry"
        case barcode = "Scan barcode"

        var icon: String {
            switch self {
            case .search: return "magnifyingglass.circle.fill"
            case .manual: return "square.and.pencil.circle.fill"
            case .barcode: return "barcode.viewfinder"
            }
        }

        var subtitle: String {
            switch self {
            case .search: return "Find products in our database"
            case .manual: return "Track anything you want"
            case .barcode: return "Quick and accurate"
            }
        }

        var color: Color {
            switch self {
            case .search: return .blue
            case .manual: return .purple
            case .barcode: return .green
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                adaptiveBackground

                VStack(spacing: 0) {
                    // Emotional header
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 28)

                    // Method selector cards
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(AddMethod.allCases, id: \.self) { method in
                                methodCard(method)
                                    .onTapGesture {
                                        selectMethod(method)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(appPalette.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSearch) {
                UseBySearchFlowRedesigned(onComplete: onComplete)
            }
            .fullScreenCover(isPresented: $showingManual) {
                UseByManualEntryRedesigned(onComplete: {
                    dismiss()
                    onComplete?()
                })
            }
            .fullScreenCover(isPresented: $showingBarcode) {
                UseByBarcodeScanRedesigned(onComplete: onComplete)
            }
        }
    }

    // MARK: - Method Selection

    private func selectMethod(_ method: AddMethod) {
        switch method {
        case .search:
            showingSearch = true
        case .manual:
            showingManual = true
        case .barcode:
            showingBarcode = true
        }
    }

    // MARK: - Adaptive Background

    private var adaptiveBackground: some View {
        LinearGradient(
            colors: [
                palette.background,
                palette.background.opacity(0.95),
                Color(UIColor.systemGroupedBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title - serif, editorial
            Text("Track what you have")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .tracking(-0.5)
                .foregroundColor(appPalette.textPrimary)

            // Emotional subtitle
            Text("Never waste food. Know what needs eating soon.")
                .font(.system(size: 17, weight: .regular))
                .tracking(0.2)
                .lineSpacing(6)
                .foregroundColor(appPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Method Card

    private func methodCard(_ method: AddMethod) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    method.color.opacity(0.85),
                                    method.color.opacity(0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: method.color.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                    Image(systemName: method.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(method.rawValue)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(appPalette.textPrimary)

                    Text(method.subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(appPalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(appPalette.textTertiary)
            }
            .padding(20)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .white)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            method.color.opacity(0.15),
                            method.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

}

// MARK: - Search Flow Redesigned

struct UseBySearchFlowRedesigned: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var onComplete: (() -> Void)? = nil

    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [FoodSearchResult] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var selectedFood: FoodSearchResult?
    @State private var showingFoodDetail = false

    @AppStorage("userIntent") private var userIntentRaw: String = "safer"
    private var userIntent: UserIntent {
        UserIntent(rawValue: userIntentRaw) ?? .safer
    }

    private var palette: OnboardingPalette {
        OnboardingPalette.forIntent(userIntent)
    }

    private var appPalette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Adaptive background
                LinearGradient(
                    colors: [
                        palette.background,
                        Color(UIColor.systemGroupedBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    // Content
                    if isSearching {
                        loadingView
                    } else if results.isEmpty && !query.isEmpty {
                        emptyResultsView
                    } else if results.isEmpty {
                        emptyStateView
                    } else {
                        resultsListView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(appPalette.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFoodDetail) {
                if let food = selectedFood {
                    UseByFoodDetailSheetRedesigned(food: food, onComplete: {
                        dismiss()
                        onComplete?()
                    })
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(appPalette.textTertiary)

            // Text field
            TextField("Search for a product...", text: $query)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .onChange(of: query) { _, newValue in
                    performSearch(newValue)
                }

            // Clear button
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(appPalette.textTertiary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(UIColor.tertiarySystemGroupedBackground) : Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(palette.accent.opacity(query.isEmpty ? 0 : 0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: palette.accent))
                .scaleEffect(1.2)

            Text("Searching...")
                .font(.system(size: 15, design: .serif))
                .foregroundColor(appPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            palette.tertiary.opacity(0.3),
                            palette.tertiary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundColor(palette.tertiary)
                )

            Text("Start typing to search")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(appPalette.textPrimary)

            Text("Find products from our database\nto track their expiry dates")
                .font(.system(size: 15))
                .foregroundColor(appPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: 18) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.orange.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "questionmark")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.orange)
                )

            Text("No matches found")
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundColor(appPalette.textPrimary)

            Text("Try a different search term,\nor add it manually instead")
                .font(.system(size: 15))
                .foregroundColor(appPalette.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Results List

    private var resultsListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(results, id: \.id) { food in
                    Button {
                        selectedFood = food
                        showingFoodDetail = true
                    } label: {
                        resultRow(food)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if food.id != results.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func resultRow(_ food: FoodSearchResult) -> some View {
        HStack(spacing: 16) {
            // Product placeholder icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.2),
                            palette.accent.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "cart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(palette.accent)
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(food.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(appPalette.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 14))
                        .foregroundColor(appPalette.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(appPalette.textTertiary)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Search Logic

    private func performSearch(_ searchText: String) {
        searchTask?.cancel()

        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await runSearch(trimmed)
        }
    }

    @MainActor
    private func runSearch(_ trimmed: String) async {
        guard trimmed.count >= 2 else { return }
        isSearching = true

        do {
            let foods = try await FirebaseManager.shared.searchFoods(query: trimmed)
            self.results = foods
            self.isSearching = false
        } catch {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == -999 {
                return // Cancelled
            }
            self.isSearching = false
        }
    }
}

// MARK: - Manual Entry Redesigned

struct UseByManualEntryRedesigned: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: (() -> Void)? = nil

    var body: some View {
        UseByFoodDetailSheetRedesigned(onComplete: {
            dismiss()
            onComplete?()
        })
    }
}

// MARK: - Barcode Scan Redesigned

struct UseByBarcodeScanRedesigned: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            UseByBarcodeScanSheet()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Close")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct AddUseByItemSheetRedesigned_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddUseByItemSheetRedesigned()
                .preferredColorScheme(.light)

            AddUseByItemSheetRedesigned()
                .preferredColorScheme(.dark)

            UseBySearchFlowRedesigned()
                .preferredColorScheme(.light)
        }
    }
}
#endif
