//
//  OnboardingScreens.swift
//  NutraSafe Beta
//
//  Condensed 4-screen onboarding experience
//  Created on 2025-10-27
//

import SwiftUI

// MARK: - Screen 1: Welcome + Value Proposition

struct WelcomeScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // App Icon Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 32)
            
            // Title
            Text("Welcome to")
                .font(.system(size: 20, weight: .medium))
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
                .padding(.bottom, 16)
            
            Text("Your Complete Nutrition &\nFood Safety Companion")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
            
            // Key Value Points
            VStack(alignment: .leading, spacing: 20) {
                ValuePoint(
                    icon: "checkmark.shield.fill",
                    color: .green,
                    text: "Know exactly what's in your food"
                )
                
                ValuePoint(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    text: "Track 20+ vitamins & minerals automatically"
                )
                
                ValuePoint(
                    icon: "bolt.heart.fill",
                    color: .purple,
                    text: "Identify allergens & food reactions instantly"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Continue Button
            Button(action: { currentPage += 1 }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 2: Core Features

struct CoreFeaturesScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Powerful Food Tracking")
                        .font(.system(size: 34, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Three easy ways to log your meals")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // Three Input Methods
                VStack(spacing: 16) {
                    InputMethodCard(
                        icon: "barcode.viewfinder",
                        gradient: [.blue, .cyan],
                        title: "Barcode Scanner",
                        description: "Instant product lookup with detailed nutrition info"
                    )
                    
                    InputMethodCard(
                        icon: "magnifyingglass",
                        gradient: [.purple, .pink],
                        title: "Search 29,000+ Foods",
                        description: "Comprehensive database of branded & generic items"
                    )
                    
                    InputMethodCard(
                        icon: "pencil.circle.fill",
                        gradient: [.orange, .red],
                        title: "Manual Entry",
                        description: "Create custom foods and recipes from scratch"
                    )
                }
                .padding(.horizontal, 20)
                
                // What You Get
                VStack(alignment: .leading, spacing: 16) {
                    Text("Every food shows:")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal, 24)
                    
                    FeatureHighlight(
                        icon: "chart.bar.fill",
                        color: .green,
                        title: "Nutrition Score (A+ to F)",
                        subtitle: "Instant health rating"
                    )
                    
                    FeatureHighlight(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        title: "Allergen Detection",
                        subtitle: "Big red warnings for your 14 allergens"
                    )
                    
                    FeatureHighlight(
                        icon: "flask.fill",
                        color: .orange,
                        title: "Ingredient Analysis",
                        subtitle: "Safety ratings for every ingredient"
                    )
                }
                .padding(.vertical, 20)
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    BackButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 3: Advanced Features

struct AdvancedFeaturesScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text("Advanced Health Tools")
                        .font(.system(size: 34, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Go deeper with comprehensive tracking")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.horizontal, 24)
                
                // Feature Cards
                VStack(spacing: 20) {
                    AdvancedFeatureCard(
                        icon: "chart.pie.fill",
                        gradient: [.purple, .blue],
                        title: "Micronutrient Dashboard",
                        description: "Track 20+ vitamins & minerals automatically",
                        features: [
                            "Visual coverage indicators (Green/Orange/Red)",
                            "7-day timeline shows which foods provide each nutrient",
                            "Spot deficiencies before they become problems"
                        ],
                        location: "Diary → Nutrients"
                    )
                    
                    AdvancedFeatureCard(
                        icon: "heart.text.square.fill",
                        gradient: [.red, .orange],
                        title: "Food Reactions Tracker",
                        description: "Log symptoms and identify problem ingredients",
                        features: [
                            "Track severity levels and symptoms",
                            "Pattern analysis shows recurring ingredients",
                            "Export reports for healthcare providers"
                        ],
                        location: "Food → Reactions"
                    )
                    
                    AdvancedFeatureCard(
                        icon: "timer",
                        gradient: [.orange, .yellow],
                        title: "Intermittent Fasting Timer",
                        description: "Track fasts with 8 metabolic stages",
                        features: [
                            "Presets: 16h, 18h, 20h, 24h fasts",
                            "Live progress in Dynamic Island",
                            "Real-time benefits at each stage"
                        ],
                        location: "Food → Fasting"
                    )
                    
                    AdvancedFeatureCard(
                        icon: "calendar.badge.clock",
                        gradient: [.green, .cyan],
                        title: "Use By Tracker",
                        description: "Never waste food again",
                        features: [
                            "Track open foods and expiry dates",
                            "Color-coded countdown (Fresh/This Week/Soon/Today)",
                            "Smart notifications before items spoil"
                        ],
                        location: "Use By Tab"
                    )
                }
                .padding(.horizontal, 20)
                
                // Navigation Buttons
                HStack(spacing: 12) {
                    BackButton(currentPage: $currentPage)
                    ContinueButton(currentPage: $currentPage)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Screen 4: Get Started + Disclaimer

struct GetStartedScreen: View {
    @Binding var currentPage: Int
    @State private var hasAcceptedDisclaimer = false
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.2), Color.mint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 40)
                
                // Title
                Text("You're All Set!")
                    .font(.system(size: 36, weight: .bold))
                
                // Quick Start Steps
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Start:")
                        .font(.system(size: 22, weight: .semibold))
                        .padding(.bottom, 4)
                    
                    QuickStartStep(
                        number: "1",
                        icon: "gearshape.fill",
                        text: "Set your allergens",
                        detail: "Settings → Health & Safety"
                    )
                    
                    QuickStartStep(
                        number: "2",
                        icon: "plus.circle.fill",
                        text: "Add your first meal",
                        detail: "Tap + → Scan or Search"
                    )
                    
                    QuickStartStep(
                        number: "3",
                        icon: "chart.bar.fill",
                        text: "Check your nutrients",
                        detail: "Diary → Nutrients tab"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // Health Disclaimer
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text("Important Health Information")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DisclaimerPoint(text: "NutraSafe is an informational tool, not medical advice")
                        DisclaimerPoint(text: "Always verify food labels yourself")
                        DisclaimerPoint(text: "Consult healthcare professionals for medical decisions")
                        DisclaimerPoint(text: "Results cannot be guaranteed to be 100% accurate")
                    }
                    
                    // Acceptance Button
                    Button(action: { 
                        hasAcceptedDisclaimer.toggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: hasAcceptedDisclaimer ? "checkmark.square.fill" : "square")
                                .font(.system(size: 24))
                                .foregroundColor(hasAcceptedDisclaimer ? .blue : .gray)
                            
                            Text("I understand and agree")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                
                // Final CTA
                Button(action: {
                    OnboardingManager.shared.acceptDisclaimer()
                    OnboardingManager.shared.completeOnboarding()
                    onComplete()
                }) {
                    HStack(spacing: 12) {
                        Text("Start Using NutraSafe")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: hasAcceptedDisclaimer ? [Color.blue, Color.purple] : [Color.gray, Color.gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: hasAcceptedDisclaimer ? Color.purple.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                }
                .disabled(!hasAcceptedDisclaimer)
                .padding(.horizontal, 24)
                
                // Back Button
                Button(action: { currentPage -= 1 }) {
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Reusable Components

struct ValuePoint: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct InputMethodCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct FeatureHighlight: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct AdvancedFeatureCard: View {
    let icon: String
    let gradient: [Color]
    let title: String
    let description: String
    let features: [String]
    let location: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(.top, 2)
                        
                        Text(feature)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Location Tag
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.system(size: 10))
                
                Text(location)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct QuickStartStep: View {
    let number: String
    let icon: String
    let text: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Number Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text(number)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(text)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct DisclaimerPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.orange)
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }
}

struct BackButton: View {
    @Binding var currentPage: Int
    
    var body: some View {
        Button(action: { 
            if currentPage > 0 { 
                currentPage -= 1 
            }
        }) {
            Text("Back")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct ContinueButton: View {
    @Binding var currentPage: Int
    
    var body: some View {
        Button(action: { currentPage += 1 }) {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
        }
    }
}
