//
//  AppTheme.swift
//  NutraSafe Beta
//
//  Global app theming for midnight blue dark mode
//

import SwiftUI
import UIKit

// MARK: - Custom Midnight Blue Theme
// All Color extensions (midnightBackground, midnightCard, midnightCardSecondary,
// adaptiveBackground, adaptiveCard) are defined in AppDesignSystem.swift

struct AppBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        Group {
            if colorScheme == .dark {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.midnightBackground,
                            Color.midnightCardSecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [AppPalette.standard.accent.opacity(0.08), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 260
                    )
                    RadialGradient(
                        colors: [Color.purple.opacity(0.06), Color.clear],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 240
                    )
                }
            } else {
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
                        colors: [AppPalette.standard.accent.opacity(0.10), Color.clear],
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
            }
        }
        .ignoresSafeArea()
    }
}
