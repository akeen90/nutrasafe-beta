import SwiftUI

// MARK: - App Design Constants
// Minimal constants extracted from deleted DesignSystem.swift

enum AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
}

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
}

// MARK: - App Colors
enum AppColors {
    static let cardBackgroundInteractive = Color(.systemGray6)
    static let cardBackgroundElevated = Color(.systemGray5)
    static let borderLight = Color(.separator)
    static let border = Color(.separator)
    static let primary = Color.accentColor
}

// MARK: - App Typography
enum AppTypography {
    static func largeTitle() -> Font {
        .largeTitle
    }

    static func title3(weight: Font.Weight = .regular) -> Font {
        .title3.weight(weight)
    }

    static func caption2(weight: Font.Weight = .regular) -> Font {
        .caption2.weight(weight)
    }
}

// MARK: - App Animation
enum AppAnimation {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let quick = Animation.easeInOut(duration: 0.2)
}

// MARK: - Color Hex Extension
extension Color {
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Card Shadow Modifier
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
