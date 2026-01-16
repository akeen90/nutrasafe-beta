//
//  FeatureTipOverlay.swift
//  NutraSafe Beta
//
//  Modern modal overlay for first-time feature tips
//

import SwiftUI

/// Full-screen modal overlay for displaying feature tips
struct FeatureTipOverlay: View {
    let title: String
    let message: String
    let icon: String
    let accentColor: Color
    let bulletPoints: [String]?
    let onDismiss: () -> Void

    @State private var isVisible = false

    init(
        title: String,
        message: String,
        icon: String,
        accentColor: Color,
        bulletPoints: [String]? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.accentColor = accentColor
        self.bulletPoints = bulletPoints
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Tip Card
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 72, height: 72)

                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(accentColor)
                }

                // Title
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Bullet points (if any)
                if let bulletPoints = bulletPoints, !bulletPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(bulletPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(accentColor)
                                    .offset(y: 1)

                                Text(point)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary.opacity(0.85))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor.opacity(0.08))
                    )
                }

                // Got it button
                Button(action: dismiss) {
                    Text("Got it")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.adaptiveCard)
                    .shadow(color: .black.opacity(0.25), radius: 30, y: 15)
            )
            .padding(.horizontal, 28)
            .scaleEffect(isVisible ? 1 : 0.85)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isVisible = true
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Convenience View Modifier

extension View {
    /// Shows a feature tip overlay when the condition is true
    func featureTip(
        isPresented: Binding<Bool>,
        tipKey: FeatureTipsManager.TipKey,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        ZStack {
            self

            if isPresented.wrappedValue,
               let content = FeatureTipsManager.shared.getContent(for: tipKey) {
                FeatureTipOverlay(
                    title: content.title,
                    message: content.message,
                    icon: content.icon,
                    accentColor: content.accentColor,
                    bulletPoints: content.bulletPoints
                ) {
                    FeatureTipsManager.shared.markTipAsSeen(tipKey)
                    isPresented.wrappedValue = false
                    onDismiss()
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.opacity(0.1)
            .ignoresSafeArea()

        FeatureTipOverlay(
            title: "Welcome to Your Food Diary",
            message: "This is where you'll track everything you eat. Tap the + button at any time to add food.",
            icon: "fork.knife.circle.fill",
            accentColor: .blue,
            bulletPoints: [
                "Search our database of thousands of foods",
                "Scan barcodes for instant lookup",
                "Add food manually for custom entries",
                "See daily calories, macros & nutrients"
            ]
        ) {
        }
    }
}
