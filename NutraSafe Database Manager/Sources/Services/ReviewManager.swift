//
//  ReviewManager.swift
//  NutraSafe Database Manager
//
//  Manages local tracking of Claude's review progress through the database
//

import Foundation

@MainActor
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()

    // MARK: - Published State

    @Published var reviewedFoodIDs: Set<String> = []
    @Published var flaggedFoodIDs: Set<String> = []  // Foods that need attention
    @Published var reviewNotes: [String: String] = [:]  // ID -> notes
    @Published var reviewStats: ReviewStats = ReviewStats()
    @Published var isReviewingBatch = false
    @Published var currentBatchProgress: BatchProgress?

    // MARK: - Configuration

    private let reviewedKey = "reviewed_food_ids"
    private let flaggedKey = "flagged_food_ids"
    private let notesKey = "review_notes"

    private init() {
        loadFromDisk()
    }

    // MARK: - Persistence

    func loadFromDisk() {
        if let reviewedData = UserDefaults.standard.array(forKey: reviewedKey) as? [String] {
            reviewedFoodIDs = Set(reviewedData)
        }
        if let flaggedData = UserDefaults.standard.array(forKey: flaggedKey) as? [String] {
            flaggedFoodIDs = Set(flaggedData)
        }
        if let notesData = UserDefaults.standard.dictionary(forKey: notesKey) as? [String: String] {
            reviewNotes = notesData
        }
        updateStats()
    }

    func saveToDisk() {
        UserDefaults.standard.set(Array(reviewedFoodIDs), forKey: reviewedKey)
        UserDefaults.standard.set(Array(flaggedFoodIDs), forKey: flaggedKey)
        UserDefaults.standard.set(reviewNotes, forKey: notesKey)
    }

    // MARK: - Review Actions

    func markAsReviewed(_ foodID: String, notes: String? = nil) {
        reviewedFoodIDs.insert(foodID)
        flaggedFoodIDs.remove(foodID)
        if let notes = notes, !notes.isEmpty {
            reviewNotes[foodID] = notes
        }
        updateStats()
        saveToDisk()
    }

    func markAsFlagged(_ foodID: String, reason: String) {
        flaggedFoodIDs.insert(foodID)
        reviewNotes[foodID] = reason
        updateStats()
        saveToDisk()
    }

    func markBatchAsReviewed(_ foodIDs: [String]) {
        for id in foodIDs {
            reviewedFoodIDs.insert(id)
            flaggedFoodIDs.remove(id)
        }
        updateStats()
        saveToDisk()
    }

    func isReviewed(_ foodID: String) -> Bool {
        reviewedFoodIDs.contains(foodID)
    }

    func isFlagged(_ foodID: String) -> Bool {
        flaggedFoodIDs.contains(foodID)
    }

    func getNote(_ foodID: String) -> String? {
        reviewNotes[foodID]
    }

    func clearReviewStatus(_ foodID: String) {
        reviewedFoodIDs.remove(foodID)
        flaggedFoodIDs.remove(foodID)
        reviewNotes.removeValue(forKey: foodID)
        updateStats()
        saveToDisk()
    }

    func resetAllReviews() {
        reviewedFoodIDs.removeAll()
        flaggedFoodIDs.removeAll()
        reviewNotes.removeAll()
        updateStats()
        saveToDisk()
    }

    // MARK: - Stats

    private func updateStats() {
        reviewStats = ReviewStats(
            totalReviewed: reviewedFoodIDs.count,
            totalFlagged: flaggedFoodIDs.count
        )
    }

    func updateStatsWithTotal(_ totalFoods: Int) {
        reviewStats = ReviewStats(
            totalReviewed: reviewedFoodIDs.count,
            totalFlagged: flaggedFoodIDs.count,
            totalFoods: totalFoods
        )
    }

    // MARK: - Batch Processing for Claude

    func startBatchReview(totalItems: Int) {
        isReviewingBatch = true
        currentBatchProgress = BatchProgress(
            currentItem: 0,
            totalItems: totalItems,
            status: "Starting review..."
        )
    }

    func updateBatchProgress(current: Int, status: String) {
        currentBatchProgress?.currentItem = current
        currentBatchProgress?.status = status
    }

    func endBatchReview() {
        isReviewingBatch = false
        currentBatchProgress = nil
    }
}

// MARK: - Supporting Types

struct ReviewStats {
    var totalReviewed: Int = 0
    var totalFlagged: Int = 0
    var totalFoods: Int = 0

    var percentageComplete: Double {
        guard totalFoods > 0 else { return 0 }
        return Double(totalReviewed) / Double(totalFoods) * 100
    }

    var remaining: Int {
        max(0, totalFoods - totalReviewed)
    }
}

struct BatchProgress: Identifiable {
    let id = UUID()
    var currentItem: Int
    var totalItems: Int
    var status: String
    var errors: [String] = []

    var progress: Double {
        guard totalItems > 0 else { return 0 }
        return Double(currentItem) / Double(totalItems)
    }
}

// MARK: - Review Filter

enum ReviewFilter: String, CaseIterable, Identifiable {
    case all = "All Foods"
    case unreviewed = "Needs Review"
    case reviewed = "Reviewed"
    case flagged = "Flagged"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .unreviewed: return "questionmark.circle"
        case .reviewed: return "checkmark.circle"
        case .flagged: return "flag.fill"
        }
    }
}
