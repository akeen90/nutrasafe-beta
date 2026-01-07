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

    @State private var food = FoodItem()
    @State private var ingredientsText = ""
    @State private var isSaving = false

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

                                TextField("Barcode (optional)", text: Binding(
                                    get: { food.barcode ?? "" },
                                    set: { food.barcode = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
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
                            NutritionInput(label: "Sodium (mg)", value: $food.sodium)
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
