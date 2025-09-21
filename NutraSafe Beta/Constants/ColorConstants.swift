//
//  ColorConstants.swift  
//  NutraSafe Beta
//
//  Centralized color constants to replace 15+ duplicate hex color definitions
//  Consolidates scattered Color(hex: "#...") calls into semantic, reusable constants
//

import SwiftUI

struct ColorConstants {
    
    // MARK: - Nutrition & Health Colors
    // Replaces duplicate hex codes found throughout the app
    
    /// Healthy green for positive nutrition indicators - Replaces Color(hex: "#4CAF50")  
    static let healthyGreen = Color(hex: "#4CAF50")
    
    /// Protein blue for protein-related UI - Replaces Color(hex: "#2196F3")
    static let proteinBlue = Color(hex: "#2196F3")
    
    /// Carbs orange for carbohydrate indicators - Replaces Color(hex: "#FF9800")
    static let carbsOrange = Color(hex: "#FF9800")
    
    /// Fat purple for fat-related nutrition - Replaces Color(hex: "#9C27B0")
    static let fatPurple = Color(hex: "#9C27B0")
    
    /// Danger red for warnings and errors - Replaces Color(hex: "#F44336")
    static let dangerRed = Color(hex: "#F44336")
    
    // MARK: - Meal Type Colors
    // Semantic colors for different meal categories
    
    /// Breakfast orange
    static let breakfastOrange = Color(hex: "#FF9800")
    
    /// Lunch amber  
    static let lunchAmber = Color(hex: "#FFC107")
    
    /// Dinner indigo
    static let dinnerIndigo = Color(hex: "#3F51B5")
    
    /// Snacks purple
    static let snacksPurple = Color(hex: "#9C27B0")
    
    // MARK: - Grade/Quality Colors
    // Colors for nutrition scoring and quality indicators
    
    /// Excellent quality (A+ grade)
    static let excellentGreen = Color(hex: "#4CAF50")
    
    /// Good quality (B grade)
    static let goodLightGreen = Color(hex: "#8BC34A")
    
    /// Moderate quality (C grade)
    static let moderateOrange = Color(hex: "#FF9800")
    
    /// Poor quality (D/F grade)
    static let poorRed = Color(hex: "#F44336")
    
    // MARK: - UI State Colors
    // Common interface state colors
    
    /// Primary action blue
    static let primaryBlue = Color(hex: "#2196F3")
    
    /// Secondary gray
    static let secondaryGray = Color(hex: "#757575")
    
    /// Success green  
    static let successGreen = Color(hex: "#4CAF50")
    
    /// Warning orange
    static let warningOrange = Color(hex: "#FF9800")
    
    /// Error red
    static let errorRed = Color(hex: "#F44336")
    
    // MARK: - Background Colors
    // Consistent background variations
    
    /// Light background gray
    static let lightBackground = Color(hex: "#F5F5F5")
    
    /// Card background (system gray 6 equivalent)
    static let cardBackground = Color(.systemGray6)
    
    /// Subtle separator gray
    static let separatorGray = Color(hex: "#E0E0E0")
}

// MARK: - Color Extension for Hex Support
extension Color {
    /// Initialize Color from hex string (supports #RRGGBB format)
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Convenience Extensions
extension Color {
    /// Get nutrition grade color based on score
    static func nutritionGradeColor(for score: Int) -> Color {
        switch score {
        case 90...100:
            return .green
        case 80..<90:
            return .green
        case 60..<80:
            return .orange
        default:
            return .red
        }
    }
    
    /// Get meal type color
    static func mealTypeColor(for mealType: String) -> Color {
        switch mealType.lowercased() {
        case "breakfast":
            return .orange
        case "lunch":
            return .yellow
        case "dinner":
            return .indigo
        case "snacks":
            return .purple
        default:
            return .gray
        }
    }
}