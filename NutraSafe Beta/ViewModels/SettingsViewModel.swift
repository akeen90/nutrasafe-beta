import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var caloricGoal: Int
    @Published var exerciseGoal: Int
    @Published var stepGoal: Int
    @Published var macroGoals: [MacroGoal]

    @AppStorage("cachedCaloricGoal") private var cachedCaloricGoal: Int = 2000
    @AppStorage("cachedExerciseGoal") private var cachedExerciseGoal: Int = 600
    @AppStorage("cachedStepGoal") private var cachedStepGoal: Int = 10000

    init() {
        caloricGoal = cachedCaloricGoal
        exerciseGoal = cachedExerciseGoal
        stepGoal = cachedStepGoal
        macroGoals = MacroGoal.defaultMacros
    }

    func load(firebaseManager: FirebaseManager) async {
        do {
            async let settingsTask = firebaseManager.getUserSettings()
            async let macroTask = firebaseManager.getMacroGoals()
            let settings = try await settingsTask
            let loadedMacroGoals = try await macroTask
            await MainActor.run {
                caloricGoal = settings.caloricGoal ?? cachedCaloricGoal
                exerciseGoal = settings.exerciseGoal ?? cachedExerciseGoal
                stepGoal = settings.stepGoal ?? cachedStepGoal
                macroGoals = loadedMacroGoals
                cachedCaloricGoal = caloricGoal
                cachedExerciseGoal = exerciseGoal
                cachedStepGoal = stepGoal
            }
        } catch {
        }
    }

    func saveCaloricGoal(_ goal: Int, firebaseManager: FirebaseManager) async {
        await MainActor.run { caloricGoal = goal; cachedCaloricGoal = goal }
        try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, caloricGoal: goal)
        await MainActor.run {
            NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
        }
    }

    func saveExerciseGoal(_ goal: Int, firebaseManager: FirebaseManager) async {
        await MainActor.run { exerciseGoal = goal; cachedExerciseGoal = goal }
        try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, exerciseGoal: goal)
        await MainActor.run {
            NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
        }
    }

    func saveStepGoal(_ goal: Int, firebaseManager: FirebaseManager) async {
        await MainActor.run { stepGoal = goal; cachedStepGoal = goal }
        try? await firebaseManager.saveUserSettings(height: nil, goalWeight: nil, stepGoal: goal)
        await MainActor.run {
            NotificationCenter.default.post(name: .nutritionGoalsUpdated, object: nil)
        }
    }
}
