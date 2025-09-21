import SwiftUI

struct DiaryHydrationView: View {
    @State private var waterCount: Int = UserDefaults.standard.integer(forKey: "dailyWaterCount")
    @State private var waterGoal: Int = 8
    @State private var showingAddWater = false
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Text("Hydration Tracker")
                .font(.largeTitle)
                .padding()
            
            Text("\(waterCount) / \(waterGoal) glasses")
                .font(.title2)
                .padding()
            
            Button("Add Water") {
                waterCount += 1
                UserDefaults.standard.set(waterCount, forKey: "dailyWaterCount")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}