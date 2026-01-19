//
//  AnalyticsManager.swift
//  NutraSafe Beta
//
//  Centralized analytics tracking using Firebase Analytics
//

import Foundation
import SwiftUI
import FirebaseAnalytics

/// Centralized analytics manager for tracking user behavior
class AnalyticsManager {
    static let shared = AnalyticsManager()

    private init() {}

    // MARK: - Screen Tracking

    /// Track screen view - call this when a screen appears
    func trackScreen(_ screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }

    // MARK: - Food Events

    /// Track when user searches for food
    func trackFoodSearch(query: String, source: String) {
        Analytics.logEvent("food_search", parameters: [
            "search_query": String(query.prefix(100)),
            "search_source": source
        ])
    }

    /// Track when user views food details
    func trackFoodView(foodName: String, source: String, hasBarcode: Bool) {
        Analytics.logEvent("food_view", parameters: [
            "food_name": String(foodName.prefix(100)),
            "source": source,
            "has_barcode": hasBarcode ? "yes" : "no"
        ])
    }

    /// Track when user adds food to diary
    func trackFoodAdded(foodName: String, mealType: String, calories: Int) {
        Analytics.logEvent("food_added", parameters: [
            "food_name": String(foodName.prefix(100)),
            "meal_type": mealType,
            "calories": calories
        ])
    }

    /// Track barcode scan
    func trackBarcodeScan(success: Bool, source: String) {
        Analytics.logEvent("barcode_scan", parameters: [
            "scan_success": success ? "yes" : "no",
            "source": source
        ])
    }

    /// Track AI scan usage
    func trackAIScan(type: String, success: Bool) {
        Analytics.logEvent("ai_scan", parameters: [
            "scan_type": type,
            "success": success ? "yes" : "no"
        ])
    }

    // MARK: - Fasting Events

    /// Track fasting session started
    func trackFastingStarted(planName: String, targetHours: Int) {
        Analytics.logEvent("fasting_started", parameters: [
            "plan_name": planName,
            "target_hours": targetHours
        ])
    }

    /// Track fasting session ended
    func trackFastingEnded(planName: String, completedHours: Double, targetHours: Int, completed: Bool) {
        Analytics.logEvent("fasting_ended", parameters: [
            "plan_name": planName,
            "completed_hours": Int(completedHours),
            "target_hours": targetHours,
            "completed_full": completed ? "yes" : "no"
        ])
    }

    /// Track fasting plan created
    func trackFastingPlanCreated(planType: String, targetHours: Int) {
        Analytics.logEvent("fasting_plan_created", parameters: [
            "plan_type": planType,
            "target_hours": targetHours
        ])
    }

    // MARK: - Diary Events

    /// Track diary day viewed
    func trackDiaryView(date: Date, mealCount: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        Analytics.logEvent("diary_view", parameters: [
            "date": formatter.string(from: date),
            "meal_count": mealCount
        ])
    }

    /// Track meal logged
    func trackMealLogged(mealType: String, foodCount: Int, totalCalories: Int) {
        Analytics.logEvent("meal_logged", parameters: [
            "meal_type": mealType,
            "food_count": foodCount,
            "total_calories": totalCalories
        ])
    }

    // MARK: - Use By Tracking Events

    /// Track use-by item added
    func trackUseByItemAdded(daysUntilExpiry: Int) {
        Analytics.logEvent("use_by_item_added", parameters: [
            "days_until_expiry": daysUntilExpiry
        ])
    }

    /// Track use-by item consumed
    func trackUseByItemConsumed(wasExpired: Bool) {
        Analytics.logEvent("use_by_item_consumed", parameters: [
            "was_expired": wasExpired ? "yes" : "no"
        ])
    }

    // MARK: - Insights & Analytics Events

    /// Track insights viewed
    func trackInsightsViewed(insightType: String) {
        Analytics.logEvent("insights_viewed", parameters: [
            "insight_type": insightType
        ])
    }

    /// Track nutrient gap viewed
    func trackNutrientGapViewed(nutrientName: String, percentMet: Int) {
        Analytics.logEvent("nutrient_gap_viewed", parameters: [
            "nutrient_name": nutrientName,
            "percent_met": percentMet
        ])
    }

    // MARK: - Settings Events

    /// Track settings change
    func trackSettingChanged(settingName: String, newValue: String) {
        Analytics.logEvent("setting_changed", parameters: [
            "setting_name": settingName,
            "new_value": newValue
        ])
    }

    /// Track allergen profile updated
    func trackAllergenProfileUpdated(allergenCount: Int) {
        Analytics.logEvent("allergen_profile_updated", parameters: [
            "allergen_count": allergenCount
        ])
    }

    // MARK: - Subscription Events

    /// Track paywall viewed
    func trackPaywallViewed(source: String) {
        Analytics.logEvent("paywall_viewed", parameters: [
            "source": source
        ])
    }

    /// Track subscription started
    func trackSubscriptionStarted(plan: String) {
        Analytics.logEvent("subscription_started", parameters: [
            "plan": plan
        ])
    }

    // MARK: - Authentication Events

    /// Track sign in
    func trackSignIn(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    /// Track sign up
    func trackSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    /// Track sign out
    func trackSignOut() {
        Analytics.logEvent("sign_out", parameters: nil)
    }

    // MARK: - Onboarding Events

    /// Track onboarding step completed
    func trackOnboardingStep(step: Int, stepName: String) {
        Analytics.logEvent("onboarding_step", parameters: [
            "step_number": step,
            "step_name": stepName
        ])
    }

    /// Track onboarding completed
    func trackOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    // MARK: - Error Events

    /// Track app error
    func trackError(errorType: String, errorMessage: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_type": errorType,
            "error_message": String(errorMessage.prefix(100))
        ])
    }

    // MARK: - User Properties

    /// Set user property for analytics segmentation
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }

    /// Set whether user has premium subscription
    func setHasPremium(_ hasPremium: Bool) {
        Analytics.setUserProperty(hasPremium ? "premium" : "free", forName: "subscription_status")
    }

    /// Set user's dietary preference
    func setDietaryPreference(_ preference: String) {
        Analytics.setUserProperty(preference, forName: "dietary_preference")
    }

    /// Set user's allergen count
    func setAllergenCount(_ count: Int) {
        Analytics.setUserProperty(String(count), forName: "allergen_count")
    }
}

// MARK: - SwiftUI View Extension for Easy Screen Tracking

extension View {
    /// Track screen view when this view appears
    func trackScreen(_ screenName: String) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreen(screenName)
        }
    }
}
