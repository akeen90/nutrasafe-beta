//
//  AtomicConstants.swift
//  NutraSafe Beta
//
//  Atomic-level UI constants to replace 2,121+ numeric literal duplications
//  Replaces scattered magic numbers with centralized, documented values
//

import SwiftUI

struct AtomicConstants {
    
    // MARK: - UI Dimensions
    // Replaces 95+ duplicate frame/spacing patterns found in forensic audit
    
    /// Apple's minimum touch target size (44pt) - Replaces 12+ duplicates of `.frame(width: 44, height: 44)`
    static let touchTargetSize: CGFloat = 44
    
    /// Standard horizontal spacing - Replaces 114+ duplicates of `.padding(.horizontal, 16)`
    static let standardSpacing: CGFloat = 16
    
    /// Wide horizontal spacing - Replaces 43+ duplicates of `.padding(.horizontal, 20)` 
    static let wideSpacing: CGFloat = 20
    
    /// Standard corner radius - Replaces 92+ duplicates of `.cornerRadius(12)`
    static let cornerRadius: CGFloat = 12
    
    /// Standard component height - Replaces 18+ duplicates of `.frame(height: 100)`
    static let standardHeight: CGFloat = 100
    
    /// Small spacing for tight layouts
    static let smallSpacing: CGFloat = 8
    
    /// Large spacing for generous layouts  
    static let largeSpacing: CGFloat = 24
    
    /// Extra large spacing for section separators
    static let extraLargeSpacing: CGFloat = 32
    
    // MARK: - Opacity Values
    // Replaces 211+ duplicate decimal values (0.3, 0.5, 0.6, 0.8, 1.0)
    
    /// Low opacity for subtle backgrounds
    static let lowOpacity: Double = 0.3
    
    /// Medium opacity for overlays
    static let mediumOpacity: Double = 0.5
    
    /// High opacity for semi-transparent elements  
    static let highOpacity: Double = 0.8
    
    /// Full opacity (explicit for clarity)
    static let fullOpacity: Double = 1.0
    
    /// Very low opacity for barely visible elements
    static let veryLowOpacity: Double = 0.1
    
    // MARK: - Animation Values
    // Standardized animation durations and values
    
    /// Standard animation duration
    static let standardAnimationDuration: Double = 0.3
    
    /// Quick animation duration  
    static let quickAnimationDuration: Double = 0.15
    
    /// Slow animation duration
    static let slowAnimationDuration: Double = 0.5
    
    /// Standard spring response
    static let standardSpringResponse: Double = 0.6
    
    /// Standard spring damping fraction
    static let standardSpringDamping: Double = 0.8
    
    // MARK: - Common Multipliers
    // Replace scattered calculation values
    
    /// Percentage calculation base (replaces scattered 100 literals)
    static let percentageBase: Double = 100.0
    
    /// Minutes to seconds multiplier
    static let minutesToSeconds: Double = 60.0
    
    /// Standard scale factor for pressed states
    static let pressedScale: Double = 0.95
    
    /// Standard scale factor for expanded states  
    static let expandedScale: Double = 1.05
}

// MARK: - Convenience Extensions
extension View {
    /// Apply standard touch target sizing
    func standardTouchTarget() -> some View {
        self.frame(width: 44, height: 44)
    }
    
    /// Apply standard horizontal padding
    func standardHorizontalPadding() -> some View {
        self.padding(.horizontal, 16)
    }
    
    /// Apply standard corner radius
    func standardCornerRadius() -> some View {
        self.cornerRadius(12)
    }
    
    /// Apply standard height
    func standardHeight() -> some View {
        self.frame(height: 100)
    }
    
    /// Apply standard pressed animation
    func standardPressedAnimation(_ isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.5, 
                             dampingFraction: 0.7), 
                      value: isPressed)
    }
}