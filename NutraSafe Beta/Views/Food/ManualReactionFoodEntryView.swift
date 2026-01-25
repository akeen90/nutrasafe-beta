import SwiftUI

/// Simple manual food entry for Reactions flow
/// Lets user type a food name and a comma-separated list of ingredients,
/// then returns a `FoodSearchResult` back to the caller.
struct ManualReactionFoodEntryView: View {
    let prefilledName: String
    let onSave: (FoodSearchResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var foodName: String
    @State private var ingredientsText: String = ""

    init(prefilledName: String, onSave: @escaping (FoodSearchResult) -> Void) {
        self.prefilledName = prefilledName
        self.onSave = onSave
        _foodName = State(initialValue: prefilledName.isEmpty ? "" : prefilledName)
    }

    var body: some View {
        Form {
            Section(header: Text("Food")) {
                TextField("Enter food name", text: $foodName)
            }

            Section(header: Text("Ingredients (optional)"), footer: Text("Separate ingredients with commas, e.g. milk, sugar, cocoa")) {
                TextField("milk, sugar, cocoa", text: $ingredientsText)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDismissButton()
        .navigationTitle("Add Manually")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") { dismiss() },
            trailing: Button("Save") {
                let trimmedName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }

                let ingredientsArray: [String]? = {
                    let raw = ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if raw.isEmpty { return nil }
                    let parts = raw
                        .split(separator: ",")
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    return parts.isEmpty ? nil : parts
                }()

                let manualFood = FoodSearchResult(
                    id: UUID().uuidString,
                    name: trimmedName,
                    brand: nil,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0,
                    fiber: 0,
                    sugar: 0,
                    sodium: 0,
                    servingDescription: "Manual entry",
                    ingredients: ingredientsArray,
                    confidence: 1.0,
                    isVerified: false
                )

                onSave(manualFood)
                dismiss()
            }
            .disabled(foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        )
    }
}