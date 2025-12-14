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
                    case 0: WelcomePage(
                        currentPage: 0,
                        onScrolledToBottom: { hasScrolledToBottom[0] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 1: DiaryPage(
                        currentPage: 1,
                        onScrolledToBottom: { hasScrolledToBottom[1] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 2: FoodDetailPage(
                        currentPage: 2,
                        onScrolledToBottom: { hasScrolledToBottom[2] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 3: NutrientsPage(
                        currentPage: 3,
                        onScrolledToBottom: { hasScrolledToBottom[3] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 4: ReactionsPage(
                        currentPage: 4,
                        onScrolledToBottom: { hasScrolledToBottom[4] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 5: PatternsPage(
                        currentPage: 5,
                        onScrolledToBottom: { hasScrolledToBottom[5] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 6: FastingPage(
                        currentPage: 6,
                        onScrolledToBottom: { hasScrolledToBottom[6] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 7: ProgressPage(
                        currentPage: 7,
                        onScrolledToBottom: { hasScrolledToBottom[7] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 8: HealthPermissionsPage(
                        currentPage: 8,
                        onScrolledToBottom: { hasScrolledToBottom[8] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 9: UseByPage(
                        currentPage: 9,
                        onScrolledToBottom: { hasScrolledToBottom[9] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 10: FinalMessagePage(
                        currentPage: 10,
                        onScrolledToBottom: { hasScrolledToBottom[10] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    case 11: DisclaimerPage(onAccept: {
                        OnboardingManager.shared.acceptDisclaimer()
                        withAnimation(.spring(response: 0.3)) { currentPage = 12 }
                    })
                    case 12: EmailConsentPage(hasConsented: $emailMarketingConsent, onContinue: {
                        OnboardingManager.shared.completeOnboarding()
                        onComplete(emailMarketingConsent) // Pass consent state
                    })
                    default: WelcomePage(
                        currentPage: 0,
                        onScrolledToBottom: { hasScrolledToBottom[0] = true },
                        onBack: { withAnimation(.spring(response: 0.3)) { currentPage -= 1 } },
                        onContinue: { withAnimation(.spring(response: 0.3)) { currentPage += 1 } }
                    )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

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
    let currentPage: Int
    let onScrolledToBottom: () -> Void
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)

                // App icon - matching actual design
                ZStack {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.40, green: 0.58, blue: 0.93), // Blue
                                    Color(red: 0.68, green: 0.45, blue: 0.93)  // Purple
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)

                    VStack(spacing: 10) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)

                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: 50, height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: 50, height: 4)
                        }
                    }
                }

                VStack(spacing: 12) {
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

                // Navigation buttons
                OnboardingNavigationButtons(
                    currentPage: currentPage,
                    totalPages: 11,
                    onBack: onBack,
                    onContinue: onContinue
                )

                // Scroll detector - triggers when navigation buttons are visible
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
