//
//  PaywallView.swift
//  NutraSafe Beta
//
//  Modern paywall design matching app's brand philosophy
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var priceText: String {
        if let product = subscriptionManager.product {
            // Use product price, but ensure we show at least £2.99 / $2.99
            // (Sandbox can cache stale pricing during price tier changes)
            let price = product.price as Decimal
            if price >= 2.99 {
                return product.displayPrice
            }
        }
        return "£2.99"
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Animated background matching brand style
                AppAnimatedBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.nutraSafeCard)
                                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, y: 2)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Header with App Icon
                            VStack(spacing: 20) {
                                // Real app icon from assets
                                Image("AppIconImage")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)

                                VStack(spacing: 8) {
                                    Text("Unlock NutraSafe Pro")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("Your complete food safety companion")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 16)

                            // Benefits list with brand styling
                            VStack(spacing: 12) {
                                ProBenefitRow(
                                    icon: "camera.viewfinder",
                                    iconColor: .teal,
                                    title: "AI Meal Scanner",
                                    description: "Snap a photo and auto-log all food items"
                                )

                                ProBenefitRow(
                                    icon: "fork.knife.circle.fill",
                                    iconColor: AppPalette.standard.accent,
                                    title: "Unlimited Diary Entries",
                                    description: "Log as much food as you like, every day"
                                )

                                ProBenefitRow(
                                    icon: "waveform.path.ecg",
                                    iconColor: .pink,
                                    title: "Pattern Analysis",
                                    description: "Spot which ingredients trigger reactions"
                                )

                                ProBenefitRow(
                                    icon: "calendar.badge.clock",
                                    iconColor: .orange,
                                    title: "Use By Tracker",
                                    description: "Track opened food and cut waste"
                                )

                                ProBenefitRow(
                                    icon: "timer",
                                    iconColor: .green,
                                    title: "Intermittent Fasting",
                                    description: "Plans, timers, streaks and insights"
                                )

                                ProBenefitRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    iconColor: .purple,
                                    title: "Full Weight History",
                                    description: "See your complete progress over time"
                                )
                            }
                            .padding(.horizontal, 4)

                            // Pricing card
                            VStack(spacing: 8) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(priceText)
                                        .font(.system(size: 42, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)

                                    Text("/ month")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }

                                Text("Cancel anytime")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)

                            // CTA Button
                            Button(action: {
                                Task {
                                    try? await subscriptionManager.purchase()
                                    // Check hasAccess after purchase completes (includes isSubscribed, isInTrial, isPremiumOverride)
                                    // Status is refreshed inside purchase() so no race condition
                                    if subscriptionManager.hasAccess {
                                        dismiss()
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if subscriptionManager.isPurchasing || !subscriptionManager.isProductLoaded {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Continue")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: AppPalette.standard.accent.opacity(0.3), radius: 15, y: 8)
                            }
                            .disabled(!subscriptionManager.isProductLoaded || subscriptionManager.isPurchasing)

                            // Error message
                            if let error = subscriptionManager.purchaseError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }

                            // Secondary actions
                            HStack(spacing: 20) {
                                Button("Restore") {
                                    Task {
                                        try? await subscriptionManager.restore()
                                        // Check hasAccess after restore (may include premium override)
                                        if subscriptionManager.hasAccess {
                                            dismiss()
                                        }
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                                Text("•")
                                    .foregroundColor(.secondary.opacity(0.5))

                                Button("Terms") {
                                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                                Text("•")
                                    .foregroundColor(.secondary.opacity(0.5))

                                Button("Privacy") {
                                    if let url = URL(string: "https://nutrasafe-705c7.web.app/privacy") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            }

                            // Fine print
                            Text("Auto-renews at \(priceText)/month. Cancel anytime in Settings.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .task { try? await subscriptionManager.load() }
            .trackScreen("Paywall")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Pro Benefit Row

private struct ProBenefitRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon with gradient background matching brand style
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [iconColor.opacity(colorScheme == .dark ? 0.25 : 0.15), iconColor.opacity(colorScheme == .dark ? 0.15 : 0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.nutraSafeCard)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.05), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
