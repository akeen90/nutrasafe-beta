//
//  ReactionLogView.swift
//  NutraSafe Beta
//
//  Reaction Log Mode - Track reactions and analyze possible food triggers
//

import SwiftUI

struct ReactionLogView: View {
    @StateObject private var manager = ReactionLogManager.shared
    @State private var showingLogSheet = false
    @State private var selectedEntry: ReactionLogEntry?

    var body: some View {
        Group {
            if manager.reactionLogs.isEmpty {
                emptyStateView
            } else {
                reactionListView
            }
        }
        .navigationTitle("Reaction Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingLogSheet = true }) {
                    Label("Log Reaction", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogReactionSheet()
        }
        .sheet(item: $selectedEntry) { entry in
            ReactionLogDetailView(entry: entry)
        }
        .task {
            await manager.loadReactionLogs()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text("No Reactions Logged")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start tracking reactions to identify possible food triggers")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingLogSheet = true }) {
                Label("Log Your First Reaction", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
    }

    private var reactionListView: some View {
        List {
            // Add New Button at top
            Button(action: { showingLogSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("Add New Reaction")
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.blue.opacity(0.05))

            ForEach(manager.reactionLogs) { entry in
                ReactionLogCard(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEntry = entry
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            Task {
                                try? await manager.deleteReactionLog(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Reaction Log Card

struct ReactionLogCard: View {
    let entry: ReactionLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Reaction type icon
                Image(systemName: reactionIcon)
                    .font(.title3)
                    .foregroundColor(.orange)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.reactionType)
                        .font(.headline)

                    Text(entry.reactionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(" at ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    +
                    Text(entry.reactionDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let analysis = entry.triggerAnalysis {
                HStack(spacing: 16) {
                    Label("\(analysis.mealCount) meals", systemImage: "fork.knife")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(analysis.topFoods.count) triggers", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Log Reaction Sheet

struct LogReactionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ReactionLogManager.shared

    @State private var selectedType: ReactionType = .headache
    @State private var customType: String = ""
    @State private var reactionDate: Date = Date()
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reaction Details")) {
                    // Reaction type picker
                    Picker("Reaction Type", selection: $selectedType) {
                        ForEach(ReactionType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }

                    if selectedType == .custom {
                        TextField("Describe reaction", text: $customType)
                    }

                    DatePicker("Date & Time", selection: $reactionDate, displayedComponents: [.date, .hourAndMinute])
                }

                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section {
                    Text("The system will automatically analyze your food diary from the 72 hours before this reaction.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Log Reaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveReaction()
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)

                            Text("Analyzing food triggers...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 20)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        if selectedType == .custom {
            return !customType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private func saveReaction() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let reactionType = selectedType == .custom ? customType : selectedType.rawValue
            let notesText = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            _ = try await manager.saveReactionLog(
                reactionType: reactionType,
                reactionDate: reactionDate,
                notes: notesText.isEmpty ? nil : notesText
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Reaction Detail View

struct ReactionLogDetailView: View {
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet = false
    @State private var showOtherIngredients = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    reactionHeader

                    if let analysis = entry.triggerAnalysis {
                        // Analysis Summary
                        analysisOverview(analysis: analysis)

                        // Top Trigger Foods
                        if !analysis.topFoods.isEmpty {
                            topFoodsSection(foods: analysis.topFoods)
                        }

                        // Top Trigger Ingredients
                        if !analysis.topIngredients.isEmpty {
                            topIngredientsSection(ingredients: analysis.topIngredients)
                        }
                    } else {
                        Text("No analysis available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Reaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                PDFExportSheet(entry: entry)
            }
        }
    }

    private var reactionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: reactionIcon)
                    .font(.title)
                    .foregroundColor(.orange)

                Text(entry.reactionType)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 16) {
                Label(entry.reactionDate.formatted(date: .long, time: .omitted), systemImage: "calendar")
                Label(entry.reactionDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func analysisOverview(analysis: TriggerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Summary")
                .font(.headline)

            HStack(spacing: 20) {
                StatBox(value: "\(analysis.mealCount)", label: "Meals Analyzed", icon: "fork.knife")
                StatBox(value: "\(analysis.totalFoodsAnalyzed)", label: "Foods Reviewed", icon: "list.bullet")
            }

            Text("72-Hour Window")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text(" • ")
                .font(.caption)
                .foregroundColor(.secondary)
            +
            Text("\(analysis.timeRangeStart.formatted(date: .abbreviated, time: .shortened)) to \(analysis.timeRangeEnd.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topFoodsSection(foods: [WeightedFoodScore]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Possible Trigger Foods")
                .font(.headline)

            ForEach(foods.prefix(10)) { food in
                FoodScoreRow(score: food)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }

    private func topIngredientsSection(ingredients: [WeightedIngredientScore]) -> some View {
        let ingredientData = categorizeIngredients(ingredients)

        return VStack(alignment: .leading, spacing: 20) {
            // Recognised Allergens Section
            if !ingredientData.allergenGroups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Recognised Allergens")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ingredientData.allergenGroups, id: \.category) { group in
                            ReactionAllergenGroup(
                                allergenCategory: group.category,
                                categoryScore: group.maxScore,
                                ingredients: group.ingredients
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }

            // Other Ingredients Section (Expandable)
            if !ingredientData.otherIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showOtherIngredients.toggle()
                        }
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("Other Ingredients")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: showOtherIngredients ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, showOtherIngredients ? 20 : 0)
                    }
                    .buttonStyle(.plain)

                    if showOtherIngredients {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredientData.otherIngredients) { ingredient in
                                IngredientScoreRow(score: ingredient)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
        }
    }

    private func categorizeIngredients(_ ingredients: [WeightedIngredientScore]) -> (allergenGroups: [(category: String, maxScore: Int, ingredients: [WeightedIngredientScore])], otherIngredients: [WeightedIngredientScore]) {
        var allergenDict: [String: [WeightedIngredientScore]] = [:]
        var otherIngredients: [WeightedIngredientScore] = []

        for ingredient in ingredients.prefix(10) {
            if let allergenCategory = getBaseAllergen(for: ingredient.ingredientName) {
                allergenDict[allergenCategory, default: []].append(ingredient)
            } else {
                otherIngredients.append(ingredient)
            }
        }

        let allergenGroups = allergenDict.map { (category, ingredients) -> (category: String, maxScore: Int, ingredients: [WeightedIngredientScore]) in
            let maxScore = ingredients.map { Int($0.totalScore) }.max() ?? 0
            return (category, maxScore, ingredients.sorted { $0.totalScore > $1.totalScore })
        }.sorted { $0.maxScore > $1.maxScore }

        return (allergenGroups, otherIngredients.sorted { $0.totalScore > $1.totalScore })
    }

    private func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy
        if lower.contains("milk") || lower.contains("dairy") || lower.contains("cream") ||
           lower.contains("cheese") || lower.contains("butter") || lower.contains("yogurt") ||
           lower.contains("whey") || lower.contains("casein") || lower.contains("lactose") {
            return "Milk"
        }

        // Eggs
        if lower.contains("egg") || lower.contains("albumin") || lower.contains("mayonnaise") {
            return "Eggs"
        }

        // Peanuts
        if lower.contains("peanut") || lower.contains("groundnut") {
            return "Peanuts"
        }

        // Tree nuts
        if lower.contains("almond") || lower.contains("hazelnut") || lower.contains("walnut") ||
           lower.contains("cashew") || lower.contains("pistachio") || lower.contains("pecan") ||
           lower.contains("brazil nut") || lower.contains("macadamia") || lower.contains("nut") {
            return "Tree Nuts"
        }

        // Gluten
        if lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") ||
           lower.contains("rye") || lower.contains("oats") || lower.contains("spelt") ||
           lower.contains("kamut") {
            return "Gluten"
        }

        // Soya
        if lower.contains("soy") || lower.contains("soya") || lower.contains("soybean") ||
           lower.contains("tofu") || lower.contains("edamame") {
            return "Soya"
        }

        // Fish
        if lower.contains("fish") || lower.contains("salmon") || lower.contains("tuna") ||
           lower.contains("cod") || lower.contains("haddock") || lower.contains("trout") {
            return "Fish"
        }

        // Shellfish
        if lower.contains("shellfish") || lower.contains("shrimp") || lower.contains("prawn") ||
           lower.contains("crab") || lower.contains("lobster") || lower.contains("mussel") ||
           lower.contains("oyster") || lower.contains("clam") {
            return "Shellfish"
        }

        // Sesame
        if lower.contains("sesame") || lower.contains("tahini") {
            return "Sesame"
        }

        // Celery
        if lower.contains("celery") || lower.contains("celeriac") {
            return "Celery"
        }

        // Mustard
        if lower.contains("mustard") {
            return "Mustard"
        }

        // Sulphites
        if lower.contains("sulphite") || lower.contains("sulfite") {
            return "Sulphites"
        }

        return nil
    }

    private var reactionIcon: String {
        if let type = ReactionType(rawValue: entry.reactionType) {
            return type.icon
        }
        return "exclamationmark.circle"
    }
}

// MARK: - Helper Views

struct StatBox: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct FoodScoreRow: View {
    let score: WeightedFoodScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Score indicator
            Circle()
                .fill(scoreColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(score.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.occurrencesWithin24h > 0 {
                        Text("\(score.occurrencesWithin24h)× <24h")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Last seen \(Int(score.lastSeenHoursBeforeReaction))h before reaction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(Int(score.totalScore))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        if score.totalScore >= 100 {
            return .red
        } else if score.totalScore >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct IngredientScoreRow: View {
    let score: WeightedIngredientScore

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Score indicator
            Circle()
                .fill(scoreColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(score.ingredientName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Label("\(score.occurrences)×", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if score.symptomAssociationScore > 0 {
                        Label("Pattern detected", systemImage: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text("Found in: \(score.contributingFoodNames.prefix(3).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(Int(score.totalScore))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
        .padding(.vertical, 8)
    }

    private var scoreColor: Color {
        if score.totalScore >= 100 {
            return .red
        } else if score.totalScore >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - Reaction Allergen Group Component

struct ReactionAllergenGroup: View {
    let allergenCategory: String
    let categoryScore: Int
    let ingredients: [WeightedIngredientScore]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header with score badge
            HStack(alignment: .center, spacing: 12) {
                Text(allergenCategory)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // Score badge
                Text("\(categoryScore)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.red.opacity(0.12))
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        }
                    )
                    .shadow(color: Color.red.opacity(0.15), radius: 3, x: 0, y: 2)
            }
            .padding(.bottom, 14)

            // Ingredient list
            VStack(alignment: .leading, spacing: 10) {
                ForEach(ingredients) { ingredient in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 4, height: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.ingredientName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            HStack(spacing: 12) {
                                Label("\(ingredient.occurrences)×", systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if ingredient.symptomAssociationScore > 0 {
                                    Label("Pattern detected", systemImage: "waveform.path.ecg")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            Text("Found in: \(ingredient.contributingFoodNames.prefix(3).joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("\(Int(ingredient.totalScore))")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(scoreColor(for: ingredient.totalScore))
                    }
                }
            }
        }
        .padding(.bottom, 28)
    }

    private func scoreColor(for score: Double) -> Color {
        if score >= 100 {
            return .red
        } else if score >= 50 {
            return .orange
        } else {
            return .yellow
        }
    }
}

// MARK: - PDF Export Sheet Placeholder

struct PDFExportSheet: View {
    let entry: ReactionLogEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("PDF Export")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("PDF export functionality will be implemented in ReactionPDFExporter.swift")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
