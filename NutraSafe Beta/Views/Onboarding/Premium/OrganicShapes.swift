//
//  OrganicShapes.swift
//  NutraSafe Beta
//
//  Custom organic shapes for premium onboarding - breathing blobs,
//  abstract marks, and generative "personal lens" visuals
//

import SwiftUI

// MARK: - Breathing Organic Blob

struct BreathingBlob: View {
    let palette: OnboardingPalette
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            // Outer glow
            BlobShape(seed: 1)
                .fill(
                    RadialGradient(
                        colors: [
                            palette.primary.opacity(0.3),
                            palette.primary.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 280, height: 280)
                .scaleEffect(isBreathing ? 1.15 : 1.0)
                .blur(radius: 30)

            // Main blob
            BlobShape(seed: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.primary,
                            palette.secondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(isBreathing ? 1.08 : 0.95)
                .opacity(isBreathing ? 0.9 : 0.7)

            // Inner highlight
            BlobShape(seed: 3)
                .fill(
                    RadialGradient(
                        colors: [
                            palette.tertiary.opacity(0.5),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: -20, y: -20)
                .scaleEffect(isBreathing ? 1.05 : 0.98)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                isBreathing = true
            }
        }
    }
}

// MARK: - Blob Shape (Organic asymmetrical)

struct BlobShape: Shape {
    let seed: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Generate organic blob using noise-like variation
        let points = 8
        var controlPoints: [CGPoint] = []

        for i in 0..<points {
            let angle = (CGFloat(i) / CGFloat(points)) * .pi * 2
            // Add variation based on seed and position
            let variation = 0.15 + 0.15 * sin(CGFloat(seed) * 0.5 + CGFloat(i) * 0.7)
            let r = radius * (1 + variation * sin(angle * 2 + CGFloat(seed)))
            let x = center.x + r * cos(angle)
            let y = center.y + r * sin(angle)
            controlPoints.append(CGPoint(x: x, y: y))
        }

        // Draw smooth curve through points
        guard !controlPoints.isEmpty else { return path }

        path.move(to: controlPoints[0])
        for i in 0..<controlPoints.count {
            let p0 = controlPoints[i]
            let p1 = controlPoints[(i + 1) % controlPoints.count]
            let p2 = controlPoints[(i + 2) % controlPoints.count]

            let mid1 = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            let mid2 = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)

            path.addQuadCurve(to: mid2, control: p1)
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Abstract Intent Marks

struct IntentMark: View {
    let intent: UserIntent
    let size: CGFloat
    let palette: OnboardingPalette

    var body: some View {
        Group {
            switch intent {
            case .safer:
                SaferMark(size: size, palette: palette)
            case .lighter:
                LighterMark(size: size, palette: palette)
            case .control:
                ControlMark(size: size, palette: palette)
            }
        }
    }
}

// Shield-like overlapping curves for "Safer"
struct SaferMark: View {
    let size: CGFloat
    let palette: OnboardingPalette

    var body: some View {
        ZStack {
            // Outer protective curve
            ShieldCurve()
                .stroke(palette.primary, lineWidth: 3)
                .frame(width: size, height: size)

            // Inner nested curve
            ShieldCurve()
                .fill(palette.primary.opacity(0.2))
                .frame(width: size * 0.7, height: size * 0.7)
        }
    }
}

struct ShieldCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control: CGPoint(x: w * 0.85, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w, y: h * 0.75)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.35),
            control: CGPoint(x: 0, y: h * 0.75)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * 0.15, y: 0)
        )

        return path
    }
}

// Ascending spiral for "Lighter"
struct LighterMark: View {
    let size: CGFloat
    let palette: OnboardingPalette

    var body: some View {
        ZStack {
            // Ascending curve
            AscendingSpiral()
                .stroke(
                    LinearGradient(
                        colors: [palette.primary.opacity(0.3), palette.primary],
                        startPoint: .bottom,
                        endPoint: .top
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)

            // Light orb at top
            Circle()
                .fill(palette.primary.opacity(0.4))
                .frame(width: size * 0.2, height: size * 0.2)
                .offset(y: -size * 0.3)
                .blur(radius: 4)
        }
    }
}

struct AscendingSpiral: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Open ascending spiral
        let turns: CGFloat = 1.5
        let points = 50

        for i in 0..<points {
            let progress = CGFloat(i) / CGFloat(points)
            let angle = progress * turns * .pi * 2
            let radius = 10 + progress * (min(rect.width, rect.height) / 2 - 15)
            let x = center.x + radius * cos(angle - .pi / 2)
            let y = center.y - progress * rect.height * 0.4 + radius * sin(angle - .pi / 2) * 0.3

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

// Intersecting circles for "Control"
struct ControlMark: View {
    let size: CGFloat
    let palette: OnboardingPalette

    var body: some View {
        ZStack {
            // Three intersecting circles
            Circle()
                .stroke(palette.primary, lineWidth: 2)
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: -size * 0.15, y: -size * 0.1)

            Circle()
                .stroke(palette.primary, lineWidth: 2)
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(x: size * 0.15, y: -size * 0.1)

            Circle()
                .stroke(palette.primary, lineWidth: 2)
                .frame(width: size * 0.6, height: size * 0.6)
                .offset(y: size * 0.15)

            // Center node
            Circle()
                .fill(palette.primary)
                .frame(width: size * 0.15, height: size * 0.15)
        }
    }
}

// MARK: - Personal Lens (Composite generative shape)

struct PersonalLens: View {
    let intent: UserIntent?
    let sensitivities: Set<FoodSensitivity>
    let size: CGFloat
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var palette: OnboardingPalette {
        OnboardingPalette.forIntent(intent)
    }

