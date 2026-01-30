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

    // Drag-to-dismiss state
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    private let dismissThreshold: CGFloat = 120

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
            if !newValue {
                // Reset drag state when closing
                dragOffset = 0
                isDragging = false
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
            }
        }
        .ignoresSafeArea()
        .animation(.easeOut(duration: 0.25), value: isPresented)
    }

    // MARK: - Command Panel Content

    private func commandPanelContent(geometry: GeometryProxy) -> some View {
        Group {
            if isPresented {
                VStack(spacing: 0) {
                    // Handle indicator - also serves as drag affordance
                    handleIndicator

                    // No ScrollView - all content fits without scrolling
                    VStack(spacing: 12) {
                        // Section label
                        sectionHeader(title: "Quick Actions", icon: "bolt.fill")

                        // Primary action tiles - 2x2 grid
                        primaryActionsGrid

                        // Subtle divider
                        dividerLine

                        // Section label for trackers
                        sectionHeader(title: "Quick Trackers", icon: "chart.line.uptrend.xyaxis")

                        // Secondary quick trackers
                        quickTrackersSection
                    }
                    .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                    .padding(.top, 4)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 12)
                }
                .background(panelBackground)
                // Apply drag offset for interactive dismissal
                .offset(y: max(0, dragOffset))
                // Reduce opacity as user drags down for visual feedback
                .opacity(isDragging ? 1.0 - (dragOffset / (dismissThreshold * 3)) : 1.0)
                // Drag gesture for swipe-to-dismiss
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            // Only allow downward drag
                            if value.translation.height > 0 {
                                isDragging = true
                                // Apply resistance as user drags further
                                let resistance: CGFloat = 0.6
                                dragOffset = value.translation.height * resistance
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            let velocity = value.predictedEndTranslation.height - value.translation.height

                            // Dismiss if dragged past threshold or with enough velocity
                            if dragOffset > dismissThreshold || velocity > 500 {
                                // Let the transition handle the exit animation
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    isPresented = false
                                    dragOffset = 0
                                }
                            } else {
                                // Snap back with spring
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                // GPU-accelerated transition for smooth entrance/exit
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    )
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isPresented)
    }

    // MARK: - Panel Background

    private var panelBackground: some View {
        ZStack {
            // Solid opaque background - NO transparency
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark
                    ? Color(red: 0.12, green: 0.12, blue: 0.14)
                    : Color(red: 0.98, green: 0.98, blue: 0.99))

            // Subtle gradient tint for warmth
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            palette.accent.opacity(colorScheme == .dark ? 0.08 : 0.04),
                            palette.primary.opacity(colorScheme == .dark ? 0.04 : 0.02),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Top edge highlight for elevation
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.8),
                            Color.white.opacity(colorScheme == .dark ? 0.04 : 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.2), radius: 30, x: 0, y: -10)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Handle Indicator

    private var handleIndicator: some View {
        Capsule()
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.25)
                : Color.black.opacity(0.15))
            .frame(width: 40, height: 5)
            .padding(.top, 14)
            .padding(.bottom, 10)
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(palette.accent)

            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(palette.textSecondary)
                .tracking(1.5)

            Spacer()
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Divider

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.vertical, 8)
    }

    // MARK: - Primary Actions Grid (2x2)

    private var primaryActionsGrid: some View {
        VStack(spacing: 10) {
            // Top row
            HStack(spacing: 10) {
                CommandTile(
                    icon: "magnifyingglass",
                    iconGradient: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.95)],
                    title: "Log Food",
                    subtitle: "Search or add",
                    isVisible: true,
                    delay: 0
                ) {
                    dismissAndExecute(onSelectDiary)
                }

                CommandTile(
                    icon: "barcode.viewfinder",
                    iconGradient: [Color(red: 0.95, green: 0.4, blue: 0.5), Color(red: 0.9, green: 0.3, blue: 0.45)],
                    title: "Barcode Scan",
                    subtitle: "Quick capture",
                    isVisible: true,
                    delay: 0
                ) {
                    if let action = onSelectBarcodeScan {
                        dismissAndExecute(action)
                    } else {
                        dismissAndExecute(onSelectDiary)
                    }
                }
            }

            // Bottom row
            HStack(spacing: 10) {
                CommandTile(
                    icon: "calendar.badge.clock",
                    iconGradient: [Color(red: 0.95, green: 0.65, blue: 0.3), Color(red: 0.95, green: 0.5, blue: 0.25)],
                    title: "Use By",
                    subtitle: "Track freshness",
                    isVisible: true,
                    delay: 0
                ) {
                    dismissAndExecute(onSelectUseBy)
                }

                CommandTile(
                    icon: "sparkles.rectangle.stack",
                    iconGradient: [Color(red: 0.0, green: 0.7, blue: 0.65), Color(red: 0.0, green: 0.6, blue: 0.55)],
                    title: "Meal Scan",
                    subtitle: "AI recognition",
                    isVisible: true,
                    delay: 0
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

            trackerDivider

            // Weight row
            QuickTrackerRow(
                icon: "figure.stand.scale",
                iconColor: Color(red: 0.95, green: 0.55, blue: 0.2),
                title: "Weight",
                subtitle: "Log weigh-in",
                isVisible: true,
                delay: 0
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
                isVisible: true,
                delay: 0
            ) {
                dismissAndExecute(onSelectReaction)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark
                    ? Color(red: 0.15, green: 0.15, blue: 0.17)
                    : Color(red: 0.96, green: 0.96, blue: 0.97))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.04),
                    lineWidth: 1
                )
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
            .fill(colorScheme == .dark
                ? Color.white.opacity(0.08)
                : Color.black.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 60)
    }

    // MARK: - Water Tracker Row

    private var waterTrackerRow: some View {
        HStack(spacing: 12) {
            // Icon with gradient background - compact
            ZStack {
                // Subtle glow
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .blur(radius: 2)

                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color(red: 0.2, green: 0.7, blue: 0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: Color.cyan.opacity(0.3), radius: 4, y: 2)

                // Custom water drop icon
                WaterDropIcon(size: 18, gradient: [Color.cyan])
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Water")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text("\(waterCount) of \(dailyWaterGoal) glasses")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(waterCount >= dailyWaterGoal ? Color.green : palette.textSecondary)
            }

            Spacer()

            // Compact stepper control
            HStack(spacing: 3) {
                // Minus button
                Button(action: removeWater) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(waterCount > 0 ? 0.1 : 0.04)
                                : Color.black.opacity(waterCount > 0 ? 0.06 : 0.02))
                            .frame(width: 32, height: 32)

                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(waterCount > 0 ? palette.textPrimary : palette.textTertiary.opacity(0.4))
                    }
                }
                .disabled(waterCount <= 0)

                // Count display
                Text("\(waterCount)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(waterCount >= dailyWaterGoal ? .green : palette.textPrimary)
                    .frame(width: 32)

                // Plus button
                Button(action: addWater) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color(red: 0.2, green: 0.7, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.cyan.opacity(0.25), radius: 3, y: 2)

                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

        // Wait for dismiss animation to complete before executing action
        // Spring animation needs more time than response value to fully settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
            VStack(spacing: 8) {
                // Icon container with gradient - compact
                ZStack {
                    // Subtle outer glow
                    Circle()
                        .fill((iconGradient.first ?? .blue).opacity(0.15))
                        .frame(width: 48, height: 48)
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
                        .frame(width: 44, height: 44)
                        .shadow(color: (iconGradient.first ?? .blue).opacity(0.4), radius: 8, y: 4)

                    // Custom bespoke icon based on type
                    customIcon
                }

                // Text stack - tighter
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 98)
            .background(
                tileBackground
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.2).delay(delay), value: isVisible)
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

    // MARK: - Custom Icon Selection

    @ViewBuilder
    private var customIcon: some View {
        let iconSize: CGFloat = 24
        switch icon {
        case "magnifyingglass":
            LogFoodIcon(size: iconSize, gradient: iconGradient)
        case "barcode.viewfinder":
            BarcodeScanIcon(size: iconSize, gradient: iconGradient)
        case "calendar.badge.clock":
            // Clean calendar with exclamation for expiry tracking
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        case "sparkles.rectangle.stack":
            PremiumAIIcon(size: iconSize)
        default:
            // Fallback to SF Symbol with enhanced styling
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private var tileBackground: some View {
        ZStack {
            // Tinted glass card - not pure white, subtle brand tint
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(colorScheme == .dark
                    ? Color(red: 0.16, green: 0.16, blue: 0.18)
                    : Color(red: 0.97, green: 0.97, blue: 0.98))

            // Stronger accent gradient overlay for tinted glass effect
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(
                    LinearGradient(
                        colors: [
                            (iconGradient.first ?? .blue).opacity(colorScheme == .dark ? 0.15 : 0.08),
                            (iconGradient.first ?? .blue).opacity(colorScheme == .dark ? 0.06 : 0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border for definition and separation
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : (iconGradient.first ?? .blue).opacity(0.15),
                    lineWidth: 1
                )
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08),
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
                // Icon with gradient background - compact
                ZStack {
                    // Subtle glow
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                        .blur(radius: 2)

                    // Background circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [iconColor, iconColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: iconColor.opacity(0.3), radius: 4, y: 2)

                    // Custom icon
                    customIcon
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Chevron with better visibility
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isPressed
                        ? (colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                        : Color.clear)
            )
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.2).delay(delay), value: isVisible)
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

    // MARK: - Custom Icon Selection

    @ViewBuilder
    private var customIcon: some View {
        let iconSize: CGFloat = 18
        switch icon {
        case "figure.stand.scale":
            // Clean scale icon for weight tracking
            Image(systemName: "scalemass.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        case "heart.text.square.fill":
            ReactionIcon(size: iconSize, gradient: [iconColor, iconColor.opacity(0.8)])
        default:
            // Fallback to SF Symbol
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
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

// MARK: - Custom NutraSafe Icons

/// Search/Log Food icon - Magnifying glass with leaf accent
struct LogFoodIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Magnifying glass body
            Circle()
                .stroke(
                    LinearGradient(colors: [Color.white, Color.white.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: size * 0.12
                )
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -size * 0.08, y: -size * 0.08)

            // Handle
            Capsule()
                .fill(
                    LinearGradient(colors: [Color.white, Color.white.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: size * 0.12, height: size * 0.32)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.2, y: size * 0.2)

            // Inner accent - small leaf/food hint
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: -size * 0.15, y: -size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

/// Barcode scanner icon - Stylized viewfinder with scan lines
struct BarcodeScanIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Viewfinder corners
            ForEach(0..<4, id: \.self) { index in
                ViewfinderCornerShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                    .frame(width: size * 0.35, height: size * 0.35)
                    .rotationEffect(.degrees(Double(index) * 90))
                    .offset(
                        x: (index == 0 || index == 3) ? -size * 0.18 : size * 0.18,
                        y: (index == 0 || index == 1) ? -size * 0.18 : size * 0.18
                    )
            }

            // Scan lines
            VStack(spacing: size * 0.08) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(Color.white.opacity(0.9 - Double(i) * 0.15))
                        .frame(width: size * 0.35 - CGFloat(i) * size * 0.08, height: size * 0.06)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Viewfinder corner shape for barcode icon
struct ViewfinderCornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: 0))
        return path
    }
}

/// Use By/Expiry icon - Calendar with date marker for tracking expiry
struct UseByCalendarIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Calendar body
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(Color.white)
                .frame(width: size * 0.7, height: size * 0.65)
                .offset(y: size * 0.05)

            // Calendar top bar (binding rings area)
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.7, height: size * 0.18)
                .offset(y: -size * 0.22)

            // Binding rings
            HStack(spacing: size * 0.2) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: size * 0.06, height: size * 0.12)
                }
            }
            .offset(y: -size * 0.28)

            // Date grid dots
            VStack(spacing: size * 0.08) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: size * 0.1) {
                        ForEach(0..<3, id: \.self) { col in
                            Circle()
                                .fill(Color.white.opacity(row == 1 && col == 1 ? 0.9 : 0.4))
                                .frame(width: size * 0.1, height: size * 0.1)
                        }
                    }
                }
            }
            .offset(y: size * 0.12)

            // Exclamation mark for urgency
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: size * 0.28, y: -size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

/// Meal Scan/AI icon - Camera viewfinder with AI sparkles
struct MealScanIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Viewfinder frame
            RoundedRectangle(cornerRadius: size * 0.15)
                .stroke(Color.white, lineWidth: size * 0.06)
                .frame(width: size * 0.65, height: size * 0.65)

            // Corner brackets for viewfinder look
            ForEach(0..<4, id: \.self) { corner in
                ViewfinderBracket()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                    .frame(width: size * 0.2, height: size * 0.2)
                    .rotationEffect(.degrees(Double(corner) * 90))
                    .offset(
                        x: (corner == 0 || corner == 3) ? -size * 0.22 : size * 0.22,
                        y: (corner == 0 || corner == 1) ? -size * 0.22 : size * 0.22
                    )
            }

            // Center target/focus point
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.12, height: size * 0.12)

            // AI sparkles around the viewfinder
            ForEach(0..<3, id: \.self) { i in
                SparkleShape()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(
                        x: size * 0.38 * cos(Double(i) * 2.1 + 0.5),
                        y: size * 0.38 * sin(Double(i) * 2.1 + 0.5)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

/// Viewfinder bracket corner shape
struct ViewfinderBracket: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: 0))
        return path
    }
}

/// AI Sparkle shape - 4-pointed star
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points: [(CGFloat, CGFloat)] = [
            (0.5, 0), (0.65, 0.35), (1, 0.5), (0.65, 0.65),
            (0.5, 1), (0.35, 0.65), (0, 0.5), (0.35, 0.35)
        ]

        path.move(to: CGPoint(x: rect.width * points[0].0, y: rect.height * points[0].1))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: rect.width * point.0, y: rect.height * point.1))
        }
        path.closeSubpath()
        return path
    }
}

/// Water drop icon - Stylized droplet with ripple
struct WaterDropIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Main drop
            WaterDropShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.55, height: size * 0.7)

            // Inner highlight
            WaterDropShape()
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.2, height: size * 0.28)
                .offset(x: -size * 0.08, y: -size * 0.1)

            // Small ripple at bottom
            Ellipse()
                .stroke(Color.white.opacity(0.5), lineWidth: size * 0.02)
                .frame(width: size * 0.35, height: size * 0.1)
                .offset(y: size * 0.35)
        }
        .frame(width: size, height: size)
    }
}

/// Water drop shape
struct WaterDropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.6),
            control1: CGPoint(x: width * 0.5, y: height * 0.1),
            control2: CGPoint(x: width, y: height * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width, y: height * 0.85),
            control2: CGPoint(x: width * 0.75, y: height)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.6),
            control1: CGPoint(x: width * 0.25, y: height),
            control2: CGPoint(x: 0, y: height * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: 0, y: height * 0.35),
            control2: CGPoint(x: width * 0.5, y: height * 0.1)
        )

        return path
    }
}

/// Weight/Scale icon - Modern digital scale design
struct WeightScaleIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Scale platform
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.2,
                bottomLeadingRadius: size * 0.08,
                bottomTrailingRadius: size * 0.08,
                topTrailingRadius: size * 0.2
            )
            .fill(Color.white)
            .frame(width: size * 0.75, height: size * 0.55)
            .offset(y: size * 0.1)

            // Display
            RoundedRectangle(cornerRadius: size * 0.06)
                .fill(Color.white.opacity(0.4))
                .frame(width: size * 0.4, height: size * 0.15)
                .offset(y: -size * 0.05)

            // Display numbers hint
            HStack(spacing: size * 0.03) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: size * 0.01)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: size * 0.08, height: size * 0.08)
                }
            }
            .offset(y: -size * 0.05)

            // Platform surface line
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: size * 0.55, height: size * 0.02)
                .offset(y: size * 0.25)
        }
        .frame(width: size, height: size)
    }
}

/// Body Weight icon - Person silhouette on scale for weigh-in
struct BodyWeightIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Scale base
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(Color.white)
                .frame(width: size * 0.8, height: size * 0.25)
                .offset(y: size * 0.3)

            // Scale display line
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.white.opacity(0.5))
                .frame(width: size * 0.4, height: size * 0.06)
                .offset(y: size * 0.3)

            // Person silhouette - head
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(y: -size * 0.28)

            // Person silhouette - body
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.35)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// Reaction/Health icon - Heart with pulse indicator
struct ReactionIcon: View {
    var size: CGFloat
    var gradient: [Color]

    var body: some View {
        ZStack {
            // Heart shape
            HeartShape()
                .fill(Color.white)
                .frame(width: size * 0.65, height: size * 0.58)
                .offset(y: size * 0.03)

            // Pulse line across heart
            PulseLine()
                .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.5, height: size * 0.2)
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// Heart shape
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.35),
            control1: CGPoint(x: width * 0.15, y: height * 0.75),
            control2: CGPoint(x: 0, y: height * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.15),
            control1: CGPoint(x: 0, y: height * 0.1),
            control2: CGPoint(x: width * 0.35, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.35),
            control1: CGPoint(x: width * 0.65, y: 0),
            control2: CGPoint(x: width, y: height * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width, y: height * 0.55),
            control2: CGPoint(x: width * 0.85, y: height * 0.75)
        )

        return path
    }
}

