import SwiftUI
import WatchConnectivity

struct QuickAddView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @State private var showingAddConfirmation = false
    @State private var selectedFood: WatchQuickFood?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Quick Add")
                        .font(.headline)
                        .padding(.top)
                    
                    if watchDataManager.quickFoods.isEmpty {
                        LoadingQuickFoodsView()
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(watchDataManager.quickFoods) { food in
                                QuickFoodButton(food: food) {
                                    selectedFood = food
                                    showingAddConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                        .padding()
                    
                    // Manual entry button
                    Button(action: {
                        // This would open the iPhone app to manual entry
                        openPhoneApp()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search on Phone")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Barcode scanning button
                    Button(action: {
                        openPhoneAppToScan()
                    }) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Scan Barcode")
                        }
                        .foregroundColor(.green)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .alert("Add Food?", isPresented: $showingAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if let food = selectedFood {
                    addQuickFood(food)
                }
            }
        } message: {
            if let food = selectedFood {
                Text("Add \(food.name) (\(Int(food.calories)) calories) to your diary?")
            }
        }
    }
    
    private func addQuickFood(_ food: WatchQuickFood) {
        connectivityManager.requestQuickAddFood(food.id)
        
        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
    }
    
    private func openPhoneApp() {
        // Send message to iPhone to open the app to search screen
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "openSearch"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to open phone app: \(error.localizedDescription)")
        }
    }
    
    private func openPhoneAppToScan() {
        // Send message to iPhone to open the app to barcode scanner
        guard WCSession.default.isReachable else { return }
        
        let message = ["action": "openScanner"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to open phone scanner: \(error.localizedDescription)")
        }
    }
}

struct QuickFoodButton: View {
    let food: WatchQuickFood
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Grade badge
                Text(food.grade)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(food.gradeColor)
                    .frame(width: 20, height: 20)
                    .background(food.gradeColor.opacity(0.2))
                    .cornerRadius(10)
                
                // Food name
                Text(food.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Calories
                Text("\(Int(food.calories)) cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct LoadingQuickFoodsView: View {
    var body: some View {
        VStack {
            ProgressView()
                .padding()
            Text("Loading quick foods...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    QuickAddView()
        .environmentObject(WatchDataManager())
        .environmentObject(WatchConnectivityManager())
}