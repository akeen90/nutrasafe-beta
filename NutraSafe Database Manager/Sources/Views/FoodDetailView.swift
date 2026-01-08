//
//  FoodDetailView.swift
//  NutraSafe Database Manager
//
//  Detailed view and editor for individual food items
//

import SwiftUI

struct FoodDetailView: View {
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService
    @EnvironmentObject var appState: AppState

    @Binding var food: FoodItem

    @State private var isEditing = false
    @State private var editedFood: FoodItem = FoodItem()
    @State private var showingSaveConfirmation = false
    @State private var showingAnalysis = false
    @State private var analysis: FoodAnalysis?
    @State private var showingImagePicker = false
    @State private var ingredientsText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with image and basic info
                headerSection

                Divider()

                // Nutrition section
                nutritionSection

                Divider()

                // Ingredients section
                ingredientsSection

                Divider()

                // Additives section
                additivesSection

                Divider()

                // Processing info
                processingSection

                Divider()

                // Metadata
                metadataSection

                // AI Analysis
                if showingAnalysis {
                    Divider()
                    if claudeService.isProcessing {
                        HStack {
                            ProgressView()
                            Text("Analyzing food with Claude AI...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else if let analysis = analysis {
                        analysisSection(analysis)
                    } else if let error = claudeService.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Analysis Failed", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Try Again") {
                                Task {
                                    analysis = await claudeService.analyzeFood(food)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding(24)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        showingAnalysis = true
                        analysis = await claudeService.analyzeFood(food)
                        if analysis == nil && claudeService.error != nil {
                            // Show error in analysis variable for display
                        }
                    }
                } label: {
                    if claudeService.isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Label("Analyze", systemImage: "sparkles")
                    }
                }
                .disabled(claudeService.isProcessing)

                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                        editedFood = food
                    }

                    Button("Save") {
                        showingSaveConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        editedFood = food
                        ingredientsText = food.ingredients?.joined(separator: ", ") ?? ""
                        isEditing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .alert("Save Changes", isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                Task {
                    await saveChanges()
                }
            }
        } message: {
            Text("Save changes to '\(editedFood.name)'?")
        }
        .onAppear {
            editedFood = food
            ingredientsText = food.ingredients?.joined(separator: ", ") ?? ""
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: 150, height: 150)

