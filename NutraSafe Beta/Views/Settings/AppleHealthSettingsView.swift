import SwiftUI
import HealthKit

struct AppleHealthSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("healthKitRingsEnabled") private var healthKitRingsEnabled = false
    @State private var isConnected = false
    @State private var isRequestingPermission = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Apple Health Logo & Header
                    VStack(spacing: 16) {
                        // Apple Health styled icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, y: 4)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                        }

                        Text("Apple Health")
                            .font(.system(size: 28, weight: .bold))

                        Text("By linking NutraSafe to Apple Health, you can allow NutraSafe to read your activity, steps, and body measurements, and update your calories.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)

                    // Connect Button
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            await requestHealthKitPermission()
                            isRequestingPermission = false
                        }
                    }) {
                        HStack(spacing: 10) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "plus.app.fill")
                                    .font(.system(size: 18))
                            }
                            Text(isRequestingPermission ? "Connecting..." : "Connect to Apple Health")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppPalette.standard.accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isRequestingPermission)
                    .padding(.horizontal, 24)

                    // What We Read Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Read")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            HealthDataRowStyled(
                                icon: "flame.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Active Energy",
                                description: "Calories burned from physical activity"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRowStyled(
                                icon: "figure.walk",
                                iconColor: .orange,
                                title: "Steps",
                                description: "Daily step count from your activity"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRowStyled(
                                icon: "scalemass.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Body Weight",
                                description: "Your current weight measurements"
                            )
                        }
                        .background(Color.nutraSafeCard)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    }

                    // What We Update Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Update")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        VStack(spacing: 0) {
                            HealthDataRowStyled(
                                icon: "fork.knife",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Calories Consumed",
                                description: "Nutrition data from meals you log"
                            )

                            Divider()
                                .padding(.leading, 56)

                            HealthDataRowStyled(
                                icon: "scalemass.fill",
                                iconColor: Color(red: 1.0, green: 0.23, blue: 0.19),
                                title: "Body Weight",
                                description: "Weight measurements you track"
                            )
                        }
                        .background(Color.nutraSafeCard)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    }

                    // Privacy Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Privacy")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)

                        Text("NutraSafe respects your privacy. You control exactly what data is shared. We never share your health information with third parties.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 8)

                    Spacer().frame(height: 40)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Apple Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkConnectionStatus()
            }
        }
        .navigationViewStyle(.stack)
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

// MARK: - Styled Health Data Row

private struct HealthDataRowStyled: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct AppleHealthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppleHealthSettingsView()
            .environmentObject(HealthKitManager.shared)
    }
}
