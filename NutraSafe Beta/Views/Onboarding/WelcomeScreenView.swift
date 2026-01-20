//
//  WelcomeScreenView.swift
//  NutraSafe Beta
//
//  Welcome screen shown after onboarding, explaining app navigation and features
//

import SwiftUI

struct WelcomeScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.adaptiveBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)

                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "hand.wave.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("You're All Set!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Here's a quick tour of NutraSafe")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }

                        // Main tabs explanation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR MAIN TABS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                                .padding(.horizontal, 4)

                            TabExplanationCard(
                                icon: "fork.knife",
                                iconColor: .orange,
                                tabName: "Diary",
                                description: "Log meals and track daily nutrition",
                                subTabs: ["Overview", "Insights"]
                            )

                            TabExplanationCard(
                                icon: "figure.run",
                                iconColor: .blue,
                                tabName: "Progress",
                                description: "Track weight and fitness over time",
                                subTabs: nil
                            )

                            TabExplanationCard(
                                icon: "heart.fill",
                                iconColor: .pink,
                                tabName: "Health",
                                description: "Monitor reactions and intermittent fasting",
                                subTabs: ["Reactions", "Fasting"]
                            )

                            TabExplanationCard(
                                icon: "calendar",
                                iconColor: .cyan,
                                tabName: "Use By",
                                description: "Track what's in your fridge and expiry dates",
                                subTabs: nil
                            )
                        }
                        .padding(.horizontal, 24)

                        // Add button explanation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 32, height: 32)

                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Text("The + button")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text("Tap the big + button at the bottom to add food. Search by name, scan a barcode, or take a photo and let AI analyse it.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)

                        // Tips notice
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.yellow)

                                Text("Tips along the way")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            Text("You'll see helpful tips on each page when you first visit. These will guide you through the features and help you get the most from NutraSafe.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 20)
                    }
                }

                // Continue button
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Start Exploring")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Tab Explanation Card

private struct TabExplanationCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let tabName: String
    let description: String
    let subTabs: [String]?

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(iconColor.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .cornerRadius(12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(tabName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Sub-tabs indicator
                if let subTabs = subTabs {
                    HStack(spacing: 6) {
                        ForEach(subTabs, id: \.self) { tab in
                            Text(tab)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(iconColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(iconColor.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - Preview

#Preview {
    WelcomeScreenView(onContinue: {})
}
