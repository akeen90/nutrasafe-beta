//
//  WeightTrackingView.swift
//  NutraSafe Beta
//
//  Simple weight tracking with chart and history
//

import SwiftUI
import HealthKit

struct WeightTrackingView: View {
    @Binding var showingSettings: Bool
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var currentWeight: Double = UserDefaults.standard.double(forKey: "userWeight")
    @State private var goalWeight: Double = UserDefaults.standard.double(forKey: "goalWeight")
    @State private var userHeight: Double = {
        let saved = UserDefaults.standard.double(forKey: "userHeight")
        return saved > 0 ? saved : 175.0 // Default to 175cm if not set
    }()
    @State private var showingAddWeight = false
    @State private var weightHistory: [WeightEntry] = []
    @State private var showingHeightSetup = false

    private var needsHeightSetup: Bool {
        UserDefaults.standard.double(forKey: "userHeight") == 0
    }

    private var currentBMI: Double {
        guard currentWeight > 0, userHeight > 0 else { return 0 }
        let heightInMeters = userHeight / 100
        return currentWeight / (heightInMeters * heightInMeters)
    }

    private var bmiCategory: (String, Color) {
        let bmi = currentBMI
        if bmi < 18.5 {
            return ("Underweight", .orange)
        } else if bmi < 25 {
            return ("Healthy", .green)
        } else if bmi < 30 {
            return ("Overweight", .orange)
        } else {
            return ("Obese", .red)
        }
    }

    private var totalProgress: Double {
        guard goalWeight > 0, let firstEntry = weightHistory.last else { return 0 }
        let startWeight = firstEntry.weight
        let totalToLose = startWeight - goalWeight
        let lostSoFar = startWeight - currentWeight
        return totalToLose != 0 ? (lostSoFar / totalToLose) * 100 : 0
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with circles (like reference app)
                    VStack(spacing: 20) {
                        // Title and Edit
                        HStack {
                            Text("Weight")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: { showingSettings = true }) {
                                Text("Edit")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Icon circles row
                        HStack(spacing: 40) {
                            Button(action: {}) {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Image(systemName: "figure.stand")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white.opacity(0.7))
                                        )
                                    Text("WAIST")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "scalemass.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                                    )
                                Text("WEIGHT")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Button(action: {}) {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 70, height: 70)
                                        .overlay(
                                            Text("BMI")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white.opacity(0.7))
                                        )
                                    Text("BMI")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.6, blue: 0.8), Color(red: 0.15, green: 0.5, blue: 0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // Bar Chart
                    if !weightHistory.isEmpty {
                        WeightBarChart(entries: weightHistory.prefix(10).reversed(), goalWeight: goalWeight, startWeight: weightHistory.last?.weight ?? currentWeight)
                            .frame(height: 280)
                            .padding(.top, 20)
                    }

                    // Weigh-in button
                    Button(action: { showingAddWeight = true }) {
                        HStack {
                            Text("Weigh-in")
                                .font(.system(size: 20, weight: .semibold))
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .cornerRadius(30)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // Stats Grid
                    HStack(spacing: 1) {
                        // Current Weight
                        VStack(spacing: 4) {
                            Text("NOW")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(String(format: "%.3f", currentWeight))
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.8))
                            Text("kg")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)

                        // Goal
                        VStack(spacing: 4) {
                            Text("GOAL")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(goalWeight > 0 ? String(format: "%.1f", goalWeight) : "--")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.green)
                            Text("kg")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }
                    .padding(.top, 30)

                    HStack(spacing: 1) {
                        // Lost so far
                        VStack(spacing: 4) {
                            Text("LOST SO FAR")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            let startWeight = weightHistory.last?.weight ?? currentWeight
                            let lost = max(startWeight - currentWeight, 0)
                            Text(String(format: "%.1f", lost))
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.green)
                            Text("kg")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)

                        // Left to lose
                        VStack(spacing: 4) {
                            Text("LEFT TO LOSE")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            let remaining = goalWeight > 0 ? max(currentWeight - goalWeight, 0) : 0
                            Text(String(format: "%.1f", remaining))
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.red)
                            Text("kg")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }

                }
                .padding(.bottom, 100)
            }
            .background(Color(.systemBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddWeight) {
            AddWeightView(currentWeight: $currentWeight, weightHistory: $weightHistory)
        }
        .sheet(isPresented: $showingHeightSetup) {
            HeightSetupView(userHeight: $userHeight)
        }
        .onAppear {
            loadWeightHistory()
            if needsHeightSetup {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingHeightSetup = true
                }
            }
        }
    }

    private func loadWeightHistory() {
        // Load from UserDefaults for now
        if let data = UserDefaults.standard.data(forKey: "weightHistory"),
           let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            weightHistory = decoded.sorted { $0.date > $1.date }
        }
    }
}

// MARK: - Weight Entry Model
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let weight: Double
    let date: Date
    let bmi: Double?
    let note: String?

    init(id: UUID = UUID(), weight: Double, date: Date = Date(), bmi: Double? = nil, note: String? = nil) {
        self.id = id
        self.weight = weight
        self.date = date
        self.bmi = bmi
        self.note = note
    }
}

// MARK: - History Row
struct WeightHistoryRow: View {
    let entry: WeightEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f kg", entry.weight))
                        .font(.system(size: 17, weight: .semibold))

