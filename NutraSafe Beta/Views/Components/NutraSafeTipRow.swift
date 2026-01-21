//
//  NutraSafeTipRow.swift
//  NutraSafe Beta
//
//  Unified tip component with NutraSafe design language
//  Features: soft glassmorphic card, gradient icon, delayed reveal animation
//

import SwiftUI

// MARK: - NutraSafe Tip Row (Unified Component)

/// A beautifully styled tip row that matches NutraSafe's soft, friendly design language.
/// Features a delayed reveal animation and glassmorphic styling.
struct NutraSafeTipRow: View {
    let icon: String
    let text: String
    let tint: Color
    let index: Int

    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    /// Base delay before tips start appearing (in seconds)
    private let baseDelay: Double = 0.3
    /// Stagger delay between each tip (in seconds)
    private let staggerDelay: Double = 0.1

    init(icon: String, text: String, tint: Color = AppPalette.standard.accent, index: Int = 0) {
        self.icon = icon
        self.text = text
        self.tint = tint
        self.index = index
    }

    var body: some View {
        HStack(spacing: 14) {
            // Gradient icon in soft container
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.2), tint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : .primary.opacity(0.8))
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(baseDelay + (Double(index) * staggerDelay))) {
                isVisible = true
            }
        }
    }
}

// MARK: - NutraSafe Tip Card (Container with Multiple Tips)

/// A card container for multiple tips with unified styling
struct NutraSafeTipCard: View {
    let tips: [(icon: String, text: String, tint: Color)]

    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    init(tips: [(icon: String, text: String, tint: Color)]) {
        self.tips = tips
    }

    /// Convenience initializer for tips with default accent color
    init(tips: [(icon: String, text: String)]) {
        self.tips = tips.map { ($0.icon, $0.text, AppPalette.standard.accent) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                NutraSafeTipRow(
                    icon: tip.icon,
                    text: tip.text,
                    tint: tip.tint,
                    index: index
                )
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Glassmorphic background
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color.nutraSafeCard)

                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.5),
                                Color.white.opacity(colorScheme == .dark ? 0.02 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Soft border
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.1), Color.white.opacity(0.05)]
                                : [Color.black.opacity(0.06), Color.black.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 12, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                isVisible = true
            }
        }
    }
}

// MARK: - NutraSafe Single Tip Card (Lightbulb Style)

/// A single tip card with lightbulb icon - perfect for contextual hints
struct NutraSafeSingleTip: View {
    let text: String
    let icon: String
    let tint: Color

    @State private var isVisible = false
    @Environment(\.colorScheme) private var colorScheme

    init(_ text: String, icon: String = "lightbulb.fill", tint: Color = .yellow) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    var body: some View {
        HStack(spacing: 12) {
            // Gradient icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.2), tint.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            ZStack {
                // Glassmorphic background
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                // Subtle tinted overlay
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.05),
                                tint.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Border
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.2),
                                tint.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: tint.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview("NutraSafe Tips") {
    ZStack {
        Color.adaptiveBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 24) {
                // Single tip
                NutraSafeSingleTip("Swipe left on items to delete them quickly")
                    .padding(.horizontal)

                // Tip card with multiple tips
                NutraSafeTipCard(tips: [
                    (icon: "magnifyingglass", text: "Search by name or brand", tint: AppPalette.standard.accent),
                    (icon: "barcode.viewfinder", text: "Scan barcodes for instant results", tint: AppPalette.standard.primary),
                    (icon: "square.and.pencil", text: "Add foods manually anytime", tint: SemanticColors.positive)
                ])
                .padding(.horizontal)

                // Individual tip rows
                VStack(alignment: .leading, spacing: 12) {
                    NutraSafeTipRow(icon: "camera.fill", text: "Good lighting helps", tint: .yellow, index: 0)
                    NutraSafeTipRow(icon: "hand.raised.fill", text: "Hold steady for best results", tint: .orange, index: 1)
                    NutraSafeTipRow(icon: "text.magnifyingglass", text: "Focus on the label text", tint: .blue, index: 2)
                }
                .padding()
            }
            .padding(.vertical)
        }
    }
}
