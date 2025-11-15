import Foundation

extension DiaryDataManager {
    // Move an existing food item across dates (and optionally meals) while preserving ID
    func moveFoodItemAcrossDates(_ item: DiaryFoodItem, from originalMeal: String, fromDate: Date, to newMeal: String, toDate: Date) async throws {
        print("DiaryDataManager: Moving food item '\(item.name)' (ID: \(item.id)) from '\(originalMeal)' on \(fromDate) to '\(newMeal)' on \(toDate)")

        // Use DateHelper for consistent local timezone date comparison
        if DateHelper.isSameDay(fromDate, toDate) {
            // Same day - just move between meals
            try await moveFoodItem(item, from: originalMeal, to: newMeal, for: toDate)
            return
        }

        // Load source date meals
        let (srcBreakfast, srcLunch, srcDinner, srcSnacks) = try await getFoodDataAsync(for: fromDate)
        var updatedSrcBreakfast = srcBreakfast
        var updatedSrcLunch = srcLunch
        var updatedSrcDinner = srcDinner
        var updatedSrcSnacks = srcSnacks

        switch originalMeal.lowercased() {
        case "breakfast":
            updatedSrcBreakfast.removeAll { $0.id == item.id }
        case "lunch":
            updatedSrcLunch.removeAll { $0.id == item.id }
        case "dinner":
            updatedSrcDinner.removeAll { $0.id == item.id }
        case "snacks":
            updatedSrcSnacks.removeAll { $0.id == item.id }
        default:
            print("DiaryDataManager: WARNING - Unknown original meal type: \(originalMeal)")
        }

        // Persist source date changes locally
        await MainActor.run {
            saveFoodData(for: fromDate, breakfast: updatedSrcBreakfast, lunch: updatedSrcLunch, dinner: updatedSrcDinner, snacks: updatedSrcSnacks)
        }

        // Load destination date meals
        let (dstBreakfast, dstLunch, dstDinner, dstSnacks) = try await getFoodDataAsync(for: toDate)
        var updatedDstBreakfast = dstBreakfast
        var updatedDstLunch = dstLunch
        var updatedDstDinner = dstDinner
        var updatedDstSnacks = dstSnacks

        switch newMeal.lowercased() {
        case "breakfast":
            if let index = updatedDstBreakfast.firstIndex(where: { $0.id == item.id }) {
                updatedDstBreakfast[index] = item
            } else {
                updatedDstBreakfast.append(item)
            }
        case "lunch":
            if let index = updatedDstLunch.firstIndex(where: { $0.id == item.id }) {
                updatedDstLunch[index] = item
            } else {
                updatedDstLunch.append(item)
            }
        case "dinner":
            if let index = updatedDstDinner.firstIndex(where: { $0.id == item.id }) {
                updatedDstDinner[index] = item
            } else {
                updatedDstDinner.append(item)
            }
        case "snacks":
            if let index = updatedDstSnacks.firstIndex(where: { $0.id == item.id }) {
                updatedDstSnacks[index] = item
            } else {
                updatedDstSnacks.append(item)
            }
        default:
            print("DiaryDataManager: WARNING - Unknown destination meal type: \(newMeal)")
        }

        // Persist destination date changes locally
        await MainActor.run {
            saveFoodData(for: toDate, breakfast: updatedDstBreakfast, lunch: updatedDstLunch, dinner: updatedDstDinner, snacks: updatedDstSnacks)
        }

        // Sync to Firebase with the new meal and date (preserves same document ID)
        do {
            guard let userId = FirebaseManager.shared.currentUser?.uid else {
                print("DiaryDataManager: Cannot sync to Firebase - no user logged in")
                return
            }
            let mealType: MealType
            switch newMeal.lowercased() {
            case "breakfast": mealType = .breakfast
            case "lunch": mealType = .lunch
            case "dinner": mealType = .dinner
            case "snacks": mealType = .snacks
            default:
                print("DiaryDataManager: Cannot sync to Firebase - invalid meal type: \(newMeal)")
                return
            }
            let foodEntry = item.toFoodEntry(userId: userId, mealType: mealType, date: toDate)
            try await FirebaseManager.shared.saveFoodEntry(foodEntry)
        } catch {
            print("DiaryDataManager: Failed to sync moved item to Firebase: \(error.localizedDescription)")
        }

        // Trigger reload
        await MainActor.run {
            self.objectWillChange.send()
            self.dataReloadTrigger = UUID()
        }
    }
}