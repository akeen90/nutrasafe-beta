//
//  UseByQuickAddRedesigned.swift
//  NutraSafe Beta
//
//  Redesigned Quick Add card for Use By tab
//  Design philosophy: Emotion-first, calm, trust-building, minimal friction
//

import SwiftUI
import UIKit

// MARK: - Premium Quick Add Card

struct UseByQuickAddCardRedesigned: View {
    @Binding var showingScanner: Bool
    @Binding var showingCamera: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingAddSheet = false
    @State private var selectedFoodForUseBy: FoodSearchResult?

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

    var body: some View {
        VStack(spacing: 0) {
            // Emotional header
            VStack(alignment: .leading, spacing: 6) {
                Text("Track what you have")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(appPalette.textPrimary)

                Text("Never waste. Always know.")
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.2)
                    .foregroundColor(appPalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            // Action buttons
            HStack(spacing: 12) {
                // Quick scan button
                quickActionButton(
                    icon: "barcode.viewfinder",
                    label: "Scan",
                    color: palette.accent,
                    isPrimary: false
                ) {
                    showingScanner = true
                }

                // Primary add button
                quickActionButton(
                    icon: "plus.circle.fill",
                    label: "Add Item",
                    color: palette.accent,
                    isPrimary: true
                ) {
                    showingAddSheet = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground) : .white,
                            colorScheme == .dark ? Color(UIColor.secondarySystemGroupedBackground).opacity(0.95) : .white.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(0.12),
                            palette.accent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .fullScreenCover(isPresented: $showingAddSheet) {
            AddUseByItemSheetRedesigned(onComplete: {
                showingAddSheet = false
            })
        }
    }

    // MARK: - Quick Action Button

    private func quickActionButton(
        icon: String,
        label: String,
        color: Color,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isPrimary ? 18 : 16, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(0.2)
            }
            .foregroundColor(isPrimary ? .white : color)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isPrimary ?
                        LinearGradient(
                            colors: [color, color.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.12), color.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isPrimary ? Color.clear : color.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isPrimary ? color.opacity(0.3) : .clear,
                radius: isPrimary ? 8 : 0,
                x: 0,
                y: isPrimary ? 4 : 0
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct UseByQuickAddCardRedesigned_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UseByQuickAddCardRedesigned(
                showingScanner: .constant(false),
                showingCamera: .constant(false)
            )
            .padding()

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)

        VStack {
            UseByQuickAddCardRedesigned(
                showingScanner: .constant(false),
                showingCamera: .constant(false)
            )
            .padding()

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.dark)
    }
}
#endif
