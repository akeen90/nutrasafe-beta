//
//  DatabaseToolsSheets.swift
//  NutraSafe Database Manager
//
//  Sheet views for database scanning, product import, and stock images
//

import SwiftUI

// MARK: - Database Scanner Sheet

struct DatabaseScannerSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var scannerService = DatabaseScannerService.shared
    @Environment(\.dismiss) var dismiss

    @State private var config = DatabaseScannerService.ScanConfig()
    @State private var allFoods: [FoodItem] = []
    @State private var isLoadingDatabase = false
    @State private var hasLoadedDatabase = false
    @State private var selectedIssue: DatabaseScannerService.FoodIssue?

    // Bulk selection support
    @State private var selectedIssueIDs: Set<UUID> = []
    @State private var isBulkApplying = false
    @State private var bulkApplyProgress: (completed: Int, total: Int)?
    @State private var showBulkApplyResult = false
    @State private var bulkApplyResultMessage = ""

    // Sorting support
    @State private var sortColumn: SortColumn = .name
    @State private var sortAscending = true

    enum SortColumn: String, CaseIterable {
        case name = "Name"
        case brand = "Brand"
        case severity = "Severity"
        case issueType = "Issue"
        case calDiff = "Cal Diff"
        case source = "Source"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            if !hasLoadedDatabase && !isLoadingDatabase {
                // Initial state - load database first
                startView
            } else if isLoadingDatabase {
                loadingDatabaseView
            } else if scannerService.isScanning {
                scanningView
            } else if let results = scannerService.scanResults {
                resultsView(results)
            } else {
                configurationView
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Database Scanner")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Verify nutrition data against Open Food Facts and UK retailers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if scannerService.isScanning {
                Button("Cancel Scan") {
                    scannerService.cancelScan()
                }
                .buttonStyle(.bordered)
            }

            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Verify Your Database")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Scan your food database and compare nutrition values against online sources")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Compares against Open Food Facts (global)", systemImage: "globe")
                Label("Verifies with UK retailer data (Tesco, Sainsbury's)", systemImage: "bag.fill")
                Label("Identifies serving size discrepancies", systemImage: "scalemass")
                Label("Finds outdated or incorrect nutrition values", systemImage: "exclamationmark.triangle")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            Button {
                Task { await loadDatabase() }
            } label: {
                Label("Load Database", systemImage: "arrow.down.circle")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    // MARK: - Loading Database View

    private var loadingDatabaseView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading database...")
                .font(.headline)
            Text("This may take a moment for large databases")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Database loaded info
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("\(allFoods.count.formatted()) foods loaded")
                            .font(.headline)
                        let withBarcode = allFoods.filter { $0.barcode != nil && !$0.barcode!.isEmpty }.count
                        Text("\(withBarcode.formatted()) have barcodes (scannable)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)

                // Configuration options
                GroupBox("Verification Options") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Verify nutrition values", isOn: $config.verifyNutrition)
                        Toggle("Verify serving sizes", isOn: $config.verifyServingSizes)
                        Toggle("Verify brand names", isOn: $config.verifyBrands)
                        Toggle("Only scan foods with barcodes", isOn: $config.onlyFoodsWithBarcode)
                        Toggle("Skip recently verified (last 30 days)", isOn: $config.skipRecentlyVerified)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("Data Sources") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Open Food Facts", isOn: Binding(
                            get: { config.sources.contains(.openFoodFacts) },
                            set: { if $0 { config.sources.insert(.openFoodFacts) } else { config.sources.remove(.openFoodFacts) } }
                        ))

                        Toggle("UK Retailers (Tesco, Sainsbury's)", isOn: Binding(
                            get: { config.sources.contains(.ukRetailers) },
                            set: { if $0 { config.sources.insert(.ukRetailers) } else { config.sources.remove(.ukRetailers) } }
                        ))
                    }
                    .padding(.vertical, 8)
                }

                GroupBox("Performance") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Concurrent requests:")
                            Picker("", selection: $config.maxConcurrentRequests) {
                                Text("1 (Slow)").tag(1)
                                Text("3 (Balanced)").tag(3)
                                Text("5 (Fast)").tag(5)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                        }

                        HStack {
                            Text("Delay between batches:")
                            Picker("", selection: $config.delayBetweenRequests) {
                                Text("0.25s").tag(0.25)
                                Text("0.5s").tag(0.5)
                                Text("1s").tag(1.0)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Start button
                HStack {
                    Spacer()
                    Button {
                        Task { await startScan() }
                    } label: {
                        Label("Start Scan", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(config.sources.isEmpty)
                }
            }
            .padding()
        }
    }

    // MARK: - Scanning View

    private var scanningView: some View {
        VStack(spacing: 20) {
            if let progress = scannerService.scanProgress {
                ProgressView(value: progress.percentComplete, total: 100)
                    .frame(width: 400)

                Text(progress.phase.rawValue)
                    .font(.headline)

                HStack(spacing: 40) {
                    VStack {
                        Text("\(progress.processedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Scanned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(progress.issuesFound)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Issues")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(progress.skippedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Skipped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !progress.currentFood.isEmpty {
                    Text("Checking: \(progress.currentFood)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Starting scan...")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View (Full Page Table with Bulk Selection)

    private func resultsView(_ results: DatabaseScannerService.ScanResults) -> some View {
        VStack(spacing: 0) {
            resultsToolbar(results)
            resultsProgressBars
            Divider()

            // Horizontal scrollable table area
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    resultsTableHeader(results)
                    Divider()
                    resultsIssuesList(results)
                }
                .frame(minWidth: 1200) // Ensure minimum width for all columns
            }

            resultsDetailPanel
        }
    }

    private func resultsToolbar(_ results: DatabaseScannerService.ScanResults) -> some View {
        HStack(spacing: 24) {
            HStack(spacing: 16) {
                StatBadge(value: results.scannedCount, label: "Scanned", color: .blue)
                StatBadge(value: results.issuesFound, label: "Issues", color: .orange)
                StatBadge(value: results.skippedCount, label: "Skipped", color: .secondary)
            }

            Divider().frame(height: 30)

            Text("\(selectedIssueIDs.count) selected")
                .font(.callout)
                .foregroundColor(selectedIssueIDs.isEmpty ? .secondary : .blue)

            Spacer()

            resultsSelectionButtons(results)

            Divider().frame(height: 30)

            resultsActionButtons(results)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func resultsSelectionButtons(_ results: DatabaseScannerService.ScanResults) -> some View {
        let allIDs = results.issues.map { $0.id }
        let nutritionIDs = results.issues.filter { $0.issueType == .nutritionMismatch }.map { $0.id }

        return HStack(spacing: 8) {
            Button("Select All") { selectedIssueIDs = Set(allIDs) }
                .buttonStyle(.bordered).controlSize(.small)

            Button("Select None") { selectedIssueIDs.removeAll() }
                .buttonStyle(.bordered).controlSize(.small)

            Button("Select Nutrition") { selectedIssueIDs = Set(nutritionIDs) }
                .buttonStyle(.bordered).controlSize(.small)
        }
    }

    private func resultsActionButtons(_ results: DatabaseScannerService.ScanResults) -> some View {
        let selectedIssues = results.issues.filter { selectedIssueIDs.contains($0.id) }
        let selectedCount = selectedIssueIDs.count
        let canApply = !selectedIssueIDs.isEmpty && !isBulkApplying

        return HStack(spacing: 8) {
            Button { Task { await applyBulkChanges(issues: selectedIssues) } } label: {
                HStack(spacing: 4) {
                    if isBulkApplying { ProgressView().scaleEffect(0.6) }
                    Image(systemName: "checkmark.circle.fill")
                    Text("Apply to \(selectedCount) Selected")
                }
            }
            .buttonStyle(.borderedProminent).tint(.green).disabled(!canApply)

            Button("New Scan") {
                scannerService.scanResults = nil
                selectedIssue = nil
                selectedIssueIDs.removeAll()
            }
            .buttonStyle(.bordered)

            Button("Export") { exportIssues(results.issues) }
                .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var resultsProgressBars: some View {
        if isBulkApplying, let progress = bulkApplyProgress {
            HStack {
                ProgressView(value: Double(progress.completed), total: Double(progress.total))
                    .frame(width: 200)
                Text("Applying changes: \(progress.completed)/\(progress.total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
        }

        if showBulkApplyResult {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(bulkApplyResultMessage)
                    .font(.callout)
                Spacer()
                Button("Dismiss") {
                    showBulkApplyResult = false
                }
                .buttonStyle(.borderless)
            }
            .padding(8)
            .background(Color.green.opacity(0.1))
        }
    }

    private func resultsTableHeader(_ results: DatabaseScannerService.ScanResults) -> some View {
        HStack(alignment: .center, spacing: 8) {
            // Checkbox
            Toggle("", isOn: Binding(
                get: { selectedIssueIDs.count == results.issues.count && !results.issues.isEmpty },
                set: { selectAll in
                    if selectAll {
                        selectedIssueIDs = Set(results.issues.map { $0.id })
                    } else {
                        selectedIssueIDs.removeAll()
                    }
                }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 24)

            // Sortable columns
            sortableHeader("Name", column: .name, width: 180)
            sortableHeader("Brand", column: .brand, width: 140)
            sortableHeader("Severity", column: .severity, width: 70)
            sortableHeader("Issue", column: .issueType, width: 110)

            Text("Database (per 100g)").frame(width: 200, alignment: .leading)
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            Text("").frame(width: 20)
            Text("Online (per 100g)").frame(width: 200, alignment: .leading)
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)

            Text("Serving").frame(width: 100, alignment: .leading)
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)

            sortableHeader("Cal Diff", column: .calDiff, width: 65)
            sortableHeader("Source", column: .source, width: 70)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .separatorColor).opacity(0.2))
    }

    private func sortableHeader(_ title: String, column: SortColumn, width: CGFloat) -> some View {
        Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = true
            }
        } label: {
            HStack(spacing: 2) {
                Text(title)
                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
            }
            .frame(width: width, alignment: .leading)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(sortColumn == column ? .blue : .secondary)
        }
        .buttonStyle(.plain)
    }

    private func sortedIssues(_ issues: [DatabaseScannerService.FoodIssue]) -> [DatabaseScannerService.FoodIssue] {
        issues.sorted { a, b in
            let result: Bool
            switch sortColumn {
            case .name:
                result = a.food.name.lowercased() < b.food.name.lowercased()
            case .brand:
                let brandA = a.food.brand?.lowercased() ?? ""
                let brandB = b.food.brand?.lowercased() ?? ""
                result = brandA < brandB
            case .severity:
                result = severityOrder(a.severity) < severityOrder(b.severity)
            case .issueType:
                result = a.issueType.rawValue < b.issueType.rawValue
            case .calDiff:
                result = abs(calorieDiff(a)) > abs(calorieDiff(b)) // Higher diff first by default
            case .source:
                let srcA = a.onlineData?.source ?? ""
                let srcB = b.onlineData?.source ?? ""
                result = srcA < srcB
            }
            return sortAscending ? result : !result
        }
    }

    private func severityOrder(_ severity: DatabaseScannerService.FoodIssue.IssueSeverity) -> Int {
        switch severity {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    private func calorieDiff(_ issue: DatabaseScannerService.FoodIssue) -> Double {
        let dbCal = issue.food.calories
        var onlineCal: Double = 0
        if let n = issue.onlineData?.offProduct?.nutriments {
            onlineCal = n.energy_kcal_100g ?? n.energy_kcal ?? 0
        } else if let uk = issue.onlineData?.ukProductData {
            onlineCal = uk.caloriesPer100g ?? 0
        }
        guard dbCal > 0 else { return 0 }
        return ((onlineCal - dbCal) / dbCal) * 100
    }

    @ViewBuilder
    private func resultsIssuesList(_ results: DatabaseScannerService.ScanResults) -> some View {
        if results.issues.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                Text("No issues found!")
                    .font(.headline)
                Text("All scanned foods match online data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sortedIssues(results.issues)) { issue in
                        BulkIssueRow(
                            issue: issue,
                            isSelected: selectedIssueIDs.contains(issue.id),
                            onToggleSelection: {
                                if selectedIssueIDs.contains(issue.id) {
                                    selectedIssueIDs.remove(issue.id)
                                } else {
                                    selectedIssueIDs.insert(issue.id)
                                }
                            },
                            onRowTap: {
                                selectedIssue = issue
                            }
                        )
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var resultsDetailPanel: some View {
        if let issue = selectedIssue {
            Divider()
            IssueDetailPanel(issue: issue, onClose: { selectedIssue = nil })
                .frame(height: 350)
        }
    }

    // MARK: - Bulk Apply Changes

    private func applyBulkChanges(issues: [DatabaseScannerService.FoodIssue]) async {
        guard !issues.isEmpty else { return }

        isBulkApplying = true
        bulkApplyProgress = (0, issues.count)

        var successCount = 0
        var failCount = 0

        for (index, issue) in issues.enumerated() {
            // Apply all available online values to this food
            var updatedFood = issue.food

            // Apply nutrition values from online data
            // Note: Only apply per-100g values and serving sizes for per-100g foods
            let isPerUnitFood = issue.food.isPerUnit == true

            if let offProduct = issue.onlineData?.offProduct {
                // Update product name if available
                if let onlineName = offProduct.product_name_en ?? offProduct.product_name, !onlineName.isEmpty {
                    updatedFood.name = onlineName
                }

                // Nutrition values (per 100g) - only apply to per-100g foods
                if !isPerUnitFood, let nutriments = offProduct.nutriments {
                    if let val = nutriments.energy_kcal_100g ?? nutriments.energy_kcal { updatedFood.calories = val }
                    if let val = nutriments.proteins_100g ?? nutriments.proteins { updatedFood.protein = val }
                    if let val = nutriments.carbohydrates_100g ?? nutriments.carbohydrates { updatedFood.carbs = val }
                    if let val = nutriments.fat_100g ?? nutriments.fat { updatedFood.fat = val }
                    if let val = nutriments.fiber_100g ?? nutriments.fiber { updatedFood.fiber = val }
                    if let val = nutriments.sugars_100g ?? nutriments.sugars { updatedFood.sugar = val }
                    if let val = nutriments.salt_100g ?? nutriments.salt { updatedFood.sodium = (val / 2.5) * 1000 }
                    if let val = nutriments.saturated_fat_100g ?? nutriments.saturated_fat { updatedFood.saturatedFat = val }
                }
                // Brand and ingredients can be updated for both
                if let brand = offProduct.brands, !brand.isEmpty { updatedFood.brand = brand }
                // Only update serving size for per-100g foods - set BOTH servingSizeG and servingDescription
                if !isPerUnitFood, let serving = offProduct.serving_size, !serving.isEmpty {
                    // Extract numeric grams and set servingSizeG (primary field for iOS app)
                    if let grams = extractServingGrams(from: serving) {
                        updatedFood.servingSizeG = grams
                    }
                    // Also keep the description for display
                    updatedFood.servingDescription = serving
                }
                if let ingredients = offProduct.ingredients_text_en ?? offProduct.ingredients_text, !ingredients.isEmpty {
                    updatedFood.ingredientsText = ingredients
                }
            } else if let ukData = issue.onlineData?.ukProductData {
                // Update product name if available
                if let onlineName = ukData.name, !onlineName.isEmpty {
                    updatedFood.name = onlineName
                }

                // Nutrition values (per 100g) - only apply to per-100g foods
                if !isPerUnitFood {
                    if let val = ukData.caloriesPer100g { updatedFood.calories = val }
                    if let val = ukData.proteinPer100g { updatedFood.protein = val }
                    if let val = ukData.carbsPer100g { updatedFood.carbs = val }
                    if let val = ukData.fatPer100g { updatedFood.fat = val }
                    if let val = ukData.fibrePer100g { updatedFood.fiber = val }
                    if let val = ukData.sugarPer100g { updatedFood.sugar = val }
                    if let val = ukData.saltPer100g { updatedFood.sodium = (val / 2.5) * 1000 }
                    if let val = ukData.saturatedFatPer100g { updatedFood.saturatedFat = val }
                }
                // Brand and ingredients can be updated for both
                if let brand = ukData.brand, !brand.isEmpty { updatedFood.brand = brand }
                if let ingredients = ukData.ingredientsText, !ingredients.isEmpty {
                    updatedFood.ingredientsText = ingredients
                }
            }

            updatedFood.lastUpdated = ISO8601DateFormatter().string(from: Date())

            let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)

            if success {
                successCount += 1
            } else {
                failCount += 1
            }

            await MainActor.run {
                bulkApplyProgress = (index + 1, issues.count)
            }
        }

        await MainActor.run {
            isBulkApplying = false
            bulkApplyProgress = nil
            selectedIssueIDs.removeAll()
            showBulkApplyResult = true
            bulkApplyResultMessage = "Applied changes to \(successCount) items" + (failCount > 0 ? " (\(failCount) failed)" : "")

            // Auto-hide after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                showBulkApplyResult = false
            }
        }
    }

    /// Extract numeric grams from a serving size string like "225g", "1/2 pack (225g)", "1 portion (150g)"
    private func extractServingGrams(from servingString: String) -> Double? {
        let lowercased = servingString.lowercased()

        // Patterns to match numbers followed by g, ml, or gram/ml
        // IMPORTANT: Order matters - more specific patterns first, then general ones
        // The "g" must be immediately after the number (with optional space) to avoid matching "1 portion"
        let patterns = [
            #"\((\d+(?:\.\d+)?)\s*g\)"#,             // "(150g)", "(30 g)" - parenthetical grams (highest priority)
            #"(\d+(?:\.\d+)?)\s*g\s*\)"#,            // "150g)" at end of parenthetical
            #"=\s*(\d+(?:\.\d+)?)\s*g\b"#,           // "= 225g"
            #"(\d+(?:\.\d+)?)\s*g\s+serving"#,       // "30g serving"
            #"serving[:\s]+(\d+(?:\.\d+)?)\s*g\b"#,  // "serving: 30g"
            #"(\d+(?:\.\d+)?)\s*grams?\b"#,          // "225 grams", "30gram"
            #"(\d+(?:\.\d+)?)\s*ml\b"#,              // "330ml" for drinks
            #"(\d+(?:\.\d+)?)\s*g\b"#,               // "30g" with word boundary (NOT "1 portion" where g is in "portion")
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercased.startIndex..<lowercased.endIndex, in: lowercased)
                if let match = regex.firstMatch(in: lowercased, options: [], range: range) {
                    if let valueRange = Range(match.range(at: 1), in: lowercased) {
                        if let value = Double(lowercased[valueRange]) {
                            // Sanity check: reasonable serving size (5-500g), skip 100g reference
                            if value >= 5 && value <= 500 && value != 100 {
                                return value
                            }
                        }
                    }
                }
            }
        }

        return nil
    }

    private func summaryCard(_ results: DatabaseScannerService.ScanResults) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: results.issuesFound > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(results.issuesFound > 0 ? .orange : .green)
                Text("Scan Complete")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1fs", results.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 24) {
                StatView(value: results.scannedCount, label: "Scanned", color: .blue)
                StatView(value: results.issuesFound, label: "Issues", color: .orange)
                StatView(value: results.skippedCount, label: "Skipped", color: .secondary)
            }

            if results.issuesFound > 0 {
                Divider()
                HStack(spacing: 16) {
                    MiniStatView(value: results.summary.nutritionDiscrepancies, label: "Nutrition", icon: "flame")
                    MiniStatView(value: results.summary.servingSizeIssues, label: "Serving", icon: "scalemass")
                    MiniStatView(value: results.summary.brandMismatches, label: "Brand", icon: "tag")
                    MiniStatView(value: results.summary.missingOnlineData, label: "Not Found", icon: "questionmark")
                }
            }

            HStack {
                Button("Run New Scan") {
                    scannerService.scanResults = nil
                    selectedIssue = nil
                }
                .buttonStyle(.bordered)

                Spacer()

                if results.issuesFound > 0 {
                    Button("Export Issues") {
                        exportIssues(results.issues)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func loadDatabase() async {
        isLoadingDatabase = true
        await algoliaService.browseAllFoods(database: appState.selectedDatabase)
        allFoods = algoliaService.foods
        isLoadingDatabase = false
        hasLoadedDatabase = true
    }

    private func startScan() async {
        _ = await scannerService.scanDatabase(foods: allFoods, config: config)
    }

    private func exportIssues(_ issues: [DatabaseScannerService.FoodIssue]) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "scan_issues_\(Date().ISO8601Format()).json"

        if panel.runModal() == .OK, let url = panel.url {
            let exportData = issues.map { issue -> [String: Any] in
                [
                    "foodName": issue.food.name,
                    "barcode": issue.food.barcode ?? "",
                    "issueType": issue.issueType.rawValue,
                    "severity": issue.severity.rawValue,
                    "description": issue.description,
                    "details": issue.details.map { ["field": $0.field, "ourValue": $0.ourValue, "onlineValue": $0.onlineValue] }
                ]
            }

            if let data = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
                try? data.write(to: url)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
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

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct MiniStatView: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text("\(value)")
                .fontWeight(.medium)
            Text(label)
                .foregroundColor(.secondary)
        }
        .font(.caption)
    }
}

// MARK: - Bulk Issue Row (for full-page table view)

struct BulkIssueRow: View {
    let issue: DatabaseScannerService.FoodIssue
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onRowTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Checkbox
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggleSelection() }
            ))
            .toggleStyle(.checkbox)
            .frame(width: 24)
            .padding(.top, 4)

            // Name column
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.food.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)
                if let barcode = issue.food.barcode {
                    Text(barcode)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 180, alignment: .leading)
            .clipped()

            // Brand column
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.food.brand ?? "—")
                    .font(.callout)
                    .lineLimit(2)
                    .foregroundColor(issue.food.brand != nil ? .primary : .gray)
                if let onlineBrand = onlineBrandValue, !onlineBrand.isEmpty, onlineBrand.lowercased() != (issue.food.brand ?? "").lowercased() {
                    Text("→ \(onlineBrand)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .clipped()

            // Severity
            Text(issue.severity.rawValue)
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(severityColor.opacity(0.2))
                .foregroundColor(severityColor)
                .cornerRadius(4)
                .frame(width: 70, alignment: .leading)

            // Issue Type
            Text(issue.issueType.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)
                .clipped()

            // Database values
            databaseValuesColumn
                .frame(width: 200, alignment: .leading)
                .clipped()

            // Arrow
            Image(systemName: "arrow.right.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 20)
                .padding(.top, 15)

            // Online values
            onlineValuesColumn
                .frame(width: 200, alignment: .leading)
                .clipped()

            // Serving size column
            servingSizeColumn
                .frame(width: 100, alignment: .leading)
                .clipped()

            // Cal Diff %
            Text(calDiffText)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(calDiffColor)
                .frame(width: 65, alignment: .leading)

            // Source
            Text(issue.onlineData?.source ?? "—")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 70, alignment: .leading)
                .clipped()

            Spacer()

            // Expand button
            Button { onRowTap() } label: {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onToggleSelection() }
    }

    // MARK: - Database Values Column

    private var databaseValuesColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Calories row
            HStack(spacing: 4) {
                Text("Cal:")
                    .foregroundColor(.secondary)
                Text("\(Int(issue.food.calories))")
                    .fontWeight(.semibold)
            }
            .font(.caption)

            // Macros row
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Text("P").foregroundColor(.secondary)
                    Text(String(format: "%.1f", issue.food.protein))
                }
                HStack(spacing: 2) {
                    Text("C").foregroundColor(.secondary)
                    Text(String(format: "%.1f", issue.food.carbs))
                }
                HStack(spacing: 2) {
                    Text("F").foregroundColor(.secondary)
                    Text(String(format: "%.1f", issue.food.fat))
                }
            }
            .font(.caption)

            // Fiber/Sugar row
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Text("Fib").foregroundColor(.secondary)
                    Text(String(format: "%.1f", issue.food.fiber))
                }
                HStack(spacing: 2) {
                    Text("Sug").foregroundColor(.secondary)
                    Text(String(format: "%.1f", issue.food.sugar))
                }
            }
            .font(.caption)
        }
    }

    // MARK: - Online Values Column

    private var onlineValuesColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let n = issue.onlineData?.offProduct?.nutriments {
                // Calories row
                HStack(spacing: 4) {
                    Text("Cal:")
                        .foregroundColor(.blue.opacity(0.7))
                    Text("\(Int(n.energy_kcal_100g ?? n.energy_kcal ?? 0))")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.caption)

                // Macros row
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("P").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", n.proteins_100g ?? n.proteins ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("C").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", n.carbohydrates_100g ?? n.carbohydrates ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("F").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", n.fat_100g ?? n.fat ?? 0))
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)

                // Fiber/Sugar row
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("Fib").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", n.fiber_100g ?? n.fiber ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("Sug").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", n.sugars_100g ?? n.sugars ?? 0))
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)

            } else if let uk = issue.onlineData?.ukProductData {
                // Calories row
                HStack(spacing: 4) {
                    Text("Cal:")
                        .foregroundColor(.blue.opacity(0.7))
                    Text("\(Int(uk.caloriesPer100g ?? 0))")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .font(.caption)

                // Macros row
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("P").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", uk.proteinPer100g ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("C").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", uk.carbsPer100g ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("F").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", uk.fatPer100g ?? 0))
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)

                // Fiber/Sugar row
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("Fib").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", uk.fibrePer100g ?? 0))
                    }
                    HStack(spacing: 2) {
                        Text("Sug").foregroundColor(.blue.opacity(0.7))
                        Text(String(format: "%.1f", uk.sugarPer100g ?? 0))
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Serving Size Column

    private var servingSizeColumn: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Database serving
            HStack(spacing: 2) {
                Text("DB:")
                    .foregroundColor(.secondary)
                if let serving = issue.food.servingSizeG, serving > 0 {
                    Text("\(Int(serving))g")
                } else if let desc = issue.food.servingDescription, !desc.isEmpty {
                    Text(desc)
                        .lineLimit(1)
                } else {
                    Text("—")
                        .foregroundColor(.gray)
                }
            }
            .font(.caption)

            // Online serving
            HStack(spacing: 2) {
                Text("Online:")
                    .foregroundColor(.blue.opacity(0.7))
                Text(onlineServingText)
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
            .font(.caption)
        }
    }

    private var onlineServingText: String {
        if let offProduct = issue.onlineData?.offProduct {
            if let serving = offProduct.serving_size, !serving.isEmpty {
                return serving
            }
        }
        return "—"
    }

    // MARK: - Calorie Diff

    private var calDiffText: String {
        let dbCal = issue.food.calories
        guard dbCal > 0 else { return "—" }
        var onlineCal: Double = 0
        if let n = issue.onlineData?.offProduct?.nutriments {
            onlineCal = n.energy_kcal_100g ?? n.energy_kcal ?? 0
        } else if let uk = issue.onlineData?.ukProductData {
            onlineCal = uk.caloriesPer100g ?? 0
        }
        let diff = ((onlineCal - dbCal) / dbCal) * 100
        if abs(diff) < 1 { return "~0%" }
        let sign = diff > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", diff))%"
    }

    private var calDiffColor: Color {
        let dbCal = issue.food.calories
        guard dbCal > 0 else { return .gray }
        var onlineCal: Double = 0
        if let n = issue.onlineData?.offProduct?.nutriments {
            onlineCal = n.energy_kcal_100g ?? n.energy_kcal ?? 0
        } else if let uk = issue.onlineData?.ukProductData {
            onlineCal = uk.caloriesPer100g ?? 0
        }
        let diff = abs(((onlineCal - dbCal) / dbCal) * 100)
        if diff > 30 { return .red }
        if diff > 15 { return .orange }
        if diff > 5 { return .yellow }
        return .green
    }

    private var onlineBrandValue: String? {
        if let brand = issue.onlineData?.offProduct?.brands, !brand.isEmpty {
            return brand
        }
        if let brand = issue.onlineData?.ukProductData?.brand, !brand.isEmpty {
            return brand
        }
        return nil
    }

    // MARK: - Online Values (extracted for cleaner code)

    private var onlineCalories: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.energy_kcal_100g ?? n.energy_kcal
        }
        return issue.onlineData?.ukProductData?.caloriesPer100g
    }

    private var onlineProtein: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.proteins_100g ?? n.proteins
        }
        return issue.onlineData?.ukProductData?.proteinPer100g
    }

    private var onlineCarbs: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.carbohydrates_100g ?? n.carbohydrates
        }
        return issue.onlineData?.ukProductData?.carbsPer100g
    }

    private var onlineFat: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.fat_100g ?? n.fat
        }
        return issue.onlineData?.ukProductData?.fatPer100g
    }

    private var onlineFiber: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.fiber_100g ?? n.fiber
        }
        return issue.onlineData?.ukProductData?.fibrePer100g
    }

    private var onlineSugar: Double? {
        if let n = issue.onlineData?.offProduct?.nutriments {
            return n.sugars_100g ?? n.sugars
        }
        return issue.onlineData?.ukProductData?.sugarPer100g
    }

    private var brandChanged: Bool {
        let dbBrand = issue.food.brand ?? ""
        if let offBrand = issue.onlineData?.offProduct?.brands, !offBrand.isEmpty {
            return offBrand.lowercased() != dbBrand.lowercased()
        }
        if let ukBrand = issue.onlineData?.ukProductData?.brand, !ukBrand.isEmpty {
            return ukBrand.lowercased() != dbBrand.lowercased()
        }
        return false
    }

    private var severityColor: Color {
        switch issue.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Issue Detail Panel (Bottom Panel)

struct IssueDetailPanel: View {
    let issue: DatabaseScannerService.FoodIssue
    let onClose: () -> Void
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState

    @State private var isSaving = false
    @State private var saveSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            HStack {
                Text(issue.food.name)
                    .font(.headline)
                if let brand = issue.food.brand {
                    Text("• \(brand)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let barcode = issue.food.barcode {
                    Text("• \(barcode)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if saveSuccess {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }

                Button {
                    Task { await applyAllChanges() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Text("Apply All Changes")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isSaving)

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Comparison content
            HStack(alignment: .top, spacing: 24) {
                // Database values
                GroupBox("Database (Current)") {
                    nutritionGrid(
                        cal: issue.food.calories,
                        pro: issue.food.protein,
                        carb: issue.food.carbs,
                        fat: issue.food.fat,
                        fib: issue.food.fiber,
                        sug: issue.food.sugar,
                        sod: issue.food.sodium,
                        sat: issue.food.saturatedFat
                    )
                }
                .frame(minWidth: 200)

                // Online values
                GroupBox("Online (Proposed)") {
                    if let offProduct = issue.onlineData?.offProduct, let n = offProduct.nutriments {
                        nutritionGrid(
                            cal: n.energy_kcal_100g ?? n.energy_kcal,
                            pro: n.proteins_100g ?? n.proteins,
                            carb: n.carbohydrates_100g ?? n.carbohydrates,
                            fat: n.fat_100g ?? n.fat,
                            fib: n.fiber_100g ?? n.fiber,
                            sug: n.sugars_100g ?? n.sugars,
                            sod: (n.salt_100g ?? n.salt).map { $0 / 2.5 * 1000 },
                            sat: n.saturated_fat_100g ?? n.saturated_fat
                        )
                    } else if let ukData = issue.onlineData?.ukProductData {
                        nutritionGrid(
                            cal: ukData.caloriesPer100g,
                            pro: ukData.proteinPer100g,
                            carb: ukData.carbsPer100g,
                            fat: ukData.fatPer100g,
                            fib: ukData.fibrePer100g,
                            sug: ukData.sugarPer100g,
                            sod: ukData.saltPer100g.map { $0 / 2.5 * 1000 },
                            sat: ukData.saturatedFatPer100g
                        )
                    } else {
                        Text("No data")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(minWidth: 200)

                // Differences highlighted
                GroupBox("Key Differences") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(issue.details, id: \.field) { detail in
                            HStack {
                                Text(detail.field.capitalized)
                                    .font(.caption)
                                    .frame(width: 70, alignment: .leading)
                                Text(detail.ourValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                Text(detail.onlineValue)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(minWidth: 250)

                // Ingredients
                GroupBox("Ingredients") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if let ingredients = issue.food.ingredientsText ?? issue.food.ingredients?.joined(separator: ", ") {
                                Text("Ours: \(ingredients)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let online = getOnlineIngredients() {
                                Divider()
                                Text("Online: \(online)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(minWidth: 300)

                Spacer()
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func nutritionGrid(cal: Double?, pro: Double?, carb: Double?, fat: Double?, fib: Double?, sug: Double?, sod: Double?, sat: Double?) -> some View {
        LazyVGrid(columns: [GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 4) {
            nutritionCell("Calories", value: cal, unit: "kcal", decimals: 0)
            nutritionCell("Protein", value: pro, unit: "g")
            nutritionCell("Carbs", value: carb, unit: "g")
            nutritionCell("Fat", value: fat, unit: "g")
            nutritionCell("Fiber", value: fib, unit: "g")
            nutritionCell("Sugar", value: sug, unit: "g")
            nutritionCell("Salt", value: sod != nil ? sod! / 400 : nil, unit: "g", decimals: 2)
            nutritionCell("Sat Fat", value: sat, unit: "g")
        }
    }

    private func nutritionCell(_ label: String, value: Double?, unit: String, decimals: Int = 1) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text(decimals == 0 ? "\(Int(v))\(unit)" : String(format: "%.1f\(unit)", v))
                    .font(.caption)
                    .monospacedDigit()
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func getOnlineIngredients() -> String? {
        if let offProduct = issue.onlineData?.offProduct {
            return offProduct.ingredients_text_en ?? offProduct.ingredients_text
        } else if let ukData = issue.onlineData?.ukProductData {
            return ukData.ingredientsText
        }
        return nil
    }

    private func applyAllChanges() async {
        isSaving = true

        var updatedFood = issue.food

        if let offProduct = issue.onlineData?.offProduct, let n = offProduct.nutriments {
            if let v = n.energy_kcal_100g ?? n.energy_kcal { updatedFood.calories = v }
            if let v = n.proteins_100g ?? n.proteins { updatedFood.protein = v }
            if let v = n.carbohydrates_100g ?? n.carbohydrates { updatedFood.carbs = v }
            if let v = n.fat_100g ?? n.fat { updatedFood.fat = v }
            if let v = n.fiber_100g ?? n.fiber { updatedFood.fiber = v }
            if let v = n.sugars_100g ?? n.sugars { updatedFood.sugar = v }
            if let v = n.salt_100g ?? n.salt { updatedFood.sodium = (v / 2.5) * 1000 }
            if let v = n.saturated_fat_100g ?? n.saturated_fat { updatedFood.saturatedFat = v }
            if let brand = offProduct.brands { updatedFood.brand = brand }
            if let serving = offProduct.serving_size { updatedFood.servingDescription = serving }
            if let ingredients = offProduct.ingredients_text_en ?? offProduct.ingredients_text {
                updatedFood.ingredientsText = ingredients
            }
        } else if let ukData = issue.onlineData?.ukProductData {
            if let v = ukData.caloriesPer100g { updatedFood.calories = v }
            if let v = ukData.proteinPer100g { updatedFood.protein = v }
            if let v = ukData.carbsPer100g { updatedFood.carbs = v }
            if let v = ukData.fatPer100g { updatedFood.fat = v }
            if let v = ukData.fibrePer100g { updatedFood.fiber = v }
            if let v = ukData.sugarPer100g { updatedFood.sugar = v }
            if let v = ukData.saltPer100g { updatedFood.sodium = (v / 2.5) * 1000 }
            if let v = ukData.saturatedFatPer100g { updatedFood.saturatedFat = v }
            if let brand = ukData.brand { updatedFood.brand = brand }
            if let ingredients = ukData.ingredientsText {
                updatedFood.ingredientsText = ingredients
            }
        }

        updatedFood.lastUpdated = ISO8601DateFormatter().string(from: Date())

        let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)

        await MainActor.run {
            isSaving = false
            if success {
                saveSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    saveSuccess = false
                }
            }
        }
    }
}

// Keep old IssueRowView for backwards compatibility if needed elsewhere
struct IssueRowView: View {
    let issue: DatabaseScannerService.FoodIssue

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(severityColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.food.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(issue.issueType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(issue.details.count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }

    private var severityColor: Color {
        switch issue.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct IssueDetailView: View {
    let issue: DatabaseScannerService.FoodIssue
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var appState: AppState

    @State private var selectedFields: Set<String> = []
    @State private var isSaving = false
    @State private var showSaveSuccess = false

    // All possible fields we can update
    private let nutritionFields = ["calories", "protein", "carbs", "fat", "fiber", "sugar", "sodium", "saturatedFat"]
    private let metaFields = ["brand", "servingDescription", "ingredientsText"]

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(alignment: .leading, spacing: 20) {
                // Header with product info
                headerSection

                // Source info bar
                if let onlineData = issue.onlineData {
                    sourceInfoBar(onlineData)
                }

                // Selection controls
                selectionControlsBar

                Divider()

                // Full comparison sections
                HStack(alignment: .top, spacing: 24) {
                    // Database values (current)
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Database (Current)", color: .secondary)
                        databaseValuesCard
                    }
                    .frame(minWidth: 350)

                    // Online values (proposed)
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Online Source (Proposed)", color: .blue)
                        onlineValuesCard
                    }
                    .frame(minWidth: 350)

                    // Difference column
                    VStack(alignment: .leading, spacing: 0) {
                        sectionHeader("Difference", color: .orange)
                        differenceCard
                    }
                    .frame(minWidth: 150)
                }

                Divider()

                // Ingredients comparison (full width)
                ingredientsComparison

                Divider()

                // Action buttons
                actionButtons
            }
            .padding(20)
            .frame(minWidth: 900)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Pre-select fields that have significant differences
            preselectSignificantDifferences()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Product image
            if let imageURL = issue.food.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fit)
                    default:
                        Image(systemName: "photo").font(.largeTitle).foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .background(Color.secondary.opacity(0.1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.food.name)
                    .font(.title2)
                    .fontWeight(.bold)
                if let brand = issue.food.brand {
                    Text(brand)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                if let barcode = issue.food.barcode {
                    HStack(spacing: 4) {
                        Image(systemName: "barcode")
                        Text(barcode)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Severity badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(issue.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(8)

                Text(issue.issueType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func sourceInfoBar(_ onlineData: DatabaseScannerService.FoodIssue.OnlineData) -> some View {
        HStack(spacing: 16) {
            Label(onlineData.source, systemImage: "globe")
                .font(.callout)
                .foregroundColor(.blue)

            Text("•")
                .foregroundColor(.secondary)

            Text(String(format: "%.0f%% confidence", onlineData.confidence * 100))
                .font(.callout)

            if issue.onlineData?.offProduct?.image_front_url != nil ||
               issue.onlineData?.ukProductData?.imageURL != nil {
                Text("•")
                    .foregroundColor(.secondary)
                Text("Image available")
                    .font(.callout)
                    .foregroundColor(.green)
            }

            Spacer()

            if showSaveSuccess {
                Label("Changes saved!", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.callout)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Selection Controls

    private var selectionControlsBar: some View {
        HStack(spacing: 16) {
            Text("\(selectedFields.count) field(s) selected")
                .font(.callout)
                .foregroundColor(.secondary)

            Spacer()

            Button("Select All") {
                selectAllFields()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Select Nutrition") {
                selectedFields = Set(nutritionFields.filter { hasOnlineValue(for: $0) })
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Select Differences Only") {
                preselectSignificantDifferences()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button("Clear Selection") {
                selectedFields.removeAll()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(color)
            .padding(.bottom, 8)
    }

    // MARK: - Database Values Card

    private var databaseValuesCard: some View {
        VStack(spacing: 0) {
            // Nutrition
            GroupBox("Nutrition (per 100g)") {
                VStack(spacing: 4) {
                    nutritionRow("Calories", value: "\(Int(issue.food.calories)) kcal", field: "calories", isDatabase: true)
                    nutritionRow("Protein", value: String(format: "%.1fg", issue.food.protein), field: "protein", isDatabase: true)
                    nutritionRow("Carbs", value: String(format: "%.1fg", issue.food.carbs), field: "carbs", isDatabase: true)
                    nutritionRow("Fat", value: String(format: "%.1fg", issue.food.fat), field: "fat", isDatabase: true)
                    nutritionRow("Fiber", value: String(format: "%.1fg", issue.food.fiber), field: "fiber", isDatabase: true)
                    nutritionRow("Sugar", value: String(format: "%.1fg", issue.food.sugar), field: "sugar", isDatabase: true)
                    nutritionRow("Salt", value: String(format: "%.2fg", issue.food.sodium / 400), field: "sodium", isDatabase: true)
                    if let satFat = issue.food.saturatedFat {
                        nutritionRow("Sat. Fat", value: String(format: "%.1fg", satFat), field: "saturatedFat", isDatabase: true)
                    }
                }
            }

            GroupBox("Meta") {
                VStack(spacing: 4) {
                    metaRow("Brand", value: issue.food.brand ?? "—", field: "brand", isDatabase: true)
                    metaRow("Serving", value: issue.food.servingDescription ?? "—", field: "servingDescription", isDatabase: true)
                }
            }
        }
    }

    // MARK: - Online Values Card

    private var onlineValuesCard: some View {
        VStack(spacing: 0) {
            if let offProduct = issue.onlineData?.offProduct, let nutriments = offProduct.nutriments {
                GroupBox("Nutrition (per 100g)") {
                    VStack(spacing: 4) {
                        nutritionRow("Calories", value: formatOptional(nutriments.energy_kcal_100g ?? nutriments.energy_kcal, suffix: " kcal", decimals: 0), field: "calories", isDatabase: false)
                        nutritionRow("Protein", value: formatOptional(nutriments.proteins_100g ?? nutriments.proteins, suffix: "g"), field: "protein", isDatabase: false)
                        nutritionRow("Carbs", value: formatOptional(nutriments.carbohydrates_100g ?? nutriments.carbohydrates, suffix: "g"), field: "carbs", isDatabase: false)
                        nutritionRow("Fat", value: formatOptional(nutriments.fat_100g ?? nutriments.fat, suffix: "g"), field: "fat", isDatabase: false)
                        nutritionRow("Fiber", value: formatOptional(nutriments.fiber_100g ?? nutriments.fiber, suffix: "g"), field: "fiber", isDatabase: false)
                        nutritionRow("Sugar", value: formatOptional(nutriments.sugars_100g ?? nutriments.sugars, suffix: "g"), field: "sugar", isDatabase: false)
                        nutritionRow("Sodium", value: formatSodiumFromSalt(nutriments.salt_100g ?? nutriments.salt), field: "sodium", isDatabase: false)
                        nutritionRow("Sat. Fat", value: formatOptional(nutriments.saturated_fat_100g ?? nutriments.saturated_fat, suffix: "g"), field: "saturatedFat", isDatabase: false)
                    }
                }

                GroupBox("Meta") {
                    VStack(spacing: 4) {
                        metaRow("Brand", value: offProduct.brands ?? "—", field: "brand", isDatabase: false)
                        metaRow("Serving", value: offProduct.serving_size ?? "—", field: "servingDescription", isDatabase: false)
                    }
                }
            } else if let ukData = issue.onlineData?.ukProductData {
                GroupBox("Nutrition (per 100g)") {
                    VStack(spacing: 4) {
                        nutritionRow("Calories", value: formatOptional(ukData.caloriesPer100g, suffix: " kcal", decimals: 0), field: "calories", isDatabase: false)
                        nutritionRow("Protein", value: formatOptional(ukData.proteinPer100g, suffix: "g"), field: "protein", isDatabase: false)
                        nutritionRow("Carbs", value: formatOptional(ukData.carbsPer100g, suffix: "g"), field: "carbs", isDatabase: false)
                        nutritionRow("Fat", value: formatOptional(ukData.fatPer100g, suffix: "g"), field: "fat", isDatabase: false)
                        nutritionRow("Fiber", value: formatOptional(ukData.fibrePer100g, suffix: "g"), field: "fiber", isDatabase: false)
                        nutritionRow("Sugar", value: formatOptional(ukData.sugarPer100g, suffix: "g"), field: "sugar", isDatabase: false)
                        nutritionRow("Sodium", value: formatSodiumFromSalt(ukData.saltPer100g), field: "sodium", isDatabase: false)
                        nutritionRow("Sat. Fat", value: formatOptional(ukData.saturatedFatPer100g, suffix: "g"), field: "saturatedFat", isDatabase: false)
                    }
                }

                GroupBox("Meta") {
                    VStack(spacing: 4) {
                        metaRow("Brand", value: ukData.brand ?? "—", field: "brand", isDatabase: false)
                        metaRow("Serving", value: "—", field: "servingDescription", isDatabase: false)
                    }
                }
            } else {
                Text("No online data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Difference Card

    private var differenceCard: some View {
        VStack(spacing: 0) {
            GroupBox("Nutrition") {
                VStack(spacing: 4) {
                    diffRow("Calories", field: "calories")
                    diffRow("Protein", field: "protein")
                    diffRow("Carbs", field: "carbs")
                    diffRow("Fat", field: "fat")
                    diffRow("Fiber", field: "fiber")
                    diffRow("Sugar", field: "sugar")
                    diffRow("Sodium", field: "sodium")
                    diffRow("Sat. Fat", field: "saturatedFat")
                }
            }

            GroupBox("Meta") {
                VStack(spacing: 4) {
                    Text(issue.food.brand != getOnlineValue(for: "brand") as? String ? "Different" : "Same")
                        .font(.caption)
                        .foregroundColor(issue.food.brand != getOnlineValue(for: "brand") as? String ? .orange : .green)
                }
            }
        }
    }

    // MARK: - Row Views

    private func nutritionRow(_ label: String, value: String, field: String, isDatabase: Bool) -> some View {
        HStack {
            if !isDatabase && hasOnlineValue(for: field) {
                Toggle("", isOn: Binding(
                    get: { selectedFields.contains(field) },
                    set: { if $0 { selectedFields.insert(field) } else { selectedFields.remove(field) } }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)
            } else if !isDatabase {
                Spacer().frame(width: 20)
            }

            Text(label)
                .frame(width: 70, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.callout)
                .monospacedDigit()
                .fontWeight(selectedFields.contains(field) && !isDatabase ? .bold : .regular)
                .foregroundColor(selectedFields.contains(field) && !isDatabase ? .blue : .primary)
        }
        .padding(.vertical, 2)
    }

    private func metaRow(_ label: String, value: String, field: String, isDatabase: Bool) -> some View {
        HStack {
            if !isDatabase && hasOnlineValue(for: field) {
                Toggle("", isOn: Binding(
                    get: { selectedFields.contains(field) },
                    set: { if $0 { selectedFields.insert(field) } else { selectedFields.remove(field) } }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)
            } else if !isDatabase {
                Spacer().frame(width: 20)
            }

            Text(label)
                .frame(width: 70, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.callout)
                .lineLimit(1)
                .fontWeight(selectedFields.contains(field) && !isDatabase ? .bold : .regular)
                .foregroundColor(selectedFields.contains(field) && !isDatabase ? .blue : .primary)
        }
        .padding(.vertical, 2)
    }

    private func diffRow(_ label: String, field: String) -> some View {
        let diff = calculateDifference(for: field)
        return HStack {
            Text(label)
                .frame(width: 70, alignment: .leading)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(diff ?? "—")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(diffColor(diff))
        }
        .padding(.vertical, 2)
    }

    // MARK: - Ingredients Comparison

    private var ingredientsComparison: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ingredients Comparison")
                    .font(.headline)

                Spacer()

                if hasOnlineValue(for: "ingredientsText") {
                    Toggle("Update ingredients", isOn: Binding(
                        get: { selectedFields.contains("ingredientsText") },
                        set: { if $0 { selectedFields.insert("ingredientsText") } else { selectedFields.remove("ingredientsText") } }
                    ))
                    .toggleStyle(.checkbox)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                // Database ingredients
                VStack(alignment: .leading, spacing: 4) {
                    Text("Database")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(issue.food.ingredientsText ?? issue.food.ingredients?.joined(separator: ", ") ?? "No ingredients listed")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(minWidth: 400)

                // Online ingredients
                VStack(alignment: .leading, spacing: 4) {
                    Text("Online")
                        .font(.caption)
                        .foregroundColor(.blue)
                    ScrollView {
                        Text(getOnlineIngredients() ?? "No ingredients available")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(minWidth: 400)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Spacer()

            Button("Ignore Issue") {
                // Mark as ignored
            }
            .buttonStyle(.bordered)

            Button("Mark for Review") {
                // Mark for manual review
            }
            .buttonStyle(.bordered)

            Button(action: applySelectedChanges) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text("Apply \(selectedFields.count) Selected Change\(selectedFields.count == 1 ? "" : "s")")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedFields.isEmpty || isSaving)

            Button(action: applyAllChanges) {
                Text("Apply All Changes")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isSaving)
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Functions

    private var severityColor: Color {
        switch issue.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }

    private func diffColor(_ diff: String?) -> Color {
        guard let diff = diff, let value = Double(diff.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: "")) else {
            return .secondary
        }
        if value > 20 { return .red }
        if value > 10 { return .orange }
        if value > 0 { return .yellow }
        return .green
    }

    private func formatOptional(_ value: Double?, suffix: String, decimals: Int = 1) -> String {
        guard let value = value else { return "—" }
        if decimals == 0 {
            return "\(Int(value))\(suffix)"
        }
        return String(format: "%.\(decimals)f\(suffix)", value)
    }

    private func formatSodiumFromSalt(_ salt: Double?) -> String {
        guard let salt = salt else { return "—" }
        let sodium = salt / 2.5 * 1000
        return String(format: "%.0fmg", sodium)
    }

    private func hasOnlineValue(for field: String) -> Bool {
        return getOnlineValue(for: field) != nil
    }

    private func getOnlineValue(for field: String) -> Any? {
        if let offProduct = issue.onlineData?.offProduct, let nutriments = offProduct.nutriments {
            switch field {
            case "calories": return nutriments.energy_kcal_100g ?? nutriments.energy_kcal
            case "protein": return nutriments.proteins_100g ?? nutriments.proteins
            case "carbs": return nutriments.carbohydrates_100g ?? nutriments.carbohydrates
            case "fat": return nutriments.fat_100g ?? nutriments.fat
            case "fiber": return nutriments.fiber_100g ?? nutriments.fiber
            case "sugar": return nutriments.sugars_100g ?? nutriments.sugars
            case "sodium": return (nutriments.salt_100g ?? nutriments.salt).map { $0 / 2.5 * 1000 }
            case "saturatedFat": return nutriments.saturated_fat_100g ?? nutriments.saturated_fat
            case "brand": return offProduct.brands
            case "servingDescription": return offProduct.serving_size
            case "ingredientsText": return offProduct.ingredients_text_en ?? offProduct.ingredients_text
            default: return nil
            }
        } else if let ukData = issue.onlineData?.ukProductData {
            switch field {
            case "calories": return ukData.caloriesPer100g
            case "protein": return ukData.proteinPer100g
            case "carbs": return ukData.carbsPer100g
            case "fat": return ukData.fatPer100g
            case "fiber": return ukData.fibrePer100g
            case "sugar": return ukData.sugarPer100g
            case "sodium": return ukData.saltPer100g.map { $0 / 2.5 * 1000 }
            case "saturatedFat": return ukData.saturatedFatPer100g
            case "brand": return ukData.brand
            case "ingredientsText": return ukData.ingredientsText
            default: return nil
            }
        }
        return nil
    }

    private func getDatabaseValue(for field: String) -> Double? {
        switch field {
        case "calories": return issue.food.calories
        case "protein": return issue.food.protein
        case "carbs": return issue.food.carbs
        case "fat": return issue.food.fat
        case "fiber": return issue.food.fiber
        case "sugar": return issue.food.sugar
        case "sodium": return issue.food.sodium
        case "saturatedFat": return issue.food.saturatedFat
        default: return nil
        }
    }

    private func calculateDifference(for field: String) -> String? {
        guard let dbValue = getDatabaseValue(for: field),
              let onlineValue = getOnlineValue(for: field) as? Double else {
            return nil
        }

        let diff = onlineValue - dbValue
        let percentDiff = dbValue > 0 ? (diff / dbValue) * 100 : 0

        if abs(diff) < 0.1 { return "0%" }
        return String(format: "%+.1f%%", percentDiff)
    }

    private func getOnlineIngredients() -> String? {
        if let offProduct = issue.onlineData?.offProduct {
            return offProduct.ingredients_text_en ?? offProduct.ingredients_text
        } else if let ukData = issue.onlineData?.ukProductData {
            return ukData.ingredientsText
        }
        return nil
    }

    private func preselectSignificantDifferences() {
        selectedFields.removeAll()
        for field in nutritionFields {
            if let diff = calculateDifference(for: field),
               let value = Double(diff.replacingOccurrences(of: "%", with: "").replacingOccurrences(of: "+", with: "")) {
                if abs(value) > 10 {
                    selectedFields.insert(field)
                }
            }
        }
    }

    private func selectAllFields() {
        selectedFields.removeAll()
        for field in nutritionFields + metaFields {
            if hasOnlineValue(for: field) {
                selectedFields.insert(field)
            }
        }
    }

    private func applySelectedChanges() {
        Task {
            await applyChanges(fields: selectedFields)
        }
    }

    private func applyAllChanges() {
        selectAllFields()
        Task {
            await applyChanges(fields: selectedFields)
        }
    }

    private func applyChanges(fields: Set<String>) async {
        isSaving = true

        var updatedFood = issue.food

        for field in fields {
            if let value = getOnlineValue(for: field) {
                switch field {
                case "calories": if let v = value as? Double { updatedFood.calories = v }
                case "protein": if let v = value as? Double { updatedFood.protein = v }
                case "carbs": if let v = value as? Double { updatedFood.carbs = v }
                case "fat": if let v = value as? Double { updatedFood.fat = v }
                case "fiber": if let v = value as? Double { updatedFood.fiber = v }
                case "sugar": if let v = value as? Double { updatedFood.sugar = v }
                case "sodium": if let v = value as? Double { updatedFood.sodium = v }
                case "saturatedFat": if let v = value as? Double { updatedFood.saturatedFat = v }
                case "brand": if let v = value as? String { updatedFood.brand = v }
                case "servingDescription": if let v = value as? String { updatedFood.servingDescription = v }
                case "ingredientsText": if let v = value as? String { updatedFood.ingredientsText = v }
                default: break
                }
            }
        }

        // Update last updated timestamp
        updatedFood.lastUpdated = ISO8601DateFormatter().string(from: Date())

        let success = await algoliaService.saveFood(updatedFood, database: appState.selectedDatabase)

        await MainActor.run {
            isSaving = false
            if success {
                showSaveSuccess = true
                // Clear selection after successful save
                selectedFields.removeAll()

                // Hide success message after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSaveSuccess = false
                }
            }
        }
    }
}

// MARK: - Product Import Sheet

struct ProductImportSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var importService = ProductImportService.shared
    @Environment(\.dismiss) var dismiss

    @State private var config = ProductImportService.ImportConfig()
    @State private var existingBarcodes: Set<String> = []
    @State private var isLoadingExisting = false
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            if importService.isImporting && importService.importProgress?.phase == .importing {
                importingView
            } else if hasSearched && !importService.previewProducts.isEmpty {
                previewView
            } else if let results = importService.lastImportResults {
                resultsView(results)
            } else {
                searchView
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .task {
            await loadExistingBarcodes()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Import Products")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Fetch new products from Open Food Facts to populate your database")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if importService.isImporting {
                Button("Cancel") {
                    importService.cancelImport()
                }
                .buttonStyle(.bordered)
            }

            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - Search View

    private var searchView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Search query
                GroupBox("Search") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Search products (e.g., 'Heinz', 'breakfast cereals')", text: $config.searchQuery)
                            .textFieldStyle(.roundedBorder)

                        // Popular searches
                        Text("Popular UK brands:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(ProductImportService.popularUKSearches.prefix(10), id: \.self) { search in
                                Button(search) {
                                    config.searchQuery = search
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Categories
                GroupBox("Categories (optional)") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                        ForEach(ProductImportService.ImportConfig.ProductCategory.allCases, id: \.self) { category in
                            Toggle(category.displayName, isOn: Binding(
                                get: { config.categories.contains(category) },
                                set: { if $0 { config.categories.append(category) } else { config.categories.removeAll { $0 == category } } }
                            ))
                            .toggleStyle(.checkbox)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Options
                GroupBox("Options") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximum products to fetch:")
                            Picker("", selection: $config.maxProducts) {
                                Text("20").tag(20)
                                Text("50").tag(50)
                                Text("100").tag(100)
                                Text("200").tag(200)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 300)
                        }

                        Toggle("Require barcode", isOn: $config.requireBarcode)
                        Toggle("Require nutrition data", isOn: $config.requireNutrition)
                        Toggle("Require product image", isOn: $config.requireImage)
                        Toggle("Skip products already in database", isOn: $config.skipExisting)
                    }
                    .padding(.vertical, 8)
                }

                // Existing database info
                if isLoadingExisting {
                    ProgressView("Loading existing barcodes...")
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("\(existingBarcodes.count.formatted()) products already in database")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Search button
                HStack {
                    Spacer()
                    Button {
                        Task { await searchProducts() }
                    } label: {
                        Label("Search Products", systemImage: "magnifyingglass")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(config.searchQuery.isEmpty && config.categories.isEmpty)
                }
            }
            .padding()
        }
    }

    // MARK: - Preview View

    private var previewView: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("\(importService.previewProducts.count) products found")
                    .font(.headline)

                Spacer()

                let selectedCount = importService.previewProducts.filter { $0.isSelected }.count
                Text("\(selectedCount) selected")
                    .foregroundColor(.secondary)

                Button("Select All") {
                    for i in importService.previewProducts.indices {
                        importService.previewProducts[i].isSelected = true
                    }
                }
                .buttonStyle(.bordered)

                Button("Deselect All") {
                    for i in importService.previewProducts.indices {
                        importService.previewProducts[i].isSelected = false
                    }
                }
                .buttonStyle(.bordered)

                Button("Back to Search") {
                    hasSearched = false
                    importService.previewProducts = []
                }
                .buttonStyle(.bordered)

                Button {
                    Task { await importSelected() }
                } label: {
                    Label("Import Selected", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCount == 0)
            }
            .padding()

            Divider()

            // Products list
            List {
                ForEach(importService.previewProducts.indices, id: \.self) { index in
                    ProductPreviewRow(
                        product: $importService.previewProducts[index]
                    )
                }
            }
        }
    }

    // MARK: - Importing View

    private var importingView: some View {
        VStack(spacing: 20) {
            if let progress = importService.importProgress {
                ProgressView(value: progress.percentComplete, total: 100)
                    .frame(width: 400)

                Text(progress.phase.rawValue)
                    .font(.headline)

                HStack(spacing: 40) {
                    VStack {
                        Text("\(progress.importedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Imported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(progress.processedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Processed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(progress.errorCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Errors")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !progress.currentProduct.isEmpty {
                    Text("Importing: \(progress.currentProduct)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View

    private func resultsView(_ results: ProductImportService.ImportResults) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: results.errorCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(results.errorCount == 0 ? .green : .orange)

            Text("Import Complete")
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 40) {
                VStack {
                    Text("\(results.importedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Imported")
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(results.skippedCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text("Skipped")
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(results.errorCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Errors")
                        .foregroundColor(.secondary)
                }
            }

            Text(String(format: "Completed in %.1f seconds", results.duration))
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("Import More") {
                    importService.lastImportResults = nil
                    hasSearched = false
                }
                .buttonStyle(.bordered)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }

    // MARK: - Actions

    private func loadExistingBarcodes() async {
        isLoadingExisting = true
        await algoliaService.browseAllFoods(database: appState.selectedDatabase)
        existingBarcodes = Set(algoliaService.foods.compactMap { $0.barcode })
        isLoadingExisting = false
    }

    private func searchProducts() async {
        _ = await importService.searchProductsToImport(config: config, existingBarcodes: existingBarcodes)
        hasSearched = true
    }

    private func importSelected() async {
        _ = await importService.importProducts(
            importService.previewProducts,
            using: algoliaService,
            database: appState.selectedDatabase
        )
    }
}

struct ProductPreviewRow: View {
    @Binding var product: ProductImportService.ImportableProduct

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $product.isSelected)
                .toggleStyle(.checkbox)

            // Image
            if let imageURL = product.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(6)
                    default:
                        Image(systemName: "photo")
                            .frame(width: 50, height: 50)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "photo")
                    .frame(width: 50, height: 50)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack {
                    if let brand = product.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(product.barcode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Nutrition preview
            HStack(spacing: 16) {
                NutritionMiniLabel(value: product.calories, unit: "kcal")
                NutritionMiniLabel(value: product.protein, unit: "P")
                NutritionMiniLabel(value: product.carbs, unit: "C")
                NutritionMiniLabel(value: product.fat, unit: "F")
            }

            // Source badge
            Text(product.source)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
}

struct NutritionMiniLabel: View {
    let value: Double
    let unit: String

    var body: some View {
        VStack(spacing: 0) {
            Text(String(format: "%.0f", value))
                .font(.caption)
                .fontWeight(.medium)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 40)
    }
}

// MARK: - Stock Image Sheet

struct StockImageSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var imageService = StockImageService.shared
    @Environment(\.dismiss) var dismiss

    @State private var searchQuery = ""
    @State private var selectedImage: ProductImage?
    @State private var targetFood: FoodItem?
    @State private var isDownloading = false
    @State private var whiteBackground = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            if !imageService.hasApiKey {
                apiKeySetupView
            } else {
                HSplitView {
                    // Left: Search and results
                    searchAndResultsView
                        .frame(minWidth: 500)

                    // Right: Preview and assignment
                    if let image = selectedImage {
                        imagePreviewView(image)
                            .frame(minWidth: 350)
                    } else {
                        placeholderView
                            .frame(minWidth: 350)
                    }
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Product Images")
                    .font(.title2)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Text("Find professional product images via Google Images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let remaining = imageService.remainingSearches {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(remaining) searches remaining")
                            .font(.caption)
                            .foregroundColor(remaining < 50 ? .orange : .secondary)
                    }
                }
            }

            Spacer()

            Button("Close") {
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - API Key Setup

    private var apiKeySetupView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text("SerpAPI Key Required")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("To search for product images, you need a SerpAPI key for Google Images search")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("SerpAPI - Google Images")
                                .fontWeight(.semibold)
                            Spacer()
                            Link("Get API Key", destination: URL(string: "https://serpapi.com/")!)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pricing:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("• Free: 250 searches/month")
                            Text("• $25/mo: 1,000 searches")
                            Text("• $75/mo: 5,000 searches")
                            Text("• $150/mo: 15,000 searches")
                            Text("• $275/mo: 30,000 searches")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        HStack {
                            SecureField("SerpAPI Key", text: Binding(
                                get: { UserDefaults.standard.string(forKey: "serpapi_key") ?? "" },
                                set: { imageService.setApiKey($0) }
                            ))
                            .textFieldStyle(.roundedBorder)

                            if imageService.hasApiKey {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }

                        if imageService.hasApiKey {
                            Button("Check Account Status") {
                                Task {
                                    if let status = await imageService.checkAccountStatus() {
                                        if let remaining = status.plan_searches_left {
                                            imageService.remainingSearches = remaining
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .frame(maxWidth: 500)

            Spacer()
        }
        .padding()
    }

    // MARK: - Search and Results

    private var searchAndResultsView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search for product images (e.g., 'Heinz Ketchup')...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await search() }
                    }

                Toggle("White BG", isOn: $whiteBackground)
                    .toggleStyle(.checkbox)

                if imageService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Button("Search") {
                    Task { await search() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(searchQuery.isEmpty)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Error display
            if let error = imageService.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") {
                        imageService.lastError = nil
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }

            // Suggestions
            if imageService.searchResults.isEmpty && !imageService.isLoading {
                VStack(spacing: 16) {
                    Text("Search for actual branded products:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(["Heinz Ketchup", "Cadbury Dairy Milk", "Walkers Crisps", "Warburtons Bread", "Cathedral City Cheese", "Birds Eye Fish Fingers", "McVitie's Digestives", "Lurpak Butter"], id: \.self) { suggestion in
                            Button(suggestion) {
                                searchQuery = suggestion
                                Task { await search() }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    Text("Unlike stock photo sites, this can find actual branded product images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Results grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(imageService.searchResults) { image in
                            ProductImageThumbnail(
                                image: image,
                                isSelected: selectedImage?.id == image.id,
                                onSelect: { selectedImage = image }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Image Preview

    private func imagePreviewView(_ image: ProductImage) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Large preview
                AsyncImage(url: URL(string: image.originalURL)) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxHeight: 300)

                // Image info
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(image.title)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        HStack {
                            Image(systemName: "globe")
                            Text(image.source)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let dims = image.dimensions {
                            Text(dims)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let sourceURL = image.sourceURL {
                            Link(destination: URL(string: sourceURL)!) {
                                HStack {
                                    Text("View source")
                                        .font(.caption)
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }

                // Assignment
                GroupBox("Assign to Food") {
                    VStack(alignment: .leading, spacing: 12) {
                        if let food = targetFood {
                            HStack {
                                Text(food.name)
                                    .fontWeight(.medium)
                                Spacer()
                                Button("Change") {
                                    targetFood = nil
                                }
                                .buttonStyle(.borderless)
                            }
                        } else {
                            Picker("Select food:", selection: $targetFood) {
                                Text("Select a food...").tag(nil as FoodItem?)
                                ForEach(algoliaService.foods.prefix(50)) { food in
                                    Text(food.name).tag(food as FoodItem?)
                                }
                            }
                        }

                        if targetFood != nil {
                            Button {
                                Task { await assignImage(image) }
                            } label: {
                                HStack {
                                    if isDownloading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    }
                                    Text("Assign Image")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isDownloading)
                        }
                    }
                }

                // Copy URL
                GroupBox("Copy Image URL") {
                    VStack(spacing: 8) {
                        Text(image.originalURL)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)

                        HStack {
                            Button("Copy Original URL") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(image.originalURL, forType: .string)
                            }
                            .buttonStyle(.bordered)

                            Button("Copy Thumbnail URL") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(image.thumbnailURL, forType: .string)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var placeholderView: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select an image to preview")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func search() async {
        _ = await imageService.searchProductImages(query: searchQuery, whiteBackground: whiteBackground)
    }

    private func assignImage(_ image: ProductImage) async {
        guard var food = targetFood else { return }

        isDownloading = true

        // Assign the URLs directly
        // Note: In production you might want to download and re-host the image
        food.imageURL = image.originalURL
        food.thumbnailURL = image.thumbnailURL

        let success = await algoliaService.saveFood(food, database: appState.selectedDatabase)

        if success {
            // Update local state
            if let index = algoliaService.foods.firstIndex(where: { $0.objectID == food.objectID }) {
                algoliaService.foods[index] = food
            }
            targetFood = nil
            selectedImage = nil
        }

        isDownloading = false
    }
}

struct ProductImageThumbnail: View {
    let image: ProductImage
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            AsyncImage(url: URL(string: image.thumbnailURL)) { phase in
                switch phase {
                case .success(let img):
                    img
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipped()
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo")
                        .frame(width: 140, height: 140)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                case .empty:
                    ProgressView()
                        .frame(width: 140, height: 140)
                @unknown default:
                    EmptyView()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )

            Text(image.title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 140)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// Note: FlowLayout is already defined in FoodDetailView.swift

// MARK: - Database Completeness View (Full Page)

struct DatabaseCompletenessView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @StateObject private var completenessService = DatabaseCompletenessService.shared

    @State private var isLoadingDatabase = false
    @State private var databaseLoaded = false
    @State private var selectedCategory: DatabaseCompletenessService.CompletenessResults.CategoryResult?
    @State private var selectedMissingItems: Set<UUID> = []
    @State private var selectedItem: DatabaseCompletenessService.CompletenessResults.MissingItem?
    @State private var showingReviewTab = false  // Toggle between Missing and Review tabs
    @State private var reviewItems: [DatabaseCompletenessService.CompletenessResults.MissingItem] = []  // Items with nutrition data ready for review
    @State private var isSavingItem = false
    @State private var saveError: String?

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            if completenessService.isScanning {
                scanningView
            } else if isLoadingDatabase {
                loadingDatabaseView
            } else if databaseLoaded && completenessService.scanResults == nil {
                // Database loaded but not scanned yet
                readyToScanView
            } else if let results = completenessService.scanResults {
                resultsView(results)
            } else {
                startView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Database Completeness")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Check your database has all essential UK foods & restaurants")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Show cache status
            if completenessService.hasCachedResults, let lastScan = completenessService.lastScanDate {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.green)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last scan: \(lastScan, style: .relative) ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(completenessService.cachedFoodsCount) foods cached")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            if completenessService.isScanning {
                Button("Cancel") {
                    completenessService.cancelScan()
                }
                .buttonStyle(.bordered)
            }

            // Re-scan button when viewing results
            if completenessService.scanResults != nil && !completenessService.isScanning {
                Menu {
                    Button {
                        Task {
                            await loadDatabase()
                            await completenessService.scanWithCachedDatabase()
                        }
                    } label: {
                        Label("Fresh Scan (Reload Database)", systemImage: "arrow.clockwise")
                    }

                    if completenessService.hasCachedResults {
                        Button {
                            Task { await completenessService.scanWithCachedDatabase() }
                        } label: {
                            Label("Re-scan with Cached Data", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    Divider()

                    Button {
                        completenessService.clearCache()
                        databaseLoaded = false
                    } label: {
                        Label("Clear Cache & Start Over", systemImage: "trash")
                    }
                } label: {
                    Label("Scan Options", systemImage: "ellipsis.circle")
                }
                .menuStyle(.borderedButton)
            }
        }
        .padding()
    }

    // MARK: - Start View

    private var startView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checklist.checked")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Check Database Completeness")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Scan your database to find missing essential UK foods & fast food")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Checks \(DatabaseCompletenessService.essentialCategories.count) essential food categories", systemImage: "folder.fill")
                Label("Includes fast food: McDonald's, KFC, Nando's, Greggs & more", systemImage: "takeoutbag.and.cup.and.straw")
                Label("Includes takeaways: Chinese, Indian, Kebab shops", systemImage: "bag")
                Label("Coffee shops: Costa, Starbucks, Pret", systemImage: "cup.and.saucer")
                Label("UK supermarket brands and products", systemImage: "cart")
            }
            .font(.callout)
            .foregroundColor(.secondary)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            HStack(spacing: 16) {
                Button {
                    Task { await loadDatabase() }
                } label: {
                    Label("Load Database", systemImage: "arrow.down.circle")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if completenessService.hasCachedResults {
                    Button {
                        // Show previous results
                        databaseLoaded = true
                    } label: {
                        Label("View Previous Results", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Ready to Scan View

    private var readyToScanView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("Database Loaded")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("\(completenessService.cachedFoodsCount) foods ready to scan")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                Button {
                    Task { await completenessService.scanWithCachedDatabase() }
                } label: {
                    Label("Scan for Missing Items", systemImage: "magnifyingglass")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    Task { await loadDatabase() }
                } label: {
                    Label("Reload Database", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Loading Database View

    private var loadingDatabaseView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading database...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Scanning View

    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView(value: completenessService.scanProgress) {
                Text("Scanning...")
                    .font(.headline)
            }
            .progressViewStyle(.linear)
            .frame(width: 300)

            Text(completenessService.currentCategory)
                .font(.callout)
                .foregroundColor(.secondary)

            Text("\(Int(completenessService.scanProgress * 100))%")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results View

    // Computed property for items with nutrition data (ready for review)
    private var itemsWithNutritionData: [DatabaseCompletenessService.CompletenessResults.MissingItem] {
        completenessService.scanResults?.missingItems.filter { $0.suggestedData != nil } ?? []
    }

    @ViewBuilder
    private func resultsView(_ results: DatabaseCompletenessService.CompletenessResults) -> some View {
        HSplitView {
            // Left: Category list + Tab switcher
            VStack(spacing: 0) {
                // Summary header
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        completenessGauge(percentage: results.completenessPercentage)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(results.foundItems) / \(results.totalExpectedItems)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Essential items found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(results.missingItems.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("Missing items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Tab switcher for Missing vs Review
                    HStack(spacing: 0) {
                        Button {
                            showingReviewTab = false
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Missing")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(showingReviewTab ? Color.clear : Color.accentColor)
                            .foregroundColor(showingReviewTab ? .primary : .white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingReviewTab = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("Review (\(itemsWithNutritionData.count))")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(showingReviewTab ? Color.accentColor : Color.clear)
                            .foregroundColor(showingReviewTab ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color(nsColor: .separatorColor).opacity(0.3))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                if showingReviewTab {
                    // Review tab - no category filter needed
                    Text("Items ready to add")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlBackgroundColor))
                } else {
                    // Category list for Missing tab
                    List(results.categoryBreakdown, selection: $selectedCategory) { category in
                        categoryRow(category)
                            .tag(category)
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(width: 280)

            // Middle: Items view
            if showingReviewTab {
                reviewItemsTableView
            } else if let category = selectedCategory {
                missingItemsView(for: category, results: results)
            } else {
                allMissingItemsView(results: results)
            }

            // Right: Item detail panel
            itemDetailPanel
        }
    }

    // MARK: - Review Items Table View

    @ViewBuilder
    private var reviewItemsTableView: some View {
        VStack(spacing: 0) {
            // Header with count and actions
            reviewTableHeader

            Divider()

            if itemsWithNutritionData.isEmpty {
                reviewTableEmptyState
            } else {
                reviewTableContent
            }
        }
        .frame(minWidth: 900)
    }

    private var reviewTableHeader: some View {
        HStack {
            Text("Ready to Add (\(itemsWithNutritionData.count) items)")
                .font(.headline)

            Spacer()

            if isSavingItem {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.horizontal, 8)
            }

            if let error = saveError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(1)
            }

            if !itemsWithNutritionData.isEmpty {
                Button {
                    Task { await addAllReviewItemsToDatabase() }
                } label: {
                    Label("Add All to Database", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSavingItem)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var reviewTableEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No items with nutrition data yet")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("Fetch nutrition data for missing items to see them here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var reviewTableContent: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: reviewTableHeaderRow) {
                    ForEach(itemsWithNutritionData) { item in
                        ReviewTableRow(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            isSaving: isSavingItem,
                            isFastFood: isFastFoodCategory(item.category),
                            onSelect: { selectedItem = item },
                            onAdd: { asPerUnit in
                                Task { await addItemToDatabase(item: item, asPerUnit: asPerUnit) }
                            }
                        )
                        Divider()
                    }
                }
            }
        }
    }

    private var reviewTableHeaderRow: some View {
        HStack(spacing: 0) {
            Text("Food Name").frame(width: 180, alignment: .leading)
            Text("Brand").frame(width: 100, alignment: .leading)
            Text("Serving").frame(width: 80, alignment: .leading)
            Text("Cal").frame(width: 50, alignment: .trailing)
            Text("Prot").frame(width: 50, alignment: .trailing)
            Text("Carbs").frame(width: 50, alignment: .trailing)
            Text("Fat").frame(width: 50, alignment: .trailing)
            Text("Sat").frame(width: 45, alignment: .trailing)
            Text("Fibre").frame(width: 45, alignment: .trailing)
            Text("Sugar").frame(width: 50, alignment: .trailing)
            Text("Na").frame(width: 45, alignment: .trailing)
            Text("Type").frame(width: 55, alignment: .center)
            Text("Actions").frame(width: 90, alignment: .center)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func isFastFoodCategory(_ category: String) -> Bool {
        let lower = category.lowercased()
        return lower.contains("mcdonald") ||
            lower.contains("kfc") ||
            lower.contains("burger") ||
            lower.contains("nando") ||
            lower.contains("greggs") ||
            lower.contains("subway") ||
            lower.contains("pizza") ||
            lower.contains("chinese") ||
            lower.contains("indian") ||
            lower.contains("kebab") ||
            lower.contains("takeaway") ||
            lower.contains("costa") ||
            lower.contains("starbucks") ||
            lower.contains("pret")
    }

    // MARK: - Add to Database Functions

    private func addItemToDatabase(item: DatabaseCompletenessService.CompletenessResults.MissingItem, asPerUnit: Bool) async {
        guard let data = item.suggestedData else { return }

        isSavingItem = true
        saveError = nil

        print("📦 Adding '\(data.name)' to database:")
        print("   - isPerUnit: \(asPerUnit)")
        print("   - calories: \(data.calories)")
        print("   - servingSizeG: \(data.servingSizeG ?? 0)")
        print("   - servingDescription: \(data.servingDescription ?? "none")")

        // Create FoodItem from suggested data
        let food = FoodItem(
            objectID: UUID().uuidString,
            name: data.name,
            brand: data.brand,
            barcode: data.barcode,
            calories: data.calories,
            protein: data.protein,
            carbs: data.carbs,
            fat: data.fat,
            fiber: data.fiber ?? 0,
            sugar: data.sugar ?? 0,
            sodium: data.sodium ?? 0,
            saturatedFat: data.saturatedFat,
            servingDescription: data.servingDescription,
            servingSizeG: data.servingSizeG,
            isPerUnit: asPerUnit,
            ingredientsText: data.ingredientsText,
            isVerified: false,
            source: "completeness_scan_\(data.source)",
            imageURL: data.imageURL
        )

        print("   - FoodItem.isPerUnit = \(food.isPerUnit ?? false)")

        let success = await algoliaService.saveFood(food, database: .foods)

        if success {
            print("✅ Added '\(data.name)' to database (isPerUnit=\(asPerUnit))")
            // Remove from missing items in the service
            if let currentResults = completenessService.scanResults {
                let updatedMissing = currentResults.missingItems.filter { $0.id != item.id }
                completenessService.scanResults = DatabaseCompletenessService.CompletenessResults(
                    totalCategories: currentResults.totalCategories,
                    totalExpectedItems: currentResults.totalExpectedItems,
                    foundItems: currentResults.foundItems + 1,
                    missingItems: updatedMissing,
                    categoryBreakdown: currentResults.categoryBreakdown,
                    completenessPercentage: currentResults.completenessPercentage,
                    scanDate: currentResults.scanDate
                )
            }
        } else {
            saveError = algoliaService.error ?? "Failed to save"
            print("❌ Failed to add '\(data.name)' to database: \(saveError ?? "unknown")")
        }

        isSavingItem = false
    }

    private func addAllReviewItemsToDatabase() async {
        let items = itemsWithNutritionData

        for item in items {
            guard let data = item.suggestedData else { continue }
            await addItemToDatabase(item: item, asPerUnit: data.isPerUnit)
            // Small delay to avoid overwhelming the API
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
    }

    // MARK: - Item Detail Panel

    @ViewBuilder
    private var itemDetailPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Item Details")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if let item = selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Item name and category
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }

                        Divider()

                        if let data = item.suggestedData {
                            // Source info
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.blue)
                                Text("Source: \(data.source)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }

                            if let brand = data.brand, !brand.isEmpty {
                                HStack {
                                    Text("Brand:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(brand)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                            }

                            if let barcode = data.barcode, !barcode.isEmpty {
                                HStack {
                                    Text("Barcode:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(barcode)
                                        .font(.system(.callout, design: .monospaced))
                                }
                            }

                            // Serving info
                            if let serving = data.servingDescription, !serving.isEmpty {
                                HStack {
                                    Text("Serving:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(serving)
                                        .font(.callout)
                                }
                            }

                            if let servingG = data.servingSizeG {
                                HStack {
                                    Text("Serving size:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(servingG))g")
                                        .font(.callout)
                                        .fontWeight(.medium)
                                }
                            }

                            if data.isPerUnit {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Per-unit item (e.g., burger, sandwich)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }

                            Divider()

                            // Nutrition header
                            if data.isPerUnit, let perUnitCal = data.perUnitCalories {
                                Text("Nutrition per item")
                                    .font(.headline)
                                    .padding(.top, 8)

                                VStack(spacing: 12) {
                                    nutritionRow(label: "Calories", value: "\(Int(perUnitCal))", unit: "kcal", color: .orange)
                                    if let p = data.perUnitProtein {
                                        nutritionRow(label: "Protein", value: String(format: "%.1f", p), unit: "g", color: .red)
                                    }
                                    if let c = data.perUnitCarbs {
                                        nutritionRow(label: "Carbs", value: String(format: "%.1f", c), unit: "g", color: .blue)
                                    }
                                    if let f = data.perUnitFat {
                                        nutritionRow(label: "Fat", value: String(format: "%.1f", f), unit: "g", color: .yellow)
                                    }
                                }

                                Divider()
                            }

                            Text("Nutrition per 100g")
                                .font(.headline)
                                .padding(.top, 8)

                            VStack(spacing: 12) {
                                nutritionRow(label: "Calories", value: "\(Int(data.calories))", unit: "kcal", color: .orange)
                                nutritionRow(label: "Protein", value: String(format: "%.1f", data.protein), unit: "g", color: .red)
                                nutritionRow(label: "Carbohydrates", value: String(format: "%.1f", data.carbs), unit: "g", color: .blue)
                                nutritionRow(label: "Fat", value: String(format: "%.1f", data.fat), unit: "g", color: .yellow)

                                if let fiber = data.fiber {
                                    nutritionRow(label: "Fiber", value: String(format: "%.1f", fiber), unit: "g", color: .green)
                                }

                                if let sugar = data.sugar {
                                    nutritionRow(label: "Sugar", value: String(format: "%.1f", sugar), unit: "g", color: .pink)
                                }

                                if let saturatedFat = data.saturatedFat {
                                    nutritionRow(label: "Saturated Fat", value: String(format: "%.1f", saturatedFat), unit: "g", color: .orange)
                                }

                                if let sodium = data.sodium {
                                    nutritionRow(label: "Salt", value: String(format: "%.2f", sodium / 400), unit: "g", color: .purple)
                                }
                            }

                            Divider()

                            // Action buttons
                            VStack(spacing: 8) {
                                Button {
                                    Task {
                                        await addItemToDatabase(item: item, asPerUnit: data.isPerUnit)
                                    }
                                } label: {
                                    if isSavingItem {
                                        HStack(spacing: 6) {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                            Text("Saving...")
                                        }
                                        .frame(maxWidth: .infinity)
                                    } else {
                                        Label("Add to Database", systemImage: "plus.circle.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(isSavingItem)

                                // For fast food without serving size, offer "Save as Unit" option
                                if isFastFoodCategory(item.category) && data.servingSizeG == nil && !data.isPerUnit {
                                    Button {
                                        Task {
                                            await addItemToDatabase(item: item, asPerUnit: true)
                                        }
                                    } label: {
                                        Label("Save as Per Unit (Meal)", systemImage: "square.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(isSavingItem)
                                }

                                if let error = saveError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.top, 8)

                        } else {
                            // No data fetched yet
                            VStack(spacing: 16) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)

                                Text("No nutrition data fetched yet")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                Button {
                                    Task {
                                        await fetchDataForItem(item)
                                    }
                                } label: {
                                    Label("Fetch Nutrition Data", systemImage: "arrow.down.circle")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                    .padding()
                }
            } else {
                // No item selected
                VStack(spacing: 16) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Select an item to view details")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 280, idealWidth: 320)
    }

    private func nutritionRow(label: String, value: String, unit: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func completenessGauge(percentage: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: CGFloat(percentage / 100))
                .stroke(
                    percentage >= 80 ? Color.green : (percentage >= 50 ? Color.orange : Color.red),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(percentage))%")
                .font(.system(size: 14, weight: .bold))
        }
        .frame(width: 60, height: 60)
    }

    private func categoryRow(_ category: DatabaseCompletenessService.CompletenessResults.CategoryResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.callout)
                    .fontWeight(.medium)

                Text("\(category.foundCount)/\(category.expectedCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Completeness indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: CGFloat(category.completeness / 100))
                    .stroke(
                        category.completeness >= 80 ? Color.green : (category.completeness >= 50 ? Color.orange : Color.red),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 30, height: 30)

            if !category.missingItems.isEmpty {
                Text("\(category.missingItems.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func allMissingItemsView(results: DatabaseCompletenessService.CompletenessResults) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Missing Items (\(results.missingItems.count))")
                    .font(.headline)

                Spacer()

                if completenessService.isFetching {
                    // Show progress and stop button
                    HStack(spacing: 12) {
                        Text("\(completenessService.fetchedCount)/\(completenessService.totalToFetch)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ProgressView(value: completenessService.fetchProgress)
                            .frame(width: 100)

                        Button {
                            completenessService.cancelFetch()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                } else {
                    if !selectedMissingItems.isEmpty {
                        Button {
                            Task { await fetchDataForSelected(results: results) }
                        } label: {
                            Label("Fetch Data (\(selectedMissingItems.count))", systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        Task { await fetchDataForAllMissing(results: results) }
                    } label: {
                        Label("Fetch All Data", systemImage: "arrow.down.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if completenessService.isFetching {
                VStack(spacing: 12) {
                    ProgressView(value: completenessService.fetchProgress) {
                        Text("Fetching nutrition data...")
                    }
                    .progressViewStyle(.linear)
                    .frame(width: 300)

                    Text(completenessService.currentCategory)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(completenessService.fetchedCount) of \(completenessService.totalToFetch) items")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    Button {
                        completenessService.cancelFetch()
                    } label: {
                        Label("Stop Fetching", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Missing items list
                List {
                    ForEach(results.missingItems) { item in
                        missingItemRow(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func missingItemsView(for category: DatabaseCompletenessService.CompletenessResults.CategoryResult, results: DatabaseCompletenessService.CompletenessResults) -> some View {
        let categoryItems = results.missingItems.filter { $0.category == category.name }

        VStack(spacing: 0) {
            HStack {
                Text("Missing from \(category.name) (\(categoryItems.count))")
                    .font(.headline)

                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            List {
                ForEach(categoryItems) { item in
                    missingItemRow(item)
                }
            }
        }
    }

    private func missingItemRow(_ item: DatabaseCompletenessService.CompletenessResults.MissingItem) -> some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { selectedMissingItems.contains(item.id) },
                set: { isSelected in
                    if isSelected {
                        selectedMissingItems.insert(item.id)
                    } else {
                        selectedMissingItems.remove(item.id)
                    }
                }
            ))
            .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                    .fontWeight(.medium)

                if let data = item.suggestedData {
                    HStack(spacing: 8) {
                        Text("\(Int(data.calories)) kcal")
                        Text("P: \(String(format: "%.1f", data.protein))g")
                        Text("C: \(String(format: "%.1f", data.carbs))g")
                        Text("F: \(String(format: "%.1f", data.fat))g")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text("Source: \(data.source)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            if item.suggestedData != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle.dashed")
                    .foregroundColor(.gray)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(selectedItem?.id == item.id ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedItem = item
        }
    }

    // MARK: - Actions

    private func loadDatabase() async {
        isLoadingDatabase = true
        await algoliaService.browseAllFoods(database: appState.selectedDatabase)
        let foods = algoliaService.foods
        isLoadingDatabase = false

        if let error = algoliaService.error {
            completenessService.error = "Failed to load database: \(error)"
            return
        }

        // Cache the database for scanning
        completenessService.cacheDatabase(foods: foods)
        databaseLoaded = true
    }

    private func fetchDataForSelected(results: DatabaseCompletenessService.CompletenessResults) async {
        let selectedItems = results.missingItems.filter { selectedMissingItems.contains($0.id) }
        let updated = await completenessService.fetchSuggestedDataForMissingItems(selectedItems)

        // Update the results with fetched data
        if let currentResults = completenessService.scanResults {
            var updatedMissing = currentResults.missingItems
            for updatedItem in updated {
                if let index = updatedMissing.firstIndex(where: { $0.id == updatedItem.id }) {
                    updatedMissing[index] = updatedItem
                }
            }
            completenessService.scanResults = DatabaseCompletenessService.CompletenessResults(
                totalCategories: currentResults.totalCategories,
                totalExpectedItems: currentResults.totalExpectedItems,
                foundItems: currentResults.foundItems,
                missingItems: updatedMissing,
                categoryBreakdown: currentResults.categoryBreakdown,
                completenessPercentage: currentResults.completenessPercentage,
                scanDate: currentResults.scanDate
            )
        }
    }

    private func fetchDataForAllMissing(results: DatabaseCompletenessService.CompletenessResults) async {
        let updated = await completenessService.fetchSuggestedDataForMissingItems(results.missingItems)

        completenessService.scanResults = DatabaseCompletenessService.CompletenessResults(
            totalCategories: results.totalCategories,
            totalExpectedItems: results.totalExpectedItems,
            foundItems: results.foundItems,
            missingItems: updated,
            categoryBreakdown: results.categoryBreakdown,
            completenessPercentage: results.completenessPercentage,
            scanDate: results.scanDate
        )
    }

    private func fetchDataForItem(_ item: DatabaseCompletenessService.CompletenessResults.MissingItem) async {
        let updated = await completenessService.fetchSuggestedDataForMissingItems([item])

        // Update the selected item with fetched data
        if let updatedItem = updated.first {
            selectedItem = updatedItem

            // Also update in the scan results
            if let currentResults = completenessService.scanResults {
                var updatedMissing = currentResults.missingItems
                if let index = updatedMissing.firstIndex(where: { $0.id == item.id }) {
                    updatedMissing[index] = updatedItem
                }
                completenessService.scanResults = DatabaseCompletenessService.CompletenessResults(
                    totalCategories: currentResults.totalCategories,
                    totalExpectedItems: currentResults.totalExpectedItems,
                    foundItems: currentResults.foundItems,
                    missingItems: updatedMissing,
                    categoryBreakdown: currentResults.categoryBreakdown,
                    completenessPercentage: currentResults.completenessPercentage,
                    scanDate: currentResults.scanDate
                )
            }
        }
    }
}

// MARK: - Review Table Row (Separate struct for compiler performance)

struct ReviewTableRow: View {
    let item: DatabaseCompletenessService.CompletenessResults.MissingItem
    let isSelected: Bool
    let isSaving: Bool
    let isFastFood: Bool
    let onSelect: () -> Void
    let onAdd: (Bool) -> Void

    private var data: DatabaseCompletenessService.SuggestedFoodData? {
        item.suggestedData
    }

    var body: some View {
        HStack(spacing: 0) {
            // Food Name
            VStack(alignment: .leading, spacing: 2) {
                Text(data?.name ?? item.name)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(item.category)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 180, alignment: .leading)

            // Brand
            Text(data?.brand ?? "-")
                .foregroundColor(data?.brand != nil ? .primary : .secondary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            // Serving
            servingCell
                .frame(width: 80, alignment: .leading)

            // Nutrition values
            nutritionCell(value: data?.calories, format: "%.0f").frame(width: 50, alignment: .trailing)
            nutritionCell(value: data?.protein, format: "%.1f").frame(width: 50, alignment: .trailing)
            nutritionCell(value: data?.carbs, format: "%.1f").frame(width: 50, alignment: .trailing)
            nutritionCell(value: data?.fat, format: "%.1f").frame(width: 50, alignment: .trailing)
            nutritionCell(value: data?.saturatedFat, format: "%.1f").frame(width: 45, alignment: .trailing)
            nutritionCell(value: data?.fiber, format: "%.1f").frame(width: 45, alignment: .trailing)
            nutritionCell(value: data?.sugar, format: "%.1f").frame(width: 50, alignment: .trailing)
            nutritionCell(value: data?.sodium, format: "%.0f").frame(width: 45, alignment: .trailing)

            // Per Unit indicator
            perUnitCell
                .frame(width: 55, alignment: .center)

            // Actions
            actionsCell
                .frame(width: 90, alignment: .center)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    @ViewBuilder
    private var servingCell: some View {
        if let data = data {
            VStack(alignment: .leading, spacing: 1) {
                if let serving = data.servingDescription {
                    Text(serving)
                        .font(.caption)
                        .lineLimit(1)
                }
                if let g = data.servingSizeG {
                    Text("\(Int(g))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if data.servingDescription == nil && data.servingSizeG == nil {
                    Text("-")
                        .foregroundColor(.secondary)
                }
            }
        } else {
            Text("-")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func nutritionCell(value: Double?, format: String) -> some View {
        if let v = value {
            Text(String(format: format, v))
                .monospacedDigit()
        } else {
            Text("-")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var perUnitCell: some View {
        if data?.isPerUnit == true {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        } else {
            Text("100g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var actionsCell: some View {
        HStack(spacing: 6) {
            // Add to database button
            Button {
                onAdd(data?.isPerUnit ?? false)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.green)
            }
            .buttonStyle(.borderless)
            .disabled(isSaving)
            .help("Add to Database")

            // Save as per unit option for fast food without serving size
            if isFastFood && data?.servingSizeG == nil && data?.isPerUnit != true {
                Button {
                    onAdd(true)
                } label: {
                    Image(systemName: "square.fill")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                .disabled(isSaving)
                .help("Save as Per Unit (meal)")
            }
        }
    }
}
