//
//  NutrientRingComponents.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-10-20.
//  Animated circular ring components for nutrient visualization
//

import SwiftUI

// MARK: - Nutrient Ring Card (Featured)

struct NutrientRingCard: View {
    let nutrient: TrackedNutrient
    let frequency: NutrientFrequency?

    @State private var animateGlow = false
    @State private var animateRing = false
    @StateObject private var trackingManager = NutrientTrackingManager.shared

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Outer glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                ringColor.opacity(animateGlow ? 0.4 : 0.2),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? ringProgress : 0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                ringColor.opacity(0.6),
                                ringColor,
                                ringColor.opacity(0.6)
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.5), radius: 8, x: 0, y: 0)

                // Icon
                Image(systemName: nutrient.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ringColor, ringColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Label
            VStack(spacing: 6) {
                Text(nutrient.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                // Human-readable description
                if let freq = frequency {
                    Text(freq.frequencyDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No recent data")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                // Data summary
                if let freq = frequency {
                    Text(freq.dataSummary)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.center)
                }
            }

            // 30-day activity bar
            if let freq = frequency {
                Nutrient30DayActivityBar(
                    nutrientId: nutrient.id,
                    dayActivities: trackingManager.dayActivities,
                    color: ringColor
                )
                .padding(.horizontal, 8)
            }
        }
        .frame(width: 160)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ringColor.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: ringColor.opacity(0.2), radius: 12, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.1)) {
                animateRing = true
            }
        }
    }

    private var ringProgress: Double {
        guard let freq = frequency else { return 0 }
        // Progress out of 30 days - if logged 1 day, show 1/30th full
        return min(Double(freq.last30DaysAppearances) / 30.0, 1.0)
    }

    private var ringColor: Color {
        frequency?.ringColor ?? .gray
    }
}

// MARK: - Nutrient Grid Item (Compact)

struct NutrientGridItem: View {
    let nutrient: TrackedNutrient
    let frequency: NutrientFrequency?

    @State private var animateRing = false
    @State private var animateGlow = false
    @StateObject private var trackingManager = NutrientTrackingManager.shared

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Soft glow for active nutrients
                if let freq = frequency, freq.consistencyPercentage >= 70 {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    ringColor.opacity(animateGlow ? 0.3 : 0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)
                        .blur(radius: 15)
                }

                // Background circle
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 6)
                    .frame(width: 70, height: 70)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? ringProgress : 0)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                ringColor.opacity(0.6),
                                ringColor,
                                ringColor.opacity(0.8)
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.4), radius: 6, x: 0, y: 0)

                // Icon
                Image(systemName: nutrient.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(ringColor)
            }

            // Label
            VStack(spacing: 4) {
                Text(shortName(for: nutrient))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Human-readable description
                if let freq = frequency {
                    Text(freq.frequencyDescription)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("No recent data")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Data summary
            if let freq = frequency {
                Text(freq.dataSummary)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // 30-day activity bar
            if let freq = frequency {
                Nutrient30DayActivityBar(
                    nutrientId: nutrient.id,
                    dayActivities: trackingManager.dayActivities,
                    color: ringColor
                )
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    ringColor.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: ringColor.opacity(0.15), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                animateRing = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }

    private var ringProgress: Double {
        guard let freq = frequency else { return 0 }
        // Progress out of 30 days - if logged 1 day, show 1/30th full
        return min(Double(freq.last30DaysAppearances) / 30.0, 1.0)
    }

    private var ringColor: Color {
        frequency?.ringColor ?? .gray
    }

    private func shortName(for nutrient: TrackedNutrient) -> String {
        // Shorten long names for grid
        nutrient.displayName
            .replacingOccurrences(of: "Vitamin ", with: "Vit ")
            .replacingOccurrences(of: "Fatty Acids", with: "")
    }
}

// MARK: - Large Animated Ring (Detail View)

struct LargeNutrientRing: View {
    let nutrient: TrackedNutrient
    let frequency: NutrientFrequency

    @State private var animateGlow = false
    @State private var animateRing = false
    @State private var animatePulse = false

    var body: some View {
        ZStack {
            // Outer glow layers
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            nutrient.glowColor.opacity(animateGlow ? 0.5 : 0.3),
                            nutrient.glowColor.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 60,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .scaleEffect(animatePulse ? 1.1 : 1.0)

            // Background circle
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 16)
                .frame(width: 200, height: 200)

            // Progress ring
            Circle()
                .trim(from: 0, to: animateRing ? ringProgress : 0)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            nutrient.glowColor.opacity(0.5),
                            nutrient.glowColor,
                            nutrient.glowColor.opacity(0.8),
                            nutrient.glowColor
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .shadow(color: nutrient.glowColor.opacity(0.6), radius: 16, x: 0, y: 0)

            // Center content
            VStack(spacing: 8) {
                Image(systemName: nutrient.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [nutrient.glowColor, nutrient.glowColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(Int(frequency.consistencyPercentage))%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(frequency.status.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(frequency.status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(frequency.status.color.opacity(0.2))
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
            withAnimation(.spring(response: 1.5, dampingFraction: 0.6).delay(0.2)) {
                animateRing = true
            }
        }
    }

    private var ringProgress: Double {
        // Progress out of 30 days - if logged 1 day, show 1/30th full
        return min(Double(frequency.last30DaysAppearances) / 30.0, 1.0)
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let currentStreak: Int
    let bestStreak: Int
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Current streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(currentStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Text("Current Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )

            // Best streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("\(bestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Text("Best Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Mini Ring Indicator

struct MiniNutrientRing: View {
    let nutrient: TrackedNutrient
    let progress: Double

    @State private var animateRing = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: animateRing ? progress : 0)
                .stroke(nutrient.glowColor, lineWidth: 3)
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Image(systemName: nutrient.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(nutrient.glowColor)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                animateRing = true
            }
        }
    }
}

// MARK: - 30-Day Activity Bar

struct Nutrient30DayActivityBar: View {
    let nutrientId: String
    let dayActivities: [String: DayNutrientActivity]
    let color: Color

    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(last30Days, id: \.self) { date in
                let dateId = formatDateId(date)
                let hasNutrient = dayActivities[dateId]?.nutrientsPresent.contains(nutrientId) ?? false

                RoundedRectangle(cornerRadius: 2)
                    .fill(hasNutrient ? color : Color.gray.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }

    private func formatDateId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview("Ring Card") {
    ZStack {
        Color.black
        NutrientRingCard(
            nutrient: NutrientDatabase.allNutrients[0],
            frequency: NutrientFrequency(
                nutrientId: "vitamin_c",
                nutrientName: "Vitamin C",
                last30DaysAppearances: 22,
                totalLoggedDays: 28,
                currentStreak: 5,
                bestStreak: 12
            )
        )
    }
}

#Preview("Grid Item") {
    ZStack {
        Color.black
        NutrientGridItem(
            nutrient: NutrientDatabase.allNutrients[1],
            frequency: NutrientFrequency(
                nutrientId: "vitamin_d",
                nutrientName: "Vitamin D",
                last30DaysAppearances: 12,
                totalLoggedDays: 28
            )
        )
        .frame(width: 160)
    }
}
