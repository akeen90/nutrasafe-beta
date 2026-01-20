//
//  PaywallView.swift
//  NutraSafe Beta
//
//  Modern paywall design with clean aesthetic
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
                // Background
                Color.adaptiveBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 16) {
                            // App icon or Pro badge
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppPalette.standard.accent, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)

                                Image(systemName: "star.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }

                            VStack(spacing: 8) {
                                Text("Unlock NutraSafe Pro")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("Get the most out of your nutrition journey")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 8)

                        // Benefits list
                        VStack(spacing: 16) {
                            BenefitRow(
                                icon: "camera.viewfinder",
                                iconColor: .teal,
                                title: "AI Meal Scanner",
                                description: "Snap a photo and auto-log all food items"
                            )

                            BenefitRow(
                                icon: "fork.knife.circle.fill",
                                iconColor: AppPalette.standard.accent,
                                title: "Unlimited Diary Entries",
                                description: "Log as much food as you like, every day"
                            )

                            BenefitRow(
                                icon: "waveform.path.ecg",
                                iconColor: .pink,
                                title: "Pattern Analysis",
                                description: "Spot which ingredients trigger reactions"
                            )

                            BenefitRow(
                                icon: "calendar.badge.clock",
                                iconColor: .orange,
                                title: "Use By Tracker",
                                description: "Track opened food and cut waste"
                            )

                            BenefitRow(
                                icon: "timer",
                                iconColor: .green,
                                title: "Intermittent Fasting",
                                description: "Plans, timers, streaks and insights"
                            )

                            BenefitRow(
                                icon: "chart.line.uptrend.xyaxis",
                                iconColor: .purple,
                                title: "Full Weight History",
                                description: "See your complete progress over time"
                            )
                        }
                        .padding(.horizontal, 4)

                        // Pricing card
                        VStack(spacing: 16) {
                            // Price display
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(priceText)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("/ month")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // CTA Button
                        Button(action: {
                            Task {
                                try? await subscriptionManager.purchase()
                                if subscriptionManager.isSubscribed {
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
                                    colors: [AppPalette.standard.accent, AppPalette.standard.accent.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
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
                                    if subscriptionManager.isSubscribed {
                                        dismiss()
                                    }
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

                            Button("Terms") {
                                if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

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
                            .padding(.bottom, 20)
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

// MARK: - Benefit Row

private struct BenefitRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
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
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}
