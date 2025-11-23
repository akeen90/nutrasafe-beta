import SwiftUI
import UIKit

// MARK: - Design System
// A comprehensive design system for NutraSafe Beta with modern UI patterns

// MARK: - Typography System
extension Font {
    // Primary Typography Scale
    static let appLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let appTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let appTitle2 = Font.system(size: 22, weight: .bold, design: .default)
    static let appTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    static let appHeadline = Font.system(size: 17, weight: .semibold, design: .default)
    static let appBody = Font.system(size: 17, weight: .regular, design: .default)
    static let appCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let appSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let appFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let appCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let appCaption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // Nutrition-specific Typography
    static let nutritionValue = Font.system(size: 20, weight: .bold, design: .rounded)
    static let nutritionLabel = Font.system(size: 14, weight: .medium, design: .default)
    static let calorieDisplay = Font.system(size: 32, weight: .bold, design: .rounded)
    static let macroValue = Font.system(size: 16, weight: .semibold, design: .rounded)
    
    // Dynamic Type Support
    static func scaledFont(_ font: Font, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        return font
    }
}

// MARK: - Colour System
extension Color {
    // Brand Colours (matching app logo gradient - brightened for headers)
    static let brandOrangeLight = Color(red: 0.95, green: 0.68, blue: 0.38) // Brighter golden orange
    static let brandOrangeDark = Color(red: 0.85, green: 0.55, blue: 0.35)  // Brighter bronze
    static let brandOrange = Color(red: 0.90, green: 0.62, blue: 0.37)      // Mid-tone blend

    // Legacy color references (kept for backward compatibility)
    static let primaryBlue = Color(red: 0.2, green: 0.4, blue: 0.8)
    static let primaryGreen = Color(red: 0.3, green: 0.7, blue: 0.4)
    static let accentOrange = brandOrange
    
    // Semantic Colours
    static let nutritionGreen = Color(red: 0.3, green: 0.7, blue: 0.4)
    static let safetyBlue = Color(red: 0.2, green: 0.5, blue: 0.8)
    static let warningAmber = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let dangerRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    
    // Background Colours
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)
    static let surfaceElevated = Color(.systemGray6)
    
    // Text Colours
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textQuaternary = Color(.quaternaryLabel)
    
    // Nutrition-specific Colours
    static let proteinColour = Color(.systemRed)
    static let carbsColour = Color(.systemBlue)
    static let fatColour = Color(.systemOrange)
    static let fibreColour = Color(.systemGreen)
    static let sugarColour = Color(.systemPurple)
    
    // Meal Colours (UK spelling)
    static let breakfastColour = Color(.systemOrange)
    static let lunchColour = Color(.systemGreen)
    static let dinnerColour = Color(.systemBlue)
    static let snacksColour = Color(.systemPurple)
    
    // Interactive States
    static let buttonPrimary = Color(.systemBlue)
    static let buttonSecondary = Color(.systemGray2)
    static let buttonDisabled = Color(.systemGray4)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [brandOrangeLight, brandOrangeDark]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        gradient: Gradient(colors: [brandOrangeLight, brandOrangeDark]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nutritionGradient = LinearGradient(
        gradient: Gradient(colors: [nutritionGreen.opacity(0.8), nutritionGreen]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing System
extension CGFloat {
    // Base spacing unit (8pt)
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48
    
    // Component-specific spacing
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    
    // Touch targets
    static let minTouchTarget: CGFloat = 44
    static let buttonHeight: CGFloat = 48
    static let smallButtonHeight: CGFloat = 36
}

// MARK: - Corner Radius System
extension CGFloat {
    static let radiusXS: CGFloat = 4
    static let radiusS: CGFloat = 8
    static let radiusM: CGFloat = 12
    static let radiusL: CGFloat = 16
    static let radiusXL: CGFloat = 24
    static let radiusRound: CGFloat = 50
}

// MARK: - Shadow System
extension View {
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func lightShadow() -> some View {
        self.shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    func buttonShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

 

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: .buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: .radiusM)
                    .fill(isEnabled ? Color.buttonPrimary : Color.buttonDisabled)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .buttonShadow()
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: .buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: .radiusM)
                    .fill(Color.buttonSecondary)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .lightShadow()
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appCallout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, .spacingM)
            .frame(height: .smallButtonHeight)
            .background(
                RoundedRectangle(cornerRadius: .radiusS)
                    .fill(Color.buttonPrimary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .lightShadow()
    }
}

struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.springy, value: configuration.isPressed)
    }
}

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.springy, value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: .buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: .radiusM)
                    .fill(Color.dangerRed)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .buttonShadow()
    }
}

