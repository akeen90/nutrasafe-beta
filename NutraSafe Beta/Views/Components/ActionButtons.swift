//
//  ActionButtons.swift
//  NutraSafe Beta
//
//  Reusable button components - UNIFIED with onboarding design system.
//  NO platform blue. Palette-aware throughout.
//

import SwiftUI

// MARK: - Persistent Bottom Menu
struct PersistentBottomMenu: View {
    let selectedCount: Int
    let onEdit: () -> Void
    let onMove: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header showing selected count
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(palette.textSecondary)
                Text("Actions for \(selectedCount) item\(selectedCount == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                colorScheme == .dark
                    ? Color(white: 0.15)
                    : Color(.systemGray6)
            )

            // Action buttons row
            HStack(spacing: 0) {
                // Cancel
                BottomMenuButton(icon: "xmark", title: "Cancel", color: palette.textPrimary, action: onCancel)

                Divider()
                    .frame(height: 50)

                // Move
                BottomMenuButton(icon: "arrow.up.square", title: "Move", color: .orange, action: onMove)

                Divider()
                    .frame(height: 50)

                // View/Edit (only when 1 item selected)
                if selectedCount == 1 {
                    BottomMenuButton(icon: "pencil", title: "View/Edit", color: .green, action: onEdit)

                    Divider()
                        .frame(height: 50)
                }

                // Copy - use palette accent instead of .blue
                BottomMenuButton(icon: "doc.on.doc", title: "Copy", color: palette.accent, action: onCopy)

                Divider()
                    .frame(height: 50)

                // Delete
                BottomMenuButton(icon: "trash", title: "Delete", color: .red, action: onDelete)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .background(Color.adaptiveCard)
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Bottom Menu Button
struct BottomMenuButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color == .red ? .red : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(BottomMenuButtonStyle())
    }
}

// MARK: - Bottom Menu Button Style
struct BottomMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color(.systemGray5) : Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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

// MARK: - Compact Action Button (Palette-Aware)
struct CompactActionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

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
                    .foregroundColor(isDestructive ? .red : palette.accent)

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

// MARK: - Action Button (Palette-Aware)
struct ActionButton: View {
    let icon: String
    let title: String
    let isDestructive: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

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
                    .foregroundColor(isDestructive ? .red : palette.accent)
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

// MARK: - Unified Floating Action Button (From Design System)
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 56

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.accent, palette.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: palette.accent.opacity(0.35), radius: 12, x: 0, y: 6)

                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(DesignTokens.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Palette-Aware Pill Button
struct PillButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : palette.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [palette.accent, palette.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )
                        .shadow(
                            color: isSelected ? palette.accent.opacity(0.3) : Color.clear,
                            radius: isSelected ? 8 : 0,
                            y: 2
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : palette.textTertiary.opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
