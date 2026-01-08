//
//  ErrorHandler.swift
//  NutraSafe Beta
//
//  Centralized error handling system with user-friendly messages
//  Converts technical errors into clear, actionable messages for users
//

import Foundation
import SwiftUI

// MARK: - User-Facing Error Types

enum NutraSafeError: Error {
    // Network Errors
    case networkUnavailable
    case serverError
    case timeoutError
    case apiError(String)

    // Authentication Errors
    case notAuthenticated
    case authenticationFailed
    case accountDeleted

    // Data Errors
    case dataNotFound
    case saveFailed
    case deleteFailed
    case corruptData

    // Search & Barcode Errors
    case foodNotFound
    case barcodeNotFound
    case searchFailed

    // HealthKit Errors
    case healthKitNotAuthorized
    case healthKitNotAvailable
    case healthKitDataUnavailable

    // Image & Cache Errors
    case imageLoadFailed
    case imageSaveFailed
    case cacheError

    // General Errors
    case unknown(Error)

    var userFriendlyMessage: String {
        switch self {
        // Network Errors
        case .networkUnavailable:
            return "Unable to connect to the internet. Please check your connection and try again."
        case .serverError:
            return "Our servers are experiencing issues. Please try again in a few moments."
        case .timeoutError:
            return "The request took too long. Please check your connection and try again."
        case .apiError(let message):
            return message.isEmpty ? "An unexpected error occurred. Please try again." : message

        // Authentication Errors
        case .notAuthenticated:
            return "You need to be signed in to perform this action."
        case .authenticationFailed:
            return "Sign in failed. Please check your credentials and try again."
        case .accountDeleted:
            return "Your account has been deleted. Please sign in again to create a new account."

        // Data Errors
        case .dataNotFound:
            return "The requested data could not be found."
        case .saveFailed:
            return "Failed to save. Please try again."
        case .deleteFailed:
            return "Failed to delete. Please try again."
        case .corruptData:
            return "Some data appears to be corrupted. Please contact support if this continues."

        // Search & Barcode Errors
        case .foodNotFound:
            return "Food not found. Try scanning the barcode or searching manually."
        case .barcodeNotFound:
            return "Product not found in our database. You can add it manually."
        case .searchFailed:
            return "Search failed. Please check your connection and try again."

        // HealthKit Errors
        case .healthKitNotAuthorized:
            return "HealthKit access is not enabled. Please enable it in Settings > Health > Data Access & Devices."
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device."
        case .healthKitDataUnavailable:
            return "No health data available. Please check your Health app settings."

        // Image & Cache Errors
        case .imageLoadFailed:
            return "Failed to load image. Please try again."
        case .imageSaveFailed:
            return "Failed to save image. Please check your storage space."
        case .cacheError:
            return "Cache error occurred. The app will continue without cached data."

        // General Errors
        case .unknown(let error):
            #if DEBUG
            return "An error occurred: \(error.localizedDescription)"
            #else
            return "An unexpected error occurred. Please try again."
            #endif
        }
    }

    var actionableAdvice: String? {
        switch self {
        case .networkUnavailable:
            return "Try enabling WiFi or cellular data in your device settings."
        case .serverError:
            return "If the problem persists, please contact support."
        case .healthKitNotAuthorized:
            return "Tap Settings to enable HealthKit access for NutraSafe."
        case .barcodeNotFound:
            return "Use the scanner or manual entry to add this product."
        case .searchFailed:
            return "Make sure you're connected to the internet."
        default:
            return nil
        }
    }
}

// MARK: - Error Handler

