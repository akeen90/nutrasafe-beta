import SwiftUI

// MARK: - Diary Segmented Control (Matching Health Tab Style)

struct DiarySegmentedControl<Tab: Hashable & CaseIterable & RawRepresentable>: View where Tab.RawValue == String {
    let tabs: [Tab]
    @Binding var selectedTab: Tab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            selectedTab == tab ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.5, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.secondary, Color.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "diarySegmentedControl", in: animation)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(height: 40)
    }
}
