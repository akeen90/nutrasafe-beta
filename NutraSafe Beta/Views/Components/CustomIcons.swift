//
//  CustomIcons.swift
//  NutraSafe Beta
//
//  Custom icon shapes and components
//

import SwiftUI

/// A custom balance scale icon for weight tracking
struct BalanceScaleIcon: View {
    var color: Color = .gray
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let centerX = width / 2

            // Scale factor for drawing
            let scale = min(width, height) / 100

            // Base platform
            let basePath = Path { path in
                path.move(to: CGPoint(x: centerX - 30 * scale, y: height - 5 * scale))
                path.addLine(to: CGPoint(x: centerX + 30 * scale, y: height - 5 * scale))
                path.addLine(to: CGPoint(x: centerX + 25 * scale, y: height))
                path.addLine(to: CGPoint(x: centerX - 25 * scale, y: height))
                path.closeSubpath()
            }
            context.fill(basePath, with: .color(color))

            // Central pole
            let polePath = Path { path in
                path.move(to: CGPoint(x: centerX - 2.5 * scale, y: height - 5 * scale))
                path.addLine(to: CGPoint(x: centerX + 2.5 * scale, y: height - 5 * scale))
                path.addLine(to: CGPoint(x: centerX + 2 * scale, y: 15 * scale))
                path.addLine(to: CGPoint(x: centerX - 2 * scale, y: 15 * scale))
                path.closeSubpath()
            }
            context.fill(polePath, with: .color(color))

            // Horizontal beam
            let beamPath = Path { path in
                path.move(to: CGPoint(x: centerX - 35 * scale, y: 20 * scale))
                path.addLine(to: CGPoint(x: centerX + 35 * scale, y: 20 * scale))
                path.addLine(to: CGPoint(x: centerX + 35 * scale, y: 23 * scale))
                path.addLine(to: CGPoint(x: centerX - 35 * scale, y: 23 * scale))
                path.closeSubpath()
            }
            context.fill(beamPath, with: .color(color))

            // Left scale pan
            let leftPanPath = Path { path in
                // Chain
                path.move(to: CGPoint(x: centerX - 28 * scale, y: 23 * scale))
                path.addLine(to: CGPoint(x: centerX - 28 * scale, y: 33 * scale))

                // Pan
                path.addArc(
                    center: CGPoint(x: centerX - 28 * scale, y: 40 * scale),
                    radius: 12 * scale,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: centerX - 16 * scale, y: 40 * scale))
                path.addLine(to: CGPoint(x: centerX - 16 * scale, y: 38 * scale))
                path.addLine(to: CGPoint(x: centerX - 40 * scale, y: 38 * scale))
                path.addLine(to: CGPoint(x: centerX - 40 * scale, y: 40 * scale))
                path.closeSubpath()
            }
            context.stroke(leftPanPath, with: .color(color), lineWidth: 1.5 * scale)

            // Right scale pan
            let rightPanPath = Path { path in
                // Chain
                path.move(to: CGPoint(x: centerX + 28 * scale, y: 23 * scale))
                path.addLine(to: CGPoint(x: centerX + 28 * scale, y: 33 * scale))

                // Pan
                path.addArc(
                    center: CGPoint(x: centerX + 28 * scale, y: 40 * scale),
                    radius: 12 * scale,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                path.addLine(to: CGPoint(x: centerX + 40 * scale, y: 40 * scale))
                path.addLine(to: CGPoint(x: centerX + 40 * scale, y: 38 * scale))
                path.addLine(to: CGPoint(x: centerX + 16 * scale, y: 38 * scale))
                path.addLine(to: CGPoint(x: centerX + 16 * scale, y: 40 * scale))
                path.closeSubpath()
            }
            context.stroke(rightPanPath, with: .color(color), lineWidth: 1.5 * scale)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        BalanceScaleIcon(color: .blue, size: 64)
        BalanceScaleIcon(color: .gray, size: 48)
        BalanceScaleIcon(color: .purple, size: 32)
    }
    .padding()
}
