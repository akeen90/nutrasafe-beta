//
//  FeatureTipOverlay.swift
//  NutraSafe Beta
//
//  Modern modal overlay for first-time feature tips
//  Matches onboarding design language
//

import SwiftUI

/// Full-screen modal overlay for displaying feature tips - matches onboarding style
struct FeatureTipOverlay: View {
    let title: String
    let message: String
    let icon: String
    let accentColor: Color
    let bulletPoints: [String]?
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var bulletPointsVisible = false
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        message: String,
        icon: String,
        accentColor: Color,
        bulletPoints: [String]? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.accentColor = accentColor
        self.bulletPoints = bulletPoints
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Tip Card - matching onboarding style
            VStack(spacing: 20) {
                // Icon with gradient background (like InfoBullet)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 12, y: 6)

                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Bullet points in white cards (like InfoBullet style)
                if let bulletPoints = bulletPoints, !bulletPoints.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(Array(bulletPoints.enumerated()), id: \.element) { index, point in
                            FeatureTipBulletCard(
                                text: point,
                                index: index,
                                isVisible: bulletPointsVisible
                            )
                        }
                    }
                }

                // Got it button - matching onboarding style
                Button(action: dismiss) {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 15, y: 8)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(colorScheme == .dark ? Color.midnightCard : Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
            )
            .padding(.horizontal, 24)
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
            // Stagger bullet points after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    bulletPointsVisible = true
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Feature Tip Bullet Card (Matching Onboarding InfoBullet Style)

/// Individual bullet point card matching the onboarding design
private struct FeatureTipBulletCard: View {
    let text: String
    let index: Int
    let isVisible: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Checkmark with gradient background
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(
                    LinearGradient(
                        colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(8)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.clear, lineWidth: 1)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08),
            value: isVisible
        )
    }
}

// MARK: - Convenience View Modifier

extension View {
    /// Shows a feature tip overlay when the condition is true
    func featureTip(
        isPresented: Binding<Bool>,
        tipKey: FeatureTipsManager.TipKey,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue,
               let content = FeatureTipsManager.shared.getContent(for: tipKey) {
                FeatureTipOverlay(
                    title: content.title,
                    message: content.message,
                    icon: content.icon,
                    accentColor: content.accentColor,
                    bulletPoints: content.bulletPoints
                ) {
                    FeatureTipsManager.shared.markTipAsSeen(tipKey)
                    isPresented.wrappedValue = false
                    onDismiss()
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppAnimatedBackground()

        FeatureTipOverlay(
            title: "Your Food Diary",
            message: "This is your daily food log. Hit the + button to add what you've eaten — it's quick and easy!",
            icon: "fork.knife.circle.fill",
            accentColor: AppPalette.standard.accent,
            bulletPoints: [
                "Tap + to search, scan a barcode, or add manually",
                "Track your calories and macros at a glance",
                "Tap any food to edit portions or see details",
                "Swipe left and right to browse different days"
            ]
        ) {
        }
    }
}
