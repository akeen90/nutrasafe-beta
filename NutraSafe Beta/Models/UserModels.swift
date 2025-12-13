//
//  UserModels.swift
//  NutraSafe Beta
//
//  Domain models for User
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct UserProfile {
    let userId: String
    let name: String
    let email: String?
    let dateOfBirth: Date?
    let height: Double? // cm
    let weight: Double? // kg
    let activityLevel: ActivityLevel
    let dietaryGoals: DietaryGoals
    let allergies: [String]
    let medicalConditions: [String]
    let dateCreated: Date
    let lastUpdated: Date

    // GDPR-compliant email marketing consent
    let emailMarketingConsent: Bool
    let emailMarketingConsentDate: Date?
    let emailMarketingConsentWithdrawn: Bool
    let emailMarketingConsentWithdrawnDate: Date?
    
    enum ActivityLevel: String, CaseIterable {
        case sedentary = "sedentary"
        case lightlyActive = "lightlyActive"
        case moderatelyActive = "moderatelyActive"
        case veryActive = "veryActive"
        case extremelyActive = "extremelyActive"
    }
    
    struct DietaryGoals {
        let dailyCalories: Int
        let proteinPercentage: Double
        let carbsPercentage: Double
        let fatPercentage: Double
        let waterIntake: Double // litres
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "name": name,
            "email": email ?? "",
            "dateOfBirth": dateOfBirth != nil ? Timestamp(date: dateOfBirth!) : NSNull(),
            "height": height ?? NSNull(),
            "weight": weight ?? NSNull(),
            "activityLevel": activityLevel.rawValue,
            "dietaryGoals": [
                "dailyCalories": dietaryGoals.dailyCalories,
                "proteinPercentage": dietaryGoals.proteinPercentage,
                "carbsPercentage": dietaryGoals.carbsPercentage,
                "fatPercentage": dietaryGoals.fatPercentage,
                "waterIntake": dietaryGoals.waterIntake
            ],
            "allergies": allergies,
            "medicalConditions": medicalConditions,
            "dateCreated": Timestamp(date: dateCreated),
            "lastUpdated": Timestamp(date: lastUpdated),
            "emailMarketingConsent": emailMarketingConsent,
            "emailMarketingConsentDate": emailMarketingConsentDate != nil ? Timestamp(date: emailMarketingConsentDate!) : NSNull(),
            "emailMarketingConsentWithdrawn": emailMarketingConsentWithdrawn,
            "emailMarketingConsentWithdrawnDate": emailMarketingConsentWithdrawnDate != nil ? Timestamp(date: emailMarketingConsentWithdrawnDate!) : NSNull()
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> UserProfile? {
        guard let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let activityLevelRaw = data["activityLevel"] as? String,
              let activityLevel = ActivityLevel(rawValue: activityLevelRaw),
              let goalsData = data["dietaryGoals"] as? [String: Any],
              let dailyCalories = goalsData["dailyCalories"] as? Int,
              let proteinPercentage = goalsData["proteinPercentage"] as? Double,
              let carbsPercentage = goalsData["carbsPercentage"] as? Double,
              let fatPercentage = goalsData["fatPercentage"] as? Double,
              let waterIntake = goalsData["waterIntake"] as? Double,
              let allergies = data["allergies"] as? [String],
              let medicalConditions = data["medicalConditions"] as? [String],
              let dateCreatedTimestamp = data["dateCreated"] as? Timestamp,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp else {
            return nil
        }
        
        let email = data["email"] as? String
        let height = data["height"] as? Double
        let weight = data["weight"] as? Double
        let dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue()

        // Email consent fields with defaults for backwards compatibility
        let emailMarketingConsent = data["emailMarketingConsent"] as? Bool ?? false
        let emailMarketingConsentDate = (data["emailMarketingConsentDate"] as? Timestamp)?.dateValue()
        let emailMarketingConsentWithdrawn = data["emailMarketingConsentWithdrawn"] as? Bool ?? false
        let emailMarketingConsentWithdrawnDate = (data["emailMarketingConsentWithdrawnDate"] as? Timestamp)?.dateValue()

        let dietaryGoals = DietaryGoals(
            dailyCalories: dailyCalories,
            proteinPercentage: proteinPercentage,
            carbsPercentage: carbsPercentage,
            fatPercentage: fatPercentage,
            waterIntake: waterIntake
        )

        return UserProfile(
            userId: userId,
            name: name,
            email: email,
            dateOfBirth: dateOfBirth,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            dietaryGoals: dietaryGoals,
            allergies: allergies,
            medicalConditions: medicalConditions,
            dateCreated: dateCreatedTimestamp.dateValue(),
            lastUpdated: lastUpdatedTimestamp.dateValue(),
            emailMarketingConsent: emailMarketingConsent,
            emailMarketingConsentDate: emailMarketingConsentDate,
            emailMarketingConsentWithdrawn: emailMarketingConsentWithdrawn,
            emailMarketingConsentWithdrawnDate: emailMarketingConsentWithdrawnDate
        )
    }
}

