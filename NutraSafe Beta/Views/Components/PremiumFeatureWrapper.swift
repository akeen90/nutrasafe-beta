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
                    .blur(radius: 6)
                    .allowsHitTesting(false)

                // Tappable overlay to show paywall
                Button(action: onUpgradeTapped) {
                    VStack(spacing: 12) {
                        // Lock icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 52, height: 52)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.blue)
                        }

                        // Feature name
                        Text(featureName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        // Tap to unlock
                        Text("Tap to unlock")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Simple wrapper without custom preview
/// Simpler wrapper that just blurs its content
struct SimplePremiumWrapper<Content: View>: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let featureName: String
    let content: Content
    let onUpgradeTapped: () -> Void

    init(
        featureName: String,
        onUpgradeTapped: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.featureName = featureName
        self.onUpgradeTapped = onUpgradeTapped
        self.content = content()
    }

    private var hasAccess: Bool {
        subscriptionManager.hasAccess
    }

    var body: some View {
        if hasAccess {
            content
        } else {
            ZStack {
                content
                    .blur(radius: 6)
                    .allowsHitTesting(false)

                Button(action: onUpgradeTapped) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 52, height: 52)

                            Image(systemName: "lock.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.blue)
                        }

                        Text(featureName)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("Tap to unlock")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(PlainButtonStyle())
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
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)

                Text(message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)

                Spacer()

                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.blue))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.08))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Item Limit Banner

/// Banner showing item limit for free users - only shows when at or near limit
struct FreeTierLimitBanner: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    let currentCount: Int
    let maxCount: Int
    let itemName: String
    let onUpgradeTapped: () -> Void

    private var isAtLimit: Bool {
        currentCount >= maxCount
    }

    /// Show banner when user is at 80% of limit or more
    private var shouldShow: Bool {
        !subscriptionManager.hasAccess && currentCount >= max(1, Int(Double(maxCount) * 0.8))
    }

    var body: some View {
        // Only show for free users who are approaching or at their limit
        if shouldShow {
            HStack(spacing: 12) {
                Image(systemName: isAtLimit ? "exclamationmark.circle.fill" : "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isAtLimit ? .orange : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(currentCount)/\(maxCount) \(itemName)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)

                    Text(isAtLimit ? "Upgrade for unlimited" : "Free tier limit")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isAtLimit {
                    Button(action: onUpgradeTapped) {
                        Text("Upgrade")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.blue))
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
}

// MARK: - Blurred List Items

/// Shows first N items normally, then blurs remaining with upgrade prompt
struct BlurredListSection<Item: Identifiable, Content: View>: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    let items: [Item]
    let freeLimit: Int
    let featureName: String
    let onUpgradeTapped: () -> Void
    let content: (Item) -> Content

    init(
        items: [Item],
        freeLimit: Int,
        featureName: String,
        onUpgradeTapped: @escaping () -> Void,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.freeLimit = freeLimit
        self.featureName = featureName
        self.onUpgradeTapped = onUpgradeTapped
        self.content = content
    }

    private var hasAccess: Bool {
        subscriptionManager.hasAccess
    }

    var body: some View {
        if hasAccess {
            // Premium: show all items
            ForEach(items) { item in
                content(item)
            }
        } else {
            // Free: show first N items
            ForEach(items.prefix(freeLimit)) { item in
                content(item)
            }

            // If there are more items, show blurred preview with upgrade
            if items.count > freeLimit {
                ZStack {
                    VStack(spacing: 8) {
                        ForEach(items.dropFirst(freeLimit).prefix(2)) { item in
                            content(item)
                                .blur(radius: 4)
                        }
                    }
                    .allowsHitTesting(false)

                    Button(action: onUpgradeTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                            Text("+\(items.count - freeLimit) more")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.blue))
                    }
                }
            }
        }
    }
}

// MARK: - Premium Unlock Card

/// Full-page unlock card for premium-only features (like Use By tab)
/// Shows feature explanation and unlock button
struct PremiumUnlockCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let benefits: [String]
    let onUnlockTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Title and subtitle
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(benefits, id: \.self) { benefit in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)

                            Text(benefit)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)

                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }

            Spacer()

            // Unlock button
            Button(action: onUnlockTapped) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Unlock Feature")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [iconColor, iconColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

            // Pro badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("NutraSafe Pro Feature")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            ForEach(0..<3, id: \.self) { _ in
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

// MARK: - Diary Limit Alert Modifier

/// View modifier for showing the diary limit alert - helps reduce expression complexity in views
struct DiaryLimitAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var showingPaywall: Bool

    func body(content: Content) -> some View {
        content
            .alert("Daily Limit Reached", isPresented: $isPresented) {
                Button("Upgrade to Pro") {
                    showingPaywall = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You've reached your daily limit of \(SubscriptionManager.freeDiaryEntriesPerDay) diary entries. Upgrade to NutraSafe Pro for unlimited entries.")
            }
    }
}

extension View {
    /// Convenience modifier for showing diary limit alert
    func diaryLimitAlert(isPresented: Binding<Bool>, showingPaywall: Binding<Bool>) -> some View {
        modifier(DiaryLimitAlertModifier(isPresented: isPresented, showingPaywall: showingPaywall))
    }
}
