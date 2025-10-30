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

    /// Adaptive background that switches between white and midnight blue
    static var adaptiveBackground: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1.0)
                : UIColor.systemBackground
        })
    }

    /// Adaptive card background
    static var adaptiveCard: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.18, blue: 0.28, alpha: 1.0)
                : UIColor.secondarySystemGroupedBackground
        })
    }

    /// Adaptive secondary card background
    static var adaptiveCardSecondary: Color {
        Color(uiColor: .init { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 1.0)
                : UIColor.tertiarySystemGroupedBackground
        })
    }
    
    // MARK: - Hex Color Initializer
    
    /// Initialize a Color from a hex string (e.g., "#FF6B6B", "FFA93A")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
