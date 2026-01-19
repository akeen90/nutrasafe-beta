//
//  InferredIngredientsSheet.swift
//  NutraSafe Beta
//
//  UI for viewing and editing AI-inferred ingredients for generic foods
//
//  IMPORTANT DISCLAIMERS (displayed to user):
//  - These ingredients are ESTIMATED and may be incomplete
//  - Some real ingredients may be MISSING
//  - Users can EDIT them if they know more details
//  - This is NOT medical advice
//

import SwiftUI

/// Sheet for viewing and editing AI-inferred ingredients
struct InferredIngredientsSheet: View {
    let foodName: String
    @Binding var inferredIngredients: [InferredIngredient]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var inferenceManager = InferredIngredientManager.shared
    @State private var isLoading = false
    @State private var showAddIngredient = false
    @State private var newIngredientName = ""
    @State private var newInferredIngredientCategory: InferredIngredientCategory = .base
    @State private var removedIngredientIds: Set<String> = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Disclaimer banner
                    disclaimerBanner

                    // Ingredient sections
                    if isLoading {
                        loadingView
                    } else if inferredIngredients.isEmpty {
                        emptyStateView
                    } else {
                        ingredientsList
                    }

                    // Add ingredient button
                    addIngredientButton

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Estimated Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Filter out removed ingredients
                        inferredIngredients = inferredIngredients.filter { !removedIngredientIds.contains($0.id) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAddIngredient) {
                addIngredientSheet
            }
            .task {
                // If no inferred ingredients yet, fetch them
                if inferredIngredients.isEmpty {
                    await fetchInferredIngredients()
                }
            }
        }
    }

    // MARK: - Disclaimer Banner

    private var disclaimerBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Estimated Ingredients")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            Text("These ingredients are **estimated** based on typical UK recipes for \"\(foodName)\". They may be **incomplete** or **incorrect**. Some real ingredients may be **missing**.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("You can edit them below if you know more details.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Estimating likely ingredients...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No ingredients estimated")
                .font(.headline)
            Text("Unable to estimate ingredients for this food. You can add them manually.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Ingredients List

    private var ingredientsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Group by category
            let grouped = Dictionary(grouping: visibleIngredients) { $0.category }

            // Allergens first (if any)
            if let allergens = grouped[.allergen], !allergens.isEmpty {
                ingredientSection(title: "Potential Allergens", icon: "exclamationmark.triangle.fill", color: .red, ingredients: allergens)
            }

            // Base ingredients
            if let base = grouped[.base], !base.isEmpty {
                ingredientSection(title: "Core Ingredients", icon: "leaf.fill", color: .green, ingredients: base)
            }

            // Preparation exposures
            if let prep = grouped[.preparation], !prep.isEmpty {
                ingredientSection(title: "Preparation Exposures", icon: "flame.fill", color: .orange, ingredients: prep)
            }

            // Additives
            if let additives = grouped[.additive], !additives.isEmpty {
                ingredientSection(title: "Possible Additives", icon: "testtube.2", color: .purple, ingredients: additives)
            }

            // Cross-contact risks
            if let crossContact = grouped[.crossContact], !crossContact.isEmpty {
                ingredientSection(title: "Cross-Contact Risks", icon: "arrow.triangle.2.circlepath", color: .blue, ingredients: crossContact)
            }

            // Histamine
            if let histamine = grouped[.histamine], !histamine.isEmpty {
                ingredientSection(title: "Histamine-Related", icon: "clock.fill", color: .yellow, ingredients: histamine)
            }
        }
    }

    private var visibleIngredients: [InferredIngredient] {
        inferredIngredients.filter { !removedIngredientIds.contains($0.id) }
    }

    private func ingredientSection(title: String, icon: String, color: Color, ingredients: [InferredIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }

            ForEach(ingredients) { ingredient in
                ingredientRow(ingredient)
            }
        }
    }

    private func ingredientRow(_ ingredient: InferredIngredient) -> some View {
        HStack(spacing: 12) {
            // Confidence indicator
            confidenceBadge(ingredient.confidence)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(ingredient.name)
                        .font(.body)
                        .fontWeight(.medium)

                    if ingredient.isUserEdited {
                        Text("Confirmed")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green))
                    }
                }

                if let explanation = ingredient.explanation {
                    Text(explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Remove button
            Button(action: {
                withAnimation {
                    _ = removedIngredientIds.insert(ingredient.id)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(white: 1.0, opacity: 0.05) : Color(white: 0.0, opacity: 0.03))
        )
    }

    private func confidenceBadge(_ confidence: InferredIngredientConfidence) -> some View {
        let color: Color = {
            switch confidence {
            case .high: return .green
            case .medium: return .orange
            case .low: return .gray
            }
        }()

        return VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(confidence.displayName)
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(width: 40)
    }

    // MARK: - Add Ingredient Button

    private var addIngredientButton: some View {
        Button(action: {
            showAddIngredient = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Missing Ingredient")
            }
            .font(.body)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }

    // MARK: - Add Ingredient Sheet

    private var addIngredientSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Details")) {
                    TextField("Ingredient name", text: $newIngredientName)

                    Picker("Category", selection: $newInferredIngredientCategory) {
                        ForEach(InferredIngredientCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section(footer: Text("Adding an ingredient marks it as confirmed by you, giving it full weight in pattern analysis.")) {
                    Button("Add Ingredient") {
                        addNewIngredient()
                    }
                    .disabled(newIngredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddIngredient = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func fetchInferredIngredients() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let analysis = try await inferenceManager.inferIngredients(for: foodName)
            inferredIngredients = analysis.allInferredIngredients
        } catch {
            // Handle error silently - user can add manually
            print("Failed to infer ingredients: \(error)")
        }
    }

    private func addNewIngredient() {
        let name = newIngredientName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let newIngredient = InferredIngredient(
            name: name,
            category: newInferredIngredientCategory,
            confidence: .high,  // User-added = high confidence
            source: .userEdited,
            explanation: "Added by you",
            isUserEdited: true
        )

        inferredIngredients.append(newIngredient)
        newIngredientName = ""
        newInferredIngredientCategory = .base
        showAddIngredient = false
    }
}

// MARK: - Preview

#Preview {
    InferredIngredientsSheet(
        foodName: "Sausage",
        inferredIngredients: .constant([
            InferredIngredient.estimated(name: "Pork", category: InferredIngredientCategory.base, confidence: InferredIngredientConfidence.high, explanation: "UK sausages are predominantly pork-based"),
            InferredIngredient.estimated(name: "Salt", category: InferredIngredientCategory.base, confidence: InferredIngredientConfidence.high, explanation: "Essential preservative in all sausages"),
            InferredIngredient.estimated(name: "Wheat/rusk", category: InferredIngredientCategory.allergen, confidence: InferredIngredientConfidence.medium, explanation: "Common filler in UK sausages"),
            InferredIngredient.estimated(name: "Sulphites", category: InferredIngredientCategory.additive, confidence: InferredIngredientConfidence.medium, explanation: "Common preservative in processed meats"),
        ])
    )
}
