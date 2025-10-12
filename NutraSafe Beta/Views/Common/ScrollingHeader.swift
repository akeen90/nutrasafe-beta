import SwiftUI

// Shared scrolling header with consistent style and optional bottom content
struct ScrollingHeader<BottomContent: View, TrailingContent: View>: View {
    let title: String
    let subtitle: String?
    let gradientColors: [Color]
    @ViewBuilder var bottomContent: () -> BottomContent
    @ViewBuilder var trailingContent: () -> TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        gradientColors: [Color] = [
            Color.blue.opacity(0.8),
            Color.purple.opacity(0.7),
            Color.indigo.opacity(0.6)
        ],
        @ViewBuilder bottomContent: @escaping () -> BottomContent,
        @ViewBuilder trailingContent: @escaping () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.gradientColors = gradientColors
        self.bottomContent = bottomContent
        self.trailingContent = trailingContent
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }

                Spacer()

                trailingContent()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            bottomContent()
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.15))
        }
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}