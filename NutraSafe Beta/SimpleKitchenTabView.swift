//
//  SimpleKitchenTabView.swift
//  NutraSafe Beta
//
//  Simplified kitchen view for basic functionality
//

import SwiftUI

struct SimpleKitchenTabView: View {
    @Binding var showingSettings: Bool
    @Binding var selectedTab: TabItem
    @State private var showingAddItem = false
    @State private var showingScanner = false
    @State private var inventoryItems: [KitchenInventoryItem] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                HStack {
                    Text("Smart Kitchen")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                // Quick Actions
                HStack(spacing: 12) {
                    Button("Add Item") {
                        showingAddItem = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Scan Barcode") {
                        showingScanner = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                // Inventory List
                if inventoryItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "house")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Your Kitchen is Empty")
                            .font(.title2)
                            .bold()
                        
                        Text("Add items to track expiry dates and manage your food inventory")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(inventoryItems) { item in
                            KitchenItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                
                Spacer()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAddItem) {
            AddKitchenItemView { item in
                inventoryItems.append(item)
            }
        }
        .sheet(isPresented: $showingScanner) {
            Text("Barcode Scanner Coming Soon")
        }
        .onAppear {
            loadInventoryItems()
        }
    }
    
    private func loadInventoryItems() {
        // Load from UserDefaults or use sample data
        inventoryItems = getSampleInventoryItems()
    }
    
    private func deleteItems(offsets: IndexSet) {
        inventoryItems.remove(atOffsets: offsets)
        saveInventoryItems()
    }
    
    private func saveInventoryItems() {
        // Save to UserDefaults
        if let data = try? JSONEncoder().encode(inventoryItems) {
            UserDefaults.standard.set(data, forKey: "kitchenInventory")
        }
    }
    
    private func getSampleInventoryItems() -> [KitchenInventoryItem] {
        return [
            KitchenInventoryItem(
                name: "Milk",
                brand: "Organic Valley",
                quantity: "1 gallon",
                expiryDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                addedDate: Date(),
                category: "Dairy"
            ),
            KitchenInventoryItem(
                name: "Bread",
                brand: "Dave's Killer Bread",
                quantity: "1 loaf",
                expiryDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                addedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
                category: "Bakery"
            ),
            KitchenInventoryItem(
                name: "Bananas",
                quantity: "6 pieces",
                expiryDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                addedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                category: "Produce"
            )
        ]
    }
}

struct KitchenItemRow: View {
    let item: KitchenInventoryItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(item.quantity)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.expiryDate.formatted(.dateTime.day().month()))
                    .font(.subheadline)
                    .bold()
                
                Text(item.expiryStatus.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.expiryStatus.color.opacity(0.2))
                    .foregroundColor(item.expiryStatus.color)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddKitchenItemView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (KitchenInventoryItem) -> Void
    
    @State private var name = ""
    @State private var brand = ""
    @State private var quantity = ""
    @State private var expiryDate = Date()
    @State private var category = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    TextField("Quantity", text: $quantity)
                    TextField("Category (optional)", text: $category)
                }
                
                Section("Expiry Information") {
                    DatePicker("Expiry Date", selection: $expiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let item = KitchenInventoryItem(
                            name: name,
                            brand: brand.isEmpty ? nil : brand,
                            quantity: quantity,
                            expiryDate: expiryDate,
                            addedDate: Date(),
                            category: category.isEmpty ? nil : category
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty || quantity.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SimpleKitchenTabView(showingSettings: .constant(false), selectedTab: .constant(.kitchen))
}