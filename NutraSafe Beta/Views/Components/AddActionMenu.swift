//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Floating action buttons for adding items to diary, use by, or logging reactions
//  Modern bottom-slide menu with glass/visionOS styling
//

import SwiftUI

struct AddActionMenu: View {
    @Binding var isPresented: Bool
    var onSelectDiary: () -> Void
    var onSelectUseBy: () -> Void
    var onSelectReaction: () -> Void

    var body: some View {
        ZStack {
            // Blur dimmed background with fade-in
            Color.black.opacity(0.4)
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

                // Menu container - slides up from bottom
                VStack(spacing: 0) {
                    // Header with subtle fade and slide
                    Text("Add to...")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.bottom, 24)
                        .opacity(isPresented ? 1 : 0)
                        .offset(y: isPresented ? 0 : 10)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8).delay(0.1), value: isPresented)

                    // Triangle formation of buttons
                    VStack(spacing: 20) {
                        // Top button (Reaction - center)
                        HStack {
                            Spacer()
                            ModernFloatingButton(
                                icon: "exclamationmark.triangle.fill",
                                label: "Reaction",
                                color: .red,
                                delay: 0.0,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectReaction)
                            }
                            Spacer()
                        }

                        // Bottom row (Diary left, Use By right)
                        HStack(spacing: 70) {
                            ModernFloatingButton(
                                icon: "fork.knife",
                                label: "Diary",
                                color: .blue,
                                delay: 0.05,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectDiary)
                            }

                            ModernFloatingButton(
                                icon: "calendar.badge.clock",
                                label: "Use By",
                                color: .orange,
                                delay: 0.1,
                                isPresented: isPresented
                            ) {
                                dismissAndExecute(onSelectUseBy)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 80) // Position above the + button and tab bar
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

struct ModernFloatingButton: View {
    let icon: String
    let label: String
    let color: Color
    let delay: Double
    let isPresented: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // Glass button with shadow
                ZStack {
                    // Shadow layer
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                        .offset(y: 4)

                    // Main button with gradient and glass effect
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    color.opacity(0.95),
                                    color.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isPresented ? 1 : 0.5)
                .opacity(isPresented ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7).delay(delay),
                    value: isPresented
                )

                // Label
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(isPresented ? 1 : 0)
                    .offset(y: isPresented ? 0 : 5)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.75).delay(delay + 0.05),
                        value: isPresented
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Custom button style for subtle press effect
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    AddActionMenu(
        isPresented: .constant(true),
        onSelectDiary: {},
        onSelectUseBy: {},
        onSelectReaction: {}
    )
}
