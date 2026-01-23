import SwiftUI
import Charts

// MARK: - Primary Fasting View (Redesigned)
// This is the main entry point for the Fasting tab.
// Design philosophy: Calm, supportive, non-judgemental, user-led.

struct FastingMainView: View {
    @ObservedObject var viewModel: FastingViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Use the redesigned fasting experience
        FastingMainViewRedesigned(viewModel: viewModel)
            .environmentObject(subscriptionManager)
    }
}