    var body: some View {
        ZStack {
            // Outer glow based on sensitivity count
            let glowIntensity = min(1.0, 0.3 + Double(sensitivities.count) * 0.1)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            palette.primary.opacity(glowIntensity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 20)

            // Intent mark at center
            if let intent = intent {
                IntentMark(intent: intent, size: size * 0.5, palette: palette)
                    .scaleEffect(pulseScale)
            }

            // Sensitivity indicators orbiting
            ForEach(Array(sensitivities.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(palette.accent.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: -size * 0.4)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(max(sensitivities.count, 1))) + rotation))
            }
        }
        .onAppear {
            // Slow rotation for sensitivity indicators
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            // Gentle pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
    }
}

// MARK: - Ripple Effect

struct RippleEffect: View {
    let palette: OnboardingPalette
    @State private var ripple1: CGFloat = 0
    @State private var ripple2: CGFloat = 0
    @State private var ripple3: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(palette.primary.opacity(0.3 - ripple1 * 0.3), lineWidth: 2)
                .frame(width: 100 + ripple1 * 200, height: 100 + ripple1 * 200)

            Circle()
                .stroke(palette.primary.opacity(0.3 - ripple2 * 0.3), lineWidth: 2)
                .frame(width: 100 + ripple2 * 200, height: 100 + ripple2 * 200)

            Circle()
                .stroke(palette.primary.opacity(0.3 - ripple3 * 0.3), lineWidth: 2)
                .frame(width: 100 + ripple3 * 200, height: 100 + ripple3 * 200)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                ripple1 = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                    ripple2 = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                    ripple3 = 1
                }
            }
        }
    }
}

// MARK: - Floating Particles

struct FloatingParticles: View {
    let palette: OnboardingPalette
    let count: Int

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ParticleView(
                    palette: palette,
                    delay: Double(index) * 0.3,
                    seed: index
                )
            }
        }
    }
}

struct ParticleView: View {
    let palette: OnboardingPalette
    let delay: Double
    let seed: Int

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .fill(palette.accent.opacity(0.4))
            .frame(width: CGFloat(4 + seed % 4), height: CGFloat(4 + seed % 4))
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                // Random starting position
                let startX = CGFloat.random(in: -50...50)
                let startY = CGFloat.random(in: -50...50)
                offset = CGSize(width: startX, height: startY)

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 4).repeatForever(autoreverses: false)) {
                        let endX = startX + CGFloat.random(in: -100...100)
                        let endY = startY + CGFloat.random(in: (-150)...(-50))
                        offset = CGSize(width: endX, height: endY)
                    }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        opacity = 0.8
                    }
                }
            }
    }
}

// MARK: - Glassmorphic Card

struct GlassmorphicCard<Content: View>: View {
    let isSelected: Bool
    let palette: OnboardingPalette
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? palette.accent : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? palette.accent.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isSelected ? 20 : 10,
                        y: isSelected ? 8 : 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    let palette: OnboardingPalette
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                palette.background,
                palette.tertiary.opacity(0.3),
                palette.background
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Focus Viewfinder

struct FocusViewfinder: View {
    let palette: OnboardingPalette
    @State private var focusProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Viewfinder frame
            RoundedRectangle(cornerRadius: 24)
                .stroke(palette.primary.opacity(0.5), lineWidth: 3)
                .frame(width: 200, height: 150)

            // Blurred shapes that come into focus
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(palette.secondary.opacity(0.3))
                    .frame(width: 120, height: 20)
                    .offset(y: -30)

                RoundedRectangle(cornerRadius: 8)
                    .fill(palette.tertiary.opacity(0.3))
                    .frame(width: 80, height: 15)
                    .offset(y: 0)

                RoundedRectangle(cornerRadius: 8)
                    .fill(palette.primary.opacity(0.3))
                    .frame(width: 100, height: 18)
                    .offset(y: 30)
            }
            .blur(radius: 8 - focusProgress * 8)

            // Corner brackets
            ViewfinderCorner()
                .stroke(palette.accent, lineWidth: 3)
                .frame(width: 30, height: 30)
                .offset(x: -90, y: -65)

            ViewfinderCorner()
                .stroke(palette.accent, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(90))
                .offset(x: 90, y: -65)

            ViewfinderCorner()
                .stroke(palette.accent, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(-90))
                .offset(x: -90, y: 65)

            ViewfinderCorner()
                .stroke(palette.accent, lineWidth: 3)
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(180))
                .offset(x: 90, y: 65)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                focusProgress = 1
            }
        }
    }
}

struct ViewfinderCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Premium Button

struct PremiumButton: View {
    let text: String
    let palette: OnboardingPalette
    let action: () -> Void
    var isEnabled: Bool = true
    var showShimmer: Bool = false

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        Button(action: action) {
            ZStack {
                // Base
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled
                            ? LinearGradient(
                                colors: [palette.primary, palette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )

                // Shimmer overlay
                if showShimmer && isEnabled {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                        .mask(
                            RoundedRectangle(cornerRadius: 16)
                        )
                }

                // Text
                Text(text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isEnabled ? .white : .gray)
            }
            .frame(height: 56)
        }
        .disabled(!isEnabled)
        .onAppear {
            if showShimmer {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
        }
    }
}

// MARK: - Typewriter Text

struct TypewriterText: View {
    let text: String
    let palette: OnboardingPalette
    @State private var displayedText = ""
    @State private var currentIndex = 0

    var body: some View {
        Text(displayedText)
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(Color(white: 0.4)) // Use consistent readable gray
            .lineSpacing(6)
            .multilineTextAlignment(.center)
            .onAppear {
                animateText()
            }
    }

    private func animateText() {
        displayedText = ""
        currentIndex = 0

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText += String(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}
