//
//  AddActionMenu.swift
//  NutraSafe Beta
//
//  Floating action menu for adding items to diary, use by, or logging reactions
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isPresented = false
                    }
                }

            VStack {
                Spacer()

                // Menu content
                VStack(spacing: 0) {
                    // Menu items
                    AddActionMenuItem(
                        icon: "heart.circle.fill",
                        title: "Add to Diary",
                        subtitle: "Track your meals and nutrition",
                        color: .blue
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSelectDiary()
                        }
                    }

                    Divider()
                        .padding(.leading, 72)

                    AddActionMenuItem(
                        icon: "calendar.circle.fill",
                        title: "Add to Use By",
                        subtitle: "Track food expiry dates",
                        color: .orange
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSelectUseBy()
                        }
                    }

                    Divider()
                        .padding(.leading, 72)

                    AddActionMenuItem(
                        icon: "exclamationmark.triangle.fill",
                        title: "Log a Reaction",
                        subtitle: "Record food sensitivities",
                        color: .red
                    ) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSelectReaction()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Space above tab bar
            }
        }
        .transition(.opacity)
    }
}

struct AddActionMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color(.systemBackground)
                    .opacity(isPressed ? 0.5 : 1.0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
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
