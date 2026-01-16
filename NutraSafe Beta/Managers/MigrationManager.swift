//
//  MigrationManager.swift
//  NutraSafe Beta
//
//  Handles data migrations between app versions
//

import Foundation

/// Manages migrations between app versions
class MigrationManager {
    static let shared = MigrationManager()

    private let migrationVersionKey = "appMigrationVersion"

    // Increment this when adding new migrations
    private let currentMigrationVersion = 1

    private init() {}

    /// Run all pending migrations on app launch
    func performMigrations() {
        let lastVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)

        if lastVersion < 1 {
            migrateToV1_LeanOnboarding()
        }

        // Save current version
        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
    }

    // MARK: - Migration V1: Lean Onboarding & Feature Tips

    /// Migration for users who completed old 13-page onboarding
    /// - They should NOT see new onboarding
    /// - They should NOT see basic feature tips (they learned from old onboarding)
    /// - They SHOULD see premium feature tips (encourage exploration)
    private func migrateToV1_LeanOnboarding() {
        let hasCompletedOldOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let hasAcceptedDisclaimer = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")

        if hasCompletedOldOnboarding && hasAcceptedDisclaimer {
            
            // Mark basic overview tips as seen - they learned this from old onboarding
            FeatureTipsManager.shared.markTipsAsSeen([
                .diaryOverview,
                .diarySearch,
                .healthOverview,
                .healthReactions,
                .healthFasting,
                .progressOverview,
                .useByOverview,
                .nutrientsOverview
            ])

            // Keep premium tips (.healthPatterns, .progressWeight) as unseen
            // This encourages exploration of premium features
        } else {
                        // New users will see the new 3-page onboarding and all feature tips
        }
    }
}
