//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Redesigned Command Panel - A calm, confident primary interaction surface
//  Premium design language matching the NutraSafe design family
//

import SwiftUI

struct AddActionMenu: View {
    @Binding var isPresented: Bool
    var onSelectDiary: () -> Void
    var onSelectUseBy: () -> Void
    var onSelectReaction: () -> Void
    var onSelectWeighIn: () -> Void

    // Additional action callbacks
    var onSelectBarcodeScan: (() -> Void)?
    var onSelectVoiceLog: (() -> Void)?
    var onSelectMealScan: (() -> Void)?
    var onSelectWater: (() -> Void)?
    var onSelectExercise: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var waterCount: Int = 0
    @AppStorage("dailyWaterGoal") private var dailyWaterGoal: Int = 8

    // Animation states
    @State private var showContent = false
    @State private var primaryActionsVisible = false
    @State private var quickActionsVisible = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Frosted overlay with subtle gradient
                overlayBackground
                    .onTapGesture {
                        if isPresented {
                            dismissMenu()
                        }
                    }

                VStack {
                    Spacer()

                    // Command panel container
                    commandPanelContent(geometry: geometry)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                animateIn()
            } else {
                resetAnimations()
            }
        }
    }

    // MARK: - Overlay Background

    private var overlayBackground: some View {
        ZStack {
            // Base dim
            Color.black.opacity(isPresented ? 0.5 : 0)

            // Subtle gradient overlay for depth
            if isPresented {
                LinearGradient(
                    colors: [
                        palette.primary.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .opacity(showContent ? 1 : 0)
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.3), value: isPresented)
        .animation(.easeOut(duration: 0.4), value: showContent)
    }

    // MARK: - Command Panel Content

    private func commandPanelContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Handle indicator
            handleIndicator

            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Section label
                    sectionHeader(title: "Quick Actions", icon: "bolt.fill")
                        .opacity(primaryActionsVisible ? 1 : 0)
                        .offset(y: primaryActionsVisible ? 0 : 20)

                    // Primary action tiles - 2x2 grid
                    primaryActionsGrid

                    // Subtle divider
                    dividerLine

                    // Section label for trackers
                    sectionHeader(title: "Quick Trackers", icon: "chart.line.uptrend.xyaxis")
                        .opacity(quickActionsVisible ? 1 : 0)
                        .offset(y: quickActionsVisible ? 0 : 20)

                    // Secondary quick trackers
                    quickTrackersSection
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.sm)
                .padding(.bottom, geometry.safeAreaInsets.bottom + DesignTokens.Spacing.lg)
            }
            .frame(maxHeight: geometry.size.height * 0.55)
        }
        .background(
            panelBackground
        )
        .offset(y: isPresented ? 0 : geometry.size.height)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isPresented)
    }

    // MARK: - Panel Background

    private var panelBackground: some View {
        ZStack {
            // Base frosted glass
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)

            // Subtle gradient tint
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.primary.opacity(0.04),
                            palette.accent.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Top edge highlight
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.6),
                            Color.white.opacity(colorScheme == .dark ? 0.05 : 0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: -10)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Handle Indicator

    private var handleIndicator: some View {
        Capsule()
            .fill(palette.textTertiary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(palette.accent)

            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(palette.textTertiary)
                .tracking(1.2)

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        palette.textTertiary.opacity(0.15),
                        palette.textTertiary.opacity(0.15),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Primary Actions Grid (2x2)

    private var primaryActionsGrid: some View {
        VStack(spacing: 12) {
            // Top row
            HStack(spacing: 12) {
                CommandTile(
                    icon: "magnifyingglass",
                    iconGradient: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.95)],
                    title: "Log Food",
                    subtitle: "Search or add",
                    isVisible: primaryActionsVisible,
                    delay: 0.05
                ) {
                    dismissAndExecute(onSelectDiary)
                }

                CommandTile(
                    icon: "barcode.viewfinder",
                    iconGradient: [Color(red: 0.95, green: 0.4, blue: 0.5), Color(red: 0.9, green: 0.3, blue: 0.45)],
                    title: "Barcode Scan",
                    subtitle: "Quick capture",
                    isVisible: primaryActionsVisible,
                    delay: 0.1
                ) {
                    if let action = onSelectBarcodeScan {
                        dismissAndExecute(action)
                    } else {
                        dismissAndExecute(onSelectDiary)
                    }
                }
            }

            // Bottom row
            HStack(spacing: 12) {
                CommandTile(
                    icon: "refrigerator.fill",
                    iconGradient: [Color(red: 0.95, green: 0.65, blue: 0.3), Color(red: 0.95, green: 0.5, blue: 0.25)],
                    title: "Use By",
                    subtitle: "Track freshness",
                    isVisible: primaryActionsVisible,
                    delay: 0.15
                ) {
                    dismissAndExecute(onSelectUseBy)
                }

                CommandTile(
                    icon: "camera.viewfinder",
                    iconGradient: [Color(red: 0.0, green: 0.7, blue: 0.65), Color(red: 0.0, green: 0.6, blue: 0.55)],
                    title: "Meal Scan",
                    subtitle: "AI recognition",
                    isVisible: primaryActionsVisible,
                    delay: 0.2
                ) {
                    if let action = onSelectMealScan {
                        dismissAndExecute(action)
                    } else {
                        dismissAndExecute(onSelectDiary)
                    }
                }
            }
        }
    }

    // MARK: - Quick Trackers Section

    private var quickTrackersSection: some View {
        VStack(spacing: 0) {
            // Water control - inline stepper style
            waterTrackerRow
                .opacity(quickActionsVisible ? 1 : 0)
                .offset(y: quickActionsVisible ? 0 : 15)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: quickActionsVisible)

            trackerDivider

            // Weight row
            QuickTrackerRow(
                icon: "scalemass.fill",
                iconColor: Color(red: 0.95, green: 0.55, blue: 0.2),
                title: "Weight",
                subtitle: "Log weigh-in",
                isVisible: quickActionsVisible,
                delay: 0.3
            ) {
                dismissAndExecute(onSelectWeighIn)
            }

            trackerDivider

            // Reaction row
            QuickTrackerRow(
                icon: "heart.text.square.fill",
                iconColor: Color(red: 0.9, green: 0.4, blue: 0.5),
                title: "Log Reaction",
                subtitle: "Track symptoms",
                isVisible: quickActionsVisible,
                delay: 0.35
            ) {
                dismissAndExecute(onSelectReaction)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
        .onAppear {
            loadWaterCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .waterUpdated)) { _ in
            loadWaterCount()
        }
    }

    private var trackerDivider: some View {
        Rectangle()
            .fill(palette.textTertiary.opacity(0.1))
            .frame(height: 1)
            .padding(.leading, 56)
    }

    // MARK: - Water Tracker Row

    private var waterTrackerRow: some View {
        HStack(spacing: 12) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.2), Color.cyan.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color(red: 0.2, green: 0.7, blue: 0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Water")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text("\(waterCount) of \(dailyWaterGoal) glasses")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(waterCount >= dailyWaterGoal ? Color.green : palette.textSecondary)
            }

            Spacer()

            // Soft stepper control
            HStack(spacing: 0) {
                // Minus button
                Button(action: removeWater) {
                    ZStack {
                        Circle()
                            .fill(waterCount > 0 ? palette.accent.opacity(0.1) : palette.textTertiary.opacity(0.05))
                            .frame(width: 36, height: 36)

                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(waterCount > 0 ? palette.accent : palette.textTertiary.opacity(0.4))
                    }
                }
                .disabled(waterCount <= 0)

                // Count display
                Text("\(waterCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(waterCount >= dailyWaterGoal ? .green : palette.textPrimary)
                    .frame(width: 36)

                // Plus button
                Button(action: addWater) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.15), Color.cyan.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Animation Functions

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.3)) {
            showContent = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
            primaryActionsVisible = true
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
            quickActionsVisible = true
        }
    }

    private func resetAnimations() {
        showContent = false
        primaryActionsVisible = false
        quickActionsVisible = false
    }

    // MARK: - Water Functions

    private func loadWaterCount() {
        let dateKey = DateHelper.isoDateFormatter.string(from: Date())
        let hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount = hydrationData[dateKey] ?? 0
    }

    private func addWater() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        let dateKey = DateHelper.isoDateFormatter.string(from: Date())
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount += 1
        hydrationData[dateKey] = waterCount
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")
        NotificationCenter.default.post(name: .waterUpdated, object: nil)

        // Celebration haptic if goal reached
        if waterCount == dailyWaterGoal {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
    }

    private func removeWater() {
        guard waterCount > 0 else { return }

        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        let dateKey = DateHelper.isoDateFormatter.string(from: Date())
        var hydrationData = UserDefaults.standard.dictionary(forKey: "hydrationData") as? [String: Int] ?? [:]
        waterCount -= 1
        hydrationData[dateKey] = waterCount
        UserDefaults.standard.set(hydrationData, forKey: "hydrationData")
        NotificationCenter.default.post(name: .waterUpdated, object: nil)
    }

    // MARK: - Menu Actions

    private func dismissMenu() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isPresented = false
        }
    }

    private func dismissAndExecute(_ action: @escaping () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            isPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }
}

// MARK: - Command Tile (Primary Action)

struct CommandTile: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
    let isVisible: Bool
    let delay: Double
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon container with gradient
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(iconGradient.first!.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .blur(radius: 4)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: iconGradient.first!.opacity(0.4), radius: 8, y: 4)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Text stack
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                tileBackground
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: isVisible)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }

    private var tileBackground: some View {
        ZStack {
            // Base glass
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))

            // Subtle gradient overlay
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            iconGradient.first!.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.08)
                        : Color.black.opacity(0.04),
                    lineWidth: 1
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.06),
            radius: 10,
            y: 4
        )
    }
}

// MARK: - Quick Tracker Row

struct QuickTrackerRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isVisible: Bool
    let delay: Double
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with soft gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Subtle chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(palette.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isPressed ? palette.textTertiary.opacity(0.08) : Color.clear)
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: isVisible)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.08)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Legacy Components (Backwards Compatibility)

struct ActionGridButton: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        CommandTile(
            icon: icon,
            iconGradient: [iconColor, iconColor.opacity(0.8)],
            title: label,
            subtitle: "",
            isVisible: true,
            delay: 0,
            action: action
        )
    }
}

struct QuickAccessRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        QuickTrackerRow(
            icon: icon,
            iconColor: iconColor,
            title: label,
            subtitle: "",
            isVisible: true,
            delay: 0,
            action: action
        )
    }
}

struct GridButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color(.systemGray5) : Color.clear)
                    .padding(.horizontal, -8)
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SquareMenuButton: View {
    let icon: String
    let label: String
    let color: Color
    let isPresented: Bool
    let action: () -> Void

    var body: some View {
        ActionGridButton(icon: icon, iconColor: color, label: label, action: action)
    }
}

struct SquareMenuButtonCustomIcon: View {
    let icon: AnyView
    let label: String
    let color: Color
    let isPresented: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                icon.frame(height: 32)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.adaptiveCard))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 0.5))
        }
        .buttonStyle(GridButtonPressStyle())
    }
}

struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Analogue bathroom scale icon matching Salter 145 design
struct BathroomScaleIcon: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.35,
                bottomLeadingRadius: size * 0.15,
                bottomTrailingRadius: size * 0.15,
                topTrailingRadius: size * 0.35
            )
            .fill(color)
            .frame(width: size * 0.85, height: size * 0.85)

            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.48, height: size * 0.48)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.7), lineWidth: 2)
                )
                .offset(y: -size * 0.15)

            Circle()
                .stroke(color.opacity(0.4), lineWidth: 1)
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(y: -size * 0.15)

            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1.5, height: size * 0.15)
                    .offset(y: -size * 0.075)
            }
            .rotationEffect(.degrees(25))
            .offset(y: -size * 0.15)

            Circle()
                .fill(color.opacity(0.6))
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(y: -size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()

        AddActionMenu(
            isPresented: .constant(true),
            onSelectDiary: {},
            onSelectUseBy: {},
            onSelectReaction: {},
            onSelectWeighIn: {}
        )
    }
}