@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: NutraSafeError?
    @Published var showError = false

    private init() {}

    /// Present an error to the user
    func handle(_ error: Error, context: String = "") {
        let nutraSafeError = mapToNutraSafeError(error)
        currentError = nutraSafeError
        showError = true

        #if DEBUG
        print("❌ [\(context)] Error: \(error.localizedDescription)")
        print("   User message: \(nutraSafeError.userFriendlyMessage)")
        #endif
    }

    /// Present a custom NutraSafe error
    func handle(_ error: NutraSafeError, context: String = "") {
        currentError = error
        showError = true

        #if DEBUG
        print("❌ [\(context)] \(error.userFriendlyMessage)")
        #endif
    }

    /// Clear the current error
    func clearError() {
        currentError = nil
        showError = false
    }

    /// Map generic errors to NutraSafe errors
    func mapToNutraSafeError(_ error: Error) -> NutraSafeError {
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeoutError
            case .badServerResponse:
                return .serverError
            default:
                return .apiError("Network error occurred")
            }
        }

        // Check for HealthKit errors
        let errorDomain = (error as NSError).domain
        if errorDomain == "com.apple.healthkit" {
            let errorCode = (error as NSError).code
            switch errorCode {
            case 4: // Not authorized
                return .healthKitNotAuthorized
            case 11: // No data available
                return .healthKitDataUnavailable
            default:
                return .healthKitNotAvailable
            }
        }

        // Check for Firebase errors
        if errorDomain.contains("Firebase") || errorDomain.contains("FIRAuth") {
            if errorDomain.contains("Auth") {
                return .authenticationFailed
            }
            return .serverError
        }

        // Check error message for common patterns
        let errorMessage = error.localizedDescription.lowercased()
        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return .networkUnavailable
        }
        if errorMessage.contains("not found") {
            return .dataNotFound
        }
        if errorMessage.contains("unauthorized") || errorMessage.contains("auth") {
            return .notAuthenticated
        }

        // Default to unknown error
        return .unknown(error)
    }
}

// MARK: - SwiftUI Error Alert Modifier

struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showError, presenting: errorHandler.currentError) { error in
                Button("OK") {
                    errorHandler.clearError()
                }

                if let _ = error.actionableAdvice {
                    Button("Help") {
                        // Could open settings or help screen
                        errorHandler.clearError()
                    }
                }
            } message: { error in
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.userFriendlyMessage)

                    if let advice = error.actionableAdvice {
                        Text(advice)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

extension View {
    /// Add global error handling to any view
    func withErrorHandling() -> some View {
        self.modifier(ErrorAlert())
    }
}

// MARK: - Error Banner (Alternative to Alert)

struct ErrorBanner: View {
    let error: NutraSafeError
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: errorIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(error.userFriendlyMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            if let advice = error.actionableAdvice {
                Text(advice)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 32)
            }
        }
        .padding(16)
        .background(errorColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private var errorIcon: String {
        switch error {
        case .networkUnavailable:
            return "wifi.slash"
        case .healthKitNotAuthorized, .healthKitNotAvailable:
            return "heart.slash"
        case .foodNotFound, .barcodeNotFound:
            return "magnifyingglass"
        case .authenticationFailed, .notAuthenticated:
            return "person.crop.circle.badge.exclamationmark"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    private var errorTitle: String {
        switch error {
        case .networkUnavailable:
            return "No Internet Connection"
        case .healthKitNotAuthorized:
            return "HealthKit Not Enabled"
        case .foodNotFound, .barcodeNotFound:
            return "Not Found"
        case .authenticationFailed:
            return "Authentication Failed"
        default:
            return "Error"
        }
    }

    private var errorColor: Color {
        switch error {
        case .networkUnavailable:
            return .orange
        case .healthKitNotAuthorized, .healthKitNotAvailable:
            return .purple
        case .foodNotFound, .barcodeNotFound:
            return .blue
        default:
            return .red
        }
    }
}

// MARK: - Loading State with Error Handling

@MainActor
class LoadingState: ObservableObject {
    @Published var isLoading = false
    @Published var error: NutraSafeError?
    @Published var showError = false

    func startLoading() {
        isLoading = true
        error = nil
        showError = false
    }

    func finishLoading() {
        isLoading = false
    }

    func handle(_ error: Error) {
        isLoading = false
        self.error = ErrorHandler.shared.mapToNutraSafeError(error)
        showError = true
    }

    func handle(_ error: NutraSafeError) {
        isLoading = false
        self.error = error
        showError = true
    }

    func clearError() {
        error = nil
        showError = false
    }
}
