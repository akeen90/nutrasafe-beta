//
//  ContentView.swift
//  NutraSafe Database Manager
//
//  Main content view with sidebar navigation and sortable table
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } content: {
            switch appState.sidebarSelection {
            case .foodsDatabase:
                FoodTableView()
            case .userReports:
                UserReportsContentView()
            case .databaseCompleteness:
                DatabaseCompletenessView()
            case .importCleanCenter:
                ImportCleanCenterView()
            }
        } detail: {
            switch appState.sidebarSelection {
            case .foodsDatabase:
                if let food = appState.currentFood {
                    FoodDetailView(food: Binding(
                        get: { food },
                        set: { appState.currentFood = $0 }
                    ))
                } else {
                    EmptyDetailView()
                }
            case .userReports:
                EmptyView()
            case .databaseCompleteness:
                EmptyView()
            case .importCleanCenter:
                EmptyView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $appState.showingNewFoodSheet) {
            NewFoodSheet()
        }
        .sheet(isPresented: $appState.showingImportSheet) {
            ImportSheet()
        }
        .sheet(isPresented: $appState.showingExportSheet) {
            ExportSheet()
        }
        .sheet(isPresented: $appState.showingBulkEditSheet) {
            BulkEditSheet()
        }
        .sheet(isPresented: $appState.showingClaudeSheet) {
            ClaudeAssistantSheet()
        }
        .sheet(isPresented: $appState.showingClaudeReviewSheet) {
            ClaudeBatchReviewSheet()
        }
        .sheet(isPresented: $appState.showingValidationSheet) {
            DataValidationSheet()
        }
        .sheet(isPresented: $appState.showingDatabaseScannerSheet) {
            DatabaseScannerSheet()
        }
        .sheet(isPresented: $appState.showingProductImportSheet) {
            ProductImportSheet()
        }
        .sheet(isPresented: $appState.showingStockImageSheet) {
            StockImageSheet()
        }
        .alert("Delete Foods", isPresented: $appState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSelectedFoods()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(appState.selectedFoodIDs.count) food(s)? This cannot be undone.")
        }
        .overlay {
            if !algoliaService.isConfigured {
                SetupOverlay()
            }
        }
    }

    private func deleteSelectedFoods() async {
        let ids = Array(appState.selectedFoodIDs)
        let success = await algoliaService.deleteFoods(objectIDs: ids, database: appState.selectedDatabase)
        if success {
            appState.selectedFoodIDs.removeAll()
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var reviewManager: ReviewManager
    @StateObject private var userReportsService = UserReportsService()

    var body: some View {
        List {
            Section("Databases") {
                ForEach(DatabaseType.allCases) { database in
                    Button {
                        appState.sidebarSelection = .foodsDatabase
                        appState.selectedDatabase = database
                    } label: {
                        HStack {
                            Label(database.displayName, systemImage: database.icon)
                            Spacer()
                            if database == .foods {
                                Text("\(algoliaService.totalHits)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(appState.sidebarSelection == .foodsDatabase && appState.selectedDatabase == database ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
            }

            Section("Review Filter") {
                ForEach(ReviewFilter.allCases) { filter in
                    Button {
                        appState.reviewFilter = filter
                    } label: {
                        HStack {
                            Label(filter.rawValue, systemImage: filter.icon)
                            Spacer()
                            if appState.reviewFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                            Text(countForFilter(filter))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Review Progress") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Reviewed")
                        Spacer()
                        Text("\(reviewManager.reviewStats.totalReviewed) / \(algoliaService.totalHits)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: reviewManager.reviewStats.percentageComplete, total: 100)
                        .progressViewStyle(.linear)
                    Text(String(format: "%.1f%% complete", reviewManager.reviewStats.percentageComplete))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if reviewManager.reviewStats.totalFlagged > 0 {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                        Text("Flagged")
                        Spacer()
                        Text("\(reviewManager.reviewStats.totalFlagged)")
                            .foregroundColor(.orange)
                    }
                }
            }

            Section("User Reports") {
                Button {
                    appState.sidebarSelection = .userReports
                } label: {
                    HStack {
                        Label("View Reports", systemImage: "exclamationmark.bubble")
                        Spacer()
                        if userReportsService.pendingCount > 0 {
                            Text("\(userReportsService.pendingCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(appState.sidebarSelection == .userReports ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
            }

            Section("Claude Review") {
                Button {
                    appState.showingClaudeReviewSheet = true
                } label: {
                    Label("Start Batch Review", systemImage: "sparkles")
                }

                Button {
                    appState.showingClaudeSheet = true
                } label: {
                    Label("Chat Assistant", systemImage: "bubble.left.and.bubble.right")
                }
            }

            Section("Quick Actions") {
                Button {
                    appState.showingNewFoodSheet = true
                } label: {
                    Label("New Food", systemImage: "plus")
                }

                Button {
                    appState.showingImportSheet = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }

                Button {
                    appState.showingExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(appState.selectedFoodIDs.isEmpty && algoliaService.foods.isEmpty)
            }

            Section("Database Tools") {
                Button {
                    appState.showingDatabaseScannerSheet = true
                } label: {
                    Label("Scan & Verify", systemImage: "checkmark.shield")
                }
                .help("Scan database and verify nutrition data against online sources")

                Button {
                    appState.showingProductImportSheet = true
                } label: {
                    Label("Import Products", systemImage: "square.and.arrow.down.on.square")
                }
                .help("Import new products from Open Food Facts and UK retailers")

                Button {
                    appState.showingStockImageSheet = true
                } label: {
                    Label("Stock Images", systemImage: "photo.on.rectangle")
                }
                .help("Find professional product images from Unsplash and Pexels")

                Button {
                    appState.sidebarSelection = .databaseCompleteness
                } label: {
                    Label("Check Completeness", systemImage: "checklist.checked")
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(appState.sidebarSelection == .databaseCompleteness ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
                .help("Check database for missing essential UK foods")

                Button {
                    appState.sidebarSelection = .importCleanCenter
                } label: {
                    Label("Import & Clean", systemImage: "square.and.arrow.down.on.square")
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(appState.sidebarSelection == .importCleanCenter ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
                .help("Import data and clean with AI")
            }

            Section("Settings") {
                SettingsLink {
                    Label("Settings", systemImage: "gear")
                }

                Button(role: .destructive) {
                    reviewManager.resetAllReviews()
                } label: {
                    Label("Reset Review Progress", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        .onChange(of: appState.selectedDatabase) { _, newValue in
            Task {
                await algoliaService.searchFoods(query: "", database: newValue)
            }
        }
        .onAppear {
            reviewManager.updateStatsWithTotal(algoliaService.totalHits)
            Task {
                await userReportsService.fetchReports()
            }
        }
        .onChange(of: algoliaService.totalHits) { _, newTotal in
            reviewManager.updateStatsWithTotal(newTotal)
        }
    }

    private func countForFilter(_ filter: ReviewFilter) -> String {
        switch filter {
        case .all:
            return "\(algoliaService.totalHits)"
        case .reviewed:
            return "\(reviewManager.reviewStats.totalReviewed)"
        case .unreviewed:
            return "\(reviewManager.reviewStats.remaining)"
        case .flagged:
            return "\(reviewManager.reviewStats.totalFlagged)"
        }
    }
}

// MARK: - Food Table View (Sortable)

struct FoodTableView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService
    @EnvironmentObject var reviewManager: ReviewManager

    @State private var searchText = ""
    @State private var isLookingUpBarcode = false
    @State private var showZeroNutritionOnly = false
    @State private var showMissingIngredientsOnly = false
    @State private var showMissingBarcodeOnly = false
    @State private var showMissingBrandOnly = false
    @State private var listScrollPosition: Double = 0
    @State private var isCleaningSelected = false
    @State private var cleaningProgress: Double = 0
    @State private var showToolsPanel = false
    @State private var searchTask: Task<Void, Never>?
    @StateObject private var offService = OpenFoodFactsService.shared

    // Check if search text looks like a barcode (numeric, 8-14 digits)
    private var searchLooksLikeBarcode: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 8 && trimmed.count <= 14 && trimmed.allSatisfy { $0.isNumber }
    }

    // Check if a food has zero or missing nutrition data
    private func hasZeroNutrition(_ food: FoodItem) -> Bool {
        return food.calories == 0 && food.protein == 0 && food.carbs == 0 && food.fat == 0
    }

    // Check for missing data
    private func hasMissingIngredients(_ food: FoodItem) -> Bool {
        return food.ingredients == nil || food.ingredients?.isEmpty == true
    }

    private func hasMissingBarcode(_ food: FoodItem) -> Bool {
        return food.barcode == nil || food.barcode?.isEmpty == true
    }

    private func hasMissingBrand(_ food: FoodItem) -> Bool {
        return food.brand == nil || food.brand?.isEmpty == true
    }

    // Filter foods based on review status and data quality filters
    var filteredFoods: [FoodItem] {
        var foods: [FoodItem]
        switch appState.reviewFilter {
        case .all:
            foods = algoliaService.foods
        case .reviewed:
            foods = algoliaService.foods.filter { reviewManager.isReviewed($0.objectID) }
        case .unreviewed:
            foods = algoliaService.foods.filter { !reviewManager.isReviewed($0.objectID) }
        case .flagged:
            foods = algoliaService.foods.filter { reviewManager.isFlagged($0.objectID) }
        }

        // Apply data quality filters
        if showZeroNutritionOnly {
            foods = foods.filter { hasZeroNutrition($0) }
        }
        if showMissingIngredientsOnly {
            foods = foods.filter { hasMissingIngredients($0) }
        }
        if showMissingBarcodeOnly {
            foods = foods.filter { hasMissingBarcode($0) }
        }
        if showMissingBrandOnly {
            foods = foods.filter { hasMissingBrand($0) }
        }

        return foods
    }

    // Counts for filter badges
    var zeroNutritionCount: Int {
        algoliaService.foods.filter { hasZeroNutrition($0) }.count
    }

    var missingIngredientsCount: Int {
        algoliaService.foods.filter { hasMissingIngredients($0) }.count
    }

    var missingBarcodeCount: Int {
        algoliaService.foods.filter { hasMissingBarcode($0) }.count
    }

    var missingBrandCount: Int {
        algoliaService.foods.filter { hasMissingBrand($0) }.count
    }

    var hasAnyFilter: Bool {
        showZeroNutritionOnly || showMissingIngredientsOnly || showMissingBarcodeOnly || showMissingBrandOnly
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search foods or enter barcode...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        // Cancel any pending debounced search
                        searchTask?.cancel()
                        searchTask = nil
                        print("🔍 TextField onSubmit: Searching for '\(searchText)'")
                        Task {
                            await algoliaService.searchFoods(query: searchText, database: appState.selectedDatabase)
                        }
                    }

                // Search button - explicit search trigger
                Button {
                    // Cancel any pending debounced search
                    searchTask?.cancel()
                    searchTask = nil
                    print("🔍 Search button pressed: Searching for '\(searchText)'")
                    Task {
                        await algoliaService.searchFoods(query: searchText, database: appState.selectedDatabase)
                    }
                } label: {
                    HStack(spacing: 4) {
                        if algoliaService.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                        Text("Search")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderedProminent)

                if !searchText.isEmpty {
                    // Show barcode lookup button if search looks like a barcode
                    if searchLooksLikeBarcode {
                        Button {
                            Task {
                                await lookupBarcode()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if isLookingUpBarcode {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: "barcode.viewfinder")
                                }
                                Text("Lookup")
                            }
                            .foregroundColor(.orange)
                        }
                        .buttonStyle(.plain)
                        .help("Lookup barcode in Open Food Facts")
                        .disabled(isLookingUpBarcode)
                    }

                    Button {
                        searchText = ""
                        Task {
                            await algoliaService.searchFoods(query: "", database: appState.selectedDatabase)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 20)

                Button {
                    Task {
                        await algoliaService.searchFoods(query: searchText, database: appState.selectedDatabase)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Refresh")

                Divider()
                    .frame(height: 20)

                Button {
                    appState.selectAllFoods()
                } label: {
                    Image(systemName: "checkmark.circle")
                }
                .buttonStyle(.plain)
                .help("Select All")
                .disabled(algoliaService.foods.isEmpty)

                if !appState.selectedFoodIDs.isEmpty {
                    Button {
                        appState.deselectAllFoods()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .buttonStyle(.plain)
                    .help("Deselect All")
                }

                Divider()
                    .frame(height: 20)

                // AI Assistant button
                Button {
                    appState.showingClaudeSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                    }
                    .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
                .help("Open Claude AI Assistant")

                // Auto-Review button
                Button {
                    appState.showingClaudeReviewSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                        Text("Auto-Review")
                    }
                    .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
                .help("Start Claude Auto-Review")

                // Data Validation button
                Button {
                    appState.showingValidationSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield")
                        Text("Validate")
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .help("Open Data Validation Tool")

                Divider()
                    .frame(height: 20)

                // Data Quality Filters
                HStack(spacing: 8) {
                    // Zero Nutrition Filter
                    Button {
                        showZeroNutritionOnly.toggle()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "0.circle")
                            if zeroNutritionCount > 0 {
                                Text("\(zeroNutritionCount)")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(showZeroNutritionOnly ? Color.red.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .foregroundColor(showZeroNutritionOnly ? .red : (zeroNutritionCount > 0 ? .orange : .secondary))
                    }
                    .buttonStyle(.plain)
                    .help("Zero nutrition (\(zeroNutritionCount))")

                    // Missing Ingredients Filter
                    Button {
                        showMissingIngredientsOnly.toggle()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "list.bullet")
                            if missingIngredientsCount > 0 {
                                Text("\(missingIngredientsCount)")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(showMissingIngredientsOnly ? Color.orange.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .foregroundColor(showMissingIngredientsOnly ? .orange : (missingIngredientsCount > 0 ? .orange : .secondary))
                    }
                    .buttonStyle(.plain)
                    .help("Missing ingredients (\(missingIngredientsCount))")

                    // Missing Barcode Filter
                    Button {
                        showMissingBarcodeOnly.toggle()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "barcode")
                            if missingBarcodeCount > 0 {
                                Text("\(missingBarcodeCount)")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(showMissingBarcodeOnly ? Color.purple.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .foregroundColor(showMissingBarcodeOnly ? .purple : (missingBarcodeCount > 0 ? .purple : .secondary))
                    }
                    .buttonStyle(.plain)
                    .help("Missing barcode (\(missingBarcodeCount))")

                    // Missing Brand Filter
                    Button {
                        showMissingBrandOnly.toggle()
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "building.2")
                            if missingBrandCount > 0 {
                                Text("\(missingBrandCount)")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(showMissingBrandOnly ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(4)
                        .foregroundColor(showMissingBrandOnly ? .blue : (missingBrandCount > 0 ? .blue : .secondary))
                    }
                    .buttonStyle(.plain)
                    .help("Missing brand (\(missingBrandCount))")

                    // Clear filters
                    if hasAnyFilter {
                        Button {
                            showZeroNutritionOnly = false
                            showMissingIngredientsOnly = false
                            showMissingBarcodeOnly = false
                            showMissingBrandOnly = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Clear all filters")
                    }
                }

                Divider()
                    .frame(height: 20)

                // Tools Panel Toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showToolsPanel.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("Tools")
                    }
                    .foregroundColor(showToolsPanel ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help("Toggle tools panel")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Selection toolbar
            if !appState.selectedFoodIDs.isEmpty {
                SelectionToolbar()
            }

            // Main content area with optional tools panel
            HStack(spacing: 0) {
                // Tools Panel (collapsible)
                if showToolsPanel {
                    toolsPanel
                        .frame(width: 280)
                        .transition(.move(edge: .leading))
                }

                // Table
                if algoliaService.isLoading && algoliaService.foods.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if algoliaService.foods.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No foods found")
                            .font(.headline)
                        Text("Try a different search or browse all foods")
                            .foregroundColor(.secondary)

                        Button("Browse All") {
                            Task {
                                await algoliaService.browseAllFoods(database: appState.selectedDatabase)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredFoods.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: appState.reviewFilter.icon)
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No \(hasAnyFilter ? "matching" : appState.reviewFilter.rawValue.lowercased()) foods")
                            .font(.headline)
                        if appState.reviewFilter != .all || hasAnyFilter {
                            Button("Clear Filters") {
                                appState.reviewFilter = .all
                                showZeroNutritionOnly = false
                                showMissingIngredientsOnly = false
                                showMissingBarcodeOnly = false
                                showMissingBrandOnly = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 0) {
                        FoodTableContentWithScroll(
                            foods: filteredFoods,
                            selectedFoodIDs: $appState.selectedFoodIDs,
                            currentFoodID: $appState.currentFoodID,
                            scrollPosition: $listScrollPosition,
                            onFoodSelected: { food in
                                appState.currentFood = food
                            },
                            onDelete: { ids in
                                appState.selectedFoodIDs = ids
                                appState.showingDeleteConfirmation = true
                            }
                        )

                        // Vertical scroll slider
                        if filteredFoods.count > 20 {
                            VStack(spacing: 4) {
                                Text("▲")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Slider(
                                    value: $listScrollPosition,
                                    in: 0...1
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 150, height: 20)
                                .frame(height: 150)

                                Text("▼")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("\(Int(listScrollPosition * Double(filteredFoods.count)))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("/\(filteredFoods.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 28)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        }
                    }
                }
            }

            // Status bar
            HStack {
                if algoliaService.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                if appState.reviewFilter != .all {
                    Text("\(filteredFoods.count) \(appState.reviewFilter.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                }

                Text("\(algoliaService.foods.count) of \(algoliaService.totalHits) foods")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if algoliaService.hasMorePages {
                    Button("Load More") {
                        Task {
                            await algoliaService.loadMoreFoods(query: searchText, database: appState.selectedDatabase)
                        }
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }

                if let error = algoliaService.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationSplitViewColumnWidth(min: 500, ideal: 700, max: .infinity)
        .task {
            if algoliaService.foods.isEmpty {
                await algoliaService.searchFoods(query: "", database: appState.selectedDatabase)
            }
            appState.loadedFoods = algoliaService.foods
        }
        .onChange(of: algoliaService.foods) { _, newFoods in
            appState.loadedFoods = newFoods
        }
        .onChange(of: searchText) { _, newValue in
            // Cancel previous search task
            searchTask?.cancel()

            // Debounce search - wait 500ms after typing stops
            print("🔍 onChange: searchText changed to '\(newValue)', starting debounce timer")
            searchTask = Task {
                do {
                    try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                    if !Task.isCancelled {
                        print("🔍 Debounce complete, executing search for '\(newValue)'")
                        await algoliaService.searchFoods(query: newValue, database: appState.selectedDatabase)
                    } else {
                        print("🔍 Debounce cancelled for '\(newValue)'")
                    }
                } catch {
                    // Task was cancelled, ignore
                    print("🔍 Debounce task cancelled")
                }
            }
        }
    }

    /// Look up a barcode in Open Food Facts and offer to add it
    private func lookupBarcode() async {
        let barcode = searchText.trimmingCharacters(in: .whitespaces)
        isLookingUpBarcode = true

        // First check if we already have this barcode in our database
        await algoliaService.searchFoods(query: barcode, database: appState.selectedDatabase)

        // Check if any results match the barcode exactly
        let existingFood = algoliaService.foods.first { $0.barcode == barcode }

        if let food = existingFood {
            // Food already exists - select it
            appState.currentFood = food
            appState.currentFoodID = food.objectID
            isLookingUpBarcode = false
            return
        }

        // Not found locally - look up in Open Food Facts
        if let offProduct = await offService.lookupProduct(barcode: barcode) {
            // Create a new food from the OFF data
            var newFood = FoodItem()
            newFood.barcode = barcode
            newFood.name = offProduct.product_name_en ?? offProduct.product_name ?? "Unknown Product"
            newFood.brand = offProduct.brands
            newFood.source = "Open Food Facts"

            // Nutrition
            if let nutriments = offProduct.nutriments {
                newFood.calories = nutriments.energy_kcal_100g ?? nutriments.energy_kcal ?? 0
                newFood.protein = nutriments.proteins_100g ?? nutriments.proteins ?? 0
                newFood.carbs = nutriments.carbohydrates_100g ?? nutriments.carbohydrates ?? 0
                newFood.fat = nutriments.fat_100g ?? nutriments.fat ?? 0
                newFood.fiber = nutriments.fiber_100g ?? nutriments.fiber ?? 0
                newFood.sugar = nutriments.sugars_100g ?? nutriments.sugars ?? 0
                newFood.sodium = (nutriments.sodium_100g ?? nutriments.sodium ?? 0) * 1000 // Convert to mg
                newFood.saturatedFat = nutriments.saturated_fat_100g ?? nutriments.saturated_fat
            }

            // Ingredients
            if let ingredientsText = offProduct.ingredients_text_en ?? offProduct.ingredients_text {
                newFood.ingredientsText = ingredientsText
                newFood.ingredients = ingredientsText
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }

            // Images
            if let imageURL = offProduct.image_front_url ?? offProduct.image_url {
                newFood.imageURL = imageURL
            }

            // Set as current food for editing before saving
            appState.currentFood = newFood
            appState.currentFoodID = newFood.objectID

            // Add to the list temporarily so the user can see it
            algoliaService.foods.insert(newFood, at: 0)
        }

        isLookingUpBarcode = false
    }

    // MARK: - Tools Panel

    private var toolsPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundColor(.accentColor)
                    Text("Tools")
                        .font(.headline)
                    Spacer()
                }
                .padding(.bottom, 4)

                Divider()

                // Quick Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Quality")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    statRow(icon: "0.circle", label: "Zero Nutrition", count: zeroNutritionCount, color: .red)
                    statRow(icon: "list.bullet", label: "Missing Ingredients", count: missingIngredientsCount, color: .orange)
                    statRow(icon: "barcode", label: "Missing Barcode", count: missingBarcodeCount, color: .purple)
                    statRow(icon: "building.2", label: "Missing Brand", count: missingBrandCount, color: .blue)
                }

                Divider()

                // AI Cleaning Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("AI Cleaning")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    if isCleaningSelected {
                        VStack(spacing: 8) {
                            ProgressView(value: cleaningProgress)
                            Text("Cleaning \(appState.selectedFoodIDs.count) items...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button("Cancel") {
                                isCleaningSelected = false
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button {
                            Task { await cleanSelectedWithAI() }
                        } label: {
                            Label("Clean Selected (\(appState.selectedFoodIDs.count))", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(appState.selectedFoodIDs.isEmpty || !claudeService.isConfigured)

                        Button {
                            appState.showingClaudeReviewSheet = true
                        } label: {
                            Label("Batch Auto-Review", systemImage: "text.badge.checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if !claudeService.isConfigured {
                        Text("Configure Claude API key in Settings")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Divider()

                // Bulk Operations
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .foregroundColor(.green)
                        Text("Bulk Operations")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Button {
                        appState.showingBulkEditSheet = true
                    } label: {
                        Label("Bulk Edit Selected", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.selectedFoodIDs.isEmpty)

                    Button {
                        // Select all filtered foods
                        for food in filteredFoods {
                            appState.selectedFoodIDs.insert(food.objectID)
                        }
                    } label: {
                        Label("Select All Visible (\(filteredFoods.count))", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        appState.selectedFoodIDs.removeAll()
                    } label: {
                        Label("Deselect All", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.selectedFoodIDs.isEmpty)

                    Button(role: .destructive) {
                        appState.showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Selected (\(appState.selectedFoodIDs.count))", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.selectedFoodIDs.isEmpty)
                }

                Divider()

                // Quick Actions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bolt")
                            .foregroundColor(.orange)
                        Text("Quick Actions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Button {
                        Task {
                            await algoliaService.browseAllFoods(database: appState.selectedDatabase)
                        }
                    } label: {
                        Label("Browse All Foods", systemImage: "list.bullet.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        appState.showingValidationSheet = true
                    } label: {
                        Label("Data Validation", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        appState.showingExportSheet = true
                    } label: {
                        Label("Export Selected", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.selectedFoodIDs.isEmpty)
                }

                Spacer()
            }
            .padding()
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func statRow(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(count > 0 ? color : .secondary)
        }
    }

    private func cleanSelectedWithAI() async {
        guard !appState.selectedFoodIDs.isEmpty else { return }

        isCleaningSelected = true
        cleaningProgress = 0

        let selectedIDs = Array(appState.selectedFoodIDs)
        let total = selectedIDs.count

        for (index, id) in selectedIDs.enumerated() {
            guard isCleaningSelected else { break }

            if let food = algoliaService.foods.first(where: { $0.objectID == id }) {
                // Use Claude to analyze and suggest fixes
                let prompt = """
                Analyze this food item and suggest any fixes needed:
                Name: \(food.name)
                Brand: \(food.brand ?? "none")
                Ingredients: \(food.ingredients?.joined(separator: ", ") ?? "none")
                Calories: \(food.calories), Protein: \(food.protein)g, Carbs: \(food.carbs)g, Fat: \(food.fat)g

                Respond with JSON only: {"fixedName": "...", "fixedBrand": "...", "issues": ["..."]}
                """

                await claudeService.sendMessage(prompt)
            }

            cleaningProgress = Double(index + 1) / Double(total)
        }

        isCleaningSelected = false
        claudeService.clearConversation()
    }
}

// MARK: - Food Table Content With Scroll

struct FoodTableContentWithScroll: View {
    let foods: [FoodItem]
    @Binding var selectedFoodIDs: Set<String>
    @Binding var currentFoodID: String?
    @Binding var scrollPosition: Double
    let onFoodSelected: (FoodItem) -> Void
    let onDelete: (Set<String>) -> Void

    // Check if all visible foods are selected
    private var allSelected: Bool {
        !foods.isEmpty && foods.allSatisfy { selectedFoodIDs.contains($0.objectID) }
    }

    // Check if some (but not all) foods are selected
    private var someSelected: Bool {
        !selectedFoodIDs.isEmpty && !allSelected
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Header row with select all
                    FoodTableHeader(
                        allSelected: allSelected,
                        someSelected: someSelected,
                        onToggleSelectAll: {
                            if allSelected {
                                for food in foods {
                                    selectedFoodIDs.remove(food.objectID)
                                }
                            } else {
                                for food in foods {
                                    selectedFoodIDs.insert(food.objectID)
                                }
                            }
                        }
                    )

                    Divider()

                    // Data rows
                    ForEach(Array(foods.enumerated()), id: \.element.objectID) { index, food in
                        FoodTableRow(
                            food: food,
                            isSelected: selectedFoodIDs.contains(food.objectID),
                            isCurrent: currentFoodID == food.objectID,
                            onToggleSelection: {
                                if selectedFoodIDs.contains(food.objectID) {
                                    selectedFoodIDs.remove(food.objectID)
                                } else {
                                    selectedFoodIDs.insert(food.objectID)
                                }
                            },
                            onSelect: {
                                currentFoodID = food.objectID
                                onFoodSelected(food)
                            }
                        )
                        .id(index)
                        .contextMenu {
                            Button("Edit") { onFoodSelected(food) }
                            Button("Select") { selectedFoodIDs.insert(food.objectID) }
                            Divider()
                            Button("Delete", role: .destructive) { onDelete([food.objectID]) }
                        }

                        Divider()
                    }
                }
            }
            .onChange(of: scrollPosition) { _, newValue in
                let targetIndex = Int(Double(foods.count - 1) * newValue)
                if targetIndex >= 0 && targetIndex < foods.count {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo(targetIndex, anchor: .top)
                    }
                }
            }
        }
    }
}

// MARK: - Food Table Content

struct FoodTableContent: View {
    let foods: [FoodItem]
    @Binding var selectedFoodIDs: Set<String>
    @Binding var currentFoodID: String?
    let onFoodSelected: (FoodItem) -> Void
    let onDelete: (Set<String>) -> Void

    // Check if all visible foods are selected
    private var allSelected: Bool {
        !foods.isEmpty && foods.allSatisfy { selectedFoodIDs.contains($0.objectID) }
    }

    // Check if some (but not all) foods are selected
    private var someSelected: Bool {
        !selectedFoodIDs.isEmpty && !allSelected
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header row with select all
                FoodTableHeader(
                    allSelected: allSelected,
                    someSelected: someSelected,
                    onToggleSelectAll: {
                        if allSelected {
                            // Deselect all visible foods
                            for food in foods {
                                selectedFoodIDs.remove(food.objectID)
                            }
                        } else {
                            // Select all visible foods
                            for food in foods {
                                selectedFoodIDs.insert(food.objectID)
                            }
                        }
                    }
                )

                Divider()

                // Data rows
                ForEach(foods) { food in
                    FoodTableRow(
                        food: food,
                        isSelected: selectedFoodIDs.contains(food.objectID),
                        isCurrent: currentFoodID == food.objectID,
                        onToggleSelection: {
                            if selectedFoodIDs.contains(food.objectID) {
                                selectedFoodIDs.remove(food.objectID)
                            } else {
                                selectedFoodIDs.insert(food.objectID)
                            }
                        },
                        onSelect: {
                            currentFoodID = food.objectID
                            onFoodSelected(food)
                        }
                    )
                    .contextMenu {
                        Button("Edit") { onFoodSelected(food) }
                        Button("Select") { selectedFoodIDs.insert(food.objectID) }
                        Divider()
                        Button("Delete", role: .destructive) { onDelete([food.objectID]) }
                    }

                    Divider()
                }
            }
        }
    }
}

struct FoodTableHeader: View {
    var allSelected: Bool = false
    var someSelected: Bool = false
    var onToggleSelectAll: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            // Select all checkbox
            Button {
                onToggleSelectAll?()
            } label: {
                Image(systemName: allSelected ? "checkmark.square.fill" : (someSelected ? "minus.square.fill" : "square"))
                    .foregroundColor(allSelected || someSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 44)
            .help(allSelected ? "Deselect all" : "Select all")

            Text("").frame(width: 36) // image column
            Text("Name").frame(minWidth: 150, alignment: .leading)
            Text("Brand").frame(width: 100, alignment: .leading)
            Text("Barcode").frame(width: 110, alignment: .leading)
            Text("Serving").frame(width: 70, alignment: .leading)
            Text("Cal").frame(width: 50, alignment: .trailing)
            Text("P").frame(width: 35, alignment: .trailing)
            Text("C").frame(width: 35, alignment: .trailing)
            Text("F").frame(width: 35, alignment: .trailing)
            Text("Ing").frame(width: 40, alignment: .center)
            Text("✓").frame(width: 30, alignment: .center)
            Text("Grade").frame(width: 50, alignment: .center)
            Text("Source").frame(width: 80, alignment: .leading)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct FoodTableRow: View {
    let food: FoodItem
    let isSelected: Bool
    let isCurrent: Bool
    let onToggleSelection: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Toggle("", isOn: Binding(get: { isSelected }, set: { _ in onToggleSelection() }))
                .toggleStyle(.checkbox)
                .frame(width: 44)

            // Thumbnail image
            imageView
                .frame(width: 36, height: 28)

            Text(food.name)
                .lineLimit(1)
                .frame(minWidth: 150, alignment: .leading)

            Text(food.brand ?? "-")
                .foregroundColor(food.brand == nil ? .secondary : .primary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            // Barcode
            barcodeView
                .frame(width: 110, alignment: .leading)

            // Serving size
            servingSizeView
                .frame(width: 70, alignment: .leading)

            Text("\(Int(food.calories))")
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)

            Text(String(format: "%.0f", food.protein))
                .monospacedDigit()
                .frame(width: 35, alignment: .trailing)

            Text(String(format: "%.0f", food.carbs))
                .monospacedDigit()
                .frame(width: 35, alignment: .trailing)

            Text(String(format: "%.0f", food.fat))
                .monospacedDigit()
                .frame(width: 35, alignment: .trailing)

            ingredientCountView
                .frame(width: 40, alignment: .center)

            verifiedView
                .frame(width: 30, alignment: .center)

            gradeView
                .frame(width: 50, alignment: .center)

            Text(food.source ?? "-")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 80, alignment: .leading)
        }
        .font(.callout)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(isCurrent ? Color.accentColor.opacity(0.15) : (isSelected ? Color.accentColor.opacity(0.08) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }

    @ViewBuilder
    private var imageView: some View {
        if let imageURL = food.thumbnailURL ?? food.imageURL,
           let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .cornerRadius(4)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                        .font(.caption)
                case .empty:
                    ProgressView()
                        .scaleEffect(0.5)
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
    private var servingSizeView: some View {
        if food.isPerUnit == true {
            // Per-unit food (like Big Mac)
            VStack(alignment: .leading, spacing: 0) {
                Text("per unit")
                    .font(.caption2)
                    .foregroundColor(.purple)
                if let servingG = food.servingSizeG, servingG > 0 {
                    Text("\(Int(servingG))g")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        } else if let servingG = food.servingSizeG, servingG > 0 {
            Text("\(Int(servingG))g")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            Text("100g")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }

    @ViewBuilder
    private var barcodeView: some View {
        if let barcode = food.barcode, !barcode.isEmpty {
            HStack(spacing: 2) {
                Image(systemName: "barcode")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(barcode)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
            }
        } else {
            Text("-")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }

    private var ingredientCountView: some View {
        let count = food.ingredients?.count ?? 0
        return Text(count == 0 ? "—" : "\(count)")
            .foregroundColor(count == 0 ? .red : (count > 20 ? .orange : .primary))
    }

    private var verifiedView: some View {
        Image(systemName: food.isVerified == true ? "checkmark.seal.fill" : "xmark")
            .foregroundColor(food.isVerified == true ? .green : .secondary)
            .font(.caption)
    }

    private var gradeView: some View {
        Group {
            if let grade = food.processingGrade {
                Text(grade)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(gradeColor(grade))
            } else {
                Text("-").foregroundColor(.secondary)
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
}

// MARK: - Selection Toolbar

struct SelectionToolbar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService

    @State private var isBulkUpdating = false

    var body: some View {
        HStack {
            Text("\(appState.selectedFoodIDs.count) selected")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            if isBulkUpdating {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.horizontal, 8)
            }

            // Bulk Verify button
            Button {
                Task {
                    await bulkSetVerification(verified: true)
                }
            } label: {
                Label("Verify All", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.green)
            .disabled(isBulkUpdating)
            .help("Mark all selected foods as verified")

            // Bulk Unverify button
            Button {
                Task {
                    await bulkSetVerification(verified: false)
                }
            } label: {
                Label("Unverify All", systemImage: "xmark.seal")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.orange)
            .disabled(isBulkUpdating)
            .help("Mark all selected foods as unverified")

            Divider()
                .frame(height: 16)

            Button {
                appState.showingBulkEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .buttonStyle(.borderless)

            Button {
                appState.showingExportSheet = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                appState.showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.borderless)

            Button {
                appState.deselectAllFoods()
            } label: {
                Text("Clear")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
    }

    private func bulkSetVerification(verified: Bool) async {
        isBulkUpdating = true

        // Get the selected foods
        let selectedFoods = algoliaService.foods.filter { appState.selectedFoodIDs.contains($0.objectID) }

        // Update verification status
        var updatedFoods: [FoodItem] = []
        for var food in selectedFoods {
            food.isVerified = verified
            updatedFoods.append(food)
        }

        // Save to database
        let success = await algoliaService.saveFoods(updatedFoods, database: appState.selectedDatabase)

        if success {
            // Update local state
            for updatedFood in updatedFoods {
                if let index = algoliaService.foods.firstIndex(where: { $0.objectID == updatedFood.objectID }) {
                    algoliaService.foods[index].isVerified = verified
                }
            }
        }

        isBulkUpdating = false
    }
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Select a food to view details")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Or create a new food item")
                .foregroundColor(.secondary)

            Button {
                appState.showingNewFoodSheet = true
            } label: {
                Label("New Food", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Setup Overlay

struct SetupOverlay: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.95)

            VStack(spacing: 24) {
                Image(systemName: "key.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)

                Text("Setup Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Please configure your Algolia API credentials to connect to your food databases.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)

                VStack(spacing: 12) {
                    SettingsLink {
                        HStack {
                            Image(systemName: "gear")
                            Text("Open Settings")
                        }
                        .frame(width: 200)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text("Press ⌘, to open Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Claude Assistant Sheet

struct ClaudeAssistantSheet: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService
    @EnvironmentObject var claudeService: ClaudeService
    @Environment(\.dismiss) var dismiss

    @State private var userInput = ""
    @State private var isThinking = false
    @State private var showingPermissionAlert = false
    @State private var quickActions: [QuickAction] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header with stop button
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("Claude Assistant")
                    .font(.headline)

                Spacer()

                if isThinking || claudeService.isProcessing {
                    Button {
                        claudeService.cancelCurrentOperation()
                        isThinking = false
                        quickActions = []
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }

                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Status bar when processing
            if isThinking || claudeService.isProcessing {
                StatusBar(status: claudeService.currentStatus.isEmpty ? "Thinking..." : claudeService.currentStatus)
            }

            // Action progress bar
            if let progress = claudeService.actionProgress {
                ActionProgressBar(progress: progress)
            }

            // Pending action approval
            if let pending = claudeService.pendingAction {
                PendingActionView(
                    pending: pending,
                    onApprove: { await executeApprovedAction(pending.action) },
                    onReject: { claudeService.pendingAction = nil }
                )
            }

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // System message
                        AssistantMessageView(content: """
                        I'm your NutraSafe database assistant. I can help you:

                        • **Search and query** - Find foods by any criteria
                        • **Analyze data** - Find foods with missing ingredients, unverified items, etc.
                        • **Make changes** - Edit, update, or delete foods (I'll ask permission first)
                        • **Bulk operations** - Update multiple foods at once

                        Try asking things like:
                        - "Show me foods without ingredients"
                        - "Find all unverified foods from Open Food Facts"
                        - "Set all McDonald's foods as verified"
                        - "Delete foods with 0 calories"
                        """)

                        ForEach(claudeService.messages) { message in
                            if message.role == .user {
                                UserMessageView(content: message.content)
                            } else {
                                AssistantMessageView(content: message.content)
                            }
                        }

                        if isThinking {
                            ThinkingIndicator()
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

            // Quick action buttons (when available)
            if !quickActions.isEmpty && !isThinking {
                QuickActionsBar(actions: quickActions, onAction: handleQuickAction)
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Ask Claude to help with your database...", text: $userInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .onSubmit {
                        sendMessage()
                    }
                    .disabled(isThinking)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(userInput.isEmpty || isThinking ? .secondary : .accentColor)
                }
                .buttonStyle(.plain)
                .disabled(userInput.isEmpty || isThinking)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 700, height: 650)
    }

    private func handleQuickAction(_ action: QuickAction) {
        userInput = action.prompt
        quickActions = []
        sendMessage()
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }

        let message = userInput
        userInput = ""
        isThinking = true
        claudeService.currentStatus = "Analyzing your request..."

        Task {
            // Build context about current state
            let context = DatabaseContext(
                database: appState.selectedDatabase,
                totalRecords: algoliaService.totalHits,
                selectedCount: appState.selectedFoodIDs.count,
                currentFood: appState.currentFood
            )

            // Include sample of current foods for context
            let sampleFoods = algoliaService.foods.prefix(20).map { food in
                "- \"\(food.name)\" (ID: \(food.objectID), Brand: \(food.brand ?? "none"), Verified: \(food.isVerified ?? false), Ingredients: \(food.ingredients?.count ?? 0), Source: \(food.source ?? "unknown"))"
            }.joined(separator: "\n")

            let enhancedMessage = """
            User request: \(message)

            Current database: \(appState.selectedDatabase.displayName)
            Total records in database: \(algoliaService.totalHits)
            Currently loaded foods: \(algoliaService.foods.count)
            Selected items: \(appState.selectedFoodIDs.count)

            Sample of currently visible foods:
            \(sampleFoods)

            You are an AI assistant helping manage a UK food database. Use British English (fibre, colour, flavour, analyse, organise, etc.).

            You can:
            1. SEARCH - Find foods by name, brand, or other criteria
            2. UPDATE - Change fields on specific foods
            3. BULK UPDATE - Change fields on multiple foods at once
            4. DELETE - Remove foods from the database

            IMPORTANT INSTRUCTIONS:
            - This is a UK database - use British spellings and UK nutrition standards
            - When the user asks to find/search/show foods, ALWAYS include an action block to perform the search
            - After explaining what you'll do, include a JSON action block like this:

            ```action
            {"type": "search", "query": "search terms here"}
            ```

            For updates, use:
            ```action
            {"type": "update", "foodIDs": ["id1", "id2"], "changes": {"fieldName": "newValue"}}
            ```

            For bulk updates on selected items:
            ```action
            {"type": "bulkUpdate", "changes": {"fieldName": "newValue"}}
            ```

            For deletions:
            ```action
            {"type": "delete", "foodIDs": ["id1", "id2"]}
            ```

            Available fields to update: name, brand, isVerified (true/false), processingGrade, source

            ALWAYS include an action block when the user wants you to do something. Be proactive and execute actions immediately!
            After I execute the action, I'll show you the results so you can continue helping.
            """

            claudeService.currentStatus = "Waiting for Claude..."
            await claudeService.sendMessage(enhancedMessage, context: context)

            // Parse any actions from the response
            if let lastMessage = claudeService.messages.last, lastMessage.role == .assistant {
                claudeService.currentStatus = "Checking for actions..."
                let actionExecuted = await parseAndPrepareAction(lastMessage.content)

                // If an action was executed, add a follow-up showing results
                if actionExecuted {
                    await addResultsMessage()
                }

                // Generate quick action buttons based on context
                quickActions = generateQuickActions(from: lastMessage.content)
            }

            claudeService.currentStatus = ""
            isThinking = false
        }
    }

    private func generateQuickActions(from response: String) -> [QuickAction] {
        var actions: [QuickAction] = []

        // If we found foods, offer common follow-up actions
        if algoliaService.foods.count > 0 {
            // Offer to analyze or fix issues
            if response.lowercased().contains("missing") || response.lowercased().contains("without") {
                actions.append(QuickAction(
                    title: "Mark all as flagged",
                    prompt: "Flag all these foods for review",
                    icon: "flag.fill"
                ))
            }

            if response.lowercased().contains("unverified") {
                actions.append(QuickAction(
                    title: "Verify all",
                    prompt: "Mark all these foods as verified",
                    icon: "checkmark.seal"
                ))
            }

            // Common follow-ups
            actions.append(QuickAction(
                title: "Show more details",
                prompt: "Show me more details about these foods",
                icon: "list.bullet.rectangle"
            ))

            if algoliaService.foods.count > 10 {
                actions.append(QuickAction(
                    title: "Export these",
                    prompt: "Export these foods to a file",
                    icon: "square.and.arrow.up"
                ))
            }
        }

        // General follow-up options
        actions.append(QuickAction(
            title: "Find issues",
            prompt: "What data quality issues can you find in the database?",
            icon: "exclamationmark.triangle"
        ))

        actions.append(QuickAction(
            title: "Show stats",
            prompt: "Show me statistics about the database",
            icon: "chart.bar"
        ))

        return Array(actions.prefix(4)) // Limit to 4 actions
    }

    private func addResultsMessage() async {
        // Give a brief summary of what's now visible
        let resultSummary: String
        if algoliaService.foods.isEmpty {
            resultSummary = "No foods found matching your criteria."
        } else {
            let sampleNames = algoliaService.foods.prefix(5).map { $0.name }.joined(separator: ", ")
            resultSummary = "Found \(algoliaService.foods.count) foods. Examples: \(sampleNames)..."
        }

        let systemMessage = ChatMessage(role: .assistant, content: "✅ **Action completed.** \(resultSummary)\n\nWhat would you like to do next?")
        claudeService.messages.append(systemMessage)
    }

    @discardableResult
    private func parseAndPrepareAction(_ response: String) async -> Bool {
        // Look for action blocks
        if let actionStart = response.range(of: "```action"),
           let actionEnd = response.range(of: "```", range: actionStart.upperBound..<response.endIndex) {
            let actionJSON = String(response[actionStart.upperBound..<actionEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let data = actionJSON.data(using: .utf8),
               let action = try? JSONDecoder().decode(ClaudeAction.self, from: data) {

                // For non-destructive actions (search), execute immediately
                if action.type == "search" {
                    await executeApprovedAction(action)
                    return true
                } else {
                    // For changes, create a pending action for approval
                    let pending = createPendingAction(from: action)
                    claudeService.pendingAction = pending
                    return false // Action pending approval
                }
            }
        }
        return false
    }

    private func createPendingAction(from action: ClaudeAction) -> PendingAction {
        let actionType: PendingAction.ActionType = {
            switch action.type {
            case "delete": return .delete
            case "update": return .update
            case "bulkUpdate": return .bulkUpdate
            default: return .search
            }
        }()

        let affectedCount = action.foodIDs?.count ?? appState.selectedFoodIDs.count

        let description: String = {
            switch action.type {
            case "delete":
                return "Delete \(affectedCount) food(s)"
            case "update":
                return "Update \(affectedCount) food(s)"
            case "bulkUpdate":
                return "Bulk update \(affectedCount) food(s)"
            default:
                return "Search foods"
            }
        }()

        let details: String = {
            if let changes = action.changes {
                return "Changes: " + changes.map { "\($0.key) → \($0.value)" }.joined(separator: ", ")
            }
            return action.query ?? ""
        }()

        return PendingAction(
            type: actionType,
            description: description,
            details: details,
            affectedCount: affectedCount,
            action: action
        )
    }

    private func executeApprovedAction(_ action: ClaudeAction) async {
        claudeService.pendingAction = nil

        switch action.type {
        case "search":
            claudeService.currentStatus = "Searching entire database..."
            if let query = action.query {
                // Use extended search to get more results (up to 500)
                await algoliaService.extendedSearch(query: query, database: appState.selectedDatabase, maxResults: 500)
            }
            claudeService.currentStatus = "Found \(algoliaService.foods.count) of \(algoliaService.totalHits) results"

        case "update":
            if let foodIDs = action.foodIDs, let changes = action.changes {
                claudeService.actionProgress = ActionProgress(
                    currentStep: "Updating foods...",
                    completedItems: 0,
                    totalItems: foodIDs.count
                )

                for (index, id) in foodIDs.enumerated() {
                    claudeService.actionProgress?.currentStep = "Updating food \(index + 1) of \(foodIDs.count)"
                    claudeService.actionProgress?.completedItems = index

                    if var food = algoliaService.foods.first(where: { $0.objectID == id }) {
                        applyChanges(&food, changes: changes)
                        let success = await algoliaService.saveFood(food, database: appState.selectedDatabase)
                        if !success {
                            claudeService.actionProgress?.errors.append("Failed to update: \(food.name)")
                        }
                    }
                }

                claudeService.actionProgress?.completedItems = foodIDs.count
                claudeService.actionProgress?.currentStep = "Complete!"

                // Add completion message
                let successMessage = ChatMessage(role: .assistant, content: "✅ Updated \(foodIDs.count) food(s) successfully.")
                claudeService.messages.append(successMessage)

                // Refresh the list
                await algoliaService.searchFoods(query: "", database: appState.selectedDatabase)

                // Clear progress after a delay
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                claudeService.actionProgress = nil
            }

        case "bulkUpdate":
            if let changes = action.changes {
                let idsToUpdate = action.foodIDs ?? Array(appState.selectedFoodIDs)

                claudeService.actionProgress = ActionProgress(
                    currentStep: "Bulk updating...",
                    completedItems: 0,
                    totalItems: idsToUpdate.count
                )

                for (index, id) in idsToUpdate.enumerated() {
                    claudeService.actionProgress?.currentStep = "Updating \(index + 1) of \(idsToUpdate.count)"
                    claudeService.actionProgress?.completedItems = index

                    if var food = algoliaService.foods.first(where: { $0.objectID == id }) {
                        applyChanges(&food, changes: changes)
                        let _ = await algoliaService.saveFood(food, database: appState.selectedDatabase)
                    }
                }

                claudeService.actionProgress?.completedItems = idsToUpdate.count
                claudeService.actionProgress?.currentStep = "Complete!"

                let successMessage = ChatMessage(role: .assistant, content: "✅ Bulk updated \(idsToUpdate.count) food(s) successfully.")
                claudeService.messages.append(successMessage)

                await algoliaService.searchFoods(query: "", database: appState.selectedDatabase)

                try? await Task.sleep(nanoseconds: 1_500_000_000)
                claudeService.actionProgress = nil
            }

        case "delete":
            if let foodIDs = action.foodIDs {
                claudeService.actionProgress = ActionProgress(
                    currentStep: "Deleting foods...",
                    completedItems: 0,
                    totalItems: foodIDs.count
                )

                let success = await algoliaService.deleteFoods(objectIDs: foodIDs, database: appState.selectedDatabase)

                claudeService.actionProgress?.completedItems = foodIDs.count
                claudeService.actionProgress?.currentStep = success ? "Complete!" : "Failed"

                let message = success
                    ? "✅ Deleted \(foodIDs.count) food(s) successfully."
                    : "❌ Failed to delete foods."
                claudeService.messages.append(ChatMessage(role: .assistant, content: message))

                try? await Task.sleep(nanoseconds: 1_500_000_000)
                claudeService.actionProgress = nil
            }

        default:
            break
        }
    }

    private func applyChanges(_ food: inout FoodItem, changes: [String: String]) {
        for (key, value) in changes {
            switch key {
            case "name": food.name = value
            case "brand": food.brand = value.isEmpty ? nil : value
            case "isVerified": food.isVerified = value.lowercased() == "true"
            case "processingGrade": food.processingGrade = value.isEmpty ? nil : value
            case "source": food.source = value.isEmpty ? nil : value
            default: break
            }
        }
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    let status: String

    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.1))
    }
}

// MARK: - Thinking Indicator

struct ThinkingIndicator: View {
    @State private var animationPhase = 0

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.purple)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.4).repeatForever(), value: animationPhase)
            }
            Text("Claude is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Action Progress Bar

struct ActionProgressBar: View {
    let progress: ActionProgress

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(progress.currentStep)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(progress.completedItems)/\(progress.totalItems)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: progress.progress)
                .progressViewStyle(.linear)

            if !progress.errors.isEmpty {
                Text("\(progress.errors.count) error(s)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
    }
}

// MARK: - Pending Action View

struct PendingActionView: View {
    let pending: PendingAction
    let onApprove: () async -> Void
    let onReject: () -> Void

    @State private var isApproving = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: pending.type.icon)
                    .font(.title2)
                    .foregroundColor(pending.type.isDestructive ? .red : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pending.description)
                        .font(.headline)
                    Text(pending.details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    onReject()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    isApproving = true
                    Task {
                        await onApprove()
                        isApproving = false
                    }
                } label: {
                    HStack {
                        if isApproving {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(pending.type.isDestructive ? "Delete" : "Approve")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(pending.type.isDestructive ? .red : .accentColor)
                .disabled(isApproving)
            }
        }
        .padding()
        .background(pending.type.isDestructive ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct ClaudeAction: Codable {
    let type: String
    let query: String?
    let filter: String?
    let foodIDs: [String]?
    let changes: [String: String]?
}

// MARK: - Quick Actions

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let icon: String
}

struct QuickActionsBar: View {
    let actions: [QuickAction]
    let onAction: (QuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Continue:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(actions) { action in
                    Button {
                        onAction(action)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.title)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct UserMessageView: View {
    let content: String

    var body: some View {
        HStack {
            Spacer()
            Text(content)
                .padding(12)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }
}

struct AssistantMessageView: View {
    let content: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(content))
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AlgoliaService.shared)
        .environmentObject(ClaudeService.shared)
        .environmentObject(ReviewManager.shared)
}
