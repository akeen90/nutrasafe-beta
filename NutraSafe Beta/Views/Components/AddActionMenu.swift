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

                // Floating action buttons - stacked vertically above the + button
                VStack(spacing: 16) {
                    FloatingActionButton(
                        icon: "exclamationmark.triangle.fill",
                        label: "Reaction",
                        color: .red,
                        delay: 0.0
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSelectReaction()
                        }
                    }

                    FloatingActionButton(
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

                    FloatingActionButton(
                        icon: "fork.knife",
                        label: "Diary",
                        color: .blue,
                        delay: 0.1
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onSelectDiary()
                        }
                    }
                }
                .padding(.bottom, 110) // Position above the + button
            }
        }
        .transition(.opacity)
    }
}

struct FloatingActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let delay: Double
    let action: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 12) {
            Spacer()

            // Label
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.75))
                )
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)

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
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(delay)) {
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