                if let imageURL = (isEditing ? editedFood.imageURL : food.imageURL),
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        if isEditing {
                            Button("Add Image") {
                                showingImagePicker = true
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            // Basic info
            VStack(alignment: .leading, spacing: 12) {
                if isEditing {
                    TextField("Food Name", text: $editedFood.name)
                        .font(.title)
                        .textFieldStyle(.plain)
                } else {
                    Text(food.name)
                        .font(.title)
                        .fontWeight(.bold)
                }

                if isEditing {
                    HStack {
                        Text("Brand:")
                            .foregroundColor(.secondary)
                        TextField("Brand (optional)", text: Binding(
                            get: { editedFood.brand ?? "" },
                            set: { editedFood.brand = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }
                } else {
                    HStack {
                        Text("Brand:")
                            .foregroundColor(.secondary)
                        Text(food.brand ?? "—")
                            .fontWeight(.medium)
                    }
                    .font(.title3)
                }

                HStack(spacing: 12) {
                    if isEditing {
                        TextField("Barcode", text: Binding(
                            get: { editedFood.barcode ?? "" },
                            set: { editedFood.barcode = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    } else if let barcode = food.barcode {
                        Label(barcode, systemImage: "barcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if food.isVerified == true {
                        Label("Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if isEditing {
                    Toggle("Verified", isOn: Binding(
                        get: { editedFood.isVerified ?? false },
                        set: { editedFood.isVerified = $0 }
                    ))
                }
            }

            Spacer()
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition (per 100g)")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                NutrientField(label: "Calories", value: isEditing ? $editedFood.calories : .constant(food.calories), unit: "kcal", isEditing: isEditing)
                NutrientField(label: "Protein", value: isEditing ? $editedFood.protein : .constant(food.protein), unit: "g", isEditing: isEditing)
                NutrientField(label: "Carbs", value: isEditing ? $editedFood.carbs : .constant(food.carbs), unit: "g", isEditing: isEditing)
                NutrientField(label: "Fat", value: isEditing ? $editedFood.fat : .constant(food.fat), unit: "g", isEditing: isEditing)
                NutrientField(label: "Fiber", value: isEditing ? $editedFood.fiber : .constant(food.fiber), unit: "g", isEditing: isEditing)
                NutrientField(label: "Sugar", value: isEditing ? $editedFood.sugar : .constant(food.sugar), unit: "g", isEditing: isEditing)
                NutrientField(label: "Sodium", value: isEditing ? $editedFood.sodium : .constant(food.sodium), unit: "mg", isEditing: isEditing)
                NutrientField(label: "Sat. Fat", value: isEditing ? $editedFood.saturatedFat : .constant(food.saturatedFat), unit: "g", isEditing: isEditing)
            }

            // Serving info
            if isEditing {
                HStack {
                    TextField("Serving Description", text: Binding(
                        get: { editedFood.servingDescription ?? "" },
                        set: { editedFood.servingDescription = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)

                    TextField("Serving Size (g)", value: $editedFood.servingSizeG, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                    Toggle("Per Unit", isOn: Binding(
                        get: { editedFood.isPerUnit ?? false },
                        set: { editedFood.isPerUnit = $0 }
                    ))
                }
            } else if let serving = food.servingDescription {
                Text("Serving: \(serving)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Ingredients Section

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients")
                    .font(.headline)

                Spacer()

                if isEditing {
                    Button {
                        Task {
                            if let suggestions = await claudeService.suggestIngredients(for: editedFood.name) {
                                ingredientsText = suggestions.joined(separator: ", ")
                            }
                        }
                    } label: {
                        Label("Suggest", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderless)
                    .disabled(claudeService.isProcessing)
                }
            }

            if isEditing {
                TextEditor(text: $ingredientsText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(8)
                    .onChange(of: ingredientsText) { _, newValue in
                        editedFood.ingredients = newValue
                            .components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                    }

                Text("Separate ingredients with commas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let ingredients = food.ingredients, !ingredients.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                    }
                }
            } else {
                Text("No ingredients listed")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Additives Section

    private var additivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additives")
                .font(.headline)

            if let additives = food.additives, !additives.isEmpty {
                ForEach(additives) { additive in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(additive.name)
                                .font(.subheadline)
                            if !additive.code.isEmpty {
                                Text(additive.code)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let verdict = additive.effectsVerdict {
                            Text(verdict)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(verdictColor(verdict).opacity(0.2))
                                .foregroundColor(verdictColor(verdict))
                                .cornerRadius(4)
                        }

                        if additive.childWarning == true {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No additives detected")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Processing Section

    private var processingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Processing")
                .font(.headline)

            HStack(spacing: 20) {
                if isEditing {
                    Picker("Grade", selection: Binding(
                        get: { editedFood.processingGrade ?? "" },
                        set: { editedFood.processingGrade = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Not Set").tag("")
                        ForEach(["A+", "A", "B+", "B", "C+", "C", "D+", "D", "E", "F"], id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .frame(width: 120)
                } else {
                    VStack(alignment: .leading) {
                        Text("Grade")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let grade = food.processingGrade {
                            Text(grade)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(gradeColor(grade))
                        } else {
                            Text("N/A")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(food.processingScore != nil ? "\(food.processingScore!)" : "N/A")
                        .font(.title2)
                }

                VStack(alignment: .leading) {
                    Text("Label")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(food.processingLabel ?? "N/A")
                        .font(.subheadline)
                }
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetadataRow(label: "Object ID", value: food.objectID)
                MetadataRow(label: "Source", value: food.source ?? "Unknown")
                MetadataRow(label: "Verified By", value: food.verifiedBy ?? "N/A")
                MetadataRow(label: "Last Updated", value: food.lastUpdated ?? "N/A")
            }

            if isEditing {
                HStack {
                    TextField("Source", text: Binding(
                        get: { editedFood.source ?? "" },
                        set: { editedFood.source = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Analysis Section

    private func analysisSection(_ analysis: FoodAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Analysis")
                    .font(.headline)

                Spacer()

                Text("Quality: \(analysis.qualityScore)%")
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(qualityColor(analysis.qualityScore).opacity(0.2))
                    .foregroundColor(qualityColor(analysis.qualityScore))
                    .cornerRadius(4)
            }

            if !analysis.issues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issues")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    ForEach(analysis.issues, id: \.self) { issue in
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(issue)
                                .font(.caption)
                        }
                    }
                }
            }

            if !analysis.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggestions")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    ForEach(analysis.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }

            if let assessment = analysis.processingAssessment {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Processing Assessment")
                        .font(.subheadline)
                    Text(assessment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Helper Functions

    private func saveChanges() async {
        let success = await algoliaService.saveFood(editedFood, database: appState.selectedDatabase)
        if success {
            food = editedFood
            isEditing = false

            // Update in the list
            if let index = algoliaService.foods.firstIndex(where: { $0.objectID == food.objectID }) {
                algoliaService.foods[index] = food
            }
        }
    }

    private func gradeColor(_ grade: String) -> Color {
        switch grade.uppercased() {
        case "A", "A+": return .green
        case "B", "B+": return .mint
        case "C", "C+": return .yellow
        case "D", "D+": return .orange
        case "E", "F": return .red
        default: return .gray
        }
    }

    private func verdictColor(_ verdict: String) -> Color {
        switch verdict.lowercased() {
        case "safe", "beneficial": return .green
        case "neutral": return .gray
        case "caution": return .orange
        case "avoid": return .red
        default: return .gray
        }
    }

    private func qualityColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Supporting Views

struct NutrientField: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let isEditing: Bool

    init(label: String, value: Binding<Double>, unit: String, isEditing: Bool) {
        self.label = label
        self._value = value
        self.unit = unit
        self.isEditing = isEditing
    }

    init(label: String, value: Binding<Double?>, unit: String, isEditing: Bool) {
        self.label = label
        self._value = Binding(
            get: { value.wrappedValue ?? 0 },
            set: { value.wrappedValue = $0 }
        )
        self.unit = unit
        self.isEditing = isEditing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            if isEditing {
                HStack(spacing: 4) {
                    TextField("", value: $value, format: .number)
                        .textFieldStyle(.roundedBorder)
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(value, specifier: "%.1f") \(unit)")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}
