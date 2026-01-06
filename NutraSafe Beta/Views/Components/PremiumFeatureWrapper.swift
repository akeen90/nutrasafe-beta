//
//  PremiumFeatureWrapper.swift
//  NutraSafe Beta
//
//  Wraps premium features with blur overlay and upgrade prompt for free users
//

import SwiftUI

/// Wraps content with a blur overlay and upgrade prompt for non-premium users
struct PremiumFeatureWrapper<Content: View, Preview: View>: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let featureName: String
    let content: Content
    let blurredPreview: Preview
    let onUpgradeTapped: () -> Void

    init(
        featureName: String,
        onUpgradeTapped: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder blurredPreview: () -> Preview
    ) {
        self.featureName = featureName
        self.onUpgradeTapped = onUpgradeTapped
        self.content = content()
        self.blurredPreview = blurredPreview()
    }

    private var hasAccess: Bool {
        subscriptionManager.isSubscribed ||
        subscriptionManager.isInTrial ||
        subscriptionManager.isPremiumOverride
    }

    var body: some View {
        if hasAccess {
            content
        } else {
            ZStack {
                // Blurred preview content
                blurredPreview
                    .blur(radius: 8)
                    .allowsHitTesting(false)

                // Premium lock overlay
                VStack(spacing: 14) {
                    // Lock icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .blue.opacity(0.4), radius: 12, y: 6)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }

                    // Feature name
                    Text(featureName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    // Premium label
                    Text("Premium Feature")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    // Upgrade button
                    Button(action: onUpgradeTapped) {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                            Text("Upgrade")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                )
            }
        }
    }
}

// MARK: - Inline Upgrade Prompt

/// Subtle inline upgrade prompt for use within lists or cards
struct InlineUpgradePrompt: View {
    let message: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Item Limit Banner

/// Banner showing item limit for free users
struct FreeTierLimitBanner: View {
    let currentCount: Int
    let maxCount: Int
    let itemName: String
    let onUpgradeTapped: () -> Void

    private var isAtLimit: Bool {
        currentCount >= maxCount
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isAtLimit ? "exclamationmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(isAtLimit ? .orange : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentCount)/\(maxCount) \(itemName) used")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                if isAtLimit {
                    Text("Upgrade for unlimited \(itemName)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isAtLimit {
                Button(action: onUpgradeTapped) {
                    Text("Upgrade")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isAtLimit ? Color.orange.opacity(0.1) : Color.blue.opacity(0.08))
        )
    }
}

// MARK: - Previews

#Preview("Premium Wrapper") {
    PremiumFeatureWrapper(
        featureName: "Pattern Analysis",
        onUpgradeTapped: { print("Upgrade tapped") }
    ) {
        Text("Premium Content Here")
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.3))
            .cornerRadius(12)
    } blurredPreview: {
        VStack(spacing: 12) {
            ForEach(0..<3) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 50)
            }
        }
        .padding()
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Inline Prompt") {
    InlineUpgradePrompt(
        message: "Unlock unlimited reactions"
    ) {
        print("Upgrade tapped")
    }
    .padding()
}

#Preview("Limit Banner") {
    VStack(spacing: 20) {
        FreeTierLimitBanner(
            currentCount: 3,
            maxCount: 5,
            itemName: "items",
            onUpgradeTapped: {}
        )

        FreeTierLimitBanner(
            currentCount: 5,
            maxCount: 5,
            itemName: "items",
            onUpgradeTapped: {}
        )
    }
    .padding()
}
