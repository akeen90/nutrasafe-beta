//
//  AppConfig.swift
//  NutraSafe Beta
//
//  Centralized configuration for API endpoints and app settings
//  Security: Never commit actual API keys to source control
//

import Foundation

enum AppConfig {
    // MARK: - Environment
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
    }
    
    // MARK: - Firebase Configuration
    struct Firebase {
        static let projectId = "nutrasafe-705c7"
        
        static var functionsBaseURL: String {
            switch Environment.current {
            case .development, .staging:
                return "https://us-central1-\(projectId).cloudfunctions.net"
            case .production:
                return "https://us-central1-\(projectId).cloudfunctions.net"
            }
        }
        
        // Cloud Function Endpoints
        struct Functions {
            static let searchFoods = "\(functionsBaseURL)/searchFoodsWithMicronutrients"
            static let searchFoodByBarcode = "\(functionsBaseURL)/searchFoodByBarcode"
            static let recognizeFood = "\(functionsBaseURL)/recognizeFood"
            static let analyzeAdditives = "\(functionsBaseURL)/analyzeAdditivesEnhanced"
            static let processIngredientImage = "\(functionsBaseURL)/processIngredientImage"
            static let processCompleteFoodProfile = "\(functionsBaseURL)/processCompleteFoodProfile"
            static let extractIngredientsWithAI = "\(functionsBaseURL)/extractIngredientsWithAI"
        }
    }
    
    // MARK: - API Keys (loaded from environment/keychain)
    struct APIKeys {
        // These should be loaded from Info.plist, environment variables, or keychain
        // NEVER hardcode actual keys here
        static var openAIKey: String? {
            // Load from secure storage
            return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        }
        
        static var geminiKey: String? {
            // Load from secure storage
            return ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
        }
        
        static var nutritionixAppId: String? {
            // Load from secure storage
            return ProcessInfo.processInfo.environment["NUTRITIONIX_APP_ID"]
        }
        
        static var nutritionixAppKey: String? {
            // Load from secure storage
            return ProcessInfo.processInfo.environment["NUTRITIONIX_APP_KEY"]
        }
    }
    
    // MARK: - App Settings
    struct Settings {
        static let defaultCaloricGoal = 2000
        static let defaultProteinGoal = 50
        static let defaultCarbsGoal = 250
        static let defaultFatGoal = 65
        static let defaultFiberGoal = 25
        
        static let maxImageUploadSize = 10 * 1024 * 1024 // 10MB
        static let requestTimeout: TimeInterval = 30
        static let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let isAIScanningEnabled = true
        static let isBarcodeEnabled = true
        static let isHealthKitEnabled = true
        static let isOfflineModeEnabled = false
        static let isAnalyticsEnabled = Environment.current == .production
        
        // Allow anonymous authentication to save user data (reactions, kitchen items, etc.)
        // This enables users to use the app immediately without account creation
        // Users can upgrade to full accounts later to enable cross-device sync
        static let allowAnonymousAuth: Bool = true
    }
}
