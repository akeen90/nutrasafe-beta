//
//  Sheets.swift
//  NutraSafe Database Manager
//
//  Sheet views for various operations
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - New Food Sheet

struct NewFoodSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @StateObject private var offService = OpenFoodFactsService.shared

    @State private var food = FoodItem()
    @State private var ingredientsText = ""
    @State private var isSaving = false
    @State private var isLookingUpBarcode = false
    @State private var barcodeInput = ""
    @State private var lookupMessage: String?

    // Check if barcode input looks like a valid barcode
    private var barcodeInputIsValid: Bool {
        let trimmed = barcodeInput.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 8 && trimmed.count <= 14 && trimmed.allSatisfy { $0.isNumber }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Food Item")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    Task {
                        await saveFood()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(food.name.isEmpty || isSaving)
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Barcode Lookup Section
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(.orange)
                                Text("Quick Add by Barcode")
                                    .font(.headline)
                                Spacer()
                            }

                            HStack {
                                TextField("Enter barcode number...", text: $barcodeInput)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        if barcodeInputIsValid {
                                            Task { await lookupBarcode() }
                                        }
                                    }

                                Button {
                                    Task { await lookupBarcode() }
                                } label: {
                                    HStack(spacing: 4) {
                                        if isLookingUpBarcode {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        } else {
                                            Image(systemName: "magnifyingglass")
                                        }
                                        Text("Lookup")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .disabled(!barcodeInputIsValid || isLookingUpBarcode)
                            }

                            if let message = lookupMessage {
                                HStack {
                                    Image(systemName: message.contains("Found") ? "checkmark.circle.fill" : "info.circle")
                                        .foregroundColor(message.contains("Found") ? .green : .secondary)
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(message.contains("Found") ? .green : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        EmptyView()
                    }

                    // Basic Info
                    GroupBox("Basic Information") {
                        VStack(spacing: 12) {
                            TextField("Food Name *", text: $food.name)
                                .textFieldStyle(.roundedBorder)

                            HStack {
                                TextField("Brand (optional)", text: Binding(
                                    get: { food.brand ?? "" },
                                    set: { food.brand = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)

                                HStack {
                                    TextField("Barcode", text: Binding(
                                        get: { food.barcode ?? "" },
                                        set: { food.barcode = $0.isEmpty ? nil : $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    if food.barcode != nil && !food.barcode!.isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Nutrition
                    GroupBox("Nutrition (per 100g)") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NutritionInput(label: "Calories (kcal)", value: $food.calories)
                            NutritionInput(label: "Protein (g)", value: $food.protein)
                            NutritionInput(label: "Carbs (g)", value: $food.carbs)
                            NutritionInput(label: "Fat (g)", value: $food.fat)
                            NutritionInput(label: "Fiber (g)", value: $food.fiber)
                            NutritionInput(label: "Sugar (g)", value: $food.sugar)
                            NutritionInput(label: "Salt (g)", value: Binding(
                                get: { food.sodium / 400 }, // Convert sodium mg to salt g
                                set: { food.sodium = $0 * 400 } // Convert salt g back to sodium mg
                            ))
                        }
                        .padding(.vertical, 8)
                    }

                    // Serving Info
                    GroupBox("Serving Information") {
                        HStack {
                            TextField("Serving Description (e.g., '1 slice (30g)')", text: Binding(
                                get: { food.servingDescription ?? "" },
                                set: { food.servingDescription = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)

                            TextField("Size (g)", value: $food.servingSizeG, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)

                            Toggle("Per Unit", isOn: Binding(
                                get: { food.isPerUnit ?? false },
                                set: { food.isPerUnit = $0 }
                            ))
                        }
                        .padding(.vertical, 8)
                    }

                    // Ingredients
                    GroupBox("Ingredients") {
                        VStack(alignment: .leading) {
                            TextEditor(text: $ingredientsText)
                                .frame(height: 80)
                                .padding(4)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(6)

                            Text("Separate ingredients with commas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Source
                    GroupBox("Source") {
                        HStack {
                            TextField("Source (e.g., 'Manual Entry')", text: Binding(
                                get: { food.source ?? "Manual Entry" },
                                set: { food.source = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)

                            Toggle("Verified", isOn: Binding(
                                get: { food.isVerified ?? false },
                                set: { food.isVerified = $0 }
                            ))
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
    }

    private func saveFood() async {
        isSaving = true

        // Parse ingredients
        food.ingredients = ingredientsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Set defaults
        if food.source == nil {
            food.source = "Manual Entry"
        }
        food.lastUpdated = ISO8601DateFormatter().string(from: Date())

        let success = await algoliaService.saveFood(food, database: appState.selectedDatabase)

        if success {
            algoliaService.foods.insert(food, at: 0)
            dismiss()
        }

        isSaving = false
    }

    /// Look up barcode in Open Food Facts and populate the form
    private func lookupBarcode() async {
        let barcode = barcodeInput.trimmingCharacters(in: .whitespaces)
        isLookingUpBarcode = true
        lookupMessage = nil

        // Look up in Open Food Facts
        if let offProduct = await offService.lookupProduct(barcode: barcode) {
            // Populate the food item from OFF data
            food.barcode = barcode
            food.name = offProduct.product_name_en ?? offProduct.product_name ?? ""
            food.brand = offProduct.brands
            food.source = "Open Food Facts"

            // Nutrition
            if let nutriments = offProduct.nutriments {
                food.calories = nutriments.energy_kcal_100g ?? nutriments.energy_kcal ?? 0
                food.protein = nutriments.proteins_100g ?? nutriments.proteins ?? 0
                food.carbs = nutriments.carbohydrates_100g ?? nutriments.carbohydrates ?? 0
                food.fat = nutriments.fat_100g ?? nutriments.fat ?? 0
                food.fiber = nutriments.fiber_100g ?? nutriments.fiber ?? 0
                food.sugar = nutriments.sugars_100g ?? nutriments.sugars ?? 0
                food.sodium = (nutriments.sodium_100g ?? nutriments.sodium ?? 0) * 1000 // Convert to mg
                food.saturatedFat = nutriments.saturated_fat_100g ?? nutriments.saturated_fat
            }

            // Ingredients
            if let offIngredientsText = offProduct.ingredients_text_en ?? offProduct.ingredients_text {
                ingredientsText = offIngredientsText
                food.ingredientsText = offIngredientsText
            }

            // Serving size
            if let servingSize = offProduct.serving_size {
                food.servingDescription = servingSize
            }

            // Images
            if let imageURL = offProduct.image_front_url ?? offProduct.image_url {
                food.imageURL = imageURL
            }

            lookupMessage = "Found: \(food.name)"
        } else {
            lookupMessage = "No product found for barcode \(barcode)"
            // Still set the barcode so user can enter details manually
            food.barcode = barcode
        }

        isLookingUpBarcode = false
    }
}

struct NutritionInput: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Import Sheet

struct ImportSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedURL: URL?
    @State private var isImporting = false
    @State private var result: ImportResult?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Import Foods")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }

            // Content
            if let result = result {
                // Results view
                VStack(spacing: 16) {
                    Image(systemName: result.failureCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(result.failureCount == 0 ? .green : .orange)

                    Text("Import Complete")
                        .font(.headline)

                    HStack(spacing: 30) {
                        VStack {
                            Text("\(result.successCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("Imported")
                                .font(.caption)
                        }

                        VStack {
                            Text("\(result.failureCount)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                            Text("Failed")
                                .font(.caption)
                        }
                    }

                    if !result.errors.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(result.errors, id: \.self) { error in
                                    Text("• \(error)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .frame(maxHeight: 100)
                    }

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if isImporting {
                ProgressView("Importing...")
                    .padding()
            } else {
                // File selection
                VStack(spacing: 16) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Select a JSON or CSV file to import")
                        .foregroundColor(.secondary)

                    Text("Target: \(appState.selectedDatabase.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Choose File...") {
                        selectFile()
                    }
                    .buttonStyle(.borderedProminent)

                    if let url = selectedURL {
                        HStack {
                            Image(systemName: "doc.fill")
                            Text(url.lastPathComponent)
                            Spacer()
                            Button("Import") {
                                Task {
                                    await importFile()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 450, height: 350)
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, UTType(filenameExtension: "csv")!]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedURL = panel.url
        }
    }

    private func importFile() async {
        guard let url = selectedURL else { return }
        isImporting = true
        result = await algoliaService.importFoods(from: url, database: appState.selectedDatabase)
        isImporting = false
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var format: ExportFormat = .json
    @State private var exportSelection: ExportSelection = .selected
    @State private var isExporting = false
    @State private var exportComplete = false

    enum ExportSelection: String, CaseIterable {
        case selected = "Selected Foods"
        case all = "All Loaded Foods"
        case download = "Download Entire Database"
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Export Foods")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }

            if exportComplete {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Export Complete!")
                        .font(.headline)
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if isExporting {
                VStack(spacing: 16) {
                    ProgressView("Exporting...")
                    Text("This may take a moment for large datasets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Options
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("What to Export") {
                        Picker("Selection", selection: $exportSelection) {
                            ForEach(ExportSelection.allCases, id: \.self) { selection in
                                Text(selection.rawValue).tag(selection)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .padding(.vertical, 8)

                        if exportSelection == .selected {
                            Text("\(appState.selectedFoodIDs.count) foods selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if exportSelection == .all {
                            Text("\(algoliaService.foods.count) foods loaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    GroupBox("Format") {
                        Picker("Format", selection: $format) {
                            ForEach(ExportFormat.allCases, id: \.self) { fmt in
                                Text(fmt.rawValue).tag(fmt)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .padding(.vertical, 8)
                    }

                    HStack {
                        Spacer()
                        Button("Export...") {
                            Task {
                                await exportFoods()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(exportSelection == .selected && appState.selectedFoodIDs.isEmpty)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }

    private func exportFoods() async {
        isExporting = true

        let foodsToExport: [FoodItem]

        switch exportSelection {
        case .selected:
            foodsToExport = algoliaService.foods.filter { appState.selectedFoodIDs.contains($0.objectID) }
        case .all:
            foodsToExport = algoliaService.foods
        case .download:
            foodsToExport = await algoliaService.downloadAllFoods(database: appState.selectedDatabase)
        }

        // Show save panel
        let panel = NSSavePanel()
        panel.allowedContentTypes = [format == .json ? .json : UTType(filenameExtension: "csv")!]
        panel.nameFieldStringValue = "foods_export.\(format.fileExtension)"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try algoliaService.exportFoods(foodsToExport, format: format, to: url)
                exportComplete = true
            } catch {
                algoliaService.error = "Export failed: \(error.localizedDescription)"
            }
        }

        isExporting = false
    }
}

// MARK: - Bulk Edit Sheet

struct BulkEditSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var selectedField: BulkEditOperation.Field = .brand
    @State private var value = ""
    @State private var isProcessing = false
    @State private var result: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Bulk Edit")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }

            Text("Editing \(appState.selectedFoodIDs.count) foods")
                .foregroundColor(.secondary)

            if let result = result {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text(result)
                        .font(.headline)
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if isProcessing {
                ProgressView("Updating \(appState.selectedFoodIDs.count) foods...")
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Field to Update") {
                        Picker("Field", selection: $selectedField) {
                            ForEach(BulkEditOperation.Field.allCases, id: \.self) { field in
                                Text(field.rawValue).tag(field)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.vertical, 8)
                    }

                    GroupBox("New Value") {
                        if selectedField == .isVerified {
                            Picker("Value", selection: $value) {
                                Text("True").tag("true")
                                Text("False").tag("false")
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 8)
                        } else {
                            TextField(placeholderForField(selectedField), text: $value)
                                .textFieldStyle(.roundedBorder)
                                .padding(.vertical, 8)
                        }
                    }

                    HStack {
                        Spacer()
                        Button("Apply") {
                            Task {
                                await applyBulkEdit()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(value.isEmpty)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }

    private func placeholderForField(_ field: BulkEditOperation.Field) -> String {
        switch field {
        case .brand: return "Enter brand name"
        case .source: return "Enter source"
        case .processingGrade: return "Enter grade (A+, A, B, etc.)"
        case .isVerified: return ""
        case .category: return "Enter category"
        case .addTag: return "Enter tag to add"
        case .removeTag: return "Enter tag to remove"
        }
    }

    private func applyBulkEdit() async {
        isProcessing = true

        let operation = BulkEditOperation(field: selectedField, value: value)
        let success = await algoliaService.bulkUpdateFoods(
            Array(appState.selectedFoodIDs),
            operation: operation,
            database: appState.selectedDatabase
        )

        if success {
            result = "Successfully updated \(appState.selectedFoodIDs.count) foods"
        } else {
            result = "Update failed: \(algoliaService.error ?? "Unknown error")"
        }

        isProcessing = false
    }
}

// MARK: - Claude Chat Sheet

struct ClaudeChatSheet: View {
    @EnvironmentObject var claudeService: ClaudeService
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @Environment(\.dismiss) var dismiss

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Claude AI Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if !claudeService.messages.isEmpty {
                    Button("Clear") {
                        claudeService.clearConversation()
                    }
                    .buttonStyle(.borderless)
                }

                Button("Close") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if claudeService.messages.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48))
                                    .foregroundColor(.purple.opacity(0.5))

                                Text("Ask Claude about your food database")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 8) {
                                    SuggestionButton(text: "Find foods with missing ingredients", action: {
                                        inputText = "Find foods in my database that are missing ingredients data"
                                    })
                                    SuggestionButton(text: "Check for data quality issues", action: {
                                        inputText = "What are common data quality issues I should look for in my food database?"
                                    })
                                    SuggestionButton(text: "Help me fix nutrition values", action: {
                                        inputText = "How can I identify foods with implausible nutrition values?"
                                    })
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }

                        ForEach(claudeService.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if claudeService.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Claude is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: claudeService.messages.count) { _, _ in
                    if let lastMessage = claudeService.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Input
            HStack(spacing: 12) {
                TextField("Ask Claude...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onSubmit {
                        if !inputText.isEmpty && !claudeService.isProcessing {
                            sendMessage()
                        }
                    }

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty || claudeService.isProcessing)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .onAppear {
            isInputFocused = true
        }
    }

    private func sendMessage() {
        let text = inputText
        inputText = ""

        let context = DatabaseContext(
            database: appState.selectedDatabase,
            totalRecords: algoliaService.totalHits,
            selectedCount: appState.selectedFoodIDs.isEmpty ? nil : appState.selectedFoodIDs.count,
            currentFood: appState.currentFood
        )

        Task {
            await claudeService.sendMessage(text, context: context)
        }
    }
}

struct SuggestionButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .foregroundColor(.purple)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Claude Batch Review Sheet

struct ClaudeBatchReviewSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService
    @EnvironmentObject var reviewManager: ReviewManager
    @Environment(\.dismiss) var dismiss

    enum ReviewPhase {
        case setup
        case processing
        case showingIssues
        case applyingBulk
        case complete
    }

    @State private var phase: ReviewPhase = .setup
    @State private var currentFoodIndex = 0
    @State private var foodsToReview: [FoodItem] = []
    @State private var reviewStats = ReviewSessionStats()
    @State private var batchSize = 100
    @State private var isLoading = false
    @State private var flaggedFoods: [FlaggedFood] = []
    @State private var currentFoodName = ""
    @State private var autoMode = true
    @State private var verifyOnline = true
    @State private var fetchImages = true
    @State private var bulkProgress: BulkOperationProgress?
    @State private var errorMessage: String?

    private let ukService = UKRetailerService.shared
    private let offService = OpenFoodFactsService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Claude Auto-Review")
                    .font(.headline)

                Spacer()

                if case .processing = phase {
                    Button {
                        claudeService.cancelCurrentOperation()
                        phase = flaggedFoods.isEmpty ? .complete : .showingIssues
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                if case .applyingBulk = phase {
                    // Show cancel during bulk operations
                    Button {
                        bulkProgress?.isCancelled = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("Cancel")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                Button("Done") { dismiss() }
                    .disabled(phase == .processing || phase == .applyingBulk)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Error banner
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") {
                        errorMessage = nil
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
            }

            // Content based on phase
            switch phase {
            case .setup:
                AutoSetupView(
                    batchSize: $batchSize,
                    verifyOnline: $verifyOnline,
                    fetchImages: $fetchImages,
                    totalUnreviewed: reviewManager.reviewStats.remaining,
                    onStart: startAutoReview
                )

            case .processing:
                ProcessingView(
                    currentIndex: currentFoodIndex,
                    totalCount: foodsToReview.count,
                    currentFoodName: currentFoodName,
                    stats: reviewStats
                )

            case .showingIssues:
                IssuesListViewExpanded(
                    flaggedFoods: $flaggedFoods,
                    stats: reviewStats,
                    onDismissIssue: dismissIssue,
                    onDeleteFood: deleteFood,
                    onApplyFix: applyUKData,
                    onApplyAllSuggestions: applyAllClaudeSuggestions,
                    onContinue: { phase = .complete }
                )

            case .applyingBulk:
                BulkOperationProgressView(progress: bulkProgress ?? BulkOperationProgress())

            case .complete:
                AutoCompleteView(stats: reviewStats, flaggedCount: flaggedFoods.count, onDone: { dismiss() })
            }

            // Progress footer during processing
            if case .processing = phase {
                Divider()
                AutoProgressFooter(
                    approved: reviewStats.reviewed,
                    flagged: reviewStats.flagged,
                    current: currentFoodIndex,
                    total: foodsToReview.count
                )
            }
        }
        .frame(minWidth: 1000, idealWidth: 1200, maxWidth: .infinity, minHeight: 700, idealHeight: 900, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func startAutoReview() {
        phase = .processing
        isLoading = true
        flaggedFoods = []
        reviewStats = ReviewSessionStats()
        errorMessage = nil

        Task {
            do {
                // Get unreviewed foods
                await algoliaService.extendedSearch(query: "", database: appState.selectedDatabase, maxResults: batchSize)

                // Filter to only unreviewed
                foodsToReview = algoliaService.foods.filter { !reviewManager.isReviewed($0.objectID) }
                foodsToReview = Array(foodsToReview.prefix(batchSize))

                if foodsToReview.isEmpty {
                    await MainActor.run { phase = .complete }
                    return
                }

                currentFoodIndex = 0

                // Process foods in batches for efficiency
                await processFoodsBatch()
            } catch {
                await MainActor.run {
                    errorMessage = "Review failed: \(error.localizedDescription)"
                    phase = flaggedFoods.isEmpty ? .setup : .showingIssues
                }
            }
        }
    }

    private func processFoodsBatch() async {
        // Process foods in small batches to reduce API calls
        let batchChunkSize = 5
        var currentBatch: [FoodItem] = []

        for i in currentFoodIndex..<foodsToReview.count {
            // Check if cancelled
            if claudeService.isCancelled {
                break
            }

            await MainActor.run {
                currentFoodIndex = i
                let food = foodsToReview[i]
                currentFoodName = "\(food.brand ?? "") \(food.name)".trimmingCharacters(in: .whitespaces)
            }

            let food = foodsToReview[i]
            currentBatch.append(food)

            // Process when batch is full or at end
            if currentBatch.count >= batchChunkSize || i == foodsToReview.count - 1 {
                await analyzeBatch(currentBatch)
                currentBatch = []
                claudeService.clearConversation()
            }
        }

        // Show issues if any, otherwise complete
        await MainActor.run {
            if flaggedFoods.isEmpty {
                phase = .complete
            } else {
                phase = .showingIssues
            }
        }
    }

    private func applyAllClaudeSuggestions() {
        phase = .applyingBulk
        bulkProgress = BulkOperationProgress()

        Task {
            let toProcess = flaggedFoods
            let total = toProcess.count

            await MainActor.run {
                bulkProgress?.total = total
                bulkProgress?.currentOperation = "Processing Claude suggestions..."
            }

            var successCount = 0
            var failCount = 0

            for (index, flagged) in toProcess.enumerated() {
                // Check for cancellation
                if bulkProgress?.isCancelled == true {
                    await MainActor.run {
                        bulkProgress?.currentOperation = "Cancelled"
                    }
                    break
                }

                await MainActor.run {
                    bulkProgress?.completed = index
                    bulkProgress?.currentItem = flagged.food.name
                }

                // Determine action based on Claude's suggestion
                let issue = flagged.issue.uppercased()

                do {
                    if issue.contains("DELETE") {
                        // Delete the food
                        let success = await algoliaService.deleteFood(objectID: flagged.food.objectID, database: appState.selectedDatabase)
                        if success {
                            await MainActor.run {
                                reviewManager.markAsReviewed(flagged.food.objectID)
                                reviewStats.deleted += 1
                            }
                            successCount += 1
                        } else {
                            failCount += 1
                        }
                    } else if let ukData = flagged.ukData {
                        // Apply UK fix
                        var updatedFood = flagged.food
                        updatedFood.applyUKData(ukData)
                        let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                        if success {
                            await MainActor.run {
                                reviewManager.markAsReviewed(updatedFood.objectID)
                                reviewStats.fixed += 1
                            }
                            successCount += 1
                        } else {
                            failCount += 1
                        }
                    } else {
                        // Just approve (keep as-is)
                        await MainActor.run {
                            reviewManager.markAsReviewed(flagged.food.objectID)
                            reviewStats.reviewed += 1
                        }
                        successCount += 1
                    }
                } catch {
                    failCount += 1
                    await MainActor.run {
                        bulkProgress?.errors.append("\(flagged.food.name): \(error.localizedDescription)")
                    }
                }

                // Small delay to prevent overwhelming the API
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }

            await MainActor.run {
                bulkProgress?.completed = total
                bulkProgress?.currentOperation = "Complete! \(successCount) succeeded, \(failCount) failed"
                flaggedFoods.removeAll()

                // Return to complete phase after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    phase = .complete
                }
            }
        }
    }

    private func analyzeBatch(_ foods: [FoodItem]) async {
        // First, verify against UK retailers (Tesco, Sainsbury's, etc.)
        var ukVerifications: [String: UKVerificationResult] = [:]
        var ukProducts: [String: UKProductData] = [:]

        if verifyOnline {
            for food in foods {
                if let barcode = food.barcode, !barcode.isEmpty {
                    // Try UK retailers ONLY (Tesco, Sainsbury's etc have professional white background images)
                    // DO NOT fall back to Open Food Facts - their images are user-submitted and low quality
                    let ukResult = await ukService.verifyAgainstUKData(food: food)
                    ukVerifications[food.objectID] = ukResult
                    if let ukData = ukResult.ukData {
                        // Only use UK retailer data - has professional images
                        ukProducts[food.objectID] = ukData
                    }
                    // Note: We intentionally do NOT fall back to Open Food Facts
                    // OFF images are user-submitted and not professional quality
                    // For verification only (no images), could use OFF but we skip it
                }
            }
        }

        // Build batch analysis prompt with UK context and verification data
        var foodDescriptions = ""
        for (index, food) in foods.enumerated() {
            var verificationInfo = ""
            if let ukResult = ukVerifications[food.objectID] {
                verificationInfo = """

                UK Retailer Verification: \(ukResult.verified ? "VERIFIED" : "DISCREPANCIES FOUND")
                Source: \(ukResult.ukData?.source.rawValue ?? "Not found")
                """
                if !ukResult.discrepancies.isEmpty {
                    verificationInfo += "\nIssues: " + ukResult.discrepancies.map { "\($0.field): ours=\($0.ourValue) vs UK=\($0.ukValue)" }.joined(separator: "; ")
                }
            } else if let ukData = ukProducts[food.objectID] {
                verificationInfo = "\nUK Data Available: Yes (from \(ukData.source.rawValue))"
            }

            // Build serving info string
            var servingInfo = "per 100g"
            if food.isPerUnit == true {
                servingInfo = "PER UNIT"
                if let servingG = food.servingSizeG, servingG > 0 {
                    servingInfo += " (\(Int(servingG))g)"
                }
                if let desc = food.servingDescription, !desc.isEmpty {
                    servingInfo += " - \(desc)"
                }
            } else if let servingG = food.servingSizeG, servingG > 0 {
                servingInfo = "per 100g (typical serving: \(Int(servingG))g)"
            }

            foodDescriptions += """

            FOOD \(index + 1) [ID: \(food.objectID)]:
            Name: \(food.name)
            Brand: \(food.brand ?? "None")
            Barcode: \(food.barcode ?? "None")
            Nutrition Format: \(servingInfo)
            Calories: \(food.calories) kcal | Protein: \(food.protein)g | Carbs: \(food.carbs)g | Fat: \(food.fat)g
            Fibre: \(food.fiber)g | Sugar: \(food.sugar)g | Salt: \(String(format: "%.2f", food.sodium / 400))g
            Ingredients: \(food.ingredients?.joined(separator: ", ") ?? "None")
            Source: \(food.source ?? "Unknown")
            Verified: \(food.isVerified ?? false)\(verificationInfo)

            """
        }

        let prompt = """
        You are reviewing a UK food database. Analyse these \(foods.count) foods for data quality issues.
        Use British English spellings (fibre, colour, flavour, etc.) and UK nutrition standards.
        \(verifyOnline ? "I've included UK retailer verification data where available (from Tesco, Sainsbury's, etc.) - use this to validate the entries." : "")

        IMPORTANT - NUTRITION FORMAT:
        - "per 100g" foods: Nutrition is standardised per 100 grams (most foods)
        - "PER UNIT" foods: Nutrition is for ONE UNIT/SERVING (e.g., Big Mac, single egg, one biscuit)
          For per-unit foods, expect higher calories (a Big Mac is ~500kcal, a chocolate bar ~250kcal)
          These are NOT errors - they are intentionally stored as per-serving for convenience

        For each food, respond with EXACTLY this format:
        FOOD [number]: [APPROVE/FLAG/DELETE] - [brief reason if flagged/deleted]

        APPROVE if:
        - Nutrition values look reasonable for the food type AND format (per-100g OR per-unit)
        - Has ingredients OR is a simple whole food (e.g., "Apple", "Chicken Breast")
        - Name and brand make sense
        - UK retailer verification shows match (if available)
        - Per-unit foods like fast food items, snacks, ready meals have sensible per-serving values

        FLAG if:
        - Nutrition values seem wrong for the format (e.g., 0 calories for caloric food)
        - UK retailer data shows significant discrepancies
        - Missing critical data for a processed food
        - Name contains obvious errors or is unclear
        - Per-unit food missing serving size information

        DELETE if:
        - Clearly junk/test data
        - Completely empty or nonsensical
        - Obvious duplicate with worse data

        Foods to review:
        \(foodDescriptions)

        Respond with one line per food, nothing else.
        """

        claudeService.currentStatus = "Analysing batch of \(foods.count) foods..."

        await claudeService.sendMessage(prompt, context: DatabaseContext(
            database: appState.selectedDatabase,
            totalRecords: algoliaService.totalHits,
            selectedCount: nil,
            currentFood: nil
        ))

        // Parse response and take actions
        if let lastMessage = claudeService.messages.last, lastMessage.role == .assistant {
            let lines = lastMessage.content.components(separatedBy: "\n")

            for (index, food) in foods.enumerated() {
                // Find the line for this food
                let foodLine = lines.first { $0.contains("FOOD \(index + 1):") || $0.contains("FOOD\(index + 1):") } ?? ""
                let upperLine = foodLine.uppercased()

                let ukData = ukProducts[food.objectID]

                if upperLine.contains("APPROVE") {
                    // If we have UK data and fetchImages is enabled, update with professional image
                    if fetchImages, let ukProd = ukData, ukProd.hasImage, food.imageURL == nil || food.imageURL?.isEmpty == true {
                        var updatedFood = food
                        updatedFood.imageURL = ukProd.imageURL
                        updatedFood.thumbnailURL = ukProd.thumbnailURL ?? ukProd.imageURL
                        _ = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                        await MainActor.run { reviewStats.imagesAdded += 1 }
                    }
                    reviewManager.markAsReviewed(food.objectID)
                    await MainActor.run { reviewStats.reviewed += 1 }
                } else if upperLine.contains("DELETE") {
                    let reason = extractReason(from: foodLine)
                    let flagged = FlaggedFood(
                        food: food,
                        issue: "DELETE: \(reason)",
                        ukData: ukData,
                        suggestedAction: .delete
                    )
                    await MainActor.run {
                        flaggedFoods.append(flagged)
                        reviewStats.flagged += 1
                    }
                } else if upperLine.contains("FLAG") {
                    let reason = extractReason(from: foodLine)
                    reviewManager.markAsFlagged(food.objectID, reason: reason)

                    // Determine suggested action:
                    // 1. If UK data available, suggest applying it
                    // 2. If no brand AND not a generic food, suggest delete (likely junk data)
                    // 3. Otherwise, suggest approve
                    let suggestedAction: FlaggedFood.SuggestedAction
                    if ukData != nil {
                        suggestedAction = .applyUKFix
                    } else if (food.brand == nil || food.brand?.isEmpty == true) && !isGenericFood(food) {
                        suggestedAction = .delete
                    } else {
                        suggestedAction = .approve
                    }

                    let flagged = FlaggedFood(
                        food: food,
                        issue: reason,
                        ukData: ukData,
                        suggestedAction: suggestedAction
                    )
                    await MainActor.run {
                        flaggedFoods.append(flagged)
                        reviewStats.flagged += 1
                    }
                } else {
                    // Default to approve if unclear
                    reviewManager.markAsReviewed(food.objectID)
                    await MainActor.run { reviewStats.reviewed += 1 }
                }
            }
        } else {
            // If API failed, just mark as reviewed to avoid getting stuck
            for food in foods {
                reviewManager.markAsReviewed(food.objectID)
                await MainActor.run { reviewStats.reviewed += 1 }
            }
        }
    }

    /// Check if a food item is a generic/whole food (doesn't need a brand)
    private func isGenericFood(_ food: FoodItem) -> Bool {
        let name = food.name.lowercased()

        // Common whole foods and generic items that don't need brands
        let genericPatterns = [
            // Fruits
            "apple", "banana", "orange", "grape", "strawberr", "blueberr", "raspberr", "blackberr",
            "mango", "pineapple", "watermelon", "melon", "peach", "pear", "plum", "cherry", "kiwi",
            "lemon", "lime", "grapefruit", "avocado", "coconut", "fig", "date", "raisin", "prune",
            // Vegetables
            "carrot", "broccoli", "cauliflower", "spinach", "lettuce", "kale", "cabbage", "celery",
            "cucumber", "tomato", "potato", "sweet potato", "onion", "garlic", "pepper", "courgette",
            "zucchini", "aubergine", "eggplant", "mushroom", "corn", "pea", "bean", "lentil",
            "asparagus", "artichoke", "beetroot", "turnip", "parsnip", "swede", "leek", "radish",
            // Proteins
            "chicken breast", "chicken thigh", "chicken leg", "chicken wing", "turkey", "duck",
            "beef", "steak", "mince", "ground beef", "lamb", "pork", "bacon", "ham", "sausage",
            "salmon", "tuna", "cod", "haddock", "mackerel", "sardine", "prawn", "shrimp", "crab",
            "lobster", "mussel", "oyster", "squid", "egg", "eggs",
            // Dairy basics
            "milk", "cream", "butter", "cheese", "yogurt", "yoghurt",
            // Grains/Staples
            "rice", "pasta", "bread", "flour", "oat", "wheat", "barley", "quinoa", "couscous",
            // Nuts and seeds
            "almond", "walnut", "cashew", "peanut", "pistachio", "hazelnut", "pecan", "macadamia",
            "sunflower seed", "pumpkin seed", "chia seed", "flax seed", "sesame",
            // Herbs and spices
            "basil", "oregano", "thyme", "rosemary", "parsley", "cilantro", "coriander", "mint",
            "dill", "sage", "bay leaf", "cumin", "paprika", "turmeric", "ginger", "cinnamon",
            // Other generics
            "water", "honey", "sugar", "salt", "oil", "olive oil", "vinegar", "soy sauce",
            "tofu", "tempeh", "seitan"
        ]

        // Check if food name contains any generic pattern
        for pattern in genericPatterns {
            if name.contains(pattern) {
                return true
            }
        }

        // Also consider very short names (likely generic) or names that are just the food itself
        let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count <= 2 {
            // Short names like "Apple" or "Chicken Breast" are likely generic
            return true
        }

        return false
    }

    private func extractReason(from line: String) -> String {
        if let dashIndex = line.firstIndex(of: "-") {
            let reason = String(line[line.index(after: dashIndex)...]).trimmingCharacters(in: .whitespaces)
            return reason.isEmpty ? "Needs review" : reason
        }
        return "Needs review"
    }

    private func dismissIssue(at index: Int) {
        guard index >= 0, index < flaggedFoods.count else { return }
        let food = flaggedFoods[index].food
        reviewManager.markAsReviewed(food.objectID)
        flaggedFoods.remove(at: index)
        reviewStats.reviewed += 1
        reviewStats.flagged -= 1
    }

    private func deleteFood(at index: Int) {
        guard index >= 0, index < flaggedFoods.count else { return }
        let food = flaggedFoods[index].food

        Task {
            let success = await algoliaService.deleteFood(objectID: food.objectID, database: appState.selectedDatabase)
            await MainActor.run {
                if success {
                    reviewManager.markAsReviewed(food.objectID)
                    if index < flaggedFoods.count {
                        flaggedFoods.remove(at: index)
                    }
                    reviewStats.deleted += 1
                    reviewStats.flagged -= 1
                } else {
                    errorMessage = "Failed to delete: \(food.name)"
                }
            }
        }
    }

    private func applyUKData(at index: Int) {
        guard index >= 0, index < flaggedFoods.count else { return }
        let item = flaggedFoods[index]
        guard let ukData = item.ukData else { return }

        var updatedFood = item.food

        // Apply UK retailer data (nutrition, ingredients, images)
        updatedFood.applyUKData(ukData)

        Task {
            let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
            await MainActor.run {
                if success {
                    reviewManager.markAsReviewed(updatedFood.objectID)
                    if index < flaggedFoods.count {
                        flaggedFoods.remove(at: index)
                    }
                    reviewStats.reviewed += 1
                    reviewStats.flagged -= 1
                    reviewStats.fixed += 1
                } else {
                    errorMessage = "Failed to save: \(updatedFood.name)"
                }
            }
        }
    }
}

// MARK: - Flagged Food Model

struct FlaggedFood: Identifiable {
    let id = UUID()
    let food: FoodItem
    let issue: String
    let ukData: UKProductData?
    var suggestedAction: SuggestedAction

    enum SuggestedAction: String {
        case approve = "Approve"
        case delete = "Delete"
        case applyUKFix = "Apply UK Fix"

        var icon: String {
            switch self {
            case .approve: return "checkmark.circle"
            case .delete: return "trash"
            case .applyUKFix: return "wand.and.stars"
            }
        }

        var color: Color {
            switch self {
            case .approve: return .green
            case .delete: return .red
            case .applyUKFix: return .blue
            }
        }
    }
}

// MARK: - Bulk Operation Progress

class BulkOperationProgress: ObservableObject {
    @Published var total: Int = 0
    @Published var completed: Int = 0
    @Published var currentOperation: String = ""
    @Published var currentItem: String = ""
    @Published var errors: [String] = []
    @Published var isCancelled: Bool = false

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

struct BulkOperationProgressView: View {
    @ObservedObject var progress: BulkOperationProgress

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated progress circle
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)

                Circle()
                    .trim(from: 0, to: progress.progress)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress.completed)

                VStack {
                    Text("\(Int(progress.progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(progress.completed)/\(progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(progress.currentOperation)
                .font(.headline)

            if !progress.currentItem.isEmpty {
                Text(progress.currentItem)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: progress.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 400)

                HStack {
                    Text("Processing item \(progress.completed + 1) of \(progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    if !progress.errors.isEmpty {
                        Text("\(progress.errors.count) errors")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .frame(maxWidth: 400)
            }

            // Error list
            if !progress.errors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(progress.errors.prefix(10), id: \.self) { error in
                            Text("• \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        if progress.errors.count > 10 {
                            Text("... and \(progress.errors.count - 10) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: 400, maxHeight: 100)
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Auto Review Supporting Views

struct AutoSetupView: View {
    @Binding var batchSize: Int
    @Binding var verifyOnline: Bool
    @Binding var fetchImages: Bool
    let totalUnreviewed: Int
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 64))
                .foregroundColor(.purple)

            Text("Claude Auto-Review")
                .font(.title)
                .fontWeight(.bold)

            Text("Claude will automatically review your foods, approve good entries, and flag issues for you to check.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 450)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Auto-approves foods with valid data")
                }
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("Flags foods with issues for your review")
                }
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                    Text("Verifies against Open Food Facts online database")
                }
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.purple)
                    Text("Auto-fetches product images when available")
                }
                HStack {
                    Image(systemName: "globe.europe.africa")
                        .foregroundColor(.teal)
                    Text("Uses UK standards and spellings")
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)

            VStack(spacing: 12) {
                HStack {
                    Text("Foods to review:")
                    Spacer()
                    Text("\(totalUnreviewed) unreviewed")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Batch size:")
                    Spacer()
                    Picker("", selection: $batchSize) {
                        Text("50").tag(50)
                        Text("100").tag(100)
                        Text("250").tag(250)
                        Text("500").tag(500)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                Divider()

                Toggle(isOn: $verifyOnline) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                        Text("Verify ingredients online")
                    }
                }

                Toggle(isOn: $fetchImages) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(.purple)
                        Text("Auto-fetch product images")
                    }
                }
                .disabled(!verifyOnline)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
            .frame(maxWidth: 400)

            Button {
                onStart()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Auto-Review")
                }
                .frame(width: 220)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(totalUnreviewed == 0)

            Spacer()
        }
        .padding()
    }
}

struct ProcessingView: View {
    let currentIndex: Int
    let totalCount: Int
    let currentFoodName: String
    let stats: ReviewSessionStats

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Animated progress
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: totalCount > 0 ? Double(currentIndex) / Double(totalCount) : 0)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: currentIndex)

                VStack {
                    Text("\(Int((Double(currentIndex) / Double(max(totalCount, 1))) * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(currentIndex)/\(totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Reviewing foods...")
                .font(.title2)
                .fontWeight(.medium)

            Text(currentFoodName)
                .font(.headline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 400)

            // Live stats
            HStack(spacing: 40) {
                VStack {
                    Text("\(stats.reviewed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Approved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(stats.flagged)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Flagged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Expanded Issues List View (Full Nutrition Data Visible)

struct IssuesListViewExpanded: View {
    @Binding var flaggedFoods: [FlaggedFood]
    let stats: ReviewSessionStats
    let onDismissIssue: (Int) -> Void
    let onDeleteFood: (Int) -> Void
    let onApplyFix: (Int) -> Void
    let onApplyAllSuggestions: () -> Void
    let onContinue: () -> Void

    @State private var selectedIndices: Set<Int> = []
    @State private var showingDetailFor: Int? = nil
    @State private var sortOrder: SortOrder = .issue

    enum SortOrder: String, CaseIterable {
        case issue = "Issue"
        case name = "Name"
        case calories = "Calories"
        case action = "Action"
    }

    var sortedFoods: [(index: Int, flagged: FlaggedFood)] {
        let indexed = flaggedFoods.enumerated().map { ($0.offset, $0.element) }
        switch sortOrder {
        case .issue:
            return indexed.sorted { $0.1.issue < $1.1.issue }
        case .name:
            return indexed.sorted { $0.1.food.name < $1.1.food.name }
        case .calories:
            return indexed.sorted { $0.1.food.calories > $1.1.food.calories }
        case .action:
            return indexed.sorted { $0.1.suggestedAction.rawValue < $1.1.suggestedAction.rawValue }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with stats and bulk actions
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("\(flaggedFoods.count) Issues to Review")
                        .font(.headline)

                    Spacer()

                    // Stats
                    HStack(spacing: 16) {
                        Label("\(stats.reviewed)", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                        Label("\(stats.deleted)", systemImage: "trash")
                            .foregroundColor(.red)
                        Label("\(stats.fixed)", systemImage: "wand.and.stars")
                            .foregroundColor(.blue)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.orange.opacity(0.1))

                // Toolbar with bulk actions
                HStack(spacing: 12) {
                    // Select all / deselect
                    Button {
                        if selectedIndices.count == flaggedFoods.count {
                            selectedIndices.removeAll()
                        } else {
                            selectedIndices = Set(0..<flaggedFoods.count)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: selectedIndices.count == flaggedFoods.count ? "checkmark.square.fill" : "square")
                            Text(selectedIndices.count == flaggedFoods.count ? "Deselect All" : "Select All")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)

                    if !selectedIndices.isEmpty {
                        Text("\(selectedIndices.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider().frame(height: 16)

                        Button { bulkApprove() } label: {
                            Label("Approve", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)

                        if selectedIndices.contains(where: { flaggedFoods[safe: $0]?.ukData != nil }) {
                            Button { bulkApplyFix() } label: {
                                Label("Apply UK Fix", systemImage: "wand.and.stars")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }

                        Button { bulkDelete() } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Sort picker
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)

                    Divider().frame(height: 16)

                    // Apply All button
                    Button {
                        onApplyAllSuggestions()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Apply All Suggestions")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
            }

            // Issues list with full nutrition data - horizontal and vertical scroll
            if flaggedFoods.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("All issues resolved!")
                        .font(.headline)
                    Spacer()
                }
            } else {
                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 0) {
                        // Column headers inside scroll view
                        FlaggedFoodTableHeader()
                        Divider()

                        LazyVStack(spacing: 0) {
                            ForEach(sortedFoods, id: \.index) { index, flagged in
                                FlaggedFoodRowExpanded(
                                    flagged: flagged,
                                    isSelected: selectedIndices.contains(index),
                                    onToggleSelect: { toggleSelection(index) },
                                    onShowDetail: { showingDetailFor = index },
                                    onDismiss: { onDismissIssue(index) },
                                    onDelete: { onDeleteFood(index) },
                                    onApplyFix: { onApplyFix(index) },
                                    onChangeAction: { newAction in
                                        if index < flaggedFoods.count {
                                            flaggedFoods[index].suggestedAction = newAction
                                        }
                                    }
                                )
                                Divider()
                            }
                        }
                    }
                    .frame(minWidth: 1400) // Minimum width to ensure all columns fit
                }
            }

            Divider()

            // Footer
            HStack {
                Text("Full nutrition data shown • Click row for comparison view • 'Apply All' executes Claude's suggestions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(item: Binding<FlaggedFoodDetailNew?>(
            get: {
                guard let idx = showingDetailFor, idx < flaggedFoods.count else { return nil }
                return FlaggedFoodDetailNew(index: idx, flagged: flaggedFoods[idx])
            },
            set: { (newValue: FlaggedFoodDetailNew?, _: Transaction) in showingDetailFor = newValue?.index }
        )) { detail in
            FoodComparisonSheet(
                food: detail.flagged.food,
                ukData: detail.flagged.ukData,
                issue: detail.flagged.issue,
                onApplyFix: {
                    onApplyFix(detail.index)
                    showingDetailFor = nil
                },
                onDismiss: {
                    onDismissIssue(detail.index)
                    showingDetailFor = nil
                },
                onDelete: {
                    onDeleteFood(detail.index)
                    showingDetailFor = nil
                }
            )
        }
    }

    private func toggleSelection(_ index: Int) {
        if selectedIndices.contains(index) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.insert(index)
        }
    }

    private func bulkApprove() {
        for index in selectedIndices.sorted().reversed() {
            onDismissIssue(index)
        }
        selectedIndices.removeAll()
    }

    private func bulkApplyFix() {
        for index in selectedIndices.sorted().reversed() {
            if flaggedFoods[safe: index]?.ukData != nil {
                onApplyFix(index)
            }
        }
        selectedIndices.removeAll()
    }

    private func bulkDelete() {
        for index in selectedIndices.sorted().reversed() {
            onDeleteFood(index)
        }
        selectedIndices.removeAll()
    }
}

struct FlaggedFoodDetailNew: Identifiable {
    let index: Int
    let flagged: FlaggedFood
    var id: Int { index }
}

struct FlaggedFoodTableHeader: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("").frame(width: 30) // checkbox
            Text("").frame(width: 50) // image
            Text("Food / Brand").frame(width: 200, alignment: .leading)
            Text("Issue / Reason").frame(width: 280, alignment: .leading)
            Text("Format").frame(width: 70, alignment: .center)
            Text("Cal").frame(width: 55, alignment: .trailing)
            Text("Protein").frame(width: 60, alignment: .trailing)
            Text("Carbs").frame(width: 60, alignment: .trailing)
            Text("Fat").frame(width: 55, alignment: .trailing)
            Text("Fibre").frame(width: 55, alignment: .trailing)
            Text("Sugar").frame(width: 55, alignment: .trailing)
            Text("Ingredients").frame(width: 300, alignment: .leading)
            Text("Action").frame(width: 120, alignment: .center)
            Text("").frame(width: 100) // buttons
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct FlaggedFoodRowExpanded: View {
    let flagged: FlaggedFood
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onShowDetail: () -> Void
    let onDismiss: () -> Void
    let onDelete: () -> Void
    let onApplyFix: () -> Void
    let onChangeAction: (FlaggedFood.SuggestedAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button { onToggleSelect() } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 30)

            // Thumbnail
            foodImageView
                .frame(width: 50, height: 44)

            // Food name & brand (clickable for detail)
            Button { onShowDetail() } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flagged.food.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let brand = flagged.food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    } else {
                        Text("No brand")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(width: 200, alignment: .leading)

            // Issue - full text wrapping
            Text(flagged.issue)
                .font(.caption)
                .foregroundColor(.orange)
                .lineLimit(nil) // Allow unlimited lines
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 280, alignment: .leading)

            // Serving format
            servingFormatView
                .frame(width: 70, alignment: .center)

            // Nutrition values - larger text
            Text("\(Int(flagged.food.calories))")
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)

            Text(String(format: "%.1fg", flagged.food.protein))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.1fg", flagged.food.carbs))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.1fg", flagged.food.fat))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)

            Text(String(format: "%.1fg", flagged.food.fiber))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)

            Text(String(format: "%.1fg", flagged.food.sugar))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 55, alignment: .trailing)

            // Ingredients - full text
            ingredientsPreview
                .frame(width: 300, alignment: .leading)

            // Suggested action picker
            Picker("", selection: Binding(
                get: { flagged.suggestedAction },
                set: { onChangeAction($0) }
            )) {
                ForEach([FlaggedFood.SuggestedAction.approve, .delete, .applyUKFix], id: \.self) { action in
                    Label(action.rawValue, systemImage: action.icon)
                        .tag(action)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .disabled(flagged.ukData == nil && flagged.suggestedAction == .applyUKFix)

            // Quick action buttons
            HStack(spacing: 6) {
                Button { onDismiss() } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Approve")

                if flagged.ukData != nil {
                    Button { onApplyFix() } label: {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help("Apply UK Fix")
                }

                Button { onDelete() } label: {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
            .frame(width: 100)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var foodImageView: some View {
        if let imageURL = flagged.food.thumbnailURL ?? flagged.food.imageURL,
           let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit).cornerRadius(4)
                case .failure:
                    Image(systemName: "photo").foregroundColor(.secondary).font(.caption)
                case .empty:
                    ProgressView().scaleEffect(0.4)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "photo")
                .foregroundColor(.secondary.opacity(0.3))
                .font(.caption)
        }
    }

    @ViewBuilder
    private var servingFormatView: some View {
        if flagged.food.isPerUnit == true {
            VStack(spacing: 0) {
                Text("unit")
                    .font(.caption2)
                    .foregroundColor(.purple)
                if let g = flagged.food.servingSizeG, g > 0 {
                    Text("\(Int(g))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(4)
        } else {
            Text("100g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var ingredientsPreview: some View {
        if let ingredients = flagged.food.ingredients, !ingredients.isEmpty {
            Text(ingredients.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        } else if let text = flagged.food.ingredientsText, !text.isEmpty {
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("No ingredients listed")
                .font(.caption)
                .foregroundColor(.red.opacity(0.7))
                .italic()
        }
    }
}

// MARK: - Selectable Food Row

struct FlaggedFoodRowSelectable: View {
    let food: FoodItem
    let issue: String
    let ukData: UKProductData?
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onShowDetail: () -> Void
    let onDismiss: () -> Void
    let onDelete: () -> Void
    let onApplyFix: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button {
                onToggleSelect()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // Thumbnail image
            foodImageView
                .frame(width: 40, height: 40)

            // Main content - clickable for detail
            Button {
                onShowDetail()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            if let brand = food.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        Spacer()
                        if ukData != nil {
                            Image(systemName: "network")
                                .foregroundColor(.blue)
                                .help("UK retailer data available")
                        }
                        // Show serving size info
                        servingSizeView
                        Text("\(Int(food.calories)) kcal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }
            .buttonStyle(.plain)

            // Quick actions
            HStack(spacing: 8) {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .help("Approve")

                if ukData != nil {
                    Button {
                        onApplyFix()
                    } label: {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Apply UK Fix")
                }

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var foodImageView: some View {
        if let imageURL = food.thumbnailURL ?? food.imageURL,
           let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(6)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                case .empty:
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 40, height: 40)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "photo")
                .foregroundColor(.secondary.opacity(0.3))
                .frame(width: 40, height: 40)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
    }

    @ViewBuilder
    private var servingSizeView: some View {
        if food.isPerUnit == true {
            VStack(alignment: .trailing, spacing: 0) {
                Text("per unit")
                    .font(.caption2)
                    .foregroundColor(.purple)
                if let servingG = food.servingSizeG, servingG > 0 {
                    Text("\(Int(servingG))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(4)
        } else if let servingG = food.servingSizeG, servingG > 0 {
            Text("\(Int(servingG))g")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
        }
    }
}

// MARK: - Before/After Comparison Sheet

struct FoodComparisonSheet: View {
    let food: FoodItem
    let ukData: UKProductData?
    let issue: String
    let onApplyFix: () -> Void
    let onDismiss: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Food Details")
                    .font(.headline)
                Spacer()
                Button("Close") { dismiss() }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Issue banner
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(issue)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)

                    // Per-unit notice
                    if food.isPerUnit == true {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                            VStack(alignment: .leading) {
                                Text("Per Unit Nutrition")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("This food's nutrition is per serving/unit, not per 100g.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let serving = food.servingDescription {
                                    Text("Serving: \(serving)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let servingG = food.servingSizeG, servingG > 0 {
                                    Text("Serving size: \(Int(servingG))g")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if ukData != nil {
                                    Text("⚠️ Applying UK data will convert to per-100g format")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Comparison view with change highlighting
                    if let uk = ukData {
                        // Calculate what will change
                        let changes = calculateChanges(current: food, uk: uk)

                        // Changes summary
                        if !changes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("\(changes.count) fields will be updated")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                ForEach(changes, id: \.field) { change in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(change.field)
                                            .fontWeight(.medium)
                                        Text(":")
                                        Text(change.oldValue)
                                            .foregroundColor(.red)
                                            .strikethrough()
                                        Text("→")
                                        Text(change.newValue)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    }
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }

                        HStack(alignment: .top, spacing: 20) {
                            // Current data
                            VStack(alignment: .leading, spacing: 12) {
                                Text("CURRENT DATA")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.bold)

                                ComparisonColumnHighlighted(
                                    name: food.name,
                                    brand: food.brand,
                                    calories: food.calories,
                                    protein: food.protein,
                                    carbs: food.carbs,
                                    fat: food.fat,
                                    fibre: food.fiber,
                                    sugar: food.sugar,
                                    ingredients: food.ingredientsText ?? food.ingredients?.joined(separator: ", "),
                                    imageURL: food.imageURL,
                                    source: food.source,
                                    isPerUnit: food.isPerUnit,
                                    servingSizeG: food.servingSizeG,
                                    servingDescription: food.servingDescription,
                                    changedFields: Set(changes.map { $0.field }),
                                    isOldValue: true
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)

                            // Arrow
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundColor(.secondary)
                                .padding(.top, 60)

                            // UK retailer data
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("UK RETAILER DATA")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.bold)
                                    Text("(\(uk.source.rawValue))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                ComparisonColumnHighlighted(
                                    name: uk.name,
                                    brand: uk.brand,
                                    calories: uk.caloriesPer100g,
                                    protein: uk.proteinPer100g,
                                    carbs: uk.carbsPer100g,
                                    fat: uk.fatPer100g,
                                    fibre: uk.fibrePer100g,
                                    sugar: uk.sugarPer100g,
                                    ingredients: uk.ingredientsText,
                                    imageURL: uk.imageURL,
                                    source: uk.source.rawValue,
                                    isPerUnit: false, // UK data is always per 100g
                                    changedFields: Set(changes.map { $0.field }),
                                    isOldValue: false
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    } else {
                        // No UK data - just show current
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CURRENT DATA")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.bold)

                            ComparisonColumn(
                                name: food.name,
                                brand: food.brand,
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat,
                                fibre: food.fiber,
                                sugar: food.sugar,
                                ingredients: food.ingredientsText ?? food.ingredients?.joined(separator: ", "),
                                imageURL: food.imageURL,
                                source: food.source,
                                isPerUnit: food.isPerUnit,
                                servingSizeG: food.servingSizeG,
                                servingDescription: food.servingDescription
                            )

                            Text("No UK retailer data available for comparison")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top)
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            HStack(spacing: 16) {
                Button {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Label("Approve As-Is", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .tint(.green)

                if ukData != nil {
                    Button {
                        onApplyFix()
                    } label: {
                        Label("Apply UK Data", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 800, height: 700)
    }
}

// MARK: - Change Detection and Highlighting

struct FieldChange: Equatable {
    let field: String
    let oldValue: String
    let newValue: String
}

/// Calculate what fields will change when applying UK data
func calculateChanges(current: FoodItem, uk: UKProductData) -> [FieldChange] {
    var changes: [FieldChange] = []

    // Name change
    if let ukName = uk.name, !ukName.isEmpty, ukName != current.name {
        changes.append(FieldChange(field: "Name", oldValue: current.name, newValue: ukName))
    }

    // Brand change
    if let ukBrand = uk.brand, !ukBrand.isEmpty, ukBrand != (current.brand ?? "") {
        changes.append(FieldChange(field: "Brand", oldValue: current.brand ?? "None", newValue: ukBrand))
    }

    // Image change
    if let ukImage = uk.imageURL, !ukImage.isEmpty, ukImage != (current.imageURL ?? "") {
        let currentShort = current.imageURL?.suffix(30).description ?? "None"
        let ukShort = String(ukImage.suffix(30))
        changes.append(FieldChange(field: "Image", oldValue: currentShort, newValue: ukShort))
    }

    // Nutrition changes (compare with tolerance for floating point)
    if let ukCal = uk.caloriesPer100g, abs(ukCal - current.calories) > 0.5 {
        changes.append(FieldChange(field: "Calories", oldValue: "\(Int(current.calories)) kcal", newValue: "\(Int(ukCal)) kcal"))
    }

    if let ukProt = uk.proteinPer100g, abs(ukProt - current.protein) > 0.1 {
        changes.append(FieldChange(field: "Protein", oldValue: String(format: "%.1fg", current.protein), newValue: String(format: "%.1fg", ukProt)))
    }

    if let ukCarbs = uk.carbsPer100g, abs(ukCarbs - current.carbs) > 0.1 {
        changes.append(FieldChange(field: "Carbs", oldValue: String(format: "%.1fg", current.carbs), newValue: String(format: "%.1fg", ukCarbs)))
    }

    if let ukFat = uk.fatPer100g, abs(ukFat - current.fat) > 0.1 {
        changes.append(FieldChange(field: "Fat", oldValue: String(format: "%.1fg", current.fat), newValue: String(format: "%.1fg", ukFat)))
    }

    if let ukFibre = uk.fibrePer100g, abs(ukFibre - current.fiber) > 0.1 {
        changes.append(FieldChange(field: "Fibre", oldValue: String(format: "%.1fg", current.fiber), newValue: String(format: "%.1fg", ukFibre)))
    }

    if let ukSugar = uk.sugarPer100g, abs(ukSugar - current.sugar) > 0.1 {
        changes.append(FieldChange(field: "Sugar", oldValue: String(format: "%.1fg", current.sugar), newValue: String(format: "%.1fg", ukSugar)))
    }

    // Salt comparison
    if let ukSalt = uk.saltPer100g {
        let currentSalt = current.sodium / 400
        if abs(ukSalt - currentSalt) > 0.01 {
            changes.append(FieldChange(field: "Salt", oldValue: String(format: "%.2fg", currentSalt), newValue: String(format: "%.2fg", ukSalt)))
        }
    }

    // Ingredients change
    if let ukIngredients = uk.ingredientsText, !ukIngredients.isEmpty {
        let currentIngredients = current.ingredientsText ?? current.ingredients?.joined(separator: ", ") ?? ""
        if ukIngredients != currentIngredients && !currentIngredients.isEmpty {
            let oldShort = currentIngredients.prefix(50) + (currentIngredients.count > 50 ? "..." : "")
            let newShort = ukIngredients.prefix(50) + (ukIngredients.count > 50 ? "..." : "")
            changes.append(FieldChange(field: "Ingredients", oldValue: String(oldShort), newValue: String(newShort)))
        } else if currentIngredients.isEmpty {
            let newShort = ukIngredients.prefix(50) + (ukIngredients.count > 50 ? "..." : "")
            changes.append(FieldChange(field: "Ingredients", oldValue: "None", newValue: String(newShort)))
        }
    }

    // Per-unit to per-100g conversion
    if current.isPerUnit == true {
        changes.append(FieldChange(field: "Format", oldValue: "Per Unit", newValue: "Per 100g"))
    }

    return changes
}

struct ComparisonColumnHighlighted: View {
    let name: String?
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fibre: Double?
    let sugar: Double?
    let ingredients: String?
    let imageURL: String?
    let source: String?
    let isPerUnit: Bool?
    var servingSizeG: Double? = nil
    var servingDescription: String? = nil
    let changedFields: Set<String>
    let isOldValue: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 120)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(highlightColor(for: "Image"), lineWidth: changedFields.contains("Image") ? 3 : 0)
                            )
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .frame(height: 80)
                    case .empty:
                        ProgressView()
                            .frame(height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Name with highlight
            if let name = name {
                Text(name)
                    .font(.headline)
                    .padding(changedFields.contains("Name") ? 4 : 0)
                    .background(highlightBackground(for: "Name"))
                    .cornerRadius(4)
            }

            // Brand with highlight
            if let brand = brand, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(changedFields.contains("Brand") ? 4 : 0)
                    .background(highlightBackground(for: "Brand"))
                    .cornerRadius(4)
            }

            Divider()

            // Serving size info with format highlight
            VStack(alignment: .leading, spacing: 2) {
                if isPerUnit == true {
                    HStack {
                        Text("Nutrition (per unit)")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                            .padding(changedFields.contains("Format") ? 4 : 0)
                            .background(highlightBackground(for: "Format"))
                            .cornerRadius(4)
                        Spacer()
                    }
                    if let servingG = servingSizeG, servingG > 0 {
                        Text("Unit size: \(Int(servingG))g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let desc = servingDescription, !desc.isEmpty {
                        Text("Serving: \(desc)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Nutrition (per 100g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(changedFields.contains("Format") ? 4 : 0)
                        .background(highlightBackground(for: "Format"))
                        .cornerRadius(4)
                    if let servingG = servingSizeG, servingG > 0 {
                        Text("Typical serving: \(Int(servingG))g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Nutrition values with highlights
            NutritionRowHighlighted(label: "Calories", value: calories.map { "\(Int($0)) kcal" }, isChanged: changedFields.contains("Calories"), isOldValue: isOldValue)
            NutritionRowHighlighted(label: "Protein", value: protein.map { String(format: "%.1fg", $0) }, isChanged: changedFields.contains("Protein"), isOldValue: isOldValue)
            NutritionRowHighlighted(label: "Carbs", value: carbs.map { String(format: "%.1fg", $0) }, isChanged: changedFields.contains("Carbs"), isOldValue: isOldValue)
            NutritionRowHighlighted(label: "Fat", value: fat.map { String(format: "%.1fg", $0) }, isChanged: changedFields.contains("Fat"), isOldValue: isOldValue)
            NutritionRowHighlighted(label: "Fibre", value: fibre.map { String(format: "%.1fg", $0) }, isChanged: changedFields.contains("Fibre"), isOldValue: isOldValue)
            NutritionRowHighlighted(label: "Sugar", value: sugar.map { String(format: "%.1fg", $0) }, isChanged: changedFields.contains("Sugar"), isOldValue: isOldValue)

            // Ingredients with highlight
            if let ingredients = ingredients, !ingredients.isEmpty {
                Divider()
                Text("Ingredients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(ingredients)
                    .font(.caption)
                    .lineLimit(5)
                    .padding(changedFields.contains("Ingredients") ? 4 : 0)
                    .background(highlightBackground(for: "Ingredients"))
                    .cornerRadius(4)
            }

            if let source = source {
                Divider()
                Text("Source: \(source)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func highlightColor(for field: String) -> Color {
        guard changedFields.contains(field) else { return .clear }
        return isOldValue ? .red : .green
    }

    private func highlightBackground(for field: String) -> Color {
        guard changedFields.contains(field) else { return .clear }
        return isOldValue ? Color.red.opacity(0.15) : Color.green.opacity(0.15)
    }
}

struct NutritionRowHighlighted: View {
    let label: String
    let value: String?
    let isChanged: Bool
    let isOldValue: Bool

    var body: some View {
        if let value = value {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isChanged ? (isOldValue ? .red : .green) : .primary)
                    .padding(.horizontal, isChanged ? 6 : 0)
                    .padding(.vertical, isChanged ? 2 : 0)
                    .background(isChanged ? (isOldValue ? Color.red.opacity(0.15) : Color.green.opacity(0.15)) : Color.clear)
                    .cornerRadius(4)
            }
        }
    }
}

struct ComparisonColumn: View {
    let name: String?
    let brand: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fibre: Double?
    let sugar: Double?
    let ingredients: String?
    let imageURL: String?
    let source: String?
    let isPerUnit: Bool?
    var servingSizeG: Double? = nil
    var servingDescription: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product image
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 120)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                            .frame(height: 80)
                    case .empty:
                        ProgressView()
                            .frame(height: 80)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if let name = name {
                Text(name)
                    .font(.headline)
            }
            if let brand = brand, !brand.isEmpty {
                Text(brand)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            Divider()

            // Serving size info
            VStack(alignment: .leading, spacing: 2) {
                if isPerUnit == true {
                    HStack {
                        Text("Nutrition (per unit)")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    if let servingG = servingSizeG, servingG > 0 {
                        Text("Unit size: \(Int(servingG))g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let desc = servingDescription, !desc.isEmpty {
                        Text("Serving: \(desc)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Nutrition (per 100g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let servingG = servingSizeG, servingG > 0 {
                        Text("Typical serving: \(Int(servingG))g")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let cal = calories {
                NutritionRow(label: "Calories", value: "\(Int(cal)) kcal")
            }
            if let prot = protein {
                NutritionRow(label: "Protein", value: String(format: "%.1fg", prot))
            }
            if let carb = carbs {
                NutritionRow(label: "Carbs", value: String(format: "%.1fg", carb))
            }
            if let fat = fat {
                NutritionRow(label: "Fat", value: String(format: "%.1fg", fat))
            }
            if let fib = fibre {
                NutritionRow(label: "Fibre", value: String(format: "%.1fg", fib))
            }
            if let sug = sugar {
                NutritionRow(label: "Sugar", value: String(format: "%.1fg", sug))
            }

            if let ingredients = ingredients, !ingredients.isEmpty {
                Divider()
                Text("Ingredients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(ingredients)
                    .font(.caption)
                    .lineLimit(5)
            }

            if let source = source {
                Divider()
                Text("Source: \(source)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct FlaggedFoodRow: View {
    let food: FoodItem
    let issue: String
    let hasOFFData: Bool
    let onDismiss: () -> Void
    let onDelete: () -> Void
    let onApplyFix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name)
                        .font(.headline)
                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                Spacer()
                if hasOFFData {
                    Image(systemName: "network")
                        .foregroundColor(.blue)
                        .help("Open Food Facts data available")
                }
                Text("\(Int(food.calories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(issue)
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(4)

            // Nutrition summary
            HStack(spacing: 12) {
                Text("P: \(String(format: "%.1f", food.protein))g")
                Text("C: \(String(format: "%.1f", food.carbs))g")
                Text("F: \(String(format: "%.1f", food.fat))g")
                if let ingredients = food.ingredients {
                    Spacer()
                    Text("\(ingredients.count) ingredients")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    onDismiss()
                } label: {
                    Label("Approve", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
                .tint(.green)

                if hasOFFData {
                    Button {
                        onApplyFix()
                    } label: {
                        Label("Apply OFF Fix", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }

                Button {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

struct AutoCompleteView: View {
    let stats: ReviewSessionStats
    let flaggedCount: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Review Complete!")
                .font(.title)
                .fontWeight(.bold)

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                StatBox(value: stats.reviewed, label: "Approved", color: .green)
                StatBox(value: stats.flagged, label: "Flagged", color: .orange)
                StatBox(value: stats.deleted, label: "Deleted", color: .red)
                StatBox(value: stats.fixed, label: "Fixed (OFF)", color: .blue)
                StatBox(value: stats.imagesAdded, label: "Images Added", color: .purple)
                StatBox(value: stats.reviewed + stats.flagged + stats.deleted, label: "Total", color: .gray)
            }
            .frame(maxWidth: 450)

            if flaggedCount > 0 {
                Text("\(flaggedCount) items still need attention")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}

struct AutoProgressFooter: View {
    let approved: Int
    let flagged: Int
    let current: Int
    let total: Int

    var body: some View {
        HStack {
            Label("\(approved) approved", systemImage: "checkmark.circle")
                .foregroundColor(.green)
            Spacer()
            Label("\(flagged) flagged", systemImage: "flag.fill")
                .foregroundColor(.orange)
            Spacer()
            ProgressView(value: Double(current), total: Double(max(total, 1)))
                .frame(width: 100)
            Text("\(current)/\(total)")
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Supporting Types

struct SuggestedAction: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isPrimary: Bool
}

struct ReviewSessionStats {
    var reviewed = 0
    var flagged = 0
    var skipped = 0
    var deleted = 0
    var fixed = 0
    var imagesAdded = 0
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Data Validation Sheet

struct DataValidationSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // State
    @State private var allFoods: [FoodItem] = []
    @State private var isLoading = false
    @State private var loadingStatus = ""
    @State private var hasLoaded = false
    @State private var hasRunChecks = false

    // Validation results
    @State private var validationResults: [ValidationCategory: [FoodItem]] = [:]
    @State private var selectedCategory: ValidationCategory?
    @State private var selectedFoods: Set<String> = []

    // Bulk operations
    @State private var isProcessing = false
    @State private var processingStatus = ""
    @State private var processedCount = 0
    @State private var totalToProcess = 0

    // Errors
    @State private var errorMessage: String?

    // Validation options
    @State private var validationOptions = ValidationOptions()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            if !hasLoaded && !isLoading {
                // Initial state - show start button
                startView
            } else if isLoading {
                // Loading state
                loadingView
            } else if hasLoaded && !hasRunChecks {
                // Data loaded - show validation options
                optionsView
            } else if isProcessing {
                // Processing bulk operations
                processingView
            } else {
                // Results view
                resultsView
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Data Validation")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Find and fix data quality issues in \(appState.selectedDatabase.displayName)")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                Text("This will load the entire database into memory")
                    .font(.callout)
                    .foregroundColor(.secondary)

                Text("Once loaded, you can run various validation checks")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            Button {
                Task { await loadDatabase() }
            } label: {
                Label("Start Validation", systemImage: "play.fill")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Data Validation")
                    .font(.title2)
                    .fontWeight(.semibold)
                if hasLoaded {
                    Text("\(allFoods.count.formatted()) foods loaded from \(appState.selectedDatabase.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Find and fix data quality issues across the database")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if hasRunChecks && !isLoading && !isProcessing {
                Button("Run Different Checks") {
                    hasRunChecks = false
                    selectedCategory = nil
                    selectedFoods.removeAll()
                    validationResults.removeAll()
                }
                .buttonStyle(.bordered)
            }

            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - Options View

    private var optionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Data loaded info
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("\(allFoods.count.formatted()) foods loaded")
                            .font(.headline)
                        Text("Select which validation checks to run on the data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                // Validation options grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ValidationOptionToggle(
                        title: "Missing Brand",
                        description: "Foods without a brand name (excludes generic items)",
                        icon: "tag.slash",
                        isOn: $validationOptions.checkMissingBrand
                    )

                    ValidationOptionToggle(
                        title: "Missing Ingredients",
                        description: "Foods without ingredient lists",
                        icon: "list.bullet.clipboard",
                        isOn: $validationOptions.checkMissingIngredients
                    )

                    ValidationOptionToggle(
                        title: "Missing Barcode",
                        description: "Foods without a barcode",
                        icon: "barcode",
                        isOn: $validationOptions.checkMissingBarcode
                    )

                    ValidationOptionToggle(
                        title: "Missing Image",
                        description: "Foods without a product image",
                        icon: "photo",
                        isOn: $validationOptions.checkMissingImage
                    )

                    ValidationOptionToggle(
                        title: "Zero Calories",
                        description: "Foods with 0 calories (likely incorrect)",
                        icon: "flame.badge.minus",
                        isOn: $validationOptions.checkZeroCalories
                    )

                    ValidationOptionToggle(
                        title: "Implausible Nutrition",
                        description: "Nutrition values that don't add up",
                        icon: "exclamationmark.triangle",
                        isOn: $validationOptions.checkImplausibleNutrition
                    )

                    ValidationOptionToggle(
                        title: "Very High Calories",
                        description: "Foods with >900 kcal per 100g",
                        icon: "flame.fill",
                        isOn: $validationOptions.checkHighCalories
                    )

                    ValidationOptionToggle(
                        title: "Missing Processing Grade",
                        description: "Foods without NOVA processing grade",
                        icon: "gauge.medium",
                        isOn: $validationOptions.checkMissingProcessingGrade
                    )

                    ValidationOptionToggle(
                        title: "Unverified Foods",
                        description: "Foods not yet verified",
                        icon: "checkmark.seal",
                        isOn: $validationOptions.checkUnverified
                    )

                    ValidationOptionToggle(
                        title: "Duplicate Names",
                        description: "Multiple foods with identical names",
                        icon: "doc.on.doc",
                        isOn: $validationOptions.checkDuplicates
                    )

                    ValidationOptionToggle(
                        title: "Short Names",
                        description: "Food names with less than 3 characters",
                        icon: "textformat.size.smaller",
                        isOn: $validationOptions.checkShortNames
                    )

                    ValidationOptionToggle(
                        title: "Missing Serving Size",
                        description: "Foods without serving size info",
                        icon: "scalemass",
                        isOn: $validationOptions.checkMissingServingSize
                    )

                    ValidationOptionToggle(
                        title: "Negative Values",
                        description: "Foods with negative nutrition values",
                        icon: "minus.circle",
                        isOn: $validationOptions.checkNegativeValues
                    )

                    ValidationOptionToggle(
                        title: "No Source",
                        description: "Foods without a data source",
                        icon: "questionmark.folder",
                        isOn: $validationOptions.checkNoSource
                    )

                    ValidationOptionToggle(
                        title: "Open Food Facts Images",
                        description: "Foods with images from Open Food Facts",
                        icon: "photo.badge.exclamationmark",
                        isOn: $validationOptions.checkOFFImages
                    )

                    ValidationOptionToggle(
                        title: "Suspicious Protein",
                        description: "Protein > 50g per 100g (unusual)",
                        icon: "bolt.fill",
                        isOn: $validationOptions.checkHighProtein
                    )
                }

                // Quick select buttons
                HStack {
                    Button("Select All") {
                        validationOptions.selectAll()
                    }
                    .buttonStyle(.bordered)

                    Button("Select None") {
                        validationOptions.selectNone()
                    }
                    .buttonStyle(.bordered)

                    Button("Common Issues") {
                        validationOptions.selectCommon()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        Task { await runChecks() }
                    } label: {
                        Label("Run Checks", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!validationOptions.hasAnySelected)
                }
            }
            .padding()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text(loadingStatus)
                .font(.headline)
            Text("Please wait while the database is being analysed...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(processedCount), total: Double(max(totalToProcess, 1)))
                .frame(width: 300)
            Text(processingStatus)
                .font(.headline)
            Text("\(processedCount) / \(totalToProcess)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View

    private var resultsView: some View {
        HSplitView {
            // Left: Categories list
            categoriesList
                .frame(minWidth: 280, maxWidth: 350)

            // Right: Foods in selected category
            if let category = selectedCategory {
                foodsList(for: category)
            } else {
                VStack {
                    Image(systemName: "arrow.left")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a category to view issues")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var categoriesList: some View {
        VStack(spacing: 0) {
            // Summary header
            VStack(alignment: .leading, spacing: 8) {
                Text("Validation Results")
                    .font(.headline)

                let totalIssues = validationResults.values.map { $0.count }.reduce(0, +)
                Text("\(totalIssues) issues found across \(validationResults.count) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Categories
            List(selection: $selectedCategory) {
                ForEach(ValidationCategory.allCases.filter { validationResults[$0] != nil && !validationResults[$0]!.isEmpty }, id: \.self) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text(category.title)
                                .font(.subheadline)
                            Text(category.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("\(validationResults[category]?.count ?? 0)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 4)
                    .tag(category)
                }
            }
            .listStyle(.sidebar)
        }
    }

    private func foodsList(for category: ValidationCategory) -> some View {
        VStack(spacing: 0) {
            // Header with bulk actions
            HStack {
                VStack(alignment: .leading) {
                    Text(category.title)
                        .font(.headline)
                    Text("\(validationResults[category]?.count ?? 0) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Fix actions based on category
                if !selectedFoods.isEmpty {
                    Text("\(selectedFoods.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 8)

                    // Category-specific fix buttons
                    fixButtonsForCategory(category)

                    Button {
                        Task { await deleteSelected() }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Button(selectedFoods.count == (validationResults[category]?.count ?? 0) ? "Deselect All" : "Select All") {
                    if selectedFoods.count == (validationResults[category]?.count ?? 0) {
                        selectedFoods.removeAll()
                    } else {
                        selectedFoods = Set(validationResults[category]?.map { $0.objectID } ?? [])
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Foods list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(validationResults[category] ?? [], id: \.objectID) { food in
                        ValidationFoodRow(
                            food: food,
                            category: category,
                            isSelected: selectedFoods.contains(food.objectID),
                            onToggleSelect: {
                                if selectedFoods.contains(food.objectID) {
                                    selectedFoods.remove(food.objectID)
                                } else {
                                    selectedFoods.insert(food.objectID)
                                }
                            },
                            onDelete: {
                                Task { await deleteFood(food) }
                            }
                        )
                        Divider()
                    }
                }
            }

            // Error banner
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") {
                        errorMessage = nil
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
        }
    }

    // MARK: - Actions

    private func loadDatabase() async {
        isLoading = true
        loadingStatus = "Loading database..."

        // Load all foods using browse API
        loadingStatus = "Fetching all foods from \(appState.selectedDatabase.displayName)..."
        await algoliaService.browseAllFoods(database: appState.selectedDatabase)
        allFoods = algoliaService.foods

        loadingStatus = "Loaded \(allFoods.count) foods"
        hasLoaded = true
        isLoading = false
    }

    private func runChecks() async {
        isLoading = true
        loadingStatus = "Running validation checks..."
        selectedCategory = nil
        selectedFoods.removeAll()
        validationResults.removeAll()

        // Run validation checks on already-loaded data
        await runValidationChecks()

        hasRunChecks = true
        isLoading = false
    }

    private func runValidationChecks() async {
        var results: [ValidationCategory: [FoodItem]] = [:]

        // Check each enabled validation option
        if validationOptions.checkMissingBrand {
            loadingStatus = "Checking for missing brands..."
            results[.missingBrand] = allFoods.filter { food in
                (food.brand == nil || food.brand?.isEmpty == true) && !isGenericFood(food)
            }
        }

        if validationOptions.checkMissingIngredients {
            loadingStatus = "Checking for missing ingredients..."
            results[.missingIngredients] = allFoods.filter { food in
                (food.ingredients == nil || food.ingredients?.isEmpty == true) &&
                (food.ingredientsText == nil || food.ingredientsText?.isEmpty == true)
            }
        }

        if validationOptions.checkMissingBarcode {
            loadingStatus = "Checking for missing barcodes..."
            results[.missingBarcode] = allFoods.filter { food in
                food.barcode == nil || food.barcode?.isEmpty == true
            }
        }

        if validationOptions.checkMissingImage {
            loadingStatus = "Checking for missing images..."
            results[.missingImage] = allFoods.filter { food in
                food.imageURL == nil || food.imageURL?.isEmpty == true
            }
        }

        if validationOptions.checkZeroCalories {
            loadingStatus = "Checking for zero calories..."
            results[.zeroCalories] = allFoods.filter { $0.calories == 0 }
        }

        if validationOptions.checkImplausibleNutrition {
            loadingStatus = "Checking for implausible nutrition..."
            results[.implausibleNutrition] = allFoods.filter { food in
                // Macros should roughly equal calories (4*protein + 4*carbs + 9*fat)
                let calculatedCal = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9)
                let diff = abs(calculatedCal - food.calories)
                // Allow 20% tolerance or 50 kcal, whichever is greater
                let tolerance = max(food.calories * 0.2, 50)
                return diff > tolerance && food.calories > 0
            }
        }

        if validationOptions.checkHighCalories {
            loadingStatus = "Checking for very high calories..."
            results[.highCalories] = allFoods.filter { $0.calories > 900 }
        }

        if validationOptions.checkMissingProcessingGrade {
            loadingStatus = "Checking for missing processing grades..."
            results[.missingProcessingGrade] = allFoods.filter { food in
                food.processingGrade == nil || food.processingGrade?.isEmpty == true
            }
        }

        if validationOptions.checkUnverified {
            loadingStatus = "Checking for unverified foods..."
            results[.unverified] = allFoods.filter { $0.isVerified != true }
        }

        if validationOptions.checkDuplicates {
            loadingStatus = "Checking for duplicates..."
            var nameCounts: [String: Int] = [:]
            for food in allFoods {
                let normalizedName = food.name.lowercased().trimmingCharacters(in: .whitespaces)
                nameCounts[normalizedName, default: 0] += 1
            }
            let duplicateNames = Set(nameCounts.filter { $0.value > 1 }.keys)
            results[.duplicates] = allFoods.filter { duplicateNames.contains($0.name.lowercased().trimmingCharacters(in: .whitespaces)) }
        }

        if validationOptions.checkShortNames {
            loadingStatus = "Checking for short names..."
            results[.shortNames] = allFoods.filter { $0.name.count < 3 }
        }

        if validationOptions.checkMissingServingSize {
            loadingStatus = "Checking for missing serving sizes..."
            results[.missingServingSize] = allFoods.filter { food in
                (food.servingSizeG == nil || food.servingSizeG == 0) &&
                (food.servingDescription == nil || food.servingDescription?.isEmpty == true)
            }
        }

        if validationOptions.checkNegativeValues {
            loadingStatus = "Checking for negative values..."
            results[.negativeValues] = allFoods.filter { food in
                food.calories < 0 || food.protein < 0 || food.carbs < 0 ||
                food.fat < 0 || food.fiber < 0 || food.sugar < 0 || food.sodium < 0
            }
        }

        if validationOptions.checkNoSource {
            loadingStatus = "Checking for missing source..."
            results[.noSource] = allFoods.filter { food in
                food.source == nil || food.source?.isEmpty == true
            }
        }

        if validationOptions.checkOFFImages {
            loadingStatus = "Checking for Open Food Facts images..."
            results[.offImages] = allFoods.filter { food in
                guard let imageURL = food.imageURL else { return false }
                return imageURL.contains("openfoodfacts") || imageURL.contains("off.org")
            }
        }

        if validationOptions.checkHighProtein {
            loadingStatus = "Checking for suspicious protein levels..."
            results[.highProtein] = allFoods.filter { $0.protein > 50 }
        }

        validationResults = results
    }

    private func deleteFood(_ food: FoodItem) async {
        let success = await algoliaService.deleteFood(objectID: food.objectID, database: appState.selectedDatabase)
        if success {
            // Remove from results
            for (category, foods) in validationResults {
                validationResults[category] = foods.filter { $0.objectID != food.objectID }
            }
            allFoods.removeAll { $0.objectID == food.objectID }
        } else {
            errorMessage = "Failed to delete \(food.name)"
        }
    }

    private func deleteSelected() async {
        guard !selectedFoods.isEmpty else { return }

        isProcessing = true
        totalToProcess = selectedFoods.count
        processedCount = 0
        processingStatus = "Deleting selected items..."

        var failedDeletes: [String] = []

        for objectID in selectedFoods {
            let success = await algoliaService.deleteFood(objectID: objectID, database: appState.selectedDatabase)
            if !success {
                if let food = allFoods.first(where: { $0.objectID == objectID }) {
                    failedDeletes.append(food.name)
                }
            }
            processedCount += 1
            processingStatus = "Deleted \(processedCount) of \(totalToProcess)..."
        }

        // Remove deleted items from results
        let deletedIDs = selectedFoods.subtracting(Set(failedDeletes.map { name in
            allFoods.first { $0.name == name }?.objectID ?? ""
        }))

        for (category, foods) in validationResults {
            validationResults[category] = foods.filter { !deletedIDs.contains($0.objectID) }
        }
        allFoods.removeAll { deletedIDs.contains($0.objectID) }
        selectedFoods.removeAll()

        if !failedDeletes.isEmpty {
            errorMessage = "Failed to delete \(failedDeletes.count) items"
        }

        isProcessing = false
    }

    /// Check if a food item is a generic/whole food (doesn't need a brand)
    private func isGenericFood(_ food: FoodItem) -> Bool {
        let name = food.name.lowercased()

        let genericPatterns = [
            "apple", "banana", "orange", "grape", "strawberr", "blueberr", "raspberr", "blackberr",
            "mango", "pineapple", "watermelon", "melon", "peach", "pear", "plum", "cherry", "kiwi",
            "lemon", "lime", "grapefruit", "avocado", "coconut", "fig", "date", "raisin", "prune",
            "carrot", "broccoli", "cauliflower", "spinach", "lettuce", "kale", "cabbage", "celery",
            "cucumber", "tomato", "potato", "sweet potato", "onion", "garlic", "pepper", "courgette",
            "zucchini", "aubergine", "eggplant", "mushroom", "corn", "pea", "bean", "lentil",
            "asparagus", "artichoke", "beetroot", "turnip", "parsnip", "swede", "leek", "radish",
            "chicken breast", "chicken thigh", "chicken leg", "chicken wing", "turkey", "duck",
            "beef", "steak", "mince", "ground beef", "lamb", "pork", "bacon", "ham", "sausage",
            "salmon", "tuna", "cod", "haddock", "mackerel", "sardine", "prawn", "shrimp", "crab",
            "lobster", "mussel", "oyster", "squid", "egg", "eggs",
            "milk", "cream", "butter", "cheese", "yogurt", "yoghurt",
            "rice", "pasta", "bread", "flour", "oat", "wheat", "barley", "quinoa", "couscous",
            "almond", "walnut", "cashew", "peanut", "pistachio", "hazelnut", "pecan", "macadamia",
            "sunflower seed", "pumpkin seed", "chia seed", "flax seed", "sesame",
            "basil", "oregano", "thyme", "rosemary", "parsley", "cilantro", "coriander", "mint",
            "dill", "sage", "bay leaf", "cumin", "paprika", "turmeric", "ginger", "cinnamon",
            "water", "honey", "sugar", "salt", "oil", "olive oil", "vinegar", "soy sauce",
            "tofu", "tempeh", "seitan"
        ]

        for pattern in genericPatterns {
            if name.contains(pattern) { return true }
        }

        let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.count <= 2
    }

    // MARK: - Fix Buttons

    @ViewBuilder
    private func fixButtonsForCategory(_ category: ValidationCategory) -> some View {
        // Claude AI fix button - available for all categories
        Button {
            Task { await fixWithClaude(category: category) }
        } label: {
            Label("Fix with Claude", systemImage: "wand.and.stars")
        }
        .buttonStyle(.bordered)
        .tint(.purple)

        // Category-specific additional buttons
        switch category {
        case .missingBrand:
            Button {
                Task { await lookupBrandsViaBarcode() }
            } label: {
                Label("Lookup via Barcode", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

        case .missingIngredients:
            Button {
                Task { await fetchIngredientsViaBarcode() }
            } label: {
                Label("Fetch via Barcode", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

        case .missingBarcode, .missingImage:
            Button {
                Task { await searchAndEnrich() }
            } label: {
                Label("Search & Enrich", systemImage: "magnifyingglass")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

        case .zeroCalories, .implausibleNutrition, .negativeValues:
            Button {
                Task { await lookupNutritionViaBarcode() }
            } label: {
                Label("Lookup via Barcode", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

        case .missingProcessingGrade:
            Button {
                Task { await calculateProcessingGrades() }
            } label: {
                Label("Calculate Grades", systemImage: "gauge.with.needle")
            }
            .buttonStyle(.bordered)
            .tint(.green)

        case .unverified:
            Button {
                Task { await verifyViaBarcode() }
            } label: {
                Label("Verify via Barcode", systemImage: "checkmark.seal")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button {
                Task { await markAsVerified() }
            } label: {
                Label("Mark Verified", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .tint(.green)

        case .duplicates:
            Button {
                Task { await mergeDuplicates() }
            } label: {
                Label("Merge Duplicates", systemImage: "arrow.triangle.merge")
            }
            .buttonStyle(.bordered)
            .tint(.orange)

        case .noSource:
            Button {
                Task { await setSourceManually("User Contributed") }
            } label: {
                Label("Set as User Data", systemImage: "person.fill")
            }
            .buttonStyle(.bordered)
            .tint(.green)

        case .offImages:
            Button {
                Task { await findBetterImages() }
            } label: {
                Label("Find Better Images", systemImage: "photo.badge.arrow.down")
            }
            .buttonStyle(.bordered)
            .tint(.blue)

        default:
            EmptyView()
        }
    }

    // MARK: - Fix Actions

    /// Universal Claude fix function that handles all validation categories
    private func fixWithClaude(category: ValidationCategory) async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Fixing with Claude AI..."

        for food in foodsToFix {
            processingStatus = "Analysing: \(food.name)..."

            // Build category-specific prompt
            let prompt = buildFixPrompt(for: food, category: category)

            do {
                let response = try await callClaudeAPI(prompt: prompt)

                // Parse and apply the fix
                if let updatedFood = parseAndApplyFix(response: response, to: food, category: category) {
                    let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                    if success {
                        updateFoodInResults(updatedFood)
                    }
                }
            } catch {
                print("Claude fix error for \(food.name): \(error)")
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func buildFixPrompt(for food: FoodItem, category: ValidationCategory) -> String {
        let baseInfo = """
        Food item to fix:
        - Name: \(food.name)
        - Brand: \(food.brand ?? "None")
        - Barcode: \(food.barcode ?? "None")
        - Calories: \(food.calories) kcal
        - Protein: \(food.protein)g
        - Carbs: \(food.carbs)g
        - Fat: \(food.fat)g
        - Fiber: \(food.fiber)g
        - Sugar: \(food.sugar)g
        - Salt: \(String(format: "%.2f", food.sodium / 400))g
        """

        switch category {
        case .missingBrand:
            return """
            \(baseInfo)

            Task: Extract or identify the brand from the food name, or identify a likely brand.
            Common UK brands: Tesco, Sainsbury's, ASDA, Morrisons, Waitrose, M&S, Aldi, Lidl, Co-op, Birds Eye, McCain, Heinz, Kellogg's, Cadbury, McVitie's, Warburtons, Hovis, etc.

            Respond with JSON only:
            {"brand": "Brand Name", "cleanName": "Product name without brand prefix"}
            If no brand can be identified, respond: {"brand": null}
            """

        case .missingIngredients:
            return """
            \(baseInfo)

            Task: Estimate typical ingredients for this food product.
            Be specific to the product type and brand if known.

            Respond with JSON only:
            {"ingredients": ["ingredient1", "ingredient2", ...], "ingredientsText": "Full comma-separated ingredients text"}
            """

        case .missingBarcode, .missingImage:
            return """
            \(baseInfo)

            Task: This food is missing barcode/image. Suggest if this product should be kept or deleted.
            Consider: Is it a real product? Is it a duplicate? Is it user-generated junk data?

            Respond with JSON only:
            {"action": "keep" or "delete", "reason": "explanation"}
            """

        case .zeroCalories, .implausibleNutrition, .negativeValues:
            return """
            \(baseInfo)

            Task: Fix the nutrition values. The current values are implausible.
            Rules: (protein×4) + (carbs×4) + (fat×9) should roughly equal calories.
            Values must be non-negative and realistic for this food type.

            Respond with JSON only:
            {"calories": 123, "protein": 12.3, "carbs": 45.6, "fat": 7.8, "fiber": 2.1, "sugar": 5.0, "sodium": 300}
            """

        case .highCalories:
            return """
            \(baseInfo)

            Task: This food has very high calories (>900 kcal/100g). Verify if this is correct.
            Only oils, butter, and some nuts should be this high.

            Respond with JSON only:
            {"isCorrect": true/false, "correctedCalories": 123, "reason": "explanation"}
            """

        case .missingProcessingGrade:
            return """
            \(baseInfo)
            - Ingredients: \(food.ingredients?.joined(separator: ", ") ?? "Unknown")

            Task: Assess the processing level of this food (NOVA classification style).
            A = Minimally processed (whole foods)
            B = Lightly processed (basic cooking)
            C = Moderately processed (some additives)
            D = Highly processed (multiple additives)
            E = Ultra-processed (industrial formulations)

            Respond with JSON only:
            {"grade": "A/B/C/D/E", "score": 0-100, "label": "Processing description"}
            """

        case .unverified:
            return """
            \(baseInfo)

            Task: Assess if this food data looks accurate and complete enough to verify.
            Check: Do the nutrition values make sense? Is the name properly formatted?

            Respond with JSON only:
            {"shouldVerify": true/false, "issues": ["issue1", "issue2"], "confidence": 0-100}
            """

        case .duplicates:
            return """
            \(baseInfo)

            Task: Suggest the best canonical name for this food.
            Format should be: "Product Name" or "Brand Product Name" if brand is important.

            Respond with JSON only:
            {"canonicalName": "Best name for this product", "shouldKeep": true/false}
            """

        case .shortNames:
            return """
            \(baseInfo)

            Task: Expand this very short food name into a proper descriptive product name.

            Respond with JSON only:
            {"expandedName": "Full descriptive product name"}
            """

        case .missingServingSize:
            return """
            \(baseInfo)

            Task: Estimate a typical serving size for this food.

            Respond with JSON only:
            {"servingSizeG": 100, "servingDescription": "1 serving (100g)"}
            """

        case .noSource:
            return """
            \(baseInfo)

            Task: Based on the food details, suggest the most likely data source.
            Options: User Contributed, Open Food Facts, UK Retailer, Nutritionix, Manual Entry

            Respond with JSON only:
            {"source": "Most likely source"}
            """

        case .offImages:
            return """
            \(baseInfo)

            Task: This food has a low-quality Open Food Facts image. Suggest if we should remove the image or keep it.

            Respond with JSON only:
            {"action": "keep" or "remove", "reason": "explanation"}
            """

        case .highProtein:
            return """
            \(baseInfo)

            Task: This food has very high protein (>50g/100g). Verify if this is correct.
            Only protein powders, dried meats, and some cheeses should be this high.

            Respond with JSON only:
            {"isCorrect": true/false, "correctedProtein": 12.3, "reason": "explanation"}
            """
        }
    }

    private func parseAndApplyFix(response: String, to food: FoodItem, category: ValidationCategory) -> FoodItem? {
        // Extract JSON from response
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else { return nil }

        let jsonString = String(response[jsonStart...jsonEnd])
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        var updated = food

        switch category {
        case .missingBrand:
            if let brand = json["brand"] as? String {
                updated.brand = brand
            }
            if let cleanName = json["cleanName"] as? String, !cleanName.isEmpty {
                updated.name = cleanName
            }

        case .missingIngredients:
            if let ingredients = json["ingredients"] as? [String] {
                updated.ingredients = ingredients
            }
            if let ingredientsText = json["ingredientsText"] as? String {
                updated.ingredientsText = ingredientsText
            }

        case .zeroCalories, .implausibleNutrition, .negativeValues:
            if let cal = json["calories"] as? Double { updated.calories = cal }
            else if let cal = json["calories"] as? Int { updated.calories = Double(cal) }
            if let protein = json["protein"] as? Double { updated.protein = protein }
            if let carbs = json["carbs"] as? Double { updated.carbs = carbs }
            if let fat = json["fat"] as? Double { updated.fat = fat }
            if let fiber = json["fiber"] as? Double { updated.fiber = fiber }
            if let sugar = json["sugar"] as? Double { updated.sugar = sugar }
            if let sodium = json["sodium"] as? Double { updated.sodium = sodium }

        case .highCalories:
            if let isCorrect = json["isCorrect"] as? Bool, !isCorrect {
                if let corrected = json["correctedCalories"] as? Double {
                    updated.calories = corrected
                } else if let corrected = json["correctedCalories"] as? Int {
                    updated.calories = Double(corrected)
                }
            }

        case .missingProcessingGrade:
            if let grade = json["grade"] as? String {
                updated.processingGrade = grade
            }
            if let score = json["score"] as? Int {
                updated.processingScore = score
            }
            if let label = json["label"] as? String {
                updated.processingLabel = label
            }

        case .unverified:
            if let shouldVerify = json["shouldVerify"] as? Bool, shouldVerify {
                updated.isVerified = true
                updated.verifiedAt = ISO8601DateFormatter().string(from: Date())
                updated.verificationMethod = "Claude AI Review"
            }

        case .duplicates, .shortNames:
            if let name = json["canonicalName"] as? String ?? json["expandedName"] as? String {
                updated.name = name
            }

        case .missingServingSize:
            if let servingSizeG = json["servingSizeG"] as? Double {
                updated.servingSizeG = servingSizeG
            } else if let servingSizeG = json["servingSizeG"] as? Int {
                updated.servingSizeG = Double(servingSizeG)
            }
            if let desc = json["servingDescription"] as? String {
                updated.servingDescription = desc
            }

        case .noSource:
            if let source = json["source"] as? String {
                updated.source = source
            }

        case .offImages:
            if let action = json["action"] as? String, action == "remove" {
                updated.imageURL = nil
                updated.thumbnailURL = nil
            }

        case .highProtein:
            if let isCorrect = json["isCorrect"] as? Bool, !isCorrect {
                if let corrected = json["correctedProtein"] as? Double {
                    updated.protein = corrected
                }
            }

        default:
            return nil
        }

        return updated
    }

    private func extractBrandsWithClaude() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Extracting brands with Claude..."

        for food in foodsToFix {
            processingStatus = "Analysing: \(food.name)..."

            // Try to extract brand from name using common patterns
            if let extracted = extractBrandFromName(food.name) {
                var updatedFood = food
                updatedFood.brand = extracted.brand
                updatedFood.name = extracted.cleanName

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            } else {
                // Use Claude for complex cases
                if let result = await askClaudeToExtractBrand(food) {
                    var updatedFood = food
                    updatedFood.brand = result.brand
                    if let cleanName = result.cleanName {
                        updatedFood.name = cleanName
                    }

                    let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                    if success {
                        updateFoodInResults(updatedFood)
                    }
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func extractBrandFromName(_ name: String) -> (brand: String, cleanName: String)? {
        // Common brand separators
        let separators = [" - ", " – ", " — ", " | ", ": ", " by "]

        for separator in separators {
            if let range = name.range(of: separator) {
                let firstPart = String(name[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                let secondPart = String(name[range.upperBound...]).trimmingCharacters(in: .whitespaces)

                // Usually brand comes first
                if firstPart.count < secondPart.count && firstPart.count <= 30 {
                    return (brand: firstPart, cleanName: secondPart)
                }
            }
        }

        // Check for brand in parentheses at end: "Product Name (Brand)"
        if let parenStart = name.lastIndex(of: "("),
           let parenEnd = name.lastIndex(of: ")"),
           parenStart < parenEnd {
            let brand = String(name[name.index(after: parenStart)..<parenEnd]).trimmingCharacters(in: .whitespaces)
            let cleanName = String(name[..<parenStart]).trimmingCharacters(in: .whitespaces)
            if brand.count <= 30 && !cleanName.isEmpty {
                return (brand: brand, cleanName: cleanName)
            }
        }

        return nil
    }

    private func askClaudeToExtractBrand(_ food: FoodItem) async -> (brand: String, cleanName: String?)? {
        let prompt = """
        Analyse this food name and extract the brand if present:
        "\(food.name)"

        Common UK brands include: Tesco, Sainsbury's, ASDA, Morrisons, Waitrose, M&S, Aldi, Lidl, Co-op, Birds Eye, McCain, Heinz, Kellogg's, Cadbury, etc.

        If there's a brand in the name, respond with JSON:
        {"brand": "Brand Name", "cleanName": "Product name without brand"}

        If no brand can be identified, respond with:
        {"brand": null}
        """

        do {
            let response = try await callClaudeAPI(prompt: prompt)
            if let data = response.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let brand = json["brand"] as? String {
                let cleanName = json["cleanName"] as? String
                return (brand: brand, cleanName: cleanName)
            }
        } catch {
            print("Claude API error: \(error)")
        }
        return nil
    }

    private func lookupBrandsViaBarcode() async {
        let foodsToFix = selectedFoodsArray.filter { $0.barcode != nil && !$0.barcode!.isEmpty }
        guard !foodsToFix.isEmpty else {
            errorMessage = "No selected foods have barcodes to look up"
            return
        }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Looking up brands via barcode..."

        for food in foodsToFix {
            guard let barcode = food.barcode else { continue }
            processingStatus = "Looking up: \(barcode)..."

            if let productData = await lookupBarcode(barcode) {
                var updatedFood = food
                if let brand = productData.brand, !brand.isEmpty {
                    updatedFood.brand = brand
                }
                if let name = productData.name, !name.isEmpty {
                    updatedFood.name = name
                }
                if let imageURL = productData.imageURL, !imageURL.isEmpty {
                    updatedFood.imageURL = imageURL
                }

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func fetchIngredientsViaBarcode() async {
        let foodsToFix = selectedFoodsArray.filter { $0.barcode != nil && !$0.barcode!.isEmpty }
        guard !foodsToFix.isEmpty else {
            errorMessage = "No selected foods have barcodes to look up"
            return
        }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Fetching ingredients via barcode..."

        for food in foodsToFix {
            guard let barcode = food.barcode else { continue }
            processingStatus = "Looking up: \(barcode)..."

            if let productData = await lookupBarcode(barcode) {
                var updatedFood = food
                if let ingredients = productData.ingredients {
                    updatedFood.ingredients = ingredients
                }
                if let ingredientsText = productData.ingredientsText {
                    updatedFood.ingredientsText = ingredientsText
                }

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func searchAndEnrich() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Searching for product data..."

        for food in foodsToFix {
            processingStatus = "Searching: \(food.name)..."

            // Try barcode first if available
            if let barcode = food.barcode, !barcode.isEmpty {
                if let productData = await lookupBarcode(barcode) {
                    var updatedFood = food
                    if let imageURL = productData.imageURL, !imageURL.isEmpty, food.imageURL == nil {
                        updatedFood.imageURL = imageURL
                    }
                    if let brand = productData.brand, !brand.isEmpty, food.brand == nil {
                        updatedFood.brand = brand
                    }

                    let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                    if success {
                        updateFoodInResults(updatedFood)
                    }
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func fixNutritionWithClaude() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Fixing nutrition with Claude..."

        for food in foodsToFix {
            processingStatus = "Analysing: \(food.name)..."

            // First try barcode lookup
            if let barcode = food.barcode, !barcode.isEmpty,
               let productData = await lookupBarcode(barcode) {
                var updatedFood = food
                if let cal = productData.calories { updatedFood.calories = cal }
                if let protein = productData.protein { updatedFood.protein = protein }
                if let carbs = productData.carbs { updatedFood.carbs = carbs }
                if let fat = productData.fat { updatedFood.fat = fat }

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                    processedCount += 1
                    continue
                }
            }

            // Fall back to Claude estimation
            if let corrected = await askClaudeToFixNutrition(food) {
                var updatedFood = food
                updatedFood.calories = corrected.calories
                updatedFood.protein = corrected.protein
                updatedFood.carbs = corrected.carbs
                updatedFood.fat = corrected.fat

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func askClaudeToFixNutrition(_ food: FoodItem) async -> (calories: Double, protein: Double, carbs: Double, fat: Double)? {
        let prompt = """
        This food has implausible nutrition values. Please estimate correct values per 100g:

        Name: \(food.name)
        Brand: \(food.brand ?? "Unknown")
        Current values (per 100g):
        - Calories: \(food.calories) kcal
        - Protein: \(food.protein)g
        - Carbs: \(food.carbs)g
        - Fat: \(food.fat)g

        The macros should roughly add up: (protein×4) + (carbs×4) + (fat×9) ≈ calories

        Respond with corrected values as JSON:
        {"calories": 123, "protein": 12.3, "carbs": 45.6, "fat": 7.8}
        """

        do {
            let response = try await callClaudeAPI(prompt: prompt)
            if let data = response.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let cal = (json["calories"] as? Double) ?? (json["calories"] as? Int).map { Double($0) }
                let protein = json["protein"] as? Double
                let carbs = json["carbs"] as? Double
                let fat = json["fat"] as? Double

                if let cal = cal, let protein = protein, let carbs = carbs, let fat = fat {
                    return (calories: cal, protein: protein, carbs: carbs, fat: fat)
                }
            }
        } catch {
            print("Claude API error: \(error)")
        }
        return nil
    }

    private func lookupNutritionViaBarcode() async {
        let foodsToFix = selectedFoodsArray.filter { $0.barcode != nil && !$0.barcode!.isEmpty }
        guard !foodsToFix.isEmpty else {
            errorMessage = "No selected foods have barcodes to look up"
            return
        }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Looking up nutrition via barcode..."

        for food in foodsToFix {
            guard let barcode = food.barcode else { continue }
            processingStatus = "Looking up: \(barcode)..."

            if let productData = await lookupBarcode(barcode) {
                var updatedFood = food
                if let cal = productData.calories { updatedFood.calories = cal }
                if let protein = productData.protein { updatedFood.protein = protein }
                if let carbs = productData.carbs { updatedFood.carbs = carbs }
                if let fat = productData.fat { updatedFood.fat = fat }
                if let fiber = productData.fiber { updatedFood.fiber = fiber }
                if let sugar = productData.sugar { updatedFood.sugar = sugar }

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func calculateProcessingGrades() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Calculating processing grades..."

        for food in foodsToFix {
            processingStatus = "Processing: \(food.name)..."

            var updatedFood = food
            let (score, grade, label) = calculateProcessingScore(food)
            updatedFood.processingScore = score
            updatedFood.processingGrade = grade
            updatedFood.processingLabel = label

            let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
            if success {
                updateFoodInResults(updatedFood)
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func calculateProcessingScore(_ food: FoodItem) -> (score: Int, grade: String, label: String) {
        var score = 100

        // Deduct for additives
        if let additives = food.additives {
            score -= additives.count * 5
        }

        // Deduct for high sodium
        if food.sodium > 600 { score -= 10 }

        // Deduct for high sugar
        if food.sugar > 15 { score -= 10 }

        // Deduct for saturated fat
        if let satFat = food.saturatedFat, satFat > 5 { score -= 10 }

        // Bonus for fiber
        if food.fiber > 3 { score += 5 }

        // Bonus for protein
        if food.protein > 10 { score += 5 }

        score = max(0, min(100, score))

        let grade: String
        let label: String
        switch score {
        case 80...100:
            grade = "A"
            label = "Minimally Processed"
        case 60..<80:
            grade = "B"
            label = "Lightly Processed"
        case 40..<60:
            grade = "C"
            label = "Moderately Processed"
        case 20..<40:
            grade = "D"
            label = "Highly Processed"
        default:
            grade = "E"
            label = "Ultra-Processed"
        }

        return (score, grade, label)
    }

    private func verifyViaBarcode() async {
        let foodsToFix = selectedFoodsArray.filter { $0.barcode != nil && !$0.barcode!.isEmpty }
        guard !foodsToFix.isEmpty else {
            errorMessage = "No selected foods have barcodes to verify"
            return
        }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Verifying via barcode..."

        for food in foodsToFix {
            guard let barcode = food.barcode else { continue }
            processingStatus = "Verifying: \(barcode)..."

            if let productData = await lookupBarcode(barcode) {
                var updatedFood = food

                // Update with verified data
                if let name = productData.name, !name.isEmpty { updatedFood.name = name }
                if let brand = productData.brand, !brand.isEmpty { updatedFood.brand = brand }
                if let imageURL = productData.imageURL, !imageURL.isEmpty { updatedFood.imageURL = imageURL }
                if let cal = productData.calories { updatedFood.calories = cal }
                if let protein = productData.protein { updatedFood.protein = protein }
                if let carbs = productData.carbs { updatedFood.carbs = carbs }
                if let fat = productData.fat { updatedFood.fat = fat }
                if let ingredients = productData.ingredients { updatedFood.ingredients = ingredients }

                updatedFood.isVerified = true
                updatedFood.verifiedAt = ISO8601DateFormatter().string(from: Date())
                updatedFood.verificationMethod = "Barcode Lookup"

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func markAsVerified() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Marking as verified..."

        for food in foodsToFix {
            var updatedFood = food
            updatedFood.isVerified = true
            updatedFood.verifiedAt = ISO8601DateFormatter().string(from: Date())
            updatedFood.verificationMethod = "Manual"

            let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
            if success {
                updateFoodInResults(updatedFood)
            }

            processedCount += 1
            processingStatus = "Verified \(processedCount) of \(totalToProcess)..."
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func mergeDuplicates() async {
        // Group selected foods by normalized name
        let foodsToFix = selectedFoodsArray
        guard foodsToFix.count >= 2 else {
            errorMessage = "Select at least 2 foods to merge"
            return
        }

        var grouped: [String: [FoodItem]] = [:]
        for food in foodsToFix {
            let key = food.name.lowercased().trimmingCharacters(in: .whitespaces)
            grouped[key, default: []].append(food)
        }

        isProcessing = true
        var totalMerged = 0
        processingStatus = "Merging duplicates..."

        for (_, duplicates) in grouped where duplicates.count >= 2 {
            // Keep the most complete record
            let sorted = duplicates.sorted { scoreCompleteness($0) > scoreCompleteness($1) }
            let keeper = sorted[0]
            let toDelete = sorted.dropFirst()

            // Delete the duplicates
            for food in toDelete {
                let success = await algoliaService.deleteFood(objectID: food.objectID, database: appState.selectedDatabase)
                if success {
                    removeFoodFromResults(food.objectID)
                    totalMerged += 1
                }
            }
        }

        selectedFoods.removeAll()
        isProcessing = false
        processingStatus = "Merged \(totalMerged) duplicates"
    }

    private func scoreCompleteness(_ food: FoodItem) -> Int {
        var score = 0
        if food.brand != nil && !food.brand!.isEmpty { score += 10 }
        if food.barcode != nil && !food.barcode!.isEmpty { score += 10 }
        if food.imageURL != nil && !food.imageURL!.isEmpty { score += 10 }
        if food.ingredients != nil && !food.ingredients!.isEmpty { score += 10 }
        if food.isVerified == true { score += 20 }
        if food.processingGrade != nil { score += 5 }
        return score
    }

    private func expandNamesWithClaude() async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Expanding names with Claude..."

        for food in foodsToFix {
            processingStatus = "Expanding: \(food.name)..."

            if let expanded = await askClaudeToExpandName(food) {
                var updatedFood = food
                updatedFood.name = expanded

                let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                if success {
                    updateFoodInResults(updatedFood)
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func askClaudeToExpandName(_ food: FoodItem) async -> String? {
        let prompt = """
        This food has a very short name: "\(food.name)"
        Brand: \(food.brand ?? "Unknown")
        Calories: \(food.calories) kcal per 100g

        Please provide a more descriptive product name. Just respond with the expanded name, nothing else.
        """

        do {
            let response = try await callClaudeAPI(prompt: prompt)
            let cleanedName = response.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
            if cleanedName.count > food.name.count && cleanedName.count < 100 {
                return cleanedName
            }
        } catch {
            print("Claude API error: \(error)")
        }
        return nil
    }

    private func setSourceManually(_ source: String) async {
        let foodsToFix = selectedFoodsArray
        guard !foodsToFix.isEmpty else { return }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Setting source..."

        for food in foodsToFix {
            var updatedFood = food
            updatedFood.source = source

            let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
            if success {
                updateFoodInResults(updatedFood)
            }

            processedCount += 1
            processingStatus = "Updated \(processedCount) of \(totalToProcess)..."
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    private func findBetterImages() async {
        let foodsToFix = selectedFoodsArray.filter { $0.barcode != nil && !$0.barcode!.isEmpty }
        guard !foodsToFix.isEmpty else {
            errorMessage = "No selected foods have barcodes to look up images"
            return
        }

        isProcessing = true
        totalToProcess = foodsToFix.count
        processedCount = 0
        processingStatus = "Finding better images..."

        for food in foodsToFix {
            guard let barcode = food.barcode else { continue }
            processingStatus = "Searching: \(barcode)..."

            // Try UK retailer APIs first for better quality images
            if let productData = await lookupBarcode(barcode) {
                if let imageURL = productData.imageURL,
                   !imageURL.isEmpty,
                   !imageURL.contains("openfoodfacts"),
                   !imageURL.contains("off.org") {
                    var updatedFood = food
                    updatedFood.imageURL = imageURL

                    let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)
                    if success {
                        updateFoodInResults(updatedFood)
                    }
                }
            }

            processedCount += 1
        }

        selectedFoods.removeAll()
        isProcessing = false
    }

    // MARK: - Helper Methods

    private var selectedFoodsArray: [FoodItem] {
        allFoods.filter { selectedFoods.contains($0.objectID) }
    }

    private func updateFoodInResults(_ food: FoodItem) {
        // Update in allFoods
        if let index = allFoods.firstIndex(where: { $0.objectID == food.objectID }) {
            allFoods[index] = food
        }

        // Update or remove from validation results
        for (category, foods) in validationResults {
            if let index = foods.firstIndex(where: { $0.objectID == food.objectID }) {
                // Check if the food still has this issue
                if foodStillHasIssue(food, for: category) {
                    validationResults[category]?[index] = food
                } else {
                    validationResults[category]?.remove(at: index)
                }
            }
        }
    }

    private func removeFoodFromResults(_ objectID: String) {
        allFoods.removeAll { $0.objectID == objectID }
        for (category, _) in validationResults {
            validationResults[category]?.removeAll { $0.objectID == objectID }
        }
    }

    private func foodStillHasIssue(_ food: FoodItem, for category: ValidationCategory) -> Bool {
        switch category {
        case .missingBrand:
            return (food.brand == nil || food.brand!.isEmpty) && !isGenericFood(food)
        case .missingIngredients:
            return (food.ingredients == nil || food.ingredients!.isEmpty) &&
                   (food.ingredientsText == nil || food.ingredientsText!.isEmpty)
        case .missingBarcode:
            return food.barcode == nil || food.barcode!.isEmpty
        case .missingImage:
            return food.imageURL == nil || food.imageURL!.isEmpty
        case .zeroCalories:
            return food.calories == 0
        case .implausibleNutrition:
            let calc = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9)
            let diff = abs(calc - food.calories)
            let tolerance = max(food.calories * 0.2, 50)
            return diff > tolerance && food.calories > 0
        case .highCalories:
            return food.calories > 900
        case .missingProcessingGrade:
            return food.processingGrade == nil || food.processingGrade!.isEmpty
        case .unverified:
            return food.isVerified != true
        case .duplicates:
            return true // Keep in list until manually removed
        case .shortNames:
            return food.name.count < 3
        case .missingServingSize:
            return (food.servingSizeG == nil || food.servingSizeG == 0) &&
                   (food.servingDescription == nil || food.servingDescription!.isEmpty)
        case .negativeValues:
            return food.calories < 0 || food.protein < 0 || food.carbs < 0 ||
                   food.fat < 0 || food.fiber < 0 || food.sugar < 0 || food.sodium < 0
        case .noSource:
            return food.source == nil || food.source!.isEmpty
        case .offImages:
            guard let url = food.imageURL else { return false }
            return url.contains("openfoodfacts") || url.contains("off.org")
        case .highProtein:
            return food.protein > 50
        }
    }

    // MARK: - API Helpers

    private func lookupBarcode(_ barcode: String) async -> ProductLookupResult? {
        // Try Open Food Facts first
        let offURL = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json"

        do {
            guard let url = URL(string: offURL) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? Int, status == 1,
               let product = json["product"] as? [String: Any] {

                return ProductLookupResult(
                    name: product["product_name"] as? String,
                    brand: product["brands"] as? String,
                    imageURL: product["image_front_url"] as? String,
                    calories: (product["nutriments"] as? [String: Any])?["energy-kcal_100g"] as? Double,
                    protein: (product["nutriments"] as? [String: Any])?["proteins_100g"] as? Double,
                    carbs: (product["nutriments"] as? [String: Any])?["carbohydrates_100g"] as? Double,
                    fat: (product["nutriments"] as? [String: Any])?["fat_100g"] as? Double,
                    fiber: (product["nutriments"] as? [String: Any])?["fiber_100g"] as? Double,
                    sugar: (product["nutriments"] as? [String: Any])?["sugars_100g"] as? Double,
                    ingredients: nil,
                    ingredientsText: product["ingredients_text"] as? String
                )
            }
        } catch {
            print("OFF lookup failed: \(error)")
        }

        return nil
    }

    private func callClaudeAPI(prompt: String) async throws -> String {
        // Get API key from UserDefaults - must be configured via Settings
        let apiKey = UserDefaults.standard.string(forKey: "claude_api_key") ?? ""
        guard !apiKey.isEmpty else {
            throw NSError(domain: "ClaudeService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Claude API key not configured. Please set it in Settings."])
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "messages": [["role": "user", "content": prompt]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let content = json["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        }

        throw NSError(domain: "ClaudeAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
    }
}

// MARK: - Product Lookup Result

struct ProductLookupResult {
    let name: String?
    let brand: String?
    let imageURL: String?
    let calories: Double?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let fiber: Double?
    let sugar: Double?
    let ingredients: [String]?
    let ingredientsText: String?
}

// MARK: - Validation Option Toggle

struct ValidationOptionToggle: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isOn ? .blue : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .blue : .secondary)
            }
            .padding()
            .background(isOn ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isOn ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Validation Food Row

struct ValidationFoodRow: View {
    let food: FoodItem
    let category: ValidationCategory
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button {
                onToggleSelect()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)

            // Image
            if let imageURL = food.thumbnailURL ?? food.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fit).cornerRadius(4)
                    case .failure:
                        Image(systemName: "photo").foregroundColor(.secondary)
                    case .empty:
                        ProgressView().scaleEffect(0.5)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 40, height: 40)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary.opacity(0.3))
                    .frame(width: 40, height: 40)
            }

            // Food info
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let brand = food.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text("No brand")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                            .italic()
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(Int(food.calories)) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Issue-specific info
                issueInfoView
            }

            Spacer()

            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete this food")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
    }

    @ViewBuilder
    private var issueInfoView: some View {
        switch category {
        case .implausibleNutrition:
            let calculated = (food.protein * 4) + (food.carbs * 4) + (food.fat * 9)
            Text("Calculated: \(Int(calculated)) kcal vs \(Int(food.calories)) kcal")
                .font(.caption2)
                .foregroundColor(.orange)
        case .highCalories:
            Text("\(Int(food.calories)) kcal per 100g")
                .font(.caption2)
                .foregroundColor(.orange)
        case .highProtein:
            Text("\(String(format: "%.1f", food.protein))g protein per 100g")
                .font(.caption2)
                .foregroundColor(.orange)
        case .offImages:
            if let url = food.imageURL {
                Text(url.prefix(60) + "...")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Validation Types

enum ValidationCategory: String, CaseIterable, Hashable {
    case missingBrand
    case missingIngredients
    case missingBarcode
    case missingImage
    case zeroCalories
    case implausibleNutrition
    case highCalories
    case missingProcessingGrade
    case unverified
    case duplicates
    case shortNames
    case missingServingSize
    case negativeValues
    case noSource
    case offImages
    case highProtein

    var title: String {
        switch self {
        case .missingBrand: return "Missing Brand"
        case .missingIngredients: return "Missing Ingredients"
        case .missingBarcode: return "Missing Barcode"
        case .missingImage: return "Missing Image"
        case .zeroCalories: return "Zero Calories"
        case .implausibleNutrition: return "Implausible Nutrition"
        case .highCalories: return "Very High Calories"
        case .missingProcessingGrade: return "Missing Processing Grade"
        case .unverified: return "Unverified"
        case .duplicates: return "Duplicates"
        case .shortNames: return "Short Names"
        case .missingServingSize: return "Missing Serving Size"
        case .negativeValues: return "Negative Values"
        case .noSource: return "No Source"
        case .offImages: return "Open Food Facts Images"
        case .highProtein: return "Suspicious Protein"
        }
    }

    var description: String {
        switch self {
        case .missingBrand: return "Non-generic foods without brand"
        case .missingIngredients: return "No ingredient list"
        case .missingBarcode: return "No barcode"
        case .missingImage: return "No product image"
        case .zeroCalories: return "0 kcal (likely error)"
        case .implausibleNutrition: return "Macros don't match calories"
        case .highCalories: return ">900 kcal per 100g"
        case .missingProcessingGrade: return "No NOVA grade"
        case .unverified: return "Not yet verified"
        case .duplicates: return "Same name as other foods"
        case .shortNames: return "Less than 3 characters"
        case .missingServingSize: return "No serving info"
        case .negativeValues: return "Negative nutrition values"
        case .noSource: return "No data source listed"
        case .offImages: return "Low quality OFF images"
        case .highProtein: return ">50g protein per 100g"
        }
    }

    var icon: String {
        switch self {
        case .missingBrand: return "tag.slash"
        case .missingIngredients: return "list.bullet.clipboard"
        case .missingBarcode: return "barcode"
        case .missingImage: return "photo"
        case .zeroCalories: return "flame.badge.minus"
        case .implausibleNutrition: return "exclamationmark.triangle"
        case .highCalories: return "flame.fill"
        case .missingProcessingGrade: return "gauge.medium"
        case .unverified: return "checkmark.seal"
        case .duplicates: return "doc.on.doc"
        case .shortNames: return "textformat.size.smaller"
        case .missingServingSize: return "scalemass"
        case .negativeValues: return "minus.circle"
        case .noSource: return "questionmark.folder"
        case .offImages: return "photo.badge.exclamationmark"
        case .highProtein: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .missingBrand, .missingIngredients, .missingBarcode, .missingImage, .missingProcessingGrade, .missingServingSize, .noSource:
            return .orange
        case .zeroCalories, .implausibleNutrition, .negativeValues:
            return .red
        case .highCalories, .highProtein:
            return .purple
        case .unverified:
            return .blue
        case .duplicates, .shortNames:
            return .yellow
        case .offImages:
            return .pink
        }
    }
}

struct ValidationOptions {
    var checkMissingBrand = true
    var checkMissingIngredients = true
    var checkMissingBarcode = false
    var checkMissingImage = false
    var checkZeroCalories = true
    var checkImplausibleNutrition = true
    var checkHighCalories = false
    var checkMissingProcessingGrade = false
    var checkUnverified = false
    var checkDuplicates = false
    var checkShortNames = false
    var checkMissingServingSize = false
    var checkNegativeValues = true
    var checkNoSource = false
    var checkOFFImages = false
    var checkHighProtein = false

    var hasAnySelected: Bool {
        checkMissingBrand || checkMissingIngredients || checkMissingBarcode ||
        checkMissingImage || checkZeroCalories || checkImplausibleNutrition ||
        checkHighCalories || checkMissingProcessingGrade || checkUnverified ||
        checkDuplicates || checkShortNames || checkMissingServingSize ||
        checkNegativeValues || checkNoSource || checkOFFImages || checkHighProtein
    }

    mutating func selectAll() {
        checkMissingBrand = true
        checkMissingIngredients = true
        checkMissingBarcode = true
        checkMissingImage = true
        checkZeroCalories = true
        checkImplausibleNutrition = true
        checkHighCalories = true
        checkMissingProcessingGrade = true
        checkUnverified = true
        checkDuplicates = true
        checkShortNames = true
        checkMissingServingSize = true
        checkNegativeValues = true
        checkNoSource = true
        checkOFFImages = true
        checkHighProtein = true
    }

    mutating func selectNone() {
        checkMissingBrand = false
        checkMissingIngredients = false
        checkMissingBarcode = false
        checkMissingImage = false
        checkZeroCalories = false
        checkImplausibleNutrition = false
        checkHighCalories = false
        checkMissingProcessingGrade = false
        checkUnverified = false
        checkDuplicates = false
        checkShortNames = false
        checkMissingServingSize = false
        checkNegativeValues = false
        checkNoSource = false
        checkOFFImages = false
        checkHighProtein = false
    }

    mutating func selectCommon() {
        selectNone()
        checkMissingBrand = true
        checkMissingIngredients = true
        checkZeroCalories = true
        checkImplausibleNutrition = true
        checkNegativeValues = true
        checkDuplicates = true
    }
}

// MARK: - User Reports Sheet

struct UserReportsSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var reportsService = UserReportsService()
    @Environment(\.dismiss) var dismiss

    @State private var selectedFilter: UserReport.ReportStatus? = .pending
    @State private var selectedReport: UserReport?
    @State private var showingFoodEditor = false
    @State private var editingFoodId: String?
    @State private var isProcessingAction = false
    @State private var detailRefreshTrigger = UUID()  // Trigger to force detail view refresh
    @State private var savedFoodId: String? = nil  // Stores the actual food ID after save (may differ from report's food ID)

    var filteredReports: [UserReport] {
        guard let filter = selectedFilter else { return reportsService.reports }
        return reportsService.reports.filter { $0.status == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("User Reports")
                    .font(.title2)
                    .fontWeight(.semibold)

                if reportsService.pendingCount > 0 {
                    Text("\(reportsService.pendingCount) pending")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }

                Spacer()

                Button {
                    Task {
                        await reportsService.fetchReports()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(reportsService.isLoading)

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            // Filter tabs
            HStack(spacing: 0) {
                FilterTab(title: "All", count: reportsService.reports.count, isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }

                ForEach(UserReport.ReportStatus.allCases, id: \.self) { status in
                    FilterTab(
                        title: status.displayName,
                        count: reportsService.reports.filter { $0.status == status }.count,
                        isSelected: selectedFilter == status
                    ) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content
            if reportsService.isLoading {
                Spacer()
                ProgressView("Loading reports...")
                Spacer()
            } else if filteredReports.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No reports")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(selectedFilter == nil ? "No user reports yet" : "No \(selectedFilter!.displayName.lowercased()) reports")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                HSplitView {
                    // Reports table with horizontal scroll
                    VStack(spacing: 0) {
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            VStack(spacing: 0) {
                                // Table header
                                HStack(spacing: 0) {
                                    Text("Status")
                                        .frame(width: 100, alignment: .leading)
                                    Text("Food Name")
                                        .frame(width: 250, alignment: .leading)
                                    Text("Brand")
                                        .frame(width: 150, alignment: .leading)
                                    Text("Reporter")
                                        .frame(width: 200, alignment: .leading)
                                    Text("Reported")
                                        .frame(width: 120, alignment: .trailing)
                                }
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))

                                Divider()

                                // Table rows
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredReports) { report in
                                        ReportTableRow(
                                            report: report,
                                            isSelected: selectedReport?.id == report.id,
                                            onSelect: {
                                                // Clear saved food ID override when selecting a different report
                                                if selectedReport?.id != report.id {
                                                    savedFoodId = nil
                                                }
                                                selectedReport = report
                                            }
                                        )
                                        Divider()
                                    }
                                }
                            }
                            .frame(minWidth: 820) // Total width of all columns
                        }
                    }
                    .frame(minWidth: 500)

                    // Detail view
                    if let report = selectedReport {
                        ScrollView {
                            ReportDetailView(
                                report: report,
                                onEdit: { foodId in
                                    editingFoodId = foodId
                                    showingFoodEditor = true
                                },
                                onUpdateStatus: { status in
                                    Task {
                                        isProcessingAction = true
                                        _ = await reportsService.updateReportStatus(reportId: report.id, status: status)
                                        isProcessingAction = false
                                    }
                                },
                                onDelete: {
                                    Task {
                                        isProcessingAction = true
                                        _ = await reportsService.deleteReport(reportId: report.id)
                                        selectedReport = nil
                                        isProcessingAction = false
                                    }
                                },
                                isProcessing: isProcessingAction,
                                refreshTrigger: detailRefreshTrigger,
                                overrideFoodId: savedFoodId
                            )
                            .environmentObject(algoliaService)
                        }
                        .frame(minWidth: 400)
                    } else {
                        VStack {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Select a report to view details")
                                .foregroundColor(.secondary)
                        }
                        .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            Task {
                await reportsService.fetchReports()
            }
        }
        .sheet(isPresented: $showingFoodEditor) {
            if let foodId = editingFoodId {
                FullFoodEditorSheet(
                    foodId: foodId,
                    reportId: selectedReport?.id ?? "",
                    onSave: { updatedFood in
                        // Store the saved food ID for the detail view to use
                        savedFoodId = updatedFood.objectID
                        print("📝 Saved food ID: \(updatedFood.objectID)")

                        Task {
                            // Save the updated food to Algolia
                            let success = await algoliaService.saveFood(updatedFood, database: .foods)
                            if success {
                                // Mark report as resolved
                                if let reportId = selectedReport?.id {
                                    _ = await reportsService.updateReportStatus(reportId: reportId, status: .resolved, notes: "Food updated via Database Manager")
                                }
                                // Trigger detail view refresh
                                detailRefreshTrigger = UUID()
                            }
                        }
                    }
                )
                .environmentObject(algoliaService)
            }
        }
    }
}

// MARK: - User Reports Content View (Full Page)

// Wrapper struct for sheet(item:) - contains the report with embedded food data
struct EditingReportItem: Identifiable {
    let id: String  // report ID (for Identifiable)
    let report: UserReport
}

struct UserReportsContentView: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var reportsService = UserReportsService()

    @State private var selectedFilter: UserReport.ReportStatus? = .pending
    @State private var selectedReport: UserReport?
    @State private var editingReport: EditingReportItem?  // Using item-based sheet with full report
    @State private var isProcessingAction = false
    @State private var detailRefreshTrigger = UUID()  // Trigger to force detail view refresh
    @State private var savedFoodId: String? = nil  // Stores the actual food ID after save (may differ from report's food ID)

    var filteredReports: [UserReport] {
        guard let filter = selectedFilter else { return reportsService.reports }
        return reportsService.reports.filter { $0.status == filter }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("User Reports")
                    .font(.headline)

                if reportsService.pendingCount > 0 {
                    Text("\(reportsService.pendingCount) pending")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }

                Spacer()

                // Filter tabs in toolbar
                HStack(spacing: 4) {
                    ReportFilterButton(title: "All", count: reportsService.reports.count, isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }

                    ForEach(UserReport.ReportStatus.allCases, id: \.self) { status in
                        ReportFilterButton(
                            title: status.displayName,
                            count: reportsService.reports.filter { $0.status == status }.count,
                            isSelected: selectedFilter == status
                        ) {
                            selectedFilter = status
                        }
                    }
                }

                Divider()
                    .frame(height: 20)

                Button {
                    Task {
                        await reportsService.fetchReports()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .disabled(reportsService.isLoading)
                .help("Refresh")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            if reportsService.isLoading && reportsService.reports.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Loading reports...")
                    Spacer()
                }
            } else if filteredReports.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No reports")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(selectedFilter == nil ? "No user reports yet" : "No \(selectedFilter!.displayName.lowercased()) reports")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                HSplitView {
                    // Reports table - header pinned, content scrolls
                    VStack(spacing: 0) {
                        // PINNED header - outside scroll view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                Text("Status")
                                    .frame(width: 110, alignment: .leading)
                                Text("Food Name")
                                    .frame(width: 220, alignment: .leading)
                                Text("Brand")
                                    .frame(width: 140, alignment: .leading)
                                Text("Reporter")
                                    .frame(width: 180, alignment: .leading)
                                Text("Reported")
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .frame(minWidth: 750)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .disabled(true) // Header scroll syncs visually but user scrolls via content

                        Divider()

                        // Scrollable content - both directions
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            LazyVStack(spacing: 0, pinnedViews: []) {
                                ForEach(filteredReports) { report in
                                    ReportTableRow(
                                        report: report,
                                        isSelected: selectedReport?.id == report.id,
                                        onSelect: {
                                            // Clear saved food ID override when selecting a different report
                                            if selectedReport?.id != report.id {
                                                savedFoodId = nil
                                            }
                                            selectedReport = report
                                        }
                                    )
                                    Divider()
                                }
                            }
                            .frame(minWidth: 750)
                        }
                    }
                    .frame(minWidth: 400, idealWidth: 550)

                    // Detail view
                    if let report = selectedReport {
                        ReportDetailView(
                            report: report,
                            onEdit: { _ in
                                // Pass the whole report so we can use the embedded food data
                                editingReport = EditingReportItem(id: report.id, report: report)
                            },
                            onUpdateStatus: { status in
                                Task {
                                    isProcessingAction = true
                                    _ = await reportsService.updateReportStatus(reportId: report.id, status: status)
                                    isProcessingAction = false
                                }
                            },
                            onDelete: {
                                Task {
                                    isProcessingAction = true
                                    _ = await reportsService.deleteReport(reportId: report.id)
                                    selectedReport = nil
                                    isProcessingAction = false
                                }
                            },
                            isProcessing: isProcessingAction,
                            refreshTrigger: detailRefreshTrigger,
                            overrideFoodId: savedFoodId
                        )
                        .environmentObject(algoliaService)
                        .frame(minWidth: 350, idealWidth: 450, maxHeight: .infinity, alignment: .top)
                    } else {
                        VStack {
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Select a report to view details")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(minWidth: 350, maxWidth: .infinity)
                    }
                }
            }

            // Status bar
            HStack {
                if reportsService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Text("\(filteredReports.count) reports")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let filter = selectedFilter {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(filter.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let error = reportsService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewColumnWidth(min: 600, ideal: 900, max: .infinity)
        .task {
            await reportsService.fetchReports()
        }
        .sheet(item: $editingReport) { editItem in
            ReportFoodEditorSheet(
                report: editItem.report,
                onSave: { savedFood in
                    // Food was already saved by ReportFoodEditorSheet
                    // Store the actual saved food ID (may differ from report's food ID if it matched an existing food)
                    savedFoodId = savedFood.objectID
                    print("📝 Saved food ID: \(savedFood.objectID) (report's food ID was: \(editItem.report.food?.id ?? editItem.report.foodId ?? "unknown"))")

                    // Refresh the reports list and force the detail view to reload from database
                    Task {
                        await reportsService.fetchReports(status: selectedFilter)
                        // Trigger refresh of detail view by changing the UUID
                        // This causes onChange(of: refreshTrigger) to fire and reload from database
                        detailRefreshTrigger = UUID()
                        print("✅ Triggered detail refresh with new UUID: \(detailRefreshTrigger)")
                    }
                }
            )
            .environmentObject(algoliaService)
        }
    }
}

// MARK: - Report Filter Button

struct ReportFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                Text("\(count)")
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Tab

struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .fontWeight(isSelected ? .semibold : .regular)
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
                .foregroundColor(isSelected ? .accentColor : .secondary)

                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 80)
    }
}

// MARK: - Report Row View

struct ReportRowView: View {
    let report: UserReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: report.status.icon)
                    .foregroundColor(statusColor)
                    .font(.caption)

                Text(report.foodName)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Spacer()

                Text(report.reportedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                if let brand = report.brandName, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let barcode = report.barcode, !barcode.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(barcode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(report.reportedBy.userEmail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    var statusColor: Color {
        switch report.status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }
}

// MARK: - Report Table Row

struct ReportTableRow: View {
    let report: UserReport
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 0) {
                // Status
                HStack(spacing: 4) {
                    Image(systemName: report.status.icon)
                        .foregroundColor(statusColor)
                        .font(.caption)
                    Text(report.status.displayName)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
                .frame(width: 110, alignment: .leading)

                // Food Name
                Text(report.foodName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .frame(width: 220, alignment: .leading)

                // Brand
                Text(report.brandName ?? "-")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)

                // Reporter
                Text(report.reportedBy.userEmail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 180, alignment: .leading)

                // Reported time
                Text(report.reportedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 750)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var statusColor: Color {
        switch report.status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }
}

// MARK: - Report Detail View

struct ReportDetailView: View {
    let report: UserReport
    let onEdit: (String) -> Void  // Now passes food ID
    let onUpdateStatus: (UserReport.ReportStatus) -> Void
    let onDelete: () -> Void
    let isProcessing: Bool
    let refreshTrigger: UUID  // Changes when we need to reload from database
    var overrideFoodId: String? = nil  // If set, load this food ID instead of report's food ID

    @EnvironmentObject var algoliaService: AlgoliaService
    @State private var databaseFood: FoodItem?
    @State private var isLoadingFood = false

    // Use database version if available, otherwise fall back to report's embedded food
    private var displayFood: UserReport.ReportedFood? {
        if let dbFood = databaseFood {
            // Convert FoodItem to ReportedFood for display
            return UserReport.ReportedFood(
                id: dbFood.objectID,
                name: dbFood.name,
                brand: dbFood.brand,
                barcode: dbFood.barcode,
                calories: dbFood.calories,
                protein: dbFood.protein,
                carbs: dbFood.carbs,
                fat: dbFood.fat,
                fiber: dbFood.fiber,
                sugar: dbFood.sugar,
                sodium: dbFood.sodium,
                saturatedFat: dbFood.saturatedFat,
                servingDescription: dbFood.servingDescription,
                servingSizeG: dbFood.servingSizeG,
                ingredients: dbFood.ingredients,
                processingScore: dbFood.processingScore,
                processingGrade: dbFood.processingGrade,
                processingLabel: dbFood.processingLabel,
                isVerified: dbFood.isVerified ?? false
            )
        }
        return report.food
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(report.foodName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .lineLimit(2)

                            Spacer()

                            StatusBadge(status: report.status)
                        }

                        if let brand = report.brandName, !brand.isEmpty {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Report Info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 6) {
                            DetailInfoRow(label: "Reported by", value: report.reportedBy.userEmail)
                            DetailInfoRow(label: "Reported", value: report.reportedAt.formatted(date: .abbreviated, time: .shortened))
                            if let barcode = report.barcode, !barcode.isEmpty {
                            DetailInfoRow(label: "Barcode", value: barcode)
                        }
                        if let foodId = report.foodId {
                            DetailInfoRow(label: "Food ID", value: foodId)
                        }
                    }
                } label: {
                    Text("Report Info")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                // Food Data (if available) - shows database version if loaded
                if isLoadingFood {
                    GroupBox {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading current food data...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text("Food Data")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                } else if let food = displayFood {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            // Nutrition - 2x4 grid
                            // Serving Size
                            if let servingDesc = food.servingDescription, !servingDesc.isEmpty {
                                HStack {
                                    Text("Serving:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(servingDesc)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    if let servingG = food.servingSizeG, servingG > 0 {
                                        Text("(\(Int(servingG))g)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                            } else if let servingG = food.servingSizeG, servingG > 0, servingG != 100 {
                                HStack {
                                    Text("Serving:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(servingG))g")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                .padding(.bottom, 4)
                            }

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                CompactNutritionCell(label: "Calories", value: "\(Int(food.calories))", unit: "kcal")
                                CompactNutritionCell(label: "Protein", value: String(format: "%.1f", food.protein), unit: "g")
                                CompactNutritionCell(label: "Carbs", value: String(format: "%.1f", food.carbs), unit: "g")
                                CompactNutritionCell(label: "Fat", value: String(format: "%.1f", food.fat), unit: "g")
                                CompactNutritionCell(label: "Sat Fat", value: food.saturatedFat != nil ? String(format: "%.1f", food.saturatedFat!) : "-", unit: "g")
                                CompactNutritionCell(label: "Fiber", value: String(format: "%.1f", food.fiber), unit: "g")
                                CompactNutritionCell(label: "Sugar", value: String(format: "%.1f", food.sugar), unit: "g")
                                CompactNutritionCell(label: "Salt", value: String(format: "%.2f", food.sodium / 400), unit: "g")
                            }

                            Divider()

                            // Ingredients
                            if let ingredients = food.ingredients, !ingredients.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ingredients (\(ingredients.count))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(ingredients.joined(separator: ", "))
                                        .font(.caption)
                                        .lineLimit(4)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("No ingredients listed")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }

                            // Verified status
                            HStack(spacing: 4) {
                                Image(systemName: food.isVerified ? "checkmark.seal.fill" : "xmark.seal")
                                    .foregroundColor(food.isVerified ? .green : .red)
                                    .font(.caption)
                                Text(food.isVerified ? "Verified" : "Not Verified")
                                    .font(.caption)
                                    .foregroundColor(food.isVerified ? .green : .red)
                            }

                            // Show source indicator
                            if databaseFood != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.icloud.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("Showing current database data")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Showing data from report (not yet synced)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Food Data")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Button {
                                Task { await loadFoodFromDatabase() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .help("Refresh from database")
                        }
                    }
                } else {
                    GroupBox {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No food data attached")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text("Food Data")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                // Notes
                if let notes = report.notes, !notes.isEmpty {
                    GroupBox {
                        Text(notes)
                            .font(.caption)
                    } label: {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }

                Divider()

                // Actions - reorganized for better UX
                VStack(alignment: .leading, spacing: 10) {
                    Text("Actions")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    // Primary action: Edit & Fix Food - use food ID from report
                    if let foodId = report.food?.id ?? report.foodId {
                        Button {
                            onEdit(foodId)
                        } label: {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                Text("Edit & Update Food")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(isProcessing)
                    } else {
                        Text("No food ID available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }

                    // Status update buttons - vertical stack for clarity
                    VStack(spacing: 8) {
                        Text("Update Status")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            // In Progress
                            Button {
                                onUpdateStatus(.inProgress)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
                                    Text("In Progress")
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .disabled(isProcessing || report.status == .inProgress)

                            // Resolved
                            Button {
                                onUpdateStatus(.resolved)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Resolved")
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            .disabled(isProcessing || report.status == .resolved)
                        }

                        HStack(spacing: 8) {
                            // Dismiss
                            Button {
                                onUpdateStatus(.dismissed)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Dismiss")
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.gray)
                            .disabled(isProcessing || report.status == .dismissed)

                            // Reset to pending
                            Button {
                                onUpdateStatus(.pending)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Reset")
                                }
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                            .disabled(isProcessing || report.status == .pending)
                        }
                    }

                    Divider()

                    // Delete - clearly separated and red
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Report")
                        }
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .task {
            await loadFoodFromDatabase()
        }
        .onChange(of: report.id) { _, _ in
            // When a different report is selected, reload from database
            databaseFood = nil
            Task { await loadFoodFromDatabase() }
        }
        .onChange(of: refreshTrigger) { _, _ in
            // When refresh is triggered (e.g., after saving), reload from database
            print("🔄 Refresh trigger changed - reloading food from database")
            databaseFood = nil
            Task { await loadFoodFromDatabase() }
        }
    }

    private func loadFoodFromDatabase() async {
        // Use override ID if set (e.g., after saving to a different food), otherwise use report's food ID
        guard let foodId = overrideFoodId ?? report.food?.id ?? report.foodId else {
            print("⚠️ No food ID available for report")
            return
        }

        print("📡 Loading food '\(foodId)' from database... (override: \(overrideFoodId ?? "none"))")
        isLoadingFood = true

        // Use Firestore directly to get the latest data immediately
        // (Algolia may have stale data due to sync delay)
        databaseFood = await algoliaService.getFoodFromFirestore(foodId)

        if let food = databaseFood {
            print("✅ Loaded food from Firestore: \(food.name)")
            print("   - servingDescription: '\(food.servingDescription ?? "nil")'")
            print("   - servingSizeG: \(food.servingSizeG ?? 0)")
            print("   - calories: \(food.calories)")
        } else {
            print("⚠️ Food not found in Firestore, trying Algolia...")
            // Fall back to Algolia if Firestore fails
            databaseFood = await algoliaService.getFoodById(foodId)
        }

        isLoadingFood = false
    }
}

// MARK: - Detail Info Row (Compact)

struct DetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
            Spacer()
        }
    }
}

// MARK: - Compact Nutrition Cell

struct CompactNutritionCell: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: UserReport.ReportStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.displayName)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.2))
        .foregroundColor(backgroundColor)
        .cornerRadius(8)
    }

    var backgroundColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .dismissed: return .gray
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
            Spacer()
        }
    }
}

struct NutritionCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Report Food Editor Sheet

struct ReportFoodEditorSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var reportsService = UserReportsService()

    let report: UserReport
    let onSave: (FoodItem) -> Void

    // Editable fields - initialized from report
    @State private var name = ""
    @State private var brand = ""
    @State private var barcode = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var saturatedFat: Double = 0
    @State private var fiber: Double = 0
    @State private var sugar: Double = 0
    @State private var sodium: Double = 0
    @State private var servingDescription = ""
    @State private var servingSizeG: Double = 100
    @State private var ingredientsText = ""
    @State private var isVerified = false
    @State private var isSaving = false
    @State private var foundObjectID: String?  // ID found from Algolia search
    @State private var isLookingUpOFF = false
    @State private var offLookupMessage: String?
    @State private var saveError: String?
    @State private var showSaveSuccess = false
    @StateObject private var offService = OpenFoodFactsService.shared

    // Check if nutrition is zero/missing
    private var hasZeroNutrition: Bool {
        calories == 0 && protein == 0 && carbs == 0 && fat == 0
    }

    // The objectID to use - prefer found ID from Algolia, then report's ID, then generate new
    private var objectID: String {
        foundObjectID ?? report.food?.id ?? report.foodId ?? UUID().uuidString
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Edit & Save Food")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("From user report - will save to database")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    print("🟢 Save button tapped!")
                    print("   - isSaving: \(isSaving)")
                    print("   - name.isEmpty: \(name.isEmpty)")
                    print("   - isLoadingFood: \(isLoadingFood)")
                    Task {
                        await saveFood()
                    }
                } label: {
                    if isSaving {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Saving...")
                        }
                    } else if showSaveSuccess {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Saved!")
                        }
                        .foregroundColor(.green)
                    } else if isLoadingFood {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading...")
                        }
                    } else {
                        Text("Save to Database")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isSaving || name.isEmpty || isLoadingFood)
            }
            .padding()

            // Error message
            if let error = saveError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button("Dismiss") {
                        saveError = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
            }

            Divider()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Loading indicator when fetching from Algolia
                    if isLoadingFood {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading food data from database...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    // Zero nutrition warning with auto-lookup
                    if hasZeroNutrition && !isLoadingFood {
                        GroupBox {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("This food has zero nutrition data")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    Spacer()
                                }

                                HStack(spacing: 12) {
                                    // Lookup by barcode
                                    if !barcode.isEmpty {
                                        Button {
                                            Task { await lookupFromOFFByBarcode() }
                                        } label: {
                                            HStack(spacing: 4) {
                                                if isLookingUpOFF {
                                                    ProgressView()
                                                        .scaleEffect(0.6)
                                                } else {
                                                    Image(systemName: "barcode.viewfinder")
                                                }
                                                Text("Lookup by Barcode")
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)
                                        .disabled(isLookingUpOFF)
                                    }

                                    // Lookup by name
                                    Button {
                                        Task { await lookupFromOFFByName() }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if isLookingUpOFF {
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            } else {
                                                Image(systemName: "magnifyingglass")
                                            }
                                            Text("Search by Name")
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isLookingUpOFF || name.isEmpty)

                                    Spacer()
                                }

                                if let message = offLookupMessage {
                                    HStack {
                                        Image(systemName: message.contains("Found") ? "checkmark.circle.fill" : "info.circle")
                                            .foregroundColor(message.contains("Found") ? .green : .secondary)
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(message.contains("Found") ? .green : .secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .backgroundStyle(Color.orange.opacity(0.1))
                    }

                    // Basic Info
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("Food Name", text: $name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack {
                                Text("Brand")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("Brand", text: $brand)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack {
                                Text("Barcode")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("Barcode", text: $barcode)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    } label: {
                        Text("Basic Information")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    // Serving Info
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Description")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("e.g., 1 serving, 1 cup", text: $servingDescription)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack {
                                Text("Size (g)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("Grams", value: $servingSizeG, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Spacer()
                            }
                        }
                    } label: {
                        Text("Serving Information")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    // Nutrition
                    GroupBox {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            EditorNutritionField(label: "Calories", value: $calories, unit: "kcal")
                            EditorNutritionField(label: "Protein", value: $protein, unit: "g")
                            EditorNutritionField(label: "Carbs", value: $carbs, unit: "g")
                            EditorNutritionField(label: "Fat", value: $fat, unit: "g")
                            EditorNutritionField(label: "Sat Fat", value: $saturatedFat, unit: "g")
                            EditorNutritionField(label: "Fiber", value: $fiber, unit: "g")
                            EditorNutritionField(label: "Sugar", value: $sugar, unit: "g")
                            EditorNutritionField(label: "Salt", value: Binding(
                                get: { sodium / 400 }, // Convert sodium mg to salt g
                                set: { sodium = $0 * 400 } // Convert salt g back to sodium mg
                            ), unit: "g")
                        }
                    } label: {
                        Text("Nutrition (per 100g)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    // Ingredients
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter ingredients separated by commas")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            TextEditor(text: $ingredientsText)
                                .font(.body)
                                .frame(minHeight: 80, maxHeight: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )

                            if !ingredientsText.isEmpty {
                                let count = ingredientsText.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                                Text("\(count) ingredient(s)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } label: {
                        Text("Ingredients")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    // Verification Status
                    GroupBox {
                        HStack {
                            Toggle("Mark as Verified", isOn: $isVerified)
                                .toggleStyle(.switch)

                            Spacer()

                            if isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Status")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("Processing grade is calculated automatically")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 550)
        .onAppear {
            populateFields()
        }
    }

    @State private var isLoadingFood = false

    private func populateFields() {
        // Populate from report's embedded food data, or fall back to report fields
        if let food = report.food {
            print("📥 Populating editor from embedded food data:")
            print("   - Name: \(food.name)")
            print("   - Calories: \(food.calories)")
            print("   - Protein: \(food.protein)")
            print("   - Carbs: \(food.carbs)")
            print("   - Fat: \(food.fat)")
            print("   - Ingredients: \(food.ingredients?.count ?? 0) items")

            name = food.name
            brand = food.brand ?? ""
            barcode = food.barcode ?? report.barcode ?? ""
            calories = food.calories
            protein = food.protein
            carbs = food.carbs
            fat = food.fat
            saturatedFat = food.saturatedFat ?? 0
            fiber = food.fiber
            sugar = food.sugar
            sodium = food.sodium
            servingDescription = food.servingDescription ?? ""
            servingSizeG = food.servingSizeG ?? 100
            ingredientsText = food.ingredients?.joined(separator: ", ") ?? ""
            isVerified = food.isVerified

            // CRITICAL: Search Algolia to find the real objectID for this food
            // The embedded food ID is often a temporary UUID from iOS, not the database ID
            isLoadingFood = true
            Task {
                defer {
                    // ALWAYS ensure isLoadingFood is set to false when done
                    Task { @MainActor in
                        isLoadingFood = false
                    }
                }

                print("🔍 Searching Algolia for real objectID of: \(food.name)")
                await algoliaService.searchFoods(query: food.name, database: .foods)
                if let firstMatch = algoliaService.foods.first {
                    await MainActor.run {
                        print("✅ Found real objectID: \(firstMatch.objectID) for '\(firstMatch.name)'")
                        foundObjectID = firstMatch.objectID

                        // Fill in any missing data from the database version
                        // The report's embedded food may be missing fields that exist in the database
                        if barcode.isEmpty, let dbBarcode = firstMatch.barcode, !dbBarcode.isEmpty {
                            print("📦 Filling in barcode from database: \(dbBarcode)")
                            barcode = dbBarcode
                        }
                        if brand.isEmpty, let dbBrand = firstMatch.brand, !dbBrand.isEmpty {
                            brand = dbBrand
                        }
                        if servingDescription.isEmpty, let dbServing = firstMatch.servingDescription, !dbServing.isEmpty {
                            servingDescription = dbServing
                        }
                        if let dbServingG = firstMatch.servingSizeG, dbServingG > 0 {
                            servingSizeG = dbServingG
                        }
                        if ingredientsText.isEmpty, let dbIngredients = firstMatch.ingredients, !dbIngredients.isEmpty {
                            ingredientsText = dbIngredients.joined(separator: ", ")
                        }
                    }
                } else {
                    print("⚠️ Could not find food in Algolia - will create new entry")
                }
            }
        } else if let foodId = report.foodId, !foodId.isEmpty {
            // No embedded food data but we have a foodId - try to fetch from Algolia
            print("⚠️ No embedded food data, attempting to fetch from Algolia with foodId: \(foodId)")
            name = report.foodName
            brand = report.brandName ?? ""
            barcode = report.barcode ?? ""

            // Fetch from Algolia in background
            isLoadingFood = true
            Task {
                defer {
                    // ALWAYS ensure isLoadingFood is set to false when done
                    Task { @MainActor in
                        isLoadingFood = false
                    }
                }

                if let fetchedFood = await algoliaService.getFoodById(foodId) {
                    await MainActor.run {
                        print("✅ Fetched food from Algolia: \(fetchedFood.name) (objectID: \(fetchedFood.objectID))")
                        // Use the fetched food's objectID
                        foundObjectID = fetchedFood.objectID
                        name = fetchedFood.name
                        brand = fetchedFood.brand ?? ""
                        barcode = fetchedFood.barcode ?? report.barcode ?? ""
                        calories = fetchedFood.calories
                        protein = fetchedFood.protein
                        carbs = fetchedFood.carbs
                        fat = fetchedFood.fat
                        saturatedFat = fetchedFood.saturatedFat ?? 0
                        fiber = fetchedFood.fiber
                        sugar = fetchedFood.sugar
                        sodium = fetchedFood.sodium
                        servingDescription = fetchedFood.servingDescription ?? ""
                        servingSizeG = fetchedFood.servingSizeG ?? 100
                        ingredientsText = fetchedFood.ingredients?.joined(separator: ", ") ?? ""
                        isVerified = fetchedFood.isVerified ?? false
                    }
                } else {
                    // Food ID doesn't exist in Algolia - try searching by name as fallback
                    print("⚠️ Food ID not found in Algolia, trying search by name: \(report.foodName)")
                    await algoliaService.searchFoods(query: report.foodName, database: .foods)
                    if let firstMatch = algoliaService.foods.first {
                        await MainActor.run {
                            print("✅ Found food by name search: \(firstMatch.name) (objectID: \(firstMatch.objectID))")
                            // IMPORTANT: Use this food's objectID so we update the existing food
                            foundObjectID = firstMatch.objectID
                            name = firstMatch.name
                            brand = firstMatch.brand ?? ""
                            barcode = firstMatch.barcode ?? report.barcode ?? ""
                            calories = firstMatch.calories
                            protein = firstMatch.protein
                            carbs = firstMatch.carbs
                            fat = firstMatch.fat
                            saturatedFat = firstMatch.saturatedFat ?? 0
                            fiber = firstMatch.fiber
                            sugar = firstMatch.sugar
                            sodium = firstMatch.sodium
                            servingDescription = firstMatch.servingDescription ?? ""
                            servingSizeG = firstMatch.servingSizeG ?? 100
                            ingredientsText = firstMatch.ingredients?.joined(separator: ", ") ?? ""
                            isVerified = firstMatch.isVerified ?? false
                        }
                    } else {
                        print("❌ Could not find food by ID or name search - will create new food")
                    }
                }
            }
        } else {
            print("⚠️ No embedded food data and no foodId, using basic report fields")
            // Fall back to basic report fields
            name = report.foodName
            brand = report.brandName ?? ""
            barcode = report.barcode ?? ""
        }
    }

    private func lookupFromOFFByBarcode() async {
        guard !barcode.isEmpty else { return }
        isLookingUpOFF = true
        offLookupMessage = nil

        if let product = await offService.lookupProduct(barcode: barcode) {
            await MainActor.run {
                applyOFFProduct(product)
                offLookupMessage = "Found: \(product.displayName)"
            }
        } else {
            await MainActor.run {
                offLookupMessage = "No product found for barcode \(barcode)"
            }
        }

        isLookingUpOFF = false
    }

    private func lookupFromOFFByName() async {
        guard !name.isEmpty else { return }
        isLookingUpOFF = true
        offLookupMessage = nil

        let products = await offService.searchProducts(query: name, pageSize: 5)
        if let firstProduct = products.first {
            await MainActor.run {
                applyOFFProduct(firstProduct)
                offLookupMessage = "Found: \(firstProduct.displayName)"
            }
        } else {
            await MainActor.run {
                offLookupMessage = "No products found for '\(name)'"
            }
        }

        isLookingUpOFF = false
    }

    private func applyOFFProduct(_ product: OFFProduct) {
        // Apply nutrition values if we have them
        if let nutriments = product.nutriments {
            if let kcal = nutriments.energy_kcal_100g ?? nutriments.energy_kcal {
                calories = kcal
            }
            if let prot = nutriments.proteins_100g ?? nutriments.proteins {
                protein = prot
            }
            if let carb = nutriments.carbohydrates_100g ?? nutriments.carbohydrates {
                carbs = carb
            }
            if let fatVal = nutriments.fat_100g ?? nutriments.fat {
                fat = fatVal
            }
            if let fib = nutriments.fiber_100g ?? nutriments.fiber {
                fiber = fib
            }
            if let sug = nutriments.sugars_100g ?? nutriments.sugars {
                sugar = sug
            }
            if let sod = nutriments.sodium_100g ?? nutriments.sodium {
                sodium = sod * 1000 // convert g to mg
            }
        }

        // Apply brand if we don't have one
        if brand.isEmpty, let offBrand = product.brands {
            brand = offBrand
        }

        // Apply barcode if we don't have one
        if barcode.isEmpty, let code = product.code {
            barcode = code
        }
    }

    private func saveFood() async {
        print("🔘 SAVE BUTTON CLICKED - saveFood() called")
        isSaving = true
        saveError = nil
        showSaveSuccess = false

        print("💾 Saving food with objectID: \(objectID)")
        print("   - foundObjectID: \(foundObjectID ?? "nil")")
        print("   - report.food?.id: \(report.food?.id ?? "nil")")
        print("   - report.foodId: \(report.foodId ?? "nil")")
        print("   - isVerified: \(isVerified)")
        print("   - name: \(name)")
        print("   - calories: \(calories)")
        print("   - protein: \(protein)")
        print("   - servingDescription: '\(servingDescription)'")
        print("   - servingSizeG: \(servingSizeG)")

        // Build the FoodItem
        let ingredients: [String]? = ingredientsText.isEmpty ? nil : ingredientsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let food = FoodItem(
            objectID: objectID,
            name: name,
            brand: brand.isEmpty ? nil : brand,
            barcode: barcode.isEmpty ? nil : barcode,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            saturatedFat: saturatedFat > 0 ? saturatedFat : nil,
            servingDescription: servingDescription.isEmpty ? nil : servingDescription,
            servingSizeG: servingSizeG,
            ingredients: ingredients,
            isVerified: isVerified,
            source: "user_report"
        )

        // Save to database
        print("📤 Calling algoliaService.saveFood...")
        print("   - Food to save: \(food.objectID), name=\(food.name), calories=\(food.calories)")
        let success = await algoliaService.saveFood(food, database: .foods)
        print("   - Save result: \(success)")
        print("   - AlgoliaService error: \(algoliaService.error ?? "none")")

        if success {
            print("✅ Save succeeded! Marking report as resolved...")
            // Mark report as resolved
            let statusResult = await reportsService.updateReportStatus(reportId: report.id, status: .resolved, notes: "Food updated via Database Manager")
            print("   - Report status update result: \(statusResult)")

            // Call the callback
            print("   - Calling onSave callback...")
            onSave(food)

            // Show success feedback
            showSaveSuccess = true
            isSaving = false

            // Dismiss after a brief delay to show success
            print("   - Waiting 0.8s before dismiss...")
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            print("   - Dismissing sheet...")
            dismiss()
        } else {
            print("❌ Save FAILED!")
            saveError = algoliaService.error ?? "Failed to save food to database"
            print("   - Error shown to user: \(saveError ?? "none")")
            isSaving = false
        }
    }
}

// MARK: - Full Food Editor Sheet (Legacy - kept for reference but not used)

struct FullFoodEditorSheet: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @Environment(\.dismiss) var dismiss

    let foodId: String
    let reportId: String
    let onSave: (FoodItem) -> Void

    @State private var food: FoodItem?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var isSaving = false

    // Editable fields
    @State private var name = ""
    @State private var brand = ""
    @State private var barcode = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0
    @State private var sugar: Double = 0
    @State private var sodium: Double = 0
    @State private var saturatedFat: Double = 0
    @State private var transFat: Double = 0
    @State private var cholesterol: Double = 0
    @State private var servingDescription = ""
    @State private var servingSizeG: Double = 100
    @State private var ingredientsText = ""
    @State private var processingGrade = ""
    @State private var processingLabel = ""
    @State private var isVerified = false
    @State private var isPerUnit = false
    @State private var imageURL = ""
    @State private var source = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Edit Food")
                        .font(.title2)
                        .fontWeight(.semibold)
                    if let food = food {
                        Text("ID: \(food.objectID)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    saveFood()
                } label: {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Text("Save & Resolve")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isLoading || isSaving || food == nil)
            }
            .padding()

            Divider()

            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading food from database...")
                    Text("Food ID: \(foodId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            } else if let error = loadError {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Failed to load food")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Food ID: \(foodId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadFood() }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            } else if food != nil {
                // Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Basic Info
                        GroupBox {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Name")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Food Name", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Brand")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Brand", text: $brand)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Barcode")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Barcode", text: $barcode)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Source")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Source", text: $source)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        } label: {
                            Text("Basic Information")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Serving Info
                        GroupBox {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Description")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("e.g., 1 serving, 1 cup", text: $servingDescription)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Text("Size (g)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Grams", value: $servingSizeG, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)

                                    Spacer()

                                    Toggle("Per Unit", isOn: $isPerUnit)
                                        .toggleStyle(.switch)
                                }
                            }
                        } label: {
                            Text("Serving Information")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Nutrition - Main macros
                        GroupBox {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                EditorNutritionField(label: "Calories", value: $calories, unit: "kcal")
                                EditorNutritionField(label: "Protein", value: $protein, unit: "g")
                                EditorNutritionField(label: "Carbs", value: $carbs, unit: "g")
                                EditorNutritionField(label: "Fat", value: $fat, unit: "g")
                                EditorNutritionField(label: "Fiber", value: $fiber, unit: "g")
                                EditorNutritionField(label: "Sugar", value: $sugar, unit: "g")
                                EditorNutritionField(label: "Salt", value: Binding(
                                    get: { sodium / 400 }, // Convert sodium mg to salt g
                                    set: { sodium = $0 * 400 } // Convert salt g back to sodium mg
                                ), unit: "g")
                                EditorNutritionField(label: "Sat. Fat", value: $saturatedFat, unit: "g")
                            }
                        } label: {
                            Text("Nutrition (per 100g)")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Additional nutrition
                        GroupBox {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                EditorNutritionField(label: "Trans Fat", value: $transFat, unit: "g")
                                EditorNutritionField(label: "Cholesterol", value: $cholesterol, unit: "mg")
                            }
                        } label: {
                            Text("Additional Nutrition")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Ingredients
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Enter ingredients separated by commas")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $ingredientsText)
                                    .font(.body)
                                    .frame(minHeight: 100, maxHeight: 150)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                    )

                                if !ingredientsText.isEmpty {
                                    let count = ingredientsText.components(separatedBy: ",").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
                                    Text("\(count) ingredient(s)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } label: {
                            Text("Ingredients")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Processing & Verification
                        GroupBox {
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Grade")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)

                                    Picker("", selection: $processingGrade) {
                                        Text("None").tag("")
                                        Text("A+").tag("A+")
                                        Text("A").tag("A")
                                        Text("B").tag("B")
                                        Text("C").tag("C")
                                        Text("D").tag("D")
                                        Text("E").tag("E")
                                        Text("F").tag("F")
                                    }
                                    .pickerStyle(.segmented)
                                }

                                HStack {
                                    Text("Label")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 80, alignment: .leading)
                                    TextField("Processing Label", text: $processingLabel)
                                        .textFieldStyle(.roundedBorder)
                                }

                                HStack {
                                    Toggle("Verified", isOn: $isVerified)
                                        .toggleStyle(.switch)

                                    Spacer()

                                    if isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        } label: {
                            Text("Processing & Status")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }

                        // Image URL
                        GroupBox {
                            HStack {
                                Text("URL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                TextField("Image URL", text: $imageURL)
                                    .textFieldStyle(.roundedBorder)

                                if !imageURL.isEmpty, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 40, height: 40)
                                                .cornerRadius(4)
                                        default:
                                            Image(systemName: "photo")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text("Image")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                }
            } else {
                // Fallback - shouldn't normally happen
                VStack {
                    Spacer()
                    Text("No food data available")
                        .foregroundColor(.secondary)
                    Text("Food ID: \(foodId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await loadFood()
        }
    }

    private func loadFood() async {
        isLoading = true
        loadError = nil

        print("🔍 FullFoodEditorSheet: Loading food with ID: '\(foodId)'")

        // Try to fetch from Algolia by object ID
        if let fetchedFood = await algoliaService.getFoodById(foodId) {
            print("✅ FullFoodEditorSheet: Found food: \(fetchedFood.name)")
            food = fetchedFood
            populateFields(from: fetchedFood)
        } else {
            print("❌ FullFoodEditorSheet: Could not find food with ID: '\(foodId)'")
            print("❌ AlgoliaService error: \(algoliaService.error ?? "none")")
            loadError = "Could not find food with ID: \(foodId)"
        }

        isLoading = false
    }

    private func populateFields(from food: FoodItem) {
        name = food.name
        brand = food.brand ?? ""
        barcode = food.barcode ?? ""
        calories = food.calories
        protein = food.protein
        carbs = food.carbs
        fat = food.fat
        fiber = food.fiber
        sugar = food.sugar
        sodium = food.sodium
        saturatedFat = food.saturatedFat ?? 0
        transFat = food.transFat ?? 0
        cholesterol = food.cholesterol ?? 0
        servingDescription = food.servingDescription ?? ""
        servingSizeG = food.servingSizeG ?? 100
        ingredientsText = food.ingredients?.joined(separator: ", ") ?? ""
        processingGrade = food.processingGrade ?? ""
        processingLabel = food.processingLabel ?? ""
        isVerified = food.isVerified ?? false
        isPerUnit = food.isPerUnit ?? false
        imageURL = food.imageURL ?? ""
        source = food.source ?? ""
    }

    private func saveFood() {
        guard var updatedFood = food else { return }

        isSaving = true

        // Update all fields
        updatedFood.name = name
        updatedFood.brand = brand.isEmpty ? nil : brand
        updatedFood.barcode = barcode.isEmpty ? nil : barcode
        updatedFood.calories = calories
        updatedFood.protein = protein
        updatedFood.carbs = carbs
        updatedFood.fat = fat
        updatedFood.fiber = fiber
        updatedFood.sugar = sugar
        updatedFood.sodium = sodium
        updatedFood.saturatedFat = saturatedFat > 0 ? saturatedFat : nil
        updatedFood.transFat = transFat > 0 ? transFat : nil
        updatedFood.cholesterol = cholesterol > 0 ? cholesterol : nil
        updatedFood.servingDescription = servingDescription.isEmpty ? nil : servingDescription
        updatedFood.servingSizeG = servingSizeG
        updatedFood.ingredients = ingredientsText.isEmpty ? nil : ingredientsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        updatedFood.processingGrade = processingGrade.isEmpty ? nil : processingGrade
        updatedFood.processingLabel = processingLabel.isEmpty ? nil : processingLabel
        updatedFood.isVerified = isVerified
        updatedFood.isPerUnit = isPerUnit
        updatedFood.imageURL = imageURL.isEmpty ? nil : imageURL
        updatedFood.source = source.isEmpty ? nil : source

        onSave(updatedFood)
        dismiss()
    }
}

// MARK: - Editor Nutrition Field

struct EditorNutritionField: View {
    let label: String
    @Binding var value: Double
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                TextField("", value: $value, format: .number.precision(.fractionLength(1)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
