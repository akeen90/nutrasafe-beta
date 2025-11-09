//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Floating action buttons for adding items to diary, use by, or logging reactions
//

import SwiftUI

struct AddActionMenu: View {
    @Binding var isPresented: Bool
    var onSelectDiary: () -> Void
    var onSelectUseBy: () -> Void
    var onSelectReaction: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                // Header text
                Text("Where do you want to add?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isPresented ? 1 : 0)
                    .scaleEffect(isPresented ? 1 : 0.9)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: isPresented)
                    .padding(.bottom, 20)

                // Triangle formation of buttons
                VStack(spacing: 20) {
                    // Top button (Diary - center)
                    HStack {
                        Spacer()
                        TriangleFloatingButton(
                            icon: "fork.knife",
                            label: "Diary",
                            color: .blue,
                            delay: 0.0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSelectDiary()
                            }
                        }
                        Spacer()
                    }

                    // Bottom row (Use By left, Reaction right)
                    HStack(spacing: 70) {
                        TriangleFloatingButton(
                            icon: "calendar.badge.clock",
                            label: "Use By",
                            color: .orange,
                            delay: 0.05
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSelectUseBy()
                            }
                        }

                        TriangleFloatingButton(
                            icon: "exclamationmark.triangle.fill",
                            label: "Reaction",
                            color: .red,
                            delay: 0.1
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onSelectReaction()
                            }
                        }
                    }
                }
                .padding(.bottom, 130) // Position just above the + button
            }
        }
        .transition(.opacity)
    }
}

struct TriangleFloatingButton: View {
    let icon: String
    let label: String
    let color: Color
    let delay: Double
    let action: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            // Circular button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: color.opacity(0.5), radius: 12, x: 0, y: 6)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(appeared ? 1 : 0.3)
            .opacity(appeared ? 1 : 0)

            // Label below button
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                appeared = true
            }
        }
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
