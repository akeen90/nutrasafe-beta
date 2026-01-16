//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Full-width slide-up action menu inspired by MyFitnessPal
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

    @State private var waterCount: Int = 0
    @AppStorage("dailyWaterGoal") private var dailyWaterGoal: Int = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dim overlay
                Color.black.opacity(isPresented ? 0.4 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if isPresented {
                            dismissMenu()
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: isPresented)

                VStack {
                    Spacer()

                    // Bottom sheet container
                    VStack(spacing: 0) {
                        // Scrollable content
                        ScrollView {
                            VStack(spacing: 16) {
                                // 2x2 Grid - Main actions
                                mainActionsGrid

                                // Divider
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 1)
                                    .padding(.horizontal, 8)

                                // Quick access list
                                quickAccessList
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 34)
                        }
                        .frame(maxHeight: geometry.size.height * 0.5) // Take up to 50% of screen
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.adaptiveCard)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .offset(y: isPresented ? 0 : geometry.size.height)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
    }

    // MARK: - Main Actions Grid (2x2)
    private var mainActionsGrid: some View {
        VStack(spacing: 10) {
            // Top row
            HStack(spacing: 10) {
                ActionGridButton(
                    icon: "magnifyingglass",
                    iconColor: .blue,
                    label: "Log Food"
                ) {
                    dismissAndExecute(onSelectDiary)
                }

                ActionGridButton(
                    icon: "barcode.viewfinder",
                    iconColor: .pink,
                    label: "Barcode Scan"
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
                ActionGridButton(
                    icon: "calendar.badge.plus",
                    iconColor: .orange,
                    label: "Use By"
                ) {
                    dismissAndExecute(onSelectUseBy)
                }

                ActionGridButton(
                    icon: "camera.viewfinder",
                    iconColor: .teal,
                    label: "Meal Scan"
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

    // MARK: - Quick Access List
    private var quickAccessList: some View {
        VStack(spacing: 0) {
            // Water control with +/- buttons
            waterControlRow

            Divider()
                .padding(.leading, 48)

            QuickAccessRow(
                icon: "scalemass.fill",
                iconColor: .orange,
                label: "Weight"
            ) {
                dismissAndExecute(onSelectWeighIn)
            }

            Divider()
                .padding(.leading, 48)

            QuickAccessRow(
                icon: "heart.fill",
                iconColor: .pink,
                label: "Log Reaction"
            ) {
                dismissAndExecute(onSelectReaction)
            }
        }
        .onAppear {
            loadWaterCount()
        }
    }

    // MARK: - Water Control Row
    private var waterControlRow: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.cyan)
            }

            Text("Water")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.primary)

            Spacer()

            // Plus/Minus control with count
            HStack(spacing: 12) {
                // Minus button
                Button(action: removeWater) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(waterCount > 0 ? .red : Color(.systemGray4))
                }
                .disabled(waterCount <= 0)

                // Glass count with measurement
                VStack(spacing: 2) {
                    Text("\(waterCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(waterCount >= dailyWaterGoal ? .green : .primary)
                    Text("of \(dailyWaterGoal)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("(200ml each)")
                        .font(.system(size: 9))
                        .foregroundColor(Color(.systemGray3))
                }
                .frame(minWidth: 60)

                // Plus button
                Button(action: addWater) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding(.vertical, 10)
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

    // MARK: - Actions
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

// MARK: - Action Grid Button (Square card style)
struct ActionGridButton: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.adaptiveCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(GridButtonPressStyle())
    }
}

// MARK: - Quick Access Row
struct QuickAccessRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(label)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(RowPressStyle())
    }
}

// MARK: - Button Styles
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

// Keep legacy components for backwards compatibility
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
    AddActionMenu(
        isPresented: .constant(true),
        onSelectDiary: {},
        onSelectUseBy: {},
        onSelectReaction: {},
        onSelectWeighIn: {}
    )
}
