//
//  EmptyStateView.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-11-15.
//  Reusable empty state component for improved UX
//

import SwiftUI

/// A visually appealing empty state view that provides helpful guidance to users
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionText: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Icon
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.bottom, 8)

            // Title
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Message
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            // Optional action button
            if let actionText = actionText, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(actionText)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

/// Compact empty state for use within cards or smaller sections
struct CompactEmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview
#Preview("Full Empty State") {
    EmptyStateView(
        icon: "fork.knife",
        title: "No meals logged today",
        message: "Tap the + button to add your first meal and start tracking your nutrition",
        actionText: "Add First Meal",
        action: { print("Add meal tapped") }
    )
}

#Preview("Compact Empty State") {
    CompactEmptyStateView(
        icon: "magnifyingglass",
        message: "No results found. Try a different search term."
    )
}
