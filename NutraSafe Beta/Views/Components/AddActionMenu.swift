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
            // Subtle dim overlay for focus - only when presented
            if isPresented {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    }
                    .transition(.opacity)
            }

            VStack {
                Spacer()

                // Menu container - smooth slide up from bottom
                VStack(spacing: 12) {
                    // 2x2 Grid of square buttons
                    VStack(spacing: 12) {
                        // Top row
                        HStack(spacing: 16) {
                            SquareMenuButton(
                                icon: "fork.knife",
                                label: "Add Food",
                                color: .blue,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectDiary)
                            }

                            SquareMenuButton(
                                icon: "heart.fill",
                                label: "Log Reaction",
                                color: .red,
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
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectUseBy)
                            }

                            SquareMenuButtonCustomIcon(
                                icon: AnyView(BathroomScaleIcon(color: .gray, size: 28)),
                                label: "Weigh In",
                                color: .gray,
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
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -4)
                    )
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 50) // Position above the tab bar
                .offset(y: isPresented ? 0 : 300)
                .opacity(isPresented ? 1 : 0)
                .animation(.easeOut(duration: 0.28), value: isPresented)
            }
        }
        .allowsHitTesting(isPresented) // Disable touch interception when dismissed
    }

    private func dismissAndExecute(_ action: @escaping () -> Void) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        withAnimation(.easeOut(duration: 0.22)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
        }
    }
}

struct SquareMenuButton: View {
    let icon: String
    let label: String
    let color: Color
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
            .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 0.5))
        }
        .buttonStyle(SquareButtonStyle())
    }
}

// Custom button style for square buttons - smooth press feedback
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