struct IconButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(backgroundColor: Color = .surfaceElevated, foregroundColor: Color = .textSecondary) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appTitle3)
            .foregroundColor(foregroundColor)
            .frame(width: .minTouchTarget, height: .minTouchTarget)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.quick, value: configuration.isPressed)
            .lightShadow()
    }
}

// MARK: - Card Styles
struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: .radiusL)
                    .fill(Color.backgroundPrimary)
            )
            .cardShadow()
    }
}

struct ElevatedCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: .radiusL)
                    .fill(Color.surfaceElevated)
            )
            .cardShadow()
    }
}

extension View {
    func modernCard() -> some View {
        modifier(ModernCardStyle())
    }
    
    func elevatedCard() -> some View {
        modifier(ElevatedCardStyle())
    }
}

// MARK: - Accessibility Support
extension View {
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityRole(.button)
            .accessibilityAddTraits(.isButton)
    }
    
    func accessibleText(_ label: String, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
    }
    
    func nutritionAccessibility(nutrient: String, amount: String, unit: String) -> some View {
        self
            .accessibilityLabel("\(nutrient): \(amount) \(unit)")
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Button Style Convenience Modifiers
extension View {
    func primaryButton(isEnabled: Bool = true) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    func compactButton() -> some View {
        self.buttonStyle(CompactButtonStyle())
    }
    
    func springyButton() -> some View {
        self.buttonStyle(SpringyButtonStyle())
    }
    
    func modernButton() -> some View {
        self.buttonStyle(ModernButtonStyle())
    }
    
    func destructiveButton() -> some View {
        self.buttonStyle(DestructiveButtonStyle())
    }
    
    func iconButton(backgroundColor: Color = .surfaceElevated, foregroundColor: Color = .textSecondary) -> some View {
        self.buttonStyle(IconButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}

// MARK: - Design System Namespaces
struct DesignSystem {
    struct Typography {
        static let bodyLarge = Font.appTitle3
        static let bodyMedium = Font.appHeadline
        static let caption = Font.appCaption
        static let captionMedium = Font.appCaption.weight(.medium)
        static let captionBold = Font.appCaption.weight(.bold)
        static let captionSmall = Font.appCaption2
    }
    
    struct Colors {
        static let primary = Color.buttonPrimary
        static let textPrimary = Color.textPrimary
        static let textSecondary = Color.textSecondary
        static let backgroundPrimary = Color.backgroundPrimary
        static let backgroundSecondary = Color.backgroundSecondary
        static let border = Color(.systemGray4)
        
        struct Nutrition {
            static let protein = Color.proteinColour
            static let carbs = Color.carbsColour
            static let fat = Color.fatColour
            static let excellent = Color.nutritionGreen
            static let good = Color(.systemGreen)
            static let moderate = Color(.systemOrange)
            static let poor = Color(.systemRed)
            static let veryPoor = Color.dangerRed
        }
    }
    
    struct Spacing {
        static let extraSmall = CGFloat.spacingXS
        static let small = CGFloat.spacingS
        static let medium = CGFloat.spacingM
        static let large = CGFloat.spacingL
    }
    
    struct CornerRadius {
        static let small = CGFloat.radiusS
        static let medium = CGFloat.radiusM
        static let large = CGFloat.radiusL
    }
    
    struct Animation {
        static let spring = SwiftUI.Animation.springy
    }
}

// MARK: - Animation Presets
extension Animation {
    static let springy = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.15)
}

// MARK: - Layout Helpers
struct AdaptiveStack<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if sizeClass == .compact {
            VStack(alignment: horizontalAlignment, spacing: spacing, content: content)
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing, content: content)
        }
    }
}
