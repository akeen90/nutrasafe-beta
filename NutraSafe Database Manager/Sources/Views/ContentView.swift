//
//  ContentView.swift
//  NutraSafe Database Manager
//
//  Main content view with sidebar navigation
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
            FoodListView()
        } detail: {
            if let food = appState.currentFood {
                FoodDetailView(food: Binding(
                    get: { food },
                    set: { appState.currentFood = $0 }
                ))
            } else {
                EmptyDetailView()
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
            ClaudeChatSheet()
        }
        .alert("Delete Foods", isPresented: $appState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletedSelectedFoods()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(appState.selectedFoodIDs.count) food(s)? This cannot be undone.")
        }
        .onAppear {
            if !algoliaService.isConfigured {
                // Show settings if not configured
            }
        }
    }

    private func deletedSelectedFoods() async {
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

    var body: some View {
        List(selection: $appState.selectedDatabase) {
            Section("Databases") {
                ForEach(DatabaseType.allCases) { database in
                    NavigationLink(value: database) {
                        Label(database.displayName, systemImage: database.icon)
                    }
                }
            }

            Section("Statistics") {
                HStack {
                    Text("Total Records")
                    Spacer()
                    Text("\(algoliaService.totalHits)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Selected")
                    Spacer()
                    Text("\(appState.selectedFoodIDs.count)")
                        .foregroundColor(.secondary)
                }
            }

            Section("Quick Actions") {
                Button {
                    appState.showingClaudeSheet = true
                } label: {
                    Label("Ask Claude", systemImage: "sparkles")
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
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        .onChange(of: appState.selectedDatabase) { _, newValue in
            Task {
                await algoliaService.searchFoods(query: "", database: newValue)
            }
        }
    }
}

// MARK: - Food List View

struct FoodListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var algoliaService: AlgoliaService

    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .name
    @State private var showFilters = false

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case calories = "Calories"
        case brand = "Brand"
        case dateAdded = "Date Added"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search foods...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await algoliaService.searchFoods(query: searchText, database: appState.selectedDatabase)
                        }
                    }

                if !searchText.isEmpty {
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

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)

                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Selection toolbar
            if !appState.selectedFoodIDs.isEmpty {
                SelectionToolbar()
            }

            // Food list
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedFoods) { food in
                            FoodRowView(food: food)
                                .onTapGesture {
                                    appState.currentFood = food
                                }
                                .onAppear {
                                    // Load more when reaching the end
                                    if food.id == sortedFoods.last?.id && algoliaService.hasMorePages {
                                        Task {
                                            await algoliaService.loadMoreFoods(query: searchText, database: appState.selectedDatabase)
                                        }
                                    }
                                }
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

                Text("\(algoliaService.foods.count) of \(algoliaService.totalHits) foods")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

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
        .navigationSplitViewColumnWidth(min: 350, ideal: 400, max: 600)
        .task {
            if algoliaService.foods.isEmpty {
                await algoliaService.searchFoods(query: "", database: appState.selectedDatabase)
            }
            appState.loadedFoods = algoliaService.foods
        }
        .onChange(of: algoliaService.foods) { _, newFoods in
            appState.loadedFoods = newFoods
        }
    }

    private var sortedFoods: [FoodItem] {
        switch sortOrder {
        case .name:
            return algoliaService.foods.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .calories:
            return algoliaService.foods.sorted { $0.calories > $1.calories }
        case .brand:
            return algoliaService.foods.sorted { ($0.brand ?? "").localizedCaseInsensitiveCompare($1.brand ?? "") == .orderedAscending }
        case .dateAdded:
            return algoliaService.foods // Keep original order (most recent from Algolia)
        }
    }
}

// MARK: - Food Row View

struct FoodRowView: View {
    @EnvironmentObject var appState: AppState
    let food: FoodItem

    var isSelected: Bool {
        appState.selectedFoodIDs.contains(food.objectID)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Selection checkbox
            Button {
                appState.toggleSelection(for: food.objectID)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)

            // Food image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .frame(width: 50, height: 50)
                .overlay {
                    if let imageURL = food.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.secondary)
                    }
                }

            // Food info
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if food.isVerified == true {
                        Label("Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }

                    if let grade = food.processingGrade {
                        Text(grade)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradeColor(grade).opacity(0.2))
                            .foregroundColor(gradeColor(grade))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            // Nutrition summary
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(food.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    NutrientBadge(label: "P", value: food.protein, color: .blue)
                    NutrientBadge(label: "C", value: food.carbs, color: .orange)
                    NutrientBadge(label: "F", value: food.fat, color: .yellow)
                }
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
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

struct NutrientBadge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(color)
            Text("\(Int(value))g")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Selection Toolbar

struct SelectionToolbar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Text("\(appState.selectedFoodIDs.count) selected")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

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
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AlgoliaService.shared)
        .environmentObject(ClaudeService.shared)
}
