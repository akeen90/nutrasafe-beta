import SwiftUI

struct FridgeSearchSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var query: String = ""
    @State private var isSearching = false
    @State private var results: [FoodSearchResult] = []
    @State private var selectedFood: FoodSearchResult?
    @State private var showAddForm = false
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search products (e.g. Heinz Beans)", text: $query)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .onSubmit { Task { await runSearch() } }
                    if !query.isEmpty {
                        Button(action: { query = ""; results = [] }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .onChange(of: query) { newValue in
                    // Debounce search-as-you-type
                    searchTask?.cancel()
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.count >= 2 else { self.results = []; return }
                    searchTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                        await runSearch()
                    }
                }

                if isSearching {
                    ProgressView("Searching…")
                        .padding()
                }

List(results, id: \.id) { food in
                    Button {
                        selectedFood = food
                        showAddForm = true
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
Text(food.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .multilineTextAlignment(.leading)
                                if let brand = food.brand {
                                    Text(brand)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                if let serving = food.servingDescription {
                                    Text(serving)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Search Database")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Search") { Task { await runSearch() } }
                        .disabled(query.trimmingCharacters(in: .whitespaces).count < 2)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            if let selectedFood = selectedFood {
                // Go straight to the Fridge expiry form (not the diary-style food page)
                AddFoundFoodToFridgeSheet(food: selectedFood)
            }
        }
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }
        isSearching = true
        do {
            let foods = try await FirebaseManager.shared.searchFoods(query: trimmed)
            await MainActor.run {
                self.results = foods
                self.isSearching = false
            }
        } catch {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == -999 {
                // cancelled due to new keystroke
                return
            }
            print("Fridge search error: \(error)")
            await MainActor.run { self.isSearching = false }
        }
    }
}

private struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color
    init(_ label: String, _ value: Double, _ color: Color) { self.label = label; self.value = value; self.color = color }
    var body: some View {
        Text("\(label) \(Int(value))g")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

struct AddFoundFoodToFridgeSheet: View {
    @Environment(\.dismiss) var dismiss
    let food: FoodSearchResult
    @State private var quantity: String = "1"
    @State private var location: String = "Fridge"
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSaving = false
    private let locations = ["Fridge", "Freezer", "Pantry", "Cupboard", "Counter"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item")) {
                    Text(food.name)
                    if let brand = food.brand { Text(brand).foregroundColor(.secondary) }
                    if let serving = food.servingDescription { Text(serving).foregroundColor(.secondary) }
                }
                Section(header: Text("Details")) {
                    TextField("Quantity", text: $quantity).keyboardType(.default)
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add to Fridge")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: { isSaving ? AnyView(ProgressView()) : AnyView(Text("Add")) }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        let item = FridgeInventoryItem(
            name: food.name,
            brand: food.brand,
            quantity: quantity.isEmpty ? "1" : quantity,
            location: location,
            expiryDate: expiryDate,
            addedDate: Date(),
            barcode: nil,
            category: nil
        )
        do {
            try await FirebaseManager.shared.addFridgeItem(item)
            await MainActor.run { dismiss() }
        } catch {
            let ns = error as NSError
            print("Failed to save fridge item: \(ns)\nAttempting dev anonymous sign-in if enabled…")
            if ns.domain == "NutraSafeAuth", AppConfig.Features.allowAnonymousAuth {
                do {
                    try await FirebaseManager.shared.signInAnonymously()
                    try await FirebaseManager.shared.addFridgeItem(item)
                    await MainActor.run { dismiss() }
                    return
                } catch {
                    // fall through to final error handling
                }
            }
            let finalError = error as NSError
            print("Final error saving fridge item: \(finalError)")
            await MainActor.run {
                // Silently fail for permission errors - just close the sheet
                if finalError.domain == "FIRFirestoreErrorDomain" && finalError.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .fridgeInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToFridge, object: nil)
                    dismiss()
                } else {
                    isSaving = false
                }
            }
        }
    }
}
