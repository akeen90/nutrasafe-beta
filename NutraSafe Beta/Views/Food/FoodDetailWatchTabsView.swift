//
//  FoodDetailWatchTabsView.swift
//  NutraSafe Beta
//
//  Extracted from FoodDetailViewFromSearch.swift to reduce type complexity
//  and prevent stack overflow in SwiftUI's type resolution.
//
//  Uses @ViewBuilder closures to break the deep type chain that was causing
//  Swift's type resolver to overflow the stack.
//

import SwiftUI

// MARK: - Watch Tabs View (Pill Style)

struct FoodDetailWatchTabsView<AdditivesContent: View, AllergensContent: View, VitaminsContent: View>: View {
    @Binding var selectedTab: FoodDetailViewFromSearch.WatchTab
    let palette: AppPalette

    @ViewBuilder let additivesContent: () -> AdditivesContent
    @ViewBuilder let allergensContent: () -> AllergensContent
    @ViewBuilder let vitaminsContent: () -> VitaminsContent

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Tab pills
            tabPills

            // Tab content
            Group {
                switch selectedTab {
                case .additives:
                    additivesContent()
                case .allergies:
                    allergensContent()
                case .vitamins:
                    vitaminsContent()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                .shadow(
                    color: DesignTokens.Shadow.subtle.color,
                    radius: DesignTokens.Shadow.subtle.radius,
                    y: DesignTokens.Shadow.subtle.y
                )
        )
    }

    // MARK: - Tab Pills

    private var tabPills: some View {
        HStack(spacing: 8) {
            ForEach(FoodDetailViewFromSearch.WatchTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.shortName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(isSelected ? .white : palette.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? tab.color : palette.tertiary.opacity(0.1))
                    )
                }
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - Vitamins Content View

struct FoodDetailVitaminsContent: View {
    let hasAccess: Bool
    let detectedNutrients: [String]
    let palette: AppPalette

    @Binding var showingCitations: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasAccess {
                if !detectedNutrients.isEmpty {
                    nutrientList
                    citationsButton
                } else {
                    noDataView
                }
            } else {
                lockedView
            }
        }
    }

    // MARK: - Nutrient List

    private var nutrientList: some View {
        ForEach(Array(detectedNutrients.prefix(8)), id: \.self) { nutrientName in
            HStack {
                Text(nutrientName)
                    .font(.system(size: 14))
                    .foregroundColor(palette.textPrimary)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(SemanticColors.nutrient)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Citations Button

    private var citationsButton: some View {
        Button(action: { showingCitations = true }) {
            HStack {
                Image(systemName: "book.closed")
                    .font(.system(size: 12))
                Text("View sources")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(palette.accent)
        }
        .padding(.top, 8)
    }

    // MARK: - No Data View

    private var noDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flask")
                .font(.system(size: 28))
                .foregroundColor(palette.textTertiary)
            Text("No vitamin data available")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.textSecondary)
            Text("This food doesn't have detailed vitamin information")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Locked View

    private var lockedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundColor(palette.textTertiary)
            Text("Unlock vitamin details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(palette.textSecondary)
            Text("Subscribe to view detailed vitamin and mineral information")
                .font(.system(size: 13))
                .foregroundColor(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }
}
