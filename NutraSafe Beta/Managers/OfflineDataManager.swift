//
//  OfflineDataManager.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Manages offline-first storage for all user-generated data
//  Pattern: Write locally first, then sync to Firebase in background
//

import Foundation
import SQLite3

// MARK: - Sync Status

/// Tracks the sync status of each record
enum SyncStatus: String, Codable {
    case synced = "synced"           // Successfully synced with Firebase
    case pending = "pending"         // Waiting to be synced
    case failed = "failed"           // Sync failed, will retry
    case deleted = "deleted"         // Marked for deletion on server
}

/// Represents a pending sync operation
struct PendingSyncOperation: Codable {
    let id: String
    let type: SyncOperationType
    let collection: String  // e.g., "foodEntries", "useByInventory", "weightHistory"
    let documentId: String
    let data: Data?  // JSON-encoded data for add/update operations
    let timestamp: Date
    var retryCount: Int

    init(type: SyncOperationType, collection: String, documentId: String, data: Data? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.collection = collection
        self.documentId = documentId
        self.data = data
        self.timestamp = Date()
        self.retryCount = 0
    }
}

enum SyncOperationType: String, Codable {
    case add = "add"
    case update = "update"
    case delete = "delete"
}

/// Represents a sync operation that failed after max retries
struct FailedSyncOperation: Identifiable {
    let id: String
    let type: SyncOperationType
    let collection: String
    let documentId: String
    let timestamp: Date
    let failedAt: Date
    let errorMessage: String?
    let retryCount: Int

    /// Human-readable description of what this operation was trying to do
    var description: String {
        let action: String
        switch type {
        case .add: action = "Add"
        case .update: action = "Update"
        case .delete: action = "Delete"
        }

        let target: String
        switch collection {
        case "foodEntries": target = "food diary entry"
        case "useByInventory": target = "use-by item"
        case "weightHistory": target = "weight entry"
        case "fastingSessions": target = "fasting session"
        case "fastingPlans": target = "fasting plan"
        case "reactionLogs": target = "reaction log"
        case "favoriteFoods": target = "favorite food"
        case "settings": target = "settings"
        default: target = collection
        }

        return "\(action) \(target)"
    }
}

// MARK: - Offline Data Manager

/// Manages offline-first storage for all user-generated data
/// Data is stored locally first, then synced to Firebase in background
final class OfflineDataManager {

    // MARK: - Singleton

    static let shared = OfflineDataManager()

    // MARK: - Properties

    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.nutrasafe.offlinedb", qos: .userInitiated)
    private var isInitialized = false

