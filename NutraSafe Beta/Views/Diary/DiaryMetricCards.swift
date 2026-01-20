//
//  DiaryMetricCards.swift
//  NutraSafe Beta
//
//  Premium glass metric cards for the redesigned Diary Overview screen.
//  Matches onboarding visual language: glass-morphic, soft gradients, breathing animations.
//

import SwiftUI

// MARK: - Layout Tokens for Diary Overview

struct DiaryLayoutTokens {
    static let heroRingSize: CGFloat = 160
    static let heroGlowSize: CGFloat = 200
    static let activityCardMinHeight: CGFloat = 110
    static let macroCapsuleHeight: CGFloat = 40
    static let weeklySummaryHeight: CGFloat = 52
    static let insightBannerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cardInternalPadding: CGFloat = 16
    static let arcRingSize: CGFloat = 56
    static let arcLineWidth: CGFloat = 6
}

// MARK: - Glass Metric Card Container

/// Reusable glass-morphic card container for activity metrics
struct GlassMetricCard<Content: View>: View {
    let content: Content
    var minHeight: CGFloat = DiaryLayoutTokens.activityCardMinHeight

    @Environment(\.colorScheme) private var colorScheme

    init(minHeight: CGFloat = DiaryLayoutTokens.activityCardMinHeight, @ViewBuilder content: () -> Content) {
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        content
            .padding(DiaryLayoutTokens.cardInternalPadding)
            .frame(minHeight: minHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            )
    }
}

// MARK: - Arc Progress Ring (Quarter Circle)

/// 90-degree arc progress indicator for steps and calories burned
struct ArcProgressRing: View {
    let progress: Double
    let gradient: [Color]
    var size: CGFloat = DiaryLayoutTokens.arcRingSize
    var lineWidth: CGFloat = DiaryLayoutTokens.arcLineWidth

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    palette.tertiary.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(135))

            // Progress arc
            Circle()
                .trim(from: 0, to: min(progress, 1.0) * 0.75)
                .stroke(
                    LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(135))
                .shadow(color: gradient.first?.opacity(0.4) ?? Color.clear, radius: 4, y: 2)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
    }
}

// MARK: - Metric Icon Container

/// Soft rounded container for metric icons
struct MetricIconContainer: View {
    let icon: String
    let color: Color
    var size: CGFloat = 32

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.12))
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Water Metric Card

struct WaterMetricCard: View {
    let waterCount: Int
    let dailyGoal: Int
    let streak: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var isComplete: Bool {
        waterCount >= dailyGoal
    }

    private var fillPercent: Double {
        min(1.0, Double(waterCount) / Double(max(1, dailyGoal)))
    }

    var body: some View {
        Button(action: onTap) {
            GlassMetricCard {
                VStack(spacing: 8) {
                    // Header
                    HStack {
                        MetricIconContainer(
                            icon: "drop.fill",
                            color: isComplete ? .green : .cyan,
                            size: 28
                        )
                        Spacer()
                        if streak > 1 {
                            streakBadge
                        }
                    }

                    Spacer(minLength: 4)

                    // Water vessel visualization
                    ZStack(alignment: .bottom) {
                        // Glass outline
                        WaterVesselShape()
                            .stroke(Color(.systemGray3), lineWidth: 2)
                            .frame(width: 44, height: 50)

                        // Water fill
                        WaterVesselShape()
                            .fill(
                                LinearGradient(
                                    colors: isComplete
                                        ? [Color.green.opacity(0.6), Color.green]
                                        : [Color.cyan.opacity(0.5), Color.cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 44, height: 50)
                            .mask(
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .frame(height: 50 * fillPercent)
                                }
                                .frame(height: 50)
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: waterCount)

                        // Checkmark when complete
                        if isComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: -20)
                        }
                    }

                    Spacer(minLength: 4)

                    // Count display
                    HStack(spacing: 2) {
                        Text("\(waterCount)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(isComplete ? .green : palette.textPrimary)
                        Text("/\(dailyGoal)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(palette.textTertiary)
                    }

                    Text("glasses")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(palette.textTertiary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10))
            Text("\(streak)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
    }
}

// MARK: - Water Vessel Shape (Tapered Glass)

struct WaterVesselShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.7
        let topInset = (rect.width - topWidth) / 2
        let bottomInset = (rect.width - bottomWidth) / 2

        path.move(to: CGPoint(x: topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: 0))
        path.addLine(to: CGPoint(x: rect.width - bottomInset, y: rect.height))
        path.addLine(to: CGPoint(x: bottomInset, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Steps Metric Card

struct StepsMetricCard: View {
    let steps: Double
    let goal: Double

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return steps / goal
    }

    private var stepsGradient: [Color] {
        [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.3, green: 0.6, blue: 0.95)]
    }

    var body: some View {
        GlassMetricCard {
            VStack(spacing: 8) {
                // Header with icon
                HStack {
                    MetricIconContainer(
                        icon: "figure.walk",
                        color: stepsGradient[0],
                        size: 28
                    )
                    Spacer()
                }

                Spacer(minLength: 4)

                // Arc progress
                ArcProgressRing(
                    progress: progress,
                    gradient: stepsGradient
                )

                Spacer(minLength: 4)

                // Value display
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(formatSteps(steps))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(palette.textPrimary)
                        Text("/\(formatSteps(goal))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(palette.textTertiary)
                    }

                    Text("steps")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(palette.textTertiary)
                }
            }
        }
    }

    private func formatSteps(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "%.1fK", value / 1000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Calories Burned Metric Card

struct CaloriesBurnedMetricCard: View {
    let burned: Double
    let goal: Double

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return burned / goal
    }

    private var burnedGradient: [Color] {
        [Color(red: 1.0, green: 0.5, blue: 0.3), Color(red: 1.0, green: 0.35, blue: 0.25)]
    }

    var body: some View {
        GlassMetricCard {
            VStack(spacing: 8) {
                // Header with icon
                HStack {
                    MetricIconContainer(
                        icon: "flame.fill",
                        color: burnedGradient[0],
                        size: 28
                    )
                    Spacer()
                }

                Spacer(minLength: 4)

                // Arc progress
                ArcProgressRing(
                    progress: progress,
                    gradient: burnedGradient
                )

                Spacer(minLength: 4)

                // Value display
                VStack(spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(burned))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(palette.textPrimary)
                        Text("/\(Int(goal))")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(palette.textTertiary)
                    }

                    Text("kcal burned")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(palette.textTertiary)
                }
            }
        }
    }
}

// MARK: - Macro Capsule

/// Horizontal pill showing single macro with gradient fill
struct MacroCapsule: View {
    let name: String
    let current: Double
    let goal: Double
    let color: Color

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, current / goal)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator dot
            Circle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.7), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.4), radius: 2, y: 1)

            // Macro name
            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(palette.textPrimary)

            Spacer()

            // Progress indicator (mini bar)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: current)
                }
            }
            .frame(width: 50, height: 6)

            // Value
            HStack(spacing: 2) {
                Text("\(Int(current.rounded()))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                Text("/\(Int(goal))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(palette.textTertiary)
                Text("g")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(palette.textTertiary)
            }
            .frame(width: 75, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(height: DiaryLayoutTokens.macroCapsuleHeight)
        .background(
            RoundedRectangle(cornerRadius: DiaryLayoutTokens.macroCapsuleHeight / 2)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.08), color.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DiaryLayoutTokens.macroCapsuleHeight / 2)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Weekly Summary Pill

struct WeeklySummaryPill: View {
    let consumed: Int
    let goal: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Left side: icon + label
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.accent)

                    Text("Weekly Summary")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(palette.accent)
                }

                Spacer()

                // Right side: calorie summary
                HStack(spacing: 3) {
                    Text(formatNumber(consumed))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(palette.textPrimary)
                    Text("/")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                    Text(formatNumber(goal))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(palette.textTertiary)
                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textTertiary.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .frame(height: DiaryLayoutTokens.weeklySummaryHeight)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.primary.opacity(0.06),
                                palette.accent.opacity(0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(palette.accent.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Coaching Banner (Nutrition Insights)

struct CoachingBanner: View {
    let icon: String
    let message: String
    let color: Color
    let isPositive: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon container
            ZStack {
                Circle()
                    .fill(color.opacity(colorScheme == .dark ? 0.2 : 0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // Message
            Text(message)
                .font(.system(size: 14, weight: isPositive ? .medium : .semibold, design: .rounded))
                .foregroundColor(isPositive ? palette.textPrimary : color)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DiaryLayoutTokens.insightBannerRadius)
                .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        )
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
            removal: .opacity
        ))
    }
}

// MARK: - Hero Calorie Ring

struct HeroCalorieRing: View {
    let calories: Int
    let goal: Double

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(calories) / goal)
    }

    var body: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(palette.accent.opacity(0.06))
                .frame(width: DiaryLayoutTokens.heroGlowSize, height: DiaryLayoutTokens.heroGlowSize)
                .blur(radius: 25)

            // Background ring
            Circle()
                .stroke(palette.tertiary.opacity(0.12), lineWidth: 18)
                .frame(width: DiaryLayoutTokens.heroRingSize, height: DiaryLayoutTokens.heroRingSize)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [palette.accent, palette.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .frame(width: DiaryLayoutTokens.heroRingSize, height: DiaryLayoutTokens.heroRingSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: palette.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: calories)

            // Center content
            VStack(spacing: 2) {
                Text("\(calories)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(palette.textPrimary)

                Text("/\(Int(goal))")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(palette.textTertiary)

                Text("kcal")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(palette.textTertiary)
                    .padding(.top, 2)
            }
        }
        .scaleEffect(isBreathing ? 1.02 : 1.0)
        .onAppear {
            withAnimation(DesignTokens.Animation.breathing) {
                isBreathing = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            HeroCalorieRing(calories: 1450, goal: 2000)

            HStack(spacing: 12) {
                MacroCapsule(name: "Protein", current: 85, goal: 120, color: .red)
            }

            HStack(spacing: 12) {
                WaterMetricCard(waterCount: 5, dailyGoal: 8, streak: 3, onTap: {})
                StepsMetricCard(steps: 7500, goal: 10000)
                CaloriesBurnedMetricCard(burned: 280, goal: 400)
            }
            .padding(.horizontal)

            WeeklySummaryPill(consumed: 12500, goal: 14000, onTap: {})
                .padding(.horizontal)

            CoachingBanner(
                icon: "cube.fill",
                message: "High sugar intake today – 65g consumed",
                color: .pink,
                isPositive: false
            )
            .padding(.horizontal)

            CoachingBanner(
                icon: "bolt.fill",
                message: "Great protein day! 95% of goal",
                color: .green,
                isPositive: true
            )
            .padding(.horizontal)
        }
        .padding()
    }
    .background(Color.adaptiveBackground)
}
