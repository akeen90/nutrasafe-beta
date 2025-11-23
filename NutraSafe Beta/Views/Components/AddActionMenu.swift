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
            // Darker overlay for focus without blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .opacity(isPresented ? 1 : 0)
                .animation(.easeOut(duration: 0.25), value: isPresented)
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                // Menu container - slides up from bottom with square grid
                VStack(spacing: 16) {
                    // 2x2 Grid of square buttons
                    VStack(spacing: 16) {
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
                                icon: AnyView(BalanceScaleIcon(color: .gray, size: 32)),
                                label: "Weigh In",
                                color: .gray,
                                delay: 0.15,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectWeighIn)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGray5))
                    )
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50) // Position above the + button and tab bar
                .offset(y: isPresented ? 0 : 300) // Slide up from bottom
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isPresented)
            }
        }
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
            VStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(color)
                    .frame(height: 40)

                // Label
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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
            VStack(spacing: 12) {
                // Custom Icon
                icon
                    .frame(height: 40)

                // Label
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

// Custom button style for square buttons
struct SquareButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
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