    /// Path to writable database in Documents directory
    /// Falls back to temp directory if Documents is unavailable (should never happen on iOS)
    private var databasePath: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return documentsPath.appendingPathComponent("nutrasafe_user_data.sqlite")
    }

    // MARK: - Initialization

    private init() {}

    /// Initialize the database and create tables
    func initialize() {
        dbQueue.sync {
            guard !isInitialized else { return }

            // Open database (creates if doesn't exist)
            if sqlite3_open(databasePath.path, &db) != SQLITE_OK {
                print("[OfflineDataManager] Failed to open database: \(String(cString: sqlite3_errmsg(db)))")
                return
            }

            // Enable WAL mode for better concurrent access
            executeSQL("PRAGMA journal_mode = WAL")

            // Create all tables
            createTables()

            isInitialized = true
            print("[OfflineDataManager] Initialized successfully at: \(databasePath.path)")
        }
    }

    // MARK: - Table Creation

    private func createTables() {
        // Sync queue table - tracks pending operations
        executeSQL("""
            CREATE TABLE IF NOT EXISTS sync_queue (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                collection TEXT NOT NULL,
                document_id TEXT NOT NULL,
                data BLOB,
                timestamp REAL NOT NULL,
                retry_count INTEGER DEFAULT 0
            )
        """)

        // Food entries table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS food_entries (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                food_name TEXT NOT NULL,
                brand_name TEXT,
                serving_size REAL NOT NULL,
                serving_unit TEXT NOT NULL,
                calories REAL NOT NULL,
                protein REAL NOT NULL,
                carbohydrates REAL NOT NULL,
                fat REAL NOT NULL,
                fiber REAL,
                sugar REAL,
                sodium REAL,
                calcium REAL,
                ingredients TEXT,
                additives TEXT,
                barcode TEXT,
                micronutrient_profile TEXT,
                is_per_unit INTEGER DEFAULT 0,
                image_url TEXT,
                portions TEXT,
                meal_type TEXT NOT NULL,
                date REAL NOT NULL,
                date_logged REAL NOT NULL,
                inferred_ingredients TEXT,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Create indices for food entries
        executeSQL("CREATE INDEX IF NOT EXISTS idx_food_entries_date ON food_entries(date)")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_food_entries_user ON food_entries(user_id)")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_food_entries_sync ON food_entries(sync_status)")

        // Use By inventory table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS use_by_items (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                brand TEXT,
                quantity TEXT NOT NULL,
                expiry_date REAL NOT NULL,
                added_date REAL NOT NULL,
                barcode TEXT,
                category TEXT,
                image_url TEXT,
                notes TEXT,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Create indices for use by items
        executeSQL("CREATE INDEX IF NOT EXISTS idx_use_by_expiry ON use_by_items(expiry_date)")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_use_by_sync ON use_by_items(sync_status)")

        // Weight entries table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS weight_entries (
                id TEXT PRIMARY KEY,
                weight REAL NOT NULL,
                date REAL NOT NULL,
                bmi REAL,
                note TEXT,
                photo_url TEXT,
                photo_urls TEXT,
                waist_size REAL,
                dress_size TEXT,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Create indices for weight entries
        executeSQL("CREATE INDEX IF NOT EXISTS idx_weight_date ON weight_entries(date)")
        executeSQL("CREATE INDEX IF NOT EXISTS idx_weight_sync ON weight_entries(sync_status)")

        // User settings table (single row per user)
        executeSQL("""
            CREATE TABLE IF NOT EXISTS user_settings (
                id TEXT PRIMARY KEY DEFAULT 'current',
                height REAL,
                goal_weight REAL,
                caloric_goal INTEGER,
                exercise_goal INTEGER,
                step_goal INTEGER,
                protein_percent INTEGER,
                carbs_percent INTEGER,
                fat_percent INTEGER,
                allergens TEXT,
                macro_goals TEXT,
                diet_type TEXT,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Favorite foods table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS favorite_foods (
                id TEXT PRIMARY KEY,
                food_data TEXT NOT NULL,
                added_date REAL NOT NULL,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        executeSQL("CREATE INDEX IF NOT EXISTS idx_favorites_sync ON favorite_foods(sync_status)")

        // Fasting plans table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS fasting_plans (
                id TEXT PRIMARY KEY,
                plan_data TEXT NOT NULL,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Fasting sessions table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS fasting_sessions (
                id TEXT PRIMARY KEY,
                session_data TEXT NOT NULL,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        // Reaction logs table
        executeSQL("""
            CREATE TABLE IF NOT EXISTS reaction_logs (
                id TEXT PRIMARY KEY,
                log_data TEXT NOT NULL,
                sync_status TEXT DEFAULT 'pending',
                last_modified REAL NOT NULL
            )
        """)

        executeSQL("CREATE INDEX IF NOT EXISTS idx_reactions_sync ON reaction_logs(sync_status)")

        // Sync state table - tracks last successful sync per collection
        executeSQL("""
            CREATE TABLE IF NOT EXISTS sync_state (
                collection TEXT PRIMARY KEY,
                last_sync_timestamp REAL,
                server_version TEXT
            )
        """)

        // Failed operations table - tracks operations that exceeded max retries
        // These require user attention to resolve
        executeSQL("""
            CREATE TABLE IF NOT EXISTS failed_operations (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                collection TEXT NOT NULL,
                document_id TEXT NOT NULL,
                data BLOB,
                timestamp REAL NOT NULL,
                failed_at REAL NOT NULL,
                error_message TEXT,
                retry_count INTEGER DEFAULT 0
            )
        """)

        executeSQL("CREATE INDEX IF NOT EXISTS idx_failed_ops_collection ON failed_operations(collection)")

        print("[OfflineDataManager] Tables created successfully")
    }

    // MARK: - SQL Execution Helpers

    @discardableResult
    private func executeSQL(_ sql: String) -> Bool {
        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)

        if result != SQLITE_OK {
            if let error = errorMessage {
                print("[OfflineDataManager] SQL Error: \(String(cString: error))")
                sqlite3_free(errorMessage)
            }
            return false
        }
        return true
    }

    // MARK: - Food Entry Operations

    /// Save a food entry locally (offline-first)
    func saveFoodEntry(_ entry: FoodEntry) {
        dbQueue.async {
            guard self.isInitialized else {
                print("[OfflineDataManager] Not initialized")
                return
            }

            let sql = """
                INSERT OR REPLACE INTO food_entries (
                    id, user_id, food_name, brand_name, serving_size, serving_unit,
                    calories, protein, carbohydrates, fat, fiber, sugar, sodium, calcium,
                    ingredients, additives, barcode, micronutrient_profile, is_per_unit,
                    image_url, portions, meal_type, date, date_logged, inferred_ingredients,
                    sync_status, last_modified
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                // Bind all parameters
                sqlite3_bind_text(statement, 1, entry.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, entry.userId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 3, entry.foodName, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if let brand = entry.brandName {
                    sqlite3_bind_text(statement, 4, brand, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 4)
                }

                sqlite3_bind_double(statement, 5, entry.servingSize)
                sqlite3_bind_text(statement, 6, entry.servingUnit, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 7, entry.calories)
                sqlite3_bind_double(statement, 8, entry.protein)
                sqlite3_bind_double(statement, 9, entry.carbohydrates)
                sqlite3_bind_double(statement, 10, entry.fat)

                if let fiber = entry.fiber {
                    sqlite3_bind_double(statement, 11, fiber)
                } else {
                    sqlite3_bind_null(statement, 11)
                }

                if let sugar = entry.sugar {
                    sqlite3_bind_double(statement, 12, sugar)
                } else {
                    sqlite3_bind_null(statement, 12)
                }

                if let sodium = entry.sodium {
                    sqlite3_bind_double(statement, 13, sodium)
                } else {
                    sqlite3_bind_null(statement, 13)
                }

                if let calcium = entry.calcium {
                    sqlite3_bind_double(statement, 14, calcium)
                } else {
                    sqlite3_bind_null(statement, 14)
                }

                // Encode arrays as JSON
                if let ingredients = entry.ingredients, let data = try? JSONEncoder().encode(ingredients) {
                    sqlite3_bind_text(statement, 15, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 15)
                }

                if let additives = entry.additives, let data = try? JSONEncoder().encode(additives) {
                    sqlite3_bind_text(statement, 16, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 16)
                }

                if let barcode = entry.barcode {
                    sqlite3_bind_text(statement, 17, barcode, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 17)
                }

                if let profile = entry.micronutrientProfile, let data = try? JSONEncoder().encode(profile) {
                    sqlite3_bind_text(statement, 18, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 18)
                }

                sqlite3_bind_int(statement, 19, (entry.isPerUnit ?? false) ? 1 : 0)

                if let imageUrl = entry.imageUrl {
                    sqlite3_bind_text(statement, 20, imageUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 20)
                }

                if let portions = entry.portions, let data = try? JSONEncoder().encode(portions) {
                    sqlite3_bind_text(statement, 21, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 21)
                }

                sqlite3_bind_text(statement, 22, entry.mealType.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 23, entry.date.timeIntervalSince1970)
                sqlite3_bind_double(statement, 24, entry.dateLogged.timeIntervalSince1970)

                if let inferred = entry.inferredIngredients, let data = try? JSONEncoder().encode(inferred) {
                    sqlite3_bind_text(statement, 25, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 25)
                }

                sqlite3_bind_double(statement, 26, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save food entry: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                // Add to sync queue
                self.addToSyncQueue(type: .add, collection: "foodEntries", documentId: entry.id, data: entry)
            }
        }
    }

    /// Get food entries for a specific date
    func getFoodEntries(for date: Date, userId: String) -> [FoodEntry] {
        var entries: [FoodEntry] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            let sql = """
                SELECT * FROM food_entries
                WHERE user_id = ? AND date >= ? AND date < ? AND sync_status != 'deleted'
                ORDER BY date_logged ASC
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, userId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 2, startOfDay.timeIntervalSince1970)
                sqlite3_bind_double(statement, 3, endOfDay.timeIntervalSince1970)

                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = self.parseFoodEntryRow(statement) {
                        entries.append(entry)
                    }
                }

                sqlite3_finalize(statement)
            }
        }

        return entries
    }

    /// Delete a food entry locally
    func deleteFoodEntry(entryId: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            // Mark as deleted (soft delete for sync purposes)
            let sql = "UPDATE food_entries SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, entryId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete food entry: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                // Add delete operation to sync queue
                self.addToSyncQueueRaw(type: .delete, collection: "foodEntries", documentId: entryId)
            }
        }
    }

    private func parseFoodEntryRow(_ statement: OpaquePointer?) -> FoodEntry? {
        guard let statement = statement else { return nil }

        let id = String(cString: sqlite3_column_text(statement, 0))
        let userId = String(cString: sqlite3_column_text(statement, 1))
        let foodName = String(cString: sqlite3_column_text(statement, 2))
        let brandName: String? = sqlite3_column_type(statement, 3) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 3)) : nil
        let servingSize = sqlite3_column_double(statement, 4)
        let servingUnit = String(cString: sqlite3_column_text(statement, 5))
        let calories = sqlite3_column_double(statement, 6)
        let protein = sqlite3_column_double(statement, 7)
        let carbs = sqlite3_column_double(statement, 8)
        let fat = sqlite3_column_double(statement, 9)
        let fiber: Double? = sqlite3_column_type(statement, 10) != SQLITE_NULL ? sqlite3_column_double(statement, 10) : nil
        let sugar: Double? = sqlite3_column_type(statement, 11) != SQLITE_NULL ? sqlite3_column_double(statement, 11) : nil
        let sodium: Double? = sqlite3_column_type(statement, 12) != SQLITE_NULL ? sqlite3_column_double(statement, 12) : nil
        let calcium: Double? = sqlite3_column_type(statement, 13) != SQLITE_NULL ? sqlite3_column_double(statement, 13) : nil

        // Decode JSON fields
        var ingredients: [String]?
        if sqlite3_column_type(statement, 14) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 14))
            if let jsonData = json.data(using: .utf8) {
                ingredients = try? JSONDecoder().decode([String].self, from: jsonData)
            }
        }

        var additives: [NutritionAdditiveInfo]?
        if sqlite3_column_type(statement, 15) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 15))
            if let jsonData = json.data(using: .utf8) {
                additives = try? JSONDecoder().decode([NutritionAdditiveInfo].self, from: jsonData)
            }
        }

        let barcode: String? = sqlite3_column_type(statement, 16) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 16)) : nil

        var micronutrientProfile: MicronutrientProfile?
        if sqlite3_column_type(statement, 17) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 17))
            if let jsonData = json.data(using: .utf8) {
                micronutrientProfile = try? JSONDecoder().decode(MicronutrientProfile.self, from: jsonData)
            }
        }

        let isPerUnit = sqlite3_column_int(statement, 18) == 1
        let imageUrl: String? = sqlite3_column_type(statement, 19) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 19)) : nil

        var portions: [PortionOption]?
        if sqlite3_column_type(statement, 20) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 20))
            if let jsonData = json.data(using: .utf8) {
                portions = try? JSONDecoder().decode([PortionOption].self, from: jsonData)
            }
        }

        let mealTypeRaw = String(cString: sqlite3_column_text(statement, 21))
        let mealType = MealType(rawValue: mealTypeRaw) ?? .snacks

        let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 22))
        let dateLogged = Date(timeIntervalSince1970: sqlite3_column_double(statement, 23))

        var inferredIngredients: [InferredIngredient]?
        if sqlite3_column_type(statement, 24) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 24))
            if let jsonData = json.data(using: .utf8) {
                inferredIngredients = try? JSONDecoder().decode([InferredIngredient].self, from: jsonData)
            }
        }

        return FoodEntry(
            id: id,
            userId: userId,
            foodName: foodName,
            brandName: brandName,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            calcium: calcium,
            ingredients: ingredients,
            additives: additives,
            barcode: barcode,
            micronutrientProfile: micronutrientProfile,
            isPerUnit: isPerUnit,
            imageUrl: imageUrl,
            portions: portions,
            mealType: mealType,
            date: date,
            dateLogged: dateLogged,
            inferredIngredients: inferredIngredients
        )
    }

    // MARK: - Use By Item Operations

    /// Save a Use By item locally (offline-first)
    func saveUseByItem(_ item: UseByInventoryItem) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = """
                INSERT OR REPLACE INTO use_by_items (
                    id, name, brand, quantity, expiry_date, added_date,
                    barcode, category, image_url, notes, sync_status, last_modified
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, item.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, item.name, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if let brand = item.brand {
                    sqlite3_bind_text(statement, 3, brand, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 3)
                }

                sqlite3_bind_text(statement, 4, item.quantity, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 5, item.expiryDate.timeIntervalSince1970)
                sqlite3_bind_double(statement, 6, item.addedDate.timeIntervalSince1970)

                if let barcode = item.barcode {
                    sqlite3_bind_text(statement, 7, barcode, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 7)
                }

                if let category = item.category {
                    sqlite3_bind_text(statement, 8, category, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 8)
                }

                if let imageUrl = item.imageURL {
                    sqlite3_bind_text(statement, 9, imageUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 9)
                }

                if let notes = item.notes {
                    sqlite3_bind_text(statement, 10, notes, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 10)
                }

                sqlite3_bind_double(statement, 11, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save use by item: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                // Add to sync queue
                self.addToSyncQueue(type: .add, collection: "useByInventory", documentId: item.id, data: item)
            }
        }
    }

    /// Get all Use By items
    func getUseByItems() -> [UseByInventoryItem] {
        var items: [UseByInventoryItem] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT * FROM use_by_items WHERE sync_status != 'deleted' ORDER BY expiry_date ASC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let item = self.parseUseByItemRow(statement) {
                        items.append(item)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return items
    }

    /// Delete a Use By item locally
    func deleteUseByItem(itemId: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE use_by_items SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, itemId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete use by item: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "useByInventory", documentId: itemId)
            }
        }
    }

    private func parseUseByItemRow(_ statement: OpaquePointer?) -> UseByInventoryItem? {
        guard let statement = statement else { return nil }

        let id = String(cString: sqlite3_column_text(statement, 0))
        let name = String(cString: sqlite3_column_text(statement, 1))
        let brand: String? = sqlite3_column_type(statement, 2) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 2)) : nil
        let quantity = String(cString: sqlite3_column_text(statement, 3))
        let expiryDate = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
        let addedDate = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
        let barcode: String? = sqlite3_column_type(statement, 6) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 6)) : nil
        let category: String? = sqlite3_column_type(statement, 7) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 7)) : nil
        let imageUrl: String? = sqlite3_column_type(statement, 8) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 8)) : nil
        let notes: String? = sqlite3_column_type(statement, 9) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 9)) : nil

        return UseByInventoryItem(
            id: id,
            name: name,
            brand: brand,
            quantity: quantity,
            expiryDate: expiryDate,
            addedDate: addedDate,
            barcode: barcode,
            category: category,
            imageURL: imageUrl,
            notes: notes
        )
    }

    // MARK: - Weight Entry Operations

    /// Save a weight entry locally (offline-first)
    func saveWeightEntry(_ entry: WeightEntry) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = """
                INSERT OR REPLACE INTO weight_entries (
                    id, weight, date, bmi, note, photo_url, photo_urls, waist_size, dress_size, sync_status, last_modified
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 2, entry.weight)
                sqlite3_bind_double(statement, 3, entry.date.timeIntervalSince1970)

                if let bmi = entry.bmi {
                    sqlite3_bind_double(statement, 4, bmi)
                } else {
                    sqlite3_bind_null(statement, 4)
                }

                if let note = entry.note {
                    sqlite3_bind_text(statement, 5, note, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 5)
                }

                if let photoUrl = entry.photoURL {
                    sqlite3_bind_text(statement, 6, photoUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 6)
                }

                if let photoUrls = entry.photoURLs, let data = try? JSONEncoder().encode(photoUrls) {
                    sqlite3_bind_text(statement, 7, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 7)
                }

                if let waistSize = entry.waistSize {
                    sqlite3_bind_double(statement, 8, waistSize)
                } else {
                    sqlite3_bind_null(statement, 8)
                }

                if let dressSize = entry.dressSize {
                    sqlite3_bind_text(statement, 9, dressSize, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 9)
                }

                sqlite3_bind_double(statement, 10, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save weight entry: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueue(type: .add, collection: "weightHistory", documentId: entry.id.uuidString, data: entry)
            }
        }
    }

    /// Get weight history
    func getWeightHistory() -> [WeightEntry] {
        var entries: [WeightEntry] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT * FROM weight_entries WHERE sync_status != 'deleted' ORDER BY date DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let entry = self.parseWeightEntryRow(statement) {
                        entries.append(entry)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return entries
    }

    /// Delete a weight entry locally
    func deleteWeightEntry(id: UUID) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE weight_entries SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete weight entry: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "weightHistory", documentId: id.uuidString)
            }
        }
    }

    private func parseWeightEntryRow(_ statement: OpaquePointer?) -> WeightEntry? {
        guard let statement = statement else { return nil }

        let idString = String(cString: sqlite3_column_text(statement, 0))
        guard let id = UUID(uuidString: idString) else { return nil }

        let weight = sqlite3_column_double(statement, 1)
        let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
        let bmi: Double? = sqlite3_column_type(statement, 3) != SQLITE_NULL ? sqlite3_column_double(statement, 3) : nil
        let note: String? = sqlite3_column_type(statement, 4) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 4)) : nil
        let photoUrl: String? = sqlite3_column_type(statement, 5) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 5)) : nil

        var photoUrls: [String]?
        if sqlite3_column_type(statement, 6) != SQLITE_NULL {
            let json = String(cString: sqlite3_column_text(statement, 6))
            if let jsonData = json.data(using: .utf8) {
                photoUrls = try? JSONDecoder().decode([String].self, from: jsonData)
            }
        }

        let waistSize: Double? = sqlite3_column_type(statement, 7) != SQLITE_NULL ? sqlite3_column_double(statement, 7) : nil
        let dressSize: String? = sqlite3_column_type(statement, 8) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 8)) : nil

        return WeightEntry(id: id, weight: weight, date: date, bmi: bmi, note: note, photoURL: photoUrl, photoURLs: photoUrls, waistSize: waistSize, dressSize: dressSize)
    }

    // MARK: - User Settings Operations

    /// Save user settings locally (offline-first)
    func saveUserSettings(
        height: Double?,
        goalWeight: Double?,
        caloricGoal: Int?,
        exerciseGoal: Int?,
        stepGoal: Int?,
        proteinPercent: Int?,
        carbsPercent: Int?,
        fatPercent: Int?,
        allergens: [Allergen]?
    ) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = """
                INSERT OR REPLACE INTO user_settings (
                    id, height, goal_weight, caloric_goal, exercise_goal, step_goal,
                    protein_percent, carbs_percent, fat_percent, allergens,
                    sync_status, last_modified
                ) VALUES ('current', ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                if let h = height { sqlite3_bind_double(statement, 1, h) } else { sqlite3_bind_null(statement, 1) }
                if let gw = goalWeight { sqlite3_bind_double(statement, 2, gw) } else { sqlite3_bind_null(statement, 2) }
                if let cg = caloricGoal { sqlite3_bind_int(statement, 3, Int32(cg)) } else { sqlite3_bind_null(statement, 3) }
                if let eg = exerciseGoal { sqlite3_bind_int(statement, 4, Int32(eg)) } else { sqlite3_bind_null(statement, 4) }
                if let sg = stepGoal { sqlite3_bind_int(statement, 5, Int32(sg)) } else { sqlite3_bind_null(statement, 5) }
                if let pp = proteinPercent { sqlite3_bind_int(statement, 6, Int32(pp)) } else { sqlite3_bind_null(statement, 6) }
                if let cp = carbsPercent { sqlite3_bind_int(statement, 7, Int32(cp)) } else { sqlite3_bind_null(statement, 7) }
                if let fp = fatPercent { sqlite3_bind_int(statement, 8, Int32(fp)) } else { sqlite3_bind_null(statement, 8) }

                if let allergens = allergens {
                    let allergenStrings = allergens.map { $0.rawValue }
                    if let data = try? JSONEncoder().encode(allergenStrings) {
                        sqlite3_bind_text(statement, 9, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else {
                        sqlite3_bind_null(statement, 9)
                    }
                } else {
                    sqlite3_bind_null(statement, 9)
                }

                sqlite3_bind_double(statement, 10, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save user settings: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                // Create settings dict for sync
                var settingsData: [String: Any] = [:]
                if let h = height { settingsData["height"] = h }
                if let gw = goalWeight { settingsData["goalWeight"] = gw }
                if let cg = caloricGoal { settingsData["caloricGoal"] = cg }
                if let eg = exerciseGoal { settingsData["exerciseGoal"] = eg }
                if let sg = stepGoal { settingsData["stepGoal"] = sg }
                if let pp = proteinPercent { settingsData["proteinPercent"] = pp }
                if let cp = carbsPercent { settingsData["carbsPercent"] = cp }
                if let fp = fatPercent { settingsData["fatPercent"] = fp }
                if let allergens = allergens { settingsData["allergens"] = allergens.map { $0.rawValue } }

                if let data = try? JSONSerialization.data(withJSONObject: settingsData) {
                    self.addToSyncQueueRaw(type: .update, collection: "settings", documentId: "preferences", data: data)
                }
            }
        }
    }

    /// Get user settings from local storage
    func getUserSettings() -> (height: Double?, goalWeight: Double?, caloricGoal: Int?, proteinPercent: Int?, carbsPercent: Int?, fatPercent: Int?, allergens: [Allergen]?, exerciseGoal: Int?, stepGoal: Int?) {
        var result: (height: Double?, goalWeight: Double?, caloricGoal: Int?, proteinPercent: Int?, carbsPercent: Int?, fatPercent: Int?, allergens: [Allergen]?, exerciseGoal: Int?, stepGoal: Int?) = (nil, nil, nil, nil, nil, nil, nil, nil, nil)

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT * FROM user_settings WHERE id = 'current'"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    result.height = sqlite3_column_type(statement, 1) != SQLITE_NULL ? sqlite3_column_double(statement, 1) : nil
                    result.goalWeight = sqlite3_column_type(statement, 2) != SQLITE_NULL ? sqlite3_column_double(statement, 2) : nil
                    result.caloricGoal = sqlite3_column_type(statement, 3) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 3)) : nil
                    result.exerciseGoal = sqlite3_column_type(statement, 4) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 4)) : nil
                    result.stepGoal = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil
                    result.proteinPercent = sqlite3_column_type(statement, 6) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 6)) : nil
                    result.carbsPercent = sqlite3_column_type(statement, 7) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 7)) : nil
                    result.fatPercent = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil

                    if sqlite3_column_type(statement, 9) != SQLITE_NULL {
                        let json = String(cString: sqlite3_column_text(statement, 9))
                        if let data = json.data(using: .utf8),
                           let allergenStrings = try? JSONDecoder().decode([String].self, from: data) {
                            result.allergens = allergenStrings.compactMap { Allergen(rawValue: $0) }
                        }
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return result
    }

    // MARK: - Fasting Session Operations

    /// Save a fasting session locally (offline-first)
    func saveFastingSession(_ session: FastingSession) {
        dbQueue.async {
            guard self.isInitialized else { return }

            guard let sessionData = try? JSONEncoder().encode(session) else {
                print("[OfflineDataManager] Failed to encode fasting session")
                return
            }

            let sessionId = session.id ?? UUID().uuidString

            let sql = """
                INSERT OR REPLACE INTO fasting_sessions (
                    id, session_data, sync_status, last_modified
                ) VALUES (?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, sessionId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, String(data: sessionData, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save fasting session: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .add, collection: "fastingSessions", documentId: sessionId, data: sessionData)
            }
        }
    }

    /// Get all fasting sessions
    func getFastingSessions() -> [FastingSession] {
        var sessions: [FastingSession] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT session_data FROM fasting_sessions WHERE sync_status != 'deleted' ORDER BY last_modified DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let json = String(cString: sqlite3_column_text(statement, 0))
                    if let data = json.data(using: .utf8),
                       let session = try? JSONDecoder().decode(FastingSession.self, from: data) {
                        sessions.append(session)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return sessions
    }

    /// Delete a fasting session locally
    func deleteFastingSession(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE fasting_sessions SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete fasting session: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "fastingSessions", documentId: id)
            }
        }
    }

    // MARK: - Fasting Plan Operations

    /// Save a fasting plan locally (offline-first)
    func saveFastingPlan(_ plan: FastingPlan) {
        dbQueue.async {
            guard self.isInitialized else { return }

            guard let planData = try? JSONEncoder().encode(plan) else {
                print("[OfflineDataManager] Failed to encode fasting plan")
                return
            }

            let planId = plan.id ?? UUID().uuidString

            let sql = """
                INSERT OR REPLACE INTO fasting_plans (
                    id, plan_data, sync_status, last_modified
                ) VALUES (?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, planId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, String(data: planData, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save fasting plan: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .add, collection: "fastingPlans", documentId: planId, data: planData)
            }
        }
    }

    /// Get all fasting plans
    func getFastingPlans() -> [FastingPlan] {
        var plans: [FastingPlan] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT plan_data FROM fasting_plans WHERE sync_status != 'deleted' ORDER BY last_modified DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let json = String(cString: sqlite3_column_text(statement, 0))
                    if let data = json.data(using: .utf8),
                       let plan = try? JSONDecoder().decode(FastingPlan.self, from: data) {
                        plans.append(plan)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return plans
    }

    /// Delete a fasting plan locally
    func deleteFastingPlan(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE fasting_plans SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete fasting plan: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "fastingPlans", documentId: id)
            }
        }
    }

    // MARK: - Reaction Log Operations

    /// Save a reaction log entry locally (offline-first)
    func saveReactionLog(_ entry: ReactionLogEntry) {
        dbQueue.async {
            guard self.isInitialized else { return }

            guard let logData = try? JSONEncoder().encode(entry) else {
                print("[OfflineDataManager] Failed to encode reaction log")
                return
            }

            let entryId = entry.id ?? UUID().uuidString

            let sql = """
                INSERT OR REPLACE INTO reaction_logs (
                    id, log_data, sync_status, last_modified
                ) VALUES (?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, entryId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, String(data: logData, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save reaction log: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .add, collection: "reactionLogs", documentId: entryId, data: logData)
            }
        }
    }

    /// Get all reaction logs
    func getReactionLogs() -> [ReactionLogEntry] {
        var logs: [ReactionLogEntry] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT log_data FROM reaction_logs WHERE sync_status != 'deleted' ORDER BY last_modified DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let json = String(cString: sqlite3_column_text(statement, 0))
                    if let data = json.data(using: .utf8),
                       let log = try? JSONDecoder().decode(ReactionLogEntry.self, from: data) {
                        logs.append(log)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return logs
    }

    /// Delete a reaction log entry locally
    func deleteReactionLog(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE reaction_logs SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete reaction log: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "reactionLogs", documentId: id)
            }
        }
    }

    // MARK: - Favorite Foods Operations

    /// Save a favorite food locally (offline-first)
    func saveFavoriteFood(_ food: FoodSearchResult) {
        dbQueue.async {
            guard self.isInitialized else { return }

            guard let foodData = try? JSONEncoder().encode(food) else {
                print("[OfflineDataManager] Failed to encode favorite food")
                return
            }

            let sql = """
                INSERT OR REPLACE INTO favorite_foods (
                    id, food_data, added_date, sync_status, last_modified
                ) VALUES (?, ?, ?, 'pending', ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                let now = Date().timeIntervalSince1970
                sqlite3_bind_text(statement, 1, food.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, String(data: foodData, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_double(statement, 3, now)
                sqlite3_bind_double(statement, 4, now)

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save favorite food: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .add, collection: "favoriteFoods", documentId: food.id, data: foodData)
            }
        }
    }

    /// Get all favorite foods
    func getFavoriteFoods() -> [FoodSearchResult] {
        var foods: [FoodSearchResult] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT food_data FROM favorite_foods WHERE sync_status != 'deleted' ORDER BY last_modified DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let json = String(cString: sqlite3_column_text(statement, 0))
                    if let data = json.data(using: .utf8),
                       let food = try? JSONDecoder().decode(FoodSearchResult.self, from: data) {
                        foods.append(food)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return foods
    }

    /// Delete a favorite food locally
    func deleteFavoriteFood(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE favorite_foods SET sync_status = 'deleted', last_modified = ? WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 2, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to delete favorite food: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)

                self.addToSyncQueueRaw(type: .delete, collection: "favoriteFoods", documentId: id)
            }
        }
    }

    /// Check if a food is favorited
    func isFavoriteFood(id: String) -> Bool {
        var isFavorite = false

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT COUNT(*) FROM favorite_foods WHERE id = ? AND sync_status != 'deleted'"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(statement) == SQLITE_ROW {
                    isFavorite = sqlite3_column_int(statement, 0) > 0
                }
                sqlite3_finalize(statement)
            }
        }

        return isFavorite
    }

    // MARK: - Sync Queue Operations

    private func addToSyncQueue<T: Encodable>(type: SyncOperationType, collection: String, documentId: String, data: T) {
        if let encodedData = try? JSONEncoder().encode(data) {
            addToSyncQueueRaw(type: type, collection: collection, documentId: documentId, data: encodedData)
        }
    }

    /// Add to sync queue - MUST be called from within dbQueue context
    /// All callers (save/delete methods) already execute within dbQueue.async blocks,
    /// so this method executes synchronously within that context for atomic transactions.
    private func addToSyncQueueRaw(type: SyncOperationType, collection: String, documentId: String, data: Data? = nil) {
        // Safety check - this should always be true since callers are in dbQueue.async
        guard isInitialized, db != nil else { return }

        let operation = PendingSyncOperation(type: type, collection: collection, documentId: documentId, data: data)

        let sql = """
            INSERT INTO sync_queue (id, type, collection, document_id, data, timestamp, retry_count)
            VALUES (?, ?, ?, ?, ?, ?, 0)
        """

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, operation.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text(statement, 2, operation.type.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text(statement, 3, operation.collection, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            sqlite3_bind_text(statement, 4, operation.documentId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

            if let data = operation.data {
                sqlite3_bind_blob(statement, 5, (data as NSData).bytes, Int32(data.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            } else {
                sqlite3_bind_null(statement, 5)
            }

            sqlite3_bind_double(statement, 6, operation.timestamp.timeIntervalSince1970)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("[OfflineDataManager] Failed to add to sync queue: \(String(cString: sqlite3_errmsg(db)))")
            }

            sqlite3_finalize(statement)
        }

        // Notify that there are pending operations (dispatch to main thread from dbQueue)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .offlineDataPendingSync, object: nil)
        }
    }

    /// Get all pending sync operations
    func getPendingSyncOperations() -> [PendingSyncOperation] {
        var operations: [PendingSyncOperation] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT * FROM sync_queue ORDER BY timestamp ASC LIMIT 100"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    // Read columns (id, timestamp, retryCount stored but not needed for operation)
                    _ = String(cString: sqlite3_column_text(statement, 0)) // id
                    let typeRaw = String(cString: sqlite3_column_text(statement, 1))
                    let collection = String(cString: sqlite3_column_text(statement, 2))
                    let documentId = String(cString: sqlite3_column_text(statement, 3))

                    var data: Data?
                    if sqlite3_column_type(statement, 4) != SQLITE_NULL {
                        let bytes = sqlite3_column_blob(statement, 4)
                        let length = sqlite3_column_bytes(statement, 4)
                        if let bytes = bytes {
                            data = Data(bytes: bytes, count: Int(length))
                        }
                    }

                    _ = sqlite3_column_double(statement, 5) // timestamp
                    _ = sqlite3_column_int(statement, 6) // retryCount

                    if let type = SyncOperationType(rawValue: typeRaw) {
                        let operation = PendingSyncOperation(type: type, collection: collection, documentId: documentId, data: data)
                        operations.append(operation)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return operations
    }

    /// Remove a sync operation after successful sync
    func removeSyncOperation(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "DELETE FROM sync_queue WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }

    /// Increment retry count for failed sync operation
    func incrementRetryCount(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }

    /// Mark a record as synced
    func markAsSynced(collection: String, documentId: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let tableName: String
            switch collection {
            case "foodEntries": tableName = "food_entries"
            case "useByInventory": tableName = "use_by_items"
            case "weightHistory": tableName = "weight_entries"
            case "settings": tableName = "user_settings"
            case "favoriteFoods": tableName = "favorite_foods"
            case "fastingPlans": tableName = "fasting_plans"
            case "fastingSessions": tableName = "fasting_sessions"
            case "reactionLogs": tableName = "reaction_logs"
            default: return
            }

            let sql = "UPDATE \(tableName) SET sync_status = 'synced' WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, documentId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }

    /// Permanently delete synced records marked as deleted
    func cleanupDeletedRecords() {
        dbQueue.async {
            guard self.isInitialized else { return }

            let tables = ["food_entries", "use_by_items", "weight_entries", "favorite_foods", "fasting_plans", "fasting_sessions", "reaction_logs"]

            for table in tables {
                let sql = "DELETE FROM \(table) WHERE sync_status = 'deleted'"
                self.executeSQL(sql)
            }
        }
    }

    /// Get count of pending sync operations
    func getPendingSyncCount() -> Int {
        var count = 0

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT COUNT(*) FROM sync_queue"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
                sqlite3_finalize(statement)
            }
        }

        return count
    }

    // MARK: - Failed Operations Management

    /// Move a failed operation to the failed_operations table for later retry
    func markOperationAsFailed(operation: PendingSyncOperation, error: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = """
                INSERT OR REPLACE INTO failed_operations (
                    id, type, collection, document_id, data, timestamp, failed_at, error_message, retry_count
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, operation.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 2, operation.type.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 3, operation.collection, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_text(statement, 4, operation.documentId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if let data = operation.data {
                    sqlite3_bind_blob(statement, 5, (data as NSData).bytes, Int32(data.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else {
                    sqlite3_bind_null(statement, 5)
                }

                sqlite3_bind_double(statement, 6, operation.timestamp.timeIntervalSince1970)
                sqlite3_bind_double(statement, 7, Date().timeIntervalSince1970)
                sqlite3_bind_text(statement, 8, error, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_bind_int(statement, 9, Int32(operation.retryCount))

                if sqlite3_step(statement) != SQLITE_DONE {
                    print("[OfflineDataManager] Failed to save failed operation: \(String(cString: sqlite3_errmsg(self.db)))")
                }

                sqlite3_finalize(statement)
            }
        }
    }

    /// Get count of failed operations
    func getFailedOperationsCount() -> Int {
        var count = 0

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT COUNT(*) FROM failed_operations"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                if sqlite3_step(statement) == SQLITE_ROW {
                    count = Int(sqlite3_column_int(statement, 0))
                }
                sqlite3_finalize(statement)
            }
        }

        return count
    }

    /// Get all failed operations for display to user
    func getFailedOperations() -> [FailedSyncOperation] {
        var operations: [FailedSyncOperation] = []

        dbQueue.sync {
            guard self.isInitialized else { return }

            let sql = "SELECT * FROM failed_operations ORDER BY failed_at DESC"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let typeRaw = String(cString: sqlite3_column_text(statement, 1))
                    let collection = String(cString: sqlite3_column_text(statement, 2))
                    let documentId = String(cString: sqlite3_column_text(statement, 3))
                    let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
                    let failedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 6))
                    let errorMessage: String? = sqlite3_column_type(statement, 7) != SQLITE_NULL
                        ? String(cString: sqlite3_column_text(statement, 7)) : nil
                    let retryCount = Int(sqlite3_column_int(statement, 8))

                    if let type = SyncOperationType(rawValue: typeRaw) {
                        let operation = FailedSyncOperation(
                            id: id,
                            type: type,
                            collection: collection,
                            documentId: documentId,
                            timestamp: timestamp,
                            failedAt: failedAt,
                            errorMessage: errorMessage,
                            retryCount: retryCount
                        )
                        operations.append(operation)
                    }
                }
                sqlite3_finalize(statement)
            }
        }

        return operations
    }

    /// Retry a failed operation by moving it back to the sync queue
    func retryFailedOperation(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            // First, get the operation data
            let selectSql = "SELECT type, collection, document_id, data, timestamp FROM failed_operations WHERE id = ?"

            var selectStatement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, selectSql, -1, &selectStatement, nil) == SQLITE_OK {
                sqlite3_bind_text(selectStatement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                if sqlite3_step(selectStatement) == SQLITE_ROW {
                    let typeRaw = String(cString: sqlite3_column_text(selectStatement, 0))
                    let collection = String(cString: sqlite3_column_text(selectStatement, 1))
                    let documentId = String(cString: sqlite3_column_text(selectStatement, 2))

                    var data: Data?
                    if sqlite3_column_type(selectStatement, 3) != SQLITE_NULL {
                        let bytes = sqlite3_column_blob(selectStatement, 3)
                        let length = sqlite3_column_bytes(selectStatement, 3)
                        if let bytes = bytes {
                            data = Data(bytes: bytes, count: Int(length))
                        }
                    }

                    let timestamp = sqlite3_column_double(selectStatement, 4)

                    sqlite3_finalize(selectStatement)

                    // Insert into sync queue with reset retry count
                    let insertSql = """
                        INSERT INTO sync_queue (id, type, collection, document_id, data, timestamp, retry_count)
                        VALUES (?, ?, ?, ?, ?, ?, 0)
                    """

                    var insertStatement: OpaquePointer?
                    if sqlite3_prepare_v2(self.db, insertSql, -1, &insertStatement, nil) == SQLITE_OK {
                        let newId = UUID().uuidString
                        sqlite3_bind_text(insertStatement, 1, newId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                        sqlite3_bind_text(insertStatement, 2, typeRaw, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                        sqlite3_bind_text(insertStatement, 3, collection, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                        sqlite3_bind_text(insertStatement, 4, documentId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                        if let data = data {
                            sqlite3_bind_blob(insertStatement, 5, (data as NSData).bytes, Int32(data.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                        } else {
                            sqlite3_bind_null(insertStatement, 5)
                        }

                        sqlite3_bind_double(insertStatement, 6, timestamp)

                        sqlite3_step(insertStatement)
                        sqlite3_finalize(insertStatement)
                    }

                    // Delete from failed operations
                    let deleteSql = "DELETE FROM failed_operations WHERE id = ?"
                    var deleteStatement: OpaquePointer?
                    if sqlite3_prepare_v2(self.db, deleteSql, -1, &deleteStatement, nil) == SQLITE_OK {
                        sqlite3_bind_text(deleteStatement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                        sqlite3_step(deleteStatement)
                        sqlite3_finalize(deleteStatement)
                    }

                    // Notify that there are pending operations
                    NotificationCenter.default.post(name: .offlineDataPendingSync, object: nil)
                } else {
                    sqlite3_finalize(selectStatement)
                }
            }
        }
    }

    /// Discard a failed operation (user chose to abandon it)
    func discardFailedOperation(id: String) {
        dbQueue.async {
            guard self.isInitialized else { return }

            let sql = "DELETE FROM failed_operations WHERE id = ?"

            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                sqlite3_step(statement)
                sqlite3_finalize(statement)
            }
        }
    }

    /// Clear all failed operations
    func clearAllFailedOperations() {
        dbQueue.async {
            guard self.isInitialized else { return }
            self.executeSQL("DELETE FROM failed_operations")
        }
    }

    // MARK: - Data Import from Firebase

    /// Import food entries from Firebase (for initial sync or full resync)
    func importFoodEntries(_ entries: [FoodEntry]) {
        dbQueue.async {
            guard self.isInitialized else { return }

            // Begin transaction for better performance
            self.executeSQL("BEGIN TRANSACTION")

            for entry in entries {
                let sql = """
                    INSERT OR REPLACE INTO food_entries (
                        id, user_id, food_name, brand_name, serving_size, serving_unit,
                        calories, protein, carbohydrates, fat, fiber, sugar, sodium, calcium,
                        ingredients, additives, barcode, micronutrient_profile, is_per_unit,
                        image_url, portions, meal_type, date, date_logged, inferred_ingredients,
                        sync_status, last_modified
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?)
                """

                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                    // Bind parameters (similar to saveFoodEntry but with 'synced' status)
                    sqlite3_bind_text(statement, 1, entry.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_text(statement, 2, entry.userId, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_text(statement, 3, entry.foodName, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                    if let brand = entry.brandName {
                        sqlite3_bind_text(statement, 4, brand, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else {
                        sqlite3_bind_null(statement, 4)
                    }

                    sqlite3_bind_double(statement, 5, entry.servingSize)
                    sqlite3_bind_text(statement, 6, entry.servingUnit, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_double(statement, 7, entry.calories)
                    sqlite3_bind_double(statement, 8, entry.protein)
                    sqlite3_bind_double(statement, 9, entry.carbohydrates)
                    sqlite3_bind_double(statement, 10, entry.fat)

                    if let fiber = entry.fiber { sqlite3_bind_double(statement, 11, fiber) } else { sqlite3_bind_null(statement, 11) }
                    if let sugar = entry.sugar { sqlite3_bind_double(statement, 12, sugar) } else { sqlite3_bind_null(statement, 12) }
                    if let sodium = entry.sodium { sqlite3_bind_double(statement, 13, sodium) } else { sqlite3_bind_null(statement, 13) }
                    if let calcium = entry.calcium { sqlite3_bind_double(statement, 14, calcium) } else { sqlite3_bind_null(statement, 14) }

                    if let ingredients = entry.ingredients, let data = try? JSONEncoder().encode(ingredients) {
                        sqlite3_bind_text(statement, 15, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 15) }

                    if let additives = entry.additives, let data = try? JSONEncoder().encode(additives) {
                        sqlite3_bind_text(statement, 16, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 16) }

                    if let barcode = entry.barcode {
                        sqlite3_bind_text(statement, 17, barcode, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 17) }

                    if let profile = entry.micronutrientProfile, let data = try? JSONEncoder().encode(profile) {
                        sqlite3_bind_text(statement, 18, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 18) }

                    sqlite3_bind_int(statement, 19, (entry.isPerUnit ?? false) ? 1 : 0)

                    if let imageUrl = entry.imageUrl {
                        sqlite3_bind_text(statement, 20, imageUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 20) }

                    if let portions = entry.portions, let data = try? JSONEncoder().encode(portions) {
                        sqlite3_bind_text(statement, 21, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 21) }

                    sqlite3_bind_text(statement, 22, entry.mealType.rawValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_double(statement, 23, entry.date.timeIntervalSince1970)
                    sqlite3_bind_double(statement, 24, entry.dateLogged.timeIntervalSince1970)

                    if let inferred = entry.inferredIngredients, let data = try? JSONEncoder().encode(inferred) {
                        sqlite3_bind_text(statement, 25, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 25) }

                    sqlite3_bind_double(statement, 26, Date().timeIntervalSince1970)

                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }

            self.executeSQL("COMMIT")
            print("[OfflineDataManager] Imported \(entries.count) food entries from Firebase")
        }
    }

    /// Import Use By items from Firebase
    func importUseByItems(_ items: [UseByInventoryItem]) {
        dbQueue.async {
            guard self.isInitialized else { return }

            self.executeSQL("BEGIN TRANSACTION")

            for item in items {
                let sql = """
                    INSERT OR REPLACE INTO use_by_items (
                        id, name, brand, quantity, expiry_date, added_date,
                        barcode, category, image_url, notes, sync_status, last_modified
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?)
                """

                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, item.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_text(statement, 2, item.name, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                    if let brand = item.brand {
                        sqlite3_bind_text(statement, 3, brand, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 3) }

                    sqlite3_bind_text(statement, 4, item.quantity, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_double(statement, 5, item.expiryDate.timeIntervalSince1970)
                    sqlite3_bind_double(statement, 6, item.addedDate.timeIntervalSince1970)

                    if let barcode = item.barcode {
                        sqlite3_bind_text(statement, 7, barcode, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 7) }

                    if let category = item.category {
                        sqlite3_bind_text(statement, 8, category, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 8) }

                    if let imageUrl = item.imageURL {
                        sqlite3_bind_text(statement, 9, imageUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 9) }

                    if let notes = item.notes {
                        sqlite3_bind_text(statement, 10, notes, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 10) }

                    sqlite3_bind_double(statement, 11, Date().timeIntervalSince1970)

                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }

            self.executeSQL("COMMIT")
            print("[OfflineDataManager] Imported \(items.count) Use By items from Firebase")
        }
    }

    /// Merge Use By items from server, respecting local deletions
    /// Items marked as 'deleted' locally will NOT be overwritten by server data
    /// This prevents deleted items from "coming back" while sync is pending
    func mergeUseByItemsFromServer(_ items: [UseByInventoryItem]) {
        dbQueue.async {
            guard self.isInitialized else { return }

            self.executeSQL("BEGIN TRANSACTION")

            for item in items {
                // First check if this item exists locally with 'deleted' status
                let checkSql = "SELECT sync_status FROM use_by_items WHERE id = ?"
                var checkStmt: OpaquePointer?
                var isLocallyDeleted = false

                if sqlite3_prepare_v2(self.db, checkSql, -1, &checkStmt, nil) == SQLITE_OK {
                    sqlite3_bind_text(checkStmt, 1, item.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    if sqlite3_step(checkStmt) == SQLITE_ROW {
                        if let statusPtr = sqlite3_column_text(checkStmt, 0) {
                            let status = String(cString: statusPtr)
                            isLocallyDeleted = (status == "deleted")
                        }
                    }
                    sqlite3_finalize(checkStmt)
                }

                // Skip items that are marked for deletion locally
                if isLocallyDeleted {
                    print("[OfflineDataManager] Skipping server item \(item.id) - locally marked as deleted")
                    continue
                }

                // Insert or update the item (not locally deleted)
                let sql = """
                    INSERT OR REPLACE INTO use_by_items (
                        id, name, brand, quantity, expiry_date, added_date,
                        barcode, category, image_url, notes, sync_status, last_modified
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?)
                """

                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, item.id, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_text(statement, 2, item.name, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

                    if let brand = item.brand {
                        sqlite3_bind_text(statement, 3, brand, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 3) }

                    sqlite3_bind_text(statement, 4, item.quantity, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_double(statement, 5, item.expiryDate.timeIntervalSince1970)
                    sqlite3_bind_double(statement, 6, item.addedDate.timeIntervalSince1970)

                    if let barcode = item.barcode {
                        sqlite3_bind_text(statement, 7, barcode, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 7) }

                    if let category = item.category {
                        sqlite3_bind_text(statement, 8, category, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 8) }

                    if let imageUrl = item.imageURL {
                        sqlite3_bind_text(statement, 9, imageUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 9) }

                    if let notes = item.notes {
                        sqlite3_bind_text(statement, 10, notes, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 10) }

                    sqlite3_bind_double(statement, 11, Date().timeIntervalSince1970)

                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }

            self.executeSQL("COMMIT")
            print("[OfflineDataManager] Merged \(items.count) Use By items from server (respecting local deletions)")
        }
    }

    /// Import weight entries from Firebase
    func importWeightEntries(_ entries: [WeightEntry]) {
        dbQueue.async {
            guard self.isInitialized else { return }

            self.executeSQL("BEGIN TRANSACTION")

            for entry in entries {
                let sql = """
                    INSERT OR REPLACE INTO weight_entries (
                        id, weight, date, bmi, note, photo_url, photo_urls, waist_size, dress_size, sync_status, last_modified
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'synced', ?)
                """

                var statement: OpaquePointer?
                if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    sqlite3_bind_double(statement, 2, entry.weight)
                    sqlite3_bind_double(statement, 3, entry.date.timeIntervalSince1970)

                    if let bmi = entry.bmi { sqlite3_bind_double(statement, 4, bmi) } else { sqlite3_bind_null(statement, 4) }
                    if let note = entry.note {
                        sqlite3_bind_text(statement, 5, note, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 5) }

                    if let photoUrl = entry.photoURL {
                        sqlite3_bind_text(statement, 6, photoUrl, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 6) }

                    if let photoUrls = entry.photoURLs, let data = try? JSONEncoder().encode(photoUrls) {
                        sqlite3_bind_text(statement, 7, String(data: data, encoding: .utf8), -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 7) }

                    if let waistSize = entry.waistSize { sqlite3_bind_double(statement, 8, waistSize) } else { sqlite3_bind_null(statement, 8) }
                    if let dressSize = entry.dressSize {
                        sqlite3_bind_text(statement, 9, dressSize, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                    } else { sqlite3_bind_null(statement, 9) }

                    sqlite3_bind_double(statement, 10, Date().timeIntervalSince1970)

                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }

            self.executeSQL("COMMIT")
            print("[OfflineDataManager] Imported \(entries.count) weight entries from Firebase")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineDataPendingSync = Notification.Name("offlineDataPendingSync")
}
