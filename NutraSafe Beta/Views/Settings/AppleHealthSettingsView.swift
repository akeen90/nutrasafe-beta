import SwiftUI
import HealthKit

struct AppleHealthSettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false
    @State private var isConnected = false
    @State private var isRequestingPermission = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Apple Health Logo & Header
                VStack(spacing: 16) {
                    // Apple Health Logo
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolRenderingMode(.palette)

                    Text("Apple Health")
                        .font(.system(size: 28, weight: .bold))

                    Text("Connect to sync your exercise and move calories with NutraSafe")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                // Connection Status Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: isConnected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(isConnected ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(isConnected ? "Connected" : "Not Connected")
                                .font(.system(size: 18, weight: .semibold))

                            Text(isConnected ? "Syncing exercise calories" : "Tap below to connect")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Connect Button
                if !isConnected {
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            await requestHealthKitPermission()
                            isRequestingPermission = false
                        }
                    }) {
                        HStack {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            }
                            Text(isRequestingPermission ? "Connecting..." : "Connect to Apple Health")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppPalette.standard.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal)
                } else {
                    // Manage in Health App Button
                    Button(action: {
                        openHealthApp()
                    }) {
                        HStack {
                            Image(systemName: "heart.text.square")
                            Text("Manage in Apple Health")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundColor(AppPalette.standard.accent)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // What We Access Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("What We Access")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        HealthDataRow(
                            icon: "figure.run",
                            title: "Exercise Minutes",
                            description: "Active energy burned during workouts"
                        )

                        Divider()
                            .padding(.leading, 52)

                        HealthDataRow(
                            icon: "flame.fill",
                            title: "Active Energy",
                            description: "Calories burned from physical activity"
                        )
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top, 8)

                // Privacy Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.horizontal)

                    Text("NutraSafe only reads exercise data to enhance your fasting rings. We never write data to Apple Health or share your health information with third parties.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.adaptiveBackground.ignoresSafeArea())
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkConnectionStatus()
        }
    }

    private func requestHealthKitPermission() async {
        await healthKitManager.requestAuthorization()
        healthKitRingsEnabled = true
        await healthKitManager.updateExerciseCalories()
        checkConnectionStatus()
    }

    private func checkConnectionStatus() {
        let healthStore = HKHealthStore()
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!

        let authStatus = healthStore.authorizationStatus(for: exerciseType)
        isConnected = (authStatus == .sharingAuthorized) && healthKitRingsEnabled
    }

    private func openHealthApp() {
        if let url = URL(string: "x-apple-health://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Health Data Row

struct HealthDataRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct AppleHealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AppleHealthSettingsView()
                .environmentObject(HealthKitManager.shared)
        }
    }
}