                    Text(entry.date, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let bmi = entry.bmi {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("BMI")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f", bmi))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Simple Chart
struct SimpleWeightChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double

    private var sortedEntries: [WeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    private var maxWeight: Double {
        max(sortedEntries.map { $0.weight }.max() ?? 0, goalWeight)
    }

    private var minWeight: Double {
        min(sortedEntries.map { $0.weight }.min() ?? 0, goalWeight)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Goal line
                if goalWeight > 0 {
                    let goalY = (1 - (goalWeight - minWeight) / (maxWeight - minWeight)) * geometry.size.height

                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: goalY))
                    }
                    .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                }

                // Weight line
                if sortedEntries.count > 1 {
                    Path { path in
                        for (index, entry) in sortedEntries.enumerated() {
                            let x = (CGFloat(index) / CGFloat(sortedEntries.count - 1)) * geometry.size.width
                            let y = (1 - (entry.weight - minWeight) / (maxWeight - minWeight)) * geometry.size.height

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 3)
                }

                // Data points
                ForEach(sortedEntries.indices, id: \.self) { index in
                    let entry = sortedEntries[index]
                    let x = (CGFloat(index) / CGFloat(max(sortedEntries.count - 1, 1))) * geometry.size.width
                    let y = (1 - (entry.weight - minWeight) / max(maxWeight - minWeight, 1)) * geometry.size.height

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Weight Bar Chart
struct WeightBarChart: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let startWeight: Double

    var body: some View {
        GeometryReader { geometry in
            let maxWeight = max(entries.map { $0.weight }.max() ?? 0, goalWeight, startWeight)
            let minWeight = min(entries.map { $0.weight }.min() ?? 0, goalWeight) - 2
            let range = maxWeight - minWeight

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let height = range > 0 ? ((entry.weight - minWeight) / range) * (geometry.size.height - 60) : 100
                    let isFirst = index == 0
                    let isLast = index == entries.count - 1

                    VStack(spacing: 4) {
                        Spacer()

                        // Weight label
                        Text(String(format: "%.1f", entry.weight))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.primary)

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.6, blue: 0.8), Color(red: 0.15, green: 0.5, blue: 0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: max(height, 20))
                            .overlay(
                                VStack {
                                    if isFirst {
                                        Text("START")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.top, 4)
                                        Spacer()
                                    } else if isLast {
                                        Text("NOW")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.top, 4)
                                        Spacer()
                                    }
                                }
                            )

                        // Date
                        Text(formattedDate(entry.date))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(height: 28)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Goal line
            if goalWeight > 0 && goalWeight >= minWeight && goalWeight <= maxWeight {
                let goalY = (1 - (goalWeight - minWeight) / range) * (geometry.size.height - 60)

                HStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: goalY))
                        path.addLine(to: CGPoint(x: geometry.size.width - 100, y: goalY))
                    }
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .padding(.leading, 16)

                    Text("GOAL")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(6)
                        .offset(y: goalY - 12)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d\nMMM 'yy"
        return formatter.string(from: date)
    }
}

// MARK: - Add Weight View
struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentWeight: Double
    @Binding var weightHistory: [WeightEntry]

    @State private var weight: String = ""
    @State private var note: String = ""
    @State private var date = Date()

    private var calculatedBMI: Double? {
        guard let weightValue = Double(weight) else { return nil }
        let height = UserDefaults.standard.double(forKey: "userHeight")
        guard height > 0 else { return nil }
        let heightInMeters = height / 100
        return weightValue / (heightInMeters * heightInMeters)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 20, weight: .semibold))

                        Text("kg")
                            .foregroundColor(.secondary)
                    }

                    if let bmi = calculatedBMI {
                        HStack {
                            Text("BMI")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }

                Section(header: Text("Date")) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Note (Optional)")) {
                    TextField("Add a note", text: $note)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .disabled(weight.isEmpty || Double(weight) == nil)
                }
            }
        }
    }

    private func saveWeight() {
        guard let weightValue = Double(weight) else { return }

        let entry = WeightEntry(weight: weightValue, date: date, bmi: calculatedBMI, note: note.isEmpty ? nil : note)
        weightHistory.append(entry)
        weightHistory.sort { $0.date > $1.date }

        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(weightHistory) {
            UserDefaults.standard.set(encoded, forKey: "weightHistory")
        }

        // Update current weight
        currentWeight = weightValue
        UserDefaults.standard.set(weightValue, forKey: "userWeight")

        dismiss()
    }
}

// MARK: - Height Setup View
struct HeightSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var userHeight: Double

    @State private var heightCm: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var useMetric: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("What's your height?")
                        .font(.system(size: 28, weight: .bold))

                    Text("We need this to calculate your BMI")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                Picker("Unit", selection: $useMetric) {
                    Text("Metric (cm)").tag(true)
                    Text("Imperial (ft/in)").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                if useMetric {
                    HStack(spacing: 12) {
                        TextField("170", text: $heightCm)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .light, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Text("cm")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 16) {
                        VStack(spacing: 8) {
                            TextField("5", text: $heightFeet)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("feet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        VStack(spacing: 8) {
                            TextField("9", text: $heightInches)
                                .keyboardType(.numberPad)
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)

                            Text("inches")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: saveHeight) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
    }

    private var isValid: Bool {
        if useMetric {
            return Double(heightCm) ?? 0 > 0
        } else {
            return (Double(heightFeet) ?? 0) > 0 || (Double(heightInches) ?? 0) > 0
        }
    }

    private func saveHeight() {
        var heightInCm: Double = 0

        if useMetric {
            heightInCm = Double(heightCm) ?? 0
        } else {
            let feet = Double(heightFeet) ?? 0
            let inches = Double(heightInches) ?? 0
            heightInCm = (feet * 12 + inches) * 2.54
        }

        userHeight = heightInCm
        UserDefaults.standard.set(heightInCm, forKey: "userHeight")
        dismiss()
    }
}