/// Pulse line shape
struct PulseLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height * 0.5

        path.move(to: CGPoint(x: 0, y: midY))
        path.addLine(to: CGPoint(x: width * 0.25, y: midY))
        path.addLine(to: CGPoint(x: width * 0.35, y: 0))
        path.addLine(to: CGPoint(x: width * 0.45, y: height))
        path.addLine(to: CGPoint(x: width * 0.55, y: midY * 0.5))
        path.addLine(to: CGPoint(x: width * 0.65, y: midY))
        path.addLine(to: CGPoint(x: width, y: midY))

        return path
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

// MARK: - AAA Premium Icons

/// Premium Calendar Icon - Clean, modern calendar for Use By tracking
struct PremiumCalendarIcon: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            // Calendar body with rounded corners
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(Color.white)
                .frame(width: size * 0.78, height: size * 0.72)
                .offset(y: size * 0.06)

            // Top header bar (month area)
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.15,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: size * 0.15
            )
            .fill(Color.white.opacity(0.7))
            .frame(width: size * 0.78, height: size * 0.22)
            .offset(y: -size * 0.19)

            // Calendar rings/binding
            HStack(spacing: size * 0.22) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(Color.white)
                        .frame(width: size * 0.08, height: size * 0.16)
                }
            }
            .offset(y: -size * 0.33)

            // Date grid - 3x2 dots representing dates
            VStack(spacing: size * 0.1) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: size * 0.12) {
                        ForEach(0..<3, id: \.self) { col in
                            RoundedRectangle(cornerRadius: size * 0.02)
                                .fill(Color.white.opacity(row == 1 && col == 1 ? 1.0 : 0.4))
                                .frame(width: size * 0.12, height: size * 0.08)
                        }
                    }
                }
            }
            .offset(y: size * 0.15)

            // Clock badge indicator (urgency/time tracking)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.28, height: size * 0.28)

                // Clock hands
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: size * 0.02, height: size * 0.09)
                    .offset(y: -size * 0.025)

                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: size * 0.02, height: size * 0.06)
                    .rotationEffect(.degrees(90))
                    .offset(x: size * 0.02)
            }
            .offset(x: size * 0.32, y: -size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

/// Premium AI Icon - Modern sparkle design for AI-powered features
struct PremiumAIIcon: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            // Main large sparkle (4-pointed star)
            FourPointStar()
                .fill(Color.white)
                .frame(width: size * 0.55, height: size * 0.55)
                .offset(x: -size * 0.08, y: size * 0.05)

            // Secondary sparkle (top right)
            FourPointStar()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(x: size * 0.24, y: -size * 0.22)

            // Tertiary sparkle (small, bottom)
            FourPointStar()
                .fill(Color.white.opacity(0.6))
                .frame(width: size * 0.18, height: size * 0.18)
                .offset(x: size * 0.28, y: size * 0.2)

            // Tiny accent sparkle
            FourPointStar()
                .fill(Color.white.opacity(0.5))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.3, y: -size * 0.28)
        }
        .frame(width: size, height: size)
    }
}

/// Four-pointed star shape for AI sparkles
struct FourPointStar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.35

        for i in 0..<8 {
            let angle = (Double(i) * .pi / 4) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

/// Premium Bathroom Scale Icon - Classic analogue scale dial design
struct PremiumBathroomScaleIcon: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            // Scale platform base
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.35,
                bottomLeadingRadius: size * 0.12,
                bottomTrailingRadius: size * 0.12,
                topTrailingRadius: size * 0.35
            )
            .fill(Color.white)
            .frame(width: size * 0.9, height: size * 0.75)
            .offset(y: size * 0.08)

            // Dial circle (main display)
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(y: -size * 0.05)

            // Inner dial ring
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: size * 0.02)
                .frame(width: size * 0.38, height: size * 0.38)
                .offset(y: -size * 0.05)

            // Scale tick marks
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: size * 0.015, height: size * 0.06)
                    .offset(y: -size * 0.17)
                    .rotationEffect(.degrees(Double(i) * 45 - 90))
            }
            .offset(y: -size * 0.05)

            // Needle/pointer
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.02, height: size * 0.15)
                .offset(y: -size * 0.05)
                .rotationEffect(.degrees(30))
                .offset(y: -size * 0.05)

            // Center pivot point
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.08, height: size * 0.08)
                .offset(y: -size * 0.05)

            // Platform surface highlight
            RoundedRectangle(cornerRadius: size * 0.02)
                .fill(Color.white.opacity(0.35))
                .frame(width: size * 0.5, height: size * 0.04)
                .offset(y: size * 0.32)
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
