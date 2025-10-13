//
//  ActionButtons.swift
//  NutraSafe Beta
//
//  Reusable button components extracted from ContentView.swift
//

import SwiftUI

// MARK: - Persistent Bottom Menu
struct PersistentBottomMenu: View {
    let selectedCount: Int
    let onEdit: () -> Void
    let onMove: () -> Void
    let onCopy: () -> Void
    let onStar: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Clean, minimal actions that replace nav area
            HStack(spacing: 20) {
                // X button to cancel selection
                SlimActionButton(icon: "xmark", title: "Cancel", color: .secondary, action: onCancel)

                if selectedCount == 1 {
                    SlimActionButton(icon: "pencil", title: "Edit", color: .green, action: onEdit)
                }

                SlimActionButton(icon: "arrow.up.arrow.down", title: "Move", color: .orange, action: onMove)
                SlimActionButton(icon: "doc.on.doc", title: "Copy", color: .blue, action: onCopy)
                SlimActionButton(icon: "star", title: "Star", color: .yellow, action: onStar)
                SlimActionButton(icon: "trash", title: "Delete", color: .red, action: onDelete)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 34) // Account for tab bar and safe area
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Slim Action Button
struct SlimActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(SlimButtonStyle())
    }
}

// MARK: - Slim Button Style
struct SlimButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Premium Action Button
struct PremiumActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PremiumButtonStyle())
    }
}

// MARK: - Premium Button Style
struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Action Button
struct CompactActionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .blue)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)
                    .lineLimit(1)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void
    
    init(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}