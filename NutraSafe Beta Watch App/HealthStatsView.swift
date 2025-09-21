import SwiftUI
import HealthKit

struct HealthStatsView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Health Stats")
                        .font(.headline)
                        .padding(.top)
                    
                    // Activity Summary
                    ActivitySummaryCard()
                    
                    // Heart Rate
                    HeartRateCard()
                    
                    // Calorie Balance
                    CalorieBalanceCard()
                    
                    // Weekly Trend (if available)
                    WeeklyTrendCard()
                }
            }
        }
        .onAppear {
            healthKitManager.requestPermissions()
            healthKitManager.startHeartRateQuery()
        }
        .onDisappear {
            healthKitManager.stopHeartRateQuery()
        }
    }
}

struct ActivitySummaryCard: View {
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Activity")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 20) {
                ActivityRing(
                    title: "Steps",
                    value: healthKitManager.todaySteps,
                    target: 10000,
                    color: .green,
                    unit: ""
                )
                
                ActivityRing(
                    title: "Exercise",
                    value: Int(healthKitManager.exerciseCalories),
                    target: 300,
                    color: .orange,
                    unit: "cal"
                )
            }
            
            if let lastUpdate = healthKitManager.lastUpdate {
                Text("Updated: \(lastUpdate, formatter: DateFormatter.timeOnly)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            healthKitManager.fetchTodayActivity()
        }
    }
}

struct ActivityRing: View {
    let title: String
    let value: Int
    let target: Int
    let color: Color
    let unit: String
    
    private var progress: Double {
        min(Double(value) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HeartRateCard: View {
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Heart Rate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let heartRate = healthKitManager.currentHeartRate {
                        Text("\(heartRate) BPM")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        Text("--")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Resting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let restingHR = healthKitManager.restingHeartRate {
                        Text("\(restingHR) BPM")
                            .font(.body)
                            .fontWeight(.medium)
                    } else {
                        Text("--")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let lastHeartRateUpdate = healthKitManager.lastHeartRateUpdate {
                Text("Updated: \(lastHeartRateUpdate, formatter: DateFormatter.timeOnly)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct CalorieBalanceCard: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @StateObject private var healthKitManager = WatchHealthKitManager()
    
    private var calorieBalance: Int {
        let consumed = Int(watchDataManager.nutritionSummary?.totalCalories ?? 0)
        let burned = Int(healthKitManager.exerciseCalories)
        return consumed - burned
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Calorie Balance")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                // Calories In
                VStack {
                    Text("In")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(watchDataManager.nutritionSummary?.totalCalories ?? 0))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                Text("-")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Calories Out
                VStack {
                    Text("Out")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(healthKitManager.exerciseCalories))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                Text("=")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Net Balance
                VStack {
                    Text("Net")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(calorieBalance)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(calorieBalance > 0 ? .green : .red)
                }
            }
            
            Text(calorieBalance > 0 ? "Calorie surplus" : "Calorie deficit")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct WeeklyTrendCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("This Week")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                TrendItem(title: "Avg Grade", value: "B+", color: .blue)
                TrendItem(title: "Foods/Day", value: "12", color: .green)
                TrendItem(title: "Avg Cal", value: "1,850", color: .orange)
            }
            
            Text("Keep up the great work!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TrendItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

class WatchHealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var currentHeartRate: Int?
    @Published var restingHeartRate: Int?
    @Published var todaySteps: Int = 0
    @Published var exerciseCalories: Double = 0
    @Published var lastUpdate: Date?
    @Published var lastHeartRateUpdate: Date?
    
    func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.fetchTodayActivity()
                    self.fetchRestingHeartRate()
                }
            }
        }
    }
    
    func startHeartRateQuery() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            
            guard let samples = samples as? [HKQuantitySample], let lastSample = samples.last else { return }
            
            DispatchQueue.main.async {
                self?.currentHeartRate = Int(lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                self?.lastHeartRateUpdate = lastSample.startDate
            }
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample], let lastSample = samples.last else { return }
            
            DispatchQueue.main.async {
                self?.currentHeartRate = Int(lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                self?.lastHeartRateUpdate = lastSample.startDate
            }
        }
        
        heartRateQuery = query
        healthStore.execute(query)
    }
    
    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
    }
    
    func fetchTodayActivity() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        
        // Fetch steps
        fetchSteps(from: startDate, to: endDate)
        
        // Fetch active calories
        fetchActiveCalories(from: startDate, to: endDate)
    }
    
    private func fetchSteps(from startDate: Date, to endDate: Date) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            
            guard let statistics = statistics, let sum = statistics.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self?.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                self?.lastUpdate = Date()
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories(from startDate: Date, to endDate: Date) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            
            guard let statistics = statistics, let sum = statistics.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self?.exerciseCalories = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate() {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: restingHRType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, samples, error in
            
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            DispatchQueue.main.async {
                self?.restingHeartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            }
        }
        
        healthStore.execute(query)
    }
}

#Preview {
    HealthStatsView()
        .environmentObject(WatchDataManager())
}