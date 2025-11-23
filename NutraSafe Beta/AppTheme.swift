//
//  AppTheme.swift
//  NutraSafe Beta
//
//  Global app theming for midnight blue dark mode
//

import SwiftUI
import UIKit

// MARK: - Custom Midnight Blue Theme

extension Color {
    /// Midnight blue background - trading platform style (lighter more visible blue)
    static var midnightBackground: Color {
        Color(red: 0.10, green: 0.14, blue: 0.24) // #192338 - slightly lighter
    }

    /// Slightly lighter midnight blue for cards
    static var midnightCard: Color {
        Color(red: 0.14, green: 0.18, blue: 0.28) // #242D47 - lighter
    }

    /// Even lighter for secondary cards
    static var midnightCardSecondary: Color {
        Color(red: 0.18, green: 0.22, blue: 0.32) // #2E3851 - lighter
    }

    /// Adaptive background that switches between light blue and midnight blue
    static var adaptiveBackground: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1.0)
                : UIColor(red: 0.82, green: 0.95, blue: 0.99, alpha: 1.0) // #D0F2FD
        })
    }

    /// Adaptive card background
    static var adaptiveCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.18, blue: 0.28, alpha: 1.0)
                : UIColor.white
        })
    }

    /// Adaptive secondary card background
    static var adaptiveCardSecondary: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1.0)
                : UIColor.white
        })
    }
}

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
                        colors: [Color.blue.opacity(0.08), Color.clear],
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
            }
        }
        .ignoresSafeArea()
    }
}
