//
//  OnboardingView.swift
//  NutraSafe Beta
//
//  Modern button-based onboarding with integrated screenshots
//

import SwiftUI

// MARK: - Scroll Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var hasScrolledToBottom: [Int: Bool] = [:] // User must scroll to bottom of each page
    @State private var emailMarketingConsent = false // GDPR email consent
    let totalPages = 13 // 11 content pages + 1 disclaimer + 1 email consent
    let onComplete: (Bool) -> Void // Pass email consent to completion handler

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.96, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                Group {
                    switch currentPage {
                    case 0: WelcomePage(onScrolledToBottom: { hasScrolledToBottom[0] = true })
                    case 1: DiaryPage(onScrolledToBottom: { hasScrolledToBottom[1] = true })
                    case 2: FoodDetailPage(onScrolledToBottom: { hasScrolledToBottom[2] = true })
                    case 3: NutrientsPage(onScrolledToBottom: { hasScrolledToBottom[3] = true })
                    case 4: ReactionsPage(onScrolledToBottom: { hasScrolledToBottom[4] = true })
                    case 5: PatternsPage(onScrolledToBottom: { hasScrolledToBottom[5] = true })
                    case 6: FastingPage(onScrolledToBottom: { hasScrolledToBottom[6] = true })
                    case 7: ProgressPage(onScrolledToBottom: { hasScrolledToBottom[7] = true })
                    case 8: HealthPermissionsPage(onScrolledToBottom: { hasScrolledToBottom[8] = true })
                    case 9: UseByPage(onScrolledToBottom: { hasScrolledToBottom[9] = true })
                    case 10: FinalMessagePage(onScrolledToBottom: { hasScrolledToBottom[10] = true })
                    case 11: DisclaimerPage(onAccept: {
                        OnboardingManager.shared.acceptDisclaimer()
                        withAnimation(.spring(response: 0.3)) { currentPage = 12 }
                    })
                    case 12: EmailConsentPage(hasConsented: $emailMarketingConsent, onContinue: {
                        OnboardingManager.shared.completeOnboarding()
                        onComplete(emailMarketingConsent) // Pass consent state
                    })
                    default: WelcomePage(onScrolledToBottom: { hasScrolledToBottom[0] = true })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                // Navigation buttons (only appear when scrolled to bottom, not on disclaimer or email consent pages)
                if currentPage < 11 {
                    let isScrolledToBottom = hasScrolledToBottom[currentPage] ?? false

                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button(action: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
                            }
                        }

                        Button(action: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }) {
                            HStack {
                                Text(currentPage == 10 ? "Continue to Disclaimer" : "Continue")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 15, y: 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .layoutPriority(1)
                    .opacity(isScrolledToBottom ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isScrolledToBottom)
                }

                // Progress indicator (only for main pages, not disclaimer or email consent)
                if currentPage < 11 {
                    HStack(spacing: 8) {
                        ForEach(0..<11) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    .layoutPriority(1)
                }
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    let onScrolledToBottom: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                // App icon or logo
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("NutraSafe")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Your complete nutrition & food safety companion")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer().frame(height: 20)

                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "doc.text.fill", color: .blue, text: "Log food, understand ingredients")
                    FeatureRow(icon: "chart.bar.fill", color: .green, text: "Track patterns & nutrition")
                    FeatureRow(icon: "shield.fill", color: .orange, text: "Stay informed & safe")
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 80)

                // Scroll detector - only triggers when user scrolls to bottom
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: WelcomeScrollOffsetKey.self, value: geometry.frame(in: .named("welcomeScroll")).minY)
                        .onPreferenceChange(WelcomeScrollOffsetKey.self) { offset in
                            if offset < UIScreen.main.bounds.height {
                                onScrolledToBottom()
                            }
                        }
                }
                .frame(height: 1)
            }
        }
        .coordinateSpace(name: "welcomeScroll")
    }
}

struct WelcomeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}
