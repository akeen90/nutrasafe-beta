import SwiftUI

struct UseBySearchSheet: View {
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
                // Go straight to the UseBy expiry form (not the diary-style food page)
                AddFoundFoodToUseBySheet(food: selectedFood)
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
            print("UseBy search error: \(error)")
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

struct AddFoundFoodToUseBySheet: View {
    @Environment(\.dismiss) var dismiss
    let food: FoodSearchResult
    @State private var quantity: String = "1"
    @State private var location: String = "UseBy"
    @State private var expiryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var showPhotoActionSheet = false
    @State private var showCameraPicker = false
    @State private var showPhotoPicker = false
    @State private var capturedImage: UIImage?
    @State private var uploadedImageURL: String?
    @State private var isUploadingPhoto = false
    private let locations = ["UseBy", "Freezer", "Pantry", "Cupboard", "Counter"]

    var body: some View {
        NavigationView {
            Form {
                // Improved Item Card
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        // Item image or placeholder
                        if let image = capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                            }
                        }

                        VStack(spacing: 4) {
                            Text(food.name)
                                .font(.system(size: 18, weight: .semibold))
                                .multilineTextAlignment(.center)

                            if let brand = food.brand {
                                Text(brand)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            if let serving = food.servingDescription {
                                Text(serving)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section(header: Text("Photo")) {
                    Button(action: { showPhotoActionSheet = true }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                            Text(capturedImage != nil || uploadedImageURL != nil ? "Change Photo" : "Add Photo")
                                .foregroundColor(.blue)
                            Spacer()
                            if isUploadingPhoto {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isUploadingPhoto)
                }

                Section(header: Text("Details")) {
                    TextField("Quantity", text: $quantity).keyboardType(.default)
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add to Use By")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: { isSaving ? AnyView(ProgressView()) : AnyView(Text("Add")) }
                    .disabled(isSaving)
                }
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoActionSheet) {
                Button("Take Photo") {
                    showCameraPicker = true
                }
                Button("Choose from Library") {
                    showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(selectedImage: nil, sourceType: .camera) { image in
                    showCameraPicker = false
                    if let image = image {
                        capturedImage = image
                        Task {
                            await uploadPhoto(image)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoLibraryPicker { image in
                    showPhotoPicker = false
                    if let image = image {
                        capturedImage = image
                        Task {
                            await uploadPhoto(image)
                        }
                    }
                }
            }
        }
    }

    private func uploadPhoto(_ image: UIImage) async {
        isUploadingPhoto = true
        do {
            let url = try await FirebaseManager.shared.uploadUseByItemPhoto(image)
            await MainActor.run {
                uploadedImageURL = url
                isUploadingPhoto = false
            }
        } catch {
            print("❌ Failed to upload photo: \(error)")
            await MainActor.run {
                isUploadingPhoto = false
            }
        }
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        let item = UseByInventoryItem(
            name: food.name,
            brand: food.brand,
            quantity: quantity.isEmpty ? "1" : quantity,
            location: location,
            expiryDate: expiryDate,
            addedDate: Date(),
            barcode: nil,
            category: nil,
            imageURL: uploadedImageURL
        )
        do {
            try await FirebaseManager.shared.addUseByItem(item)
            await MainActor.run { dismiss() }
        } catch {
            let ns = error as NSError
            print("Failed to save useBy item: \(ns)\nAttempting dev anonymous sign-in if enabled…")
            if ns.domain == "NutraSafeAuth", AppConfig.Features.allowAnonymousAuth {
                do {
                    try await FirebaseManager.shared.signInAnonymously()
                    try await FirebaseManager.shared.addUseByItem(item)
                    await MainActor.run { dismiss() }
                    return
                } catch {
                    // fall through to final error handling
                }
            }
            let finalError = error as NSError
            print("Final error saving useBy item: \(finalError)")
            await MainActor.run {
                // Silently fail for permission errors - just close the sheet
                if finalError.domain == "FIRFirestoreErrorDomain" && finalError.code == 7 {
                    // Missing permissions - post notifications and dismiss without error
                    NotificationCenter.default.post(name: .useByInventoryUpdated, object: nil)
                    NotificationCenter.default.post(name: .navigateToUseBy, object: nil)
                    dismiss()
                } else {
                    isSaving = false
                }
            }
        }
    }
}
