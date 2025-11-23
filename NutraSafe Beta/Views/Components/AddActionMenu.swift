//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Floating action buttons for adding items to diary, use by, or logging reactions
//  Modern bottom-slide menu with square grid layout
//

import SwiftUI

struct AddActionMenu: View {
    @Binding var isPresented: Bool
    var onSelectDiary: () -> Void
    var onSelectUseBy: () -> Void
    var onSelectReaction: () -> Void
    var onSelectWeighIn: () -> Void

    var body: some View {
        ZStack {
            // Transparent tap area to dismiss (no dark overlay) - only when presented
            if isPresented {
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }
            }

            VStack {
                Spacer()

                // Menu container - slides up from bottom with square grid
                VStack(spacing: 12) {
                    // 2x2 Grid of square buttons
                    VStack(spacing: 12) {
                        // Top row
                        HStack(spacing: 16) {
                            SquareMenuButton(
                                icon: "fork.knife",
                                label: "Add Food",
                                color: .blue,
                                delay: 0.0,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectDiary)
                            }

                            SquareMenuButton(
                                icon: "heart.fill",
                                label: "Log Reaction",
                                color: .red,
                                delay: 0.05,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectReaction)
                            }
                        }

                        // Bottom row
                        HStack(spacing: 16) {
                            SquareMenuButton(
                                icon: "calendar",
                                label: "Use By",
                                color: .gray,
                                delay: 0.1,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectUseBy)
                            }

                            SquareMenuButtonCustomIcon(
                                icon: AnyView(BathroomScaleIcon(color: .gray, size: 28)),
                                label: "Weigh In",
                                color: .gray,
                                delay: 0.15,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectWeighIn)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray5))
                    )
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50) // Position above the tab bar
                .offset(y: isPresented ? 0 : 500) // Slide up from bottom, fully hidden when dismissed
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isPresented)
            }
        }
        .allowsHitTesting(isPresented) // Disable touch interception when dismissed
    }

    private func dismissAndExecute(_ action: @escaping () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            action()
        }
    }
}

struct SquareMenuButton: View {
    let icon: String
    let label: String
    let color: Color
    let delay: Double
    let isPresented: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundColor(color)
                    .frame(height: 32)

                // Label
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(SquareButtonStyle())
        .scaleEffect(isPresented ? 1 : 0.8)
        .opacity(isPresented ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.75).delay(delay),
            value: isPresented
        )
    }
}

struct SquareMenuButtonCustomIcon: View {
    let icon: AnyView
    let label: String
    let color: Color
    let delay: Double
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
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 0.5))
        }
        .buttonStyle(SquareButtonStyle())
        .scaleEffect(isPresented ? 1 : 0.8)
        .opacity(isPresented ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay), value: isPresented)
    }
}

// Custom button style for square buttons
struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Analogue bathroom scale icon matching Salter 145 design
struct BathroomScaleIcon: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        ZStack {
            // Platform base (rounded top like arch)
            UnevenRoundedRectangle(
                topLeadingRadius: size * 0.35,
                bottomLeadingRadius: size * 0.15,
                bottomTrailingRadius: size * 0.15,
                topTrailingRadius: size * 0.35
            )
            .fill(color)
            .frame(width: size * 0.85, height: size * 0.85)

            // Circular dial at top
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: size * 0.48, height: size * 0.48)
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.7), lineWidth: 2)
                )
                .offset(y: -size * 0.15)

            // Inner dial ring
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 1)
                .frame(width: size * 0.4, height: size * 0.4)
                .offset(y: -size * 0.15)

            // Needle/pointer - positioned to rotate from dial center
            ZStack {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 1.5, height: size * 0.15)
                    .offset(y: -size * 0.075) // Offset half the needle height upward
            }
            .rotationEffect(.degrees(25)) // Rotate the entire ZStack
            .offset(y: -size * 0.15) // Position at dial center

            // Center dot
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
