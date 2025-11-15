import Foundation
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrial = false
    @Published var isEligibleForTrial = false
    @Published var product: Product?
    @Published var status: [Product.SubscriptionInfo.Status] = []
    @Published var isPurchasing: Bool = false
    @Published var isPremiumOverride = false
    @Published var purchaseError: String?
    @Published var isProductLoaded: Bool = false
    private var authObserver: NSObjectProtocol?
    private var transactionTask: Task<Void, Never>?

    // TODO: Adjust to your final product ID in App Store Connect
    let productID = "com.nutrasafe.pro.monthly"

    init() {
        Task { try? await load() }
        authObserver = NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.refreshPremiumOverride() }
        }
        // Ensure override is evaluated at startup, independent of StoreKit product load timing
        Task { await refreshPremiumOverride() }

        // Listen for transaction updates
        transactionTask = Task {
            await listenForTransactions()
        }
    }


    func load() async throws {
        // Add timeout to prevent infinite loading
        do {
            try await withTimeout(seconds: 10) {
                try await self.loadProductInternal()
            }
        } catch is TimeoutError {
            #if DEBUG
            print("StoreKit: Product loading timed out after 10 seconds")
            #endif
            isProductLoaded = false
            purchaseError = "Unable to connect to App Store. The subscription may be pending approval or there may be a network issue. Please try again later."
            await refreshPremiumOverride()
        } catch {
            #if DEBUG
            print("StoreKit: Product loading failed with error: \(error)")
            #endif
            isProductLoaded = false
            purchaseError = "Failed to load subscription: \(error.localizedDescription)"
            await refreshPremiumOverride()
        }
    }

    private func loadProductInternal() async throws {
        // Don't sync on load to avoid triggering authentication popup
        // Products will load from local StoreKit data first
        // Sync only happens during purchase/restore when user explicitly takes action
        #if DEBUG
        print("StoreKit: Loading products for id: \(productID)")
        #endif
        let products = try await Product.products(for: [productID])
        #if DEBUG
        print("StoreKit: Product fetch count: \(products.count)")
        #endif

        if let first = products.first {
            #if DEBUG
            print("StoreKit: Loaded product: \(first.id) price=\(first.displayPrice)")
            #endif
            product = first
            isProductLoaded = true
            await refreshEligibility()
            try await refreshStatus()
            await refreshPremiumOverride()
            return
        }

        // Still unavailable; set error state and proceed with override only
        #if DEBUG
        print("StoreKit: Products still unavailable after all attempts. Using premium override only.")
        #endif
        isProductLoaded = false
        purchaseError = "Subscription is currently unavailable. This may be because it's pending Apple approval. Please check back later or contact support."
        await refreshPremiumOverride()
    }

    func purchase() async throws {
        purchaseError = nil

        guard let initialProduct = product else {
            #if DEBUG
            print("StoreKit: purchase() ignored — product is nil (not loaded)")
            #endif
            purchaseError = "Unable to load subscription. Please check your internet connection and try again."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        // Note: Removed AppStore.sync() to prevent unnecessary Apple ID prompts
        // The product pricing is already correct from initial load
        // Transaction updates are handled automatically via Transaction.updates listener
        let productToPurchase = initialProduct
        #if DEBUG
        print("StoreKit: Starting purchase for \(productToPurchase.id) at \(productToPurchase.displayPrice)")
        #endif

        do {
            let result = try await productToPurchase.purchase()
            switch result {
            case .success(let verification):
                do {
                    let transaction = try checkVerified(verification)
                    #if DEBUG
                    print("StoreKit: Purchase verified. Finishing transaction \(transaction.id)")
                    #endif
                    await transaction.finish()
                    await refreshEligibility()
                    try await refreshStatus()
                    purchaseError = nil
                } catch {
                    #if DEBUG
                    print("StoreKit: Purchase verification failed: \(error)")
                    #endif
                    purchaseError = "Purchase verification failed. Please try again."
                }
            case .userCancelled:
                #if DEBUG
                print("StoreKit: Purchase cancelled by user")
                #endif
                purchaseError = nil
            case .pending:
                #if DEBUG
                print("StoreKit: Purchase pending")
                #endif
                purchaseError = "Purchase is pending approval. Please check back later."
            @unknown default:
                #if DEBUG
                print("StoreKit: Purchase result: \(result)")
                #endif
                purchaseError = "Unknown purchase result. Please contact support."
            }
        } catch {
            #if DEBUG
            print("StoreKit: Purchase error: \(error)")
            #endif
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }

    func refreshStatus() async throws {
        guard let subscription = product?.subscription else { return }
        let currentStatus = try await subscription.status
        status = currentStatus

        // Consider any active state as subscribed; detect trial via transaction.offerType
        if let current = currentStatus.first {
            isSubscribed = (current.state == .subscribed)

            do {
                let transaction = try checkVerified(current.transaction)
                // Introductory offer corresponds to free trial when configured in App Store Connect
                isInTrial = (transaction.offerType == .introductory)
            } catch {
                isInTrial = false
            }
        } else {
            isSubscribed = false
            isInTrial = false
        }
        #if DEBUG
        print("StoreKit: refreshStatus — isSubscribed=\(isSubscribed) isInTrial=\(isInTrial) statusCount=\(status.count)")
        #endif
    }

    func refreshEligibility() async {
        guard let product = product, let subscription = product.subscription else {
            isEligibleForTrial = false
            #if DEBUG
            print("StoreKit: Cannot check trial eligibility - product or subscription is nil")
            #endif
            return
        }

        // Check if user is eligible for introductory offer (free trial)
        let eligible = await subscription.isEligibleForIntroOffer
        isEligibleForTrial = eligible

        // Log trial configuration for debugging
        #if DEBUG
        if let introOffer = subscription.introductoryOffer {
            print("StoreKit: Trial eligibility check:")
            print("  - Eligible: \(eligible)")
            print("  - Offer type: \(introOffer.paymentMode)")
            print("  - Period: \(introOffer.period)")
            if introOffer.paymentMode == .freeTrial {
                print("  - Free trial available: \(introOffer.period.value) \(introOffer.period.unit)")
            }
        } else {
            print("StoreKit: No introductory offer configured in App Store Connect")
            print("  - Eligibility: \(eligible)")
        }
        #endif
    }

    func restore() async throws {
        #if DEBUG
        print("StoreKit: Starting restore purchases")
        #endif

        // Note: Removed AppStore.sync() to prevent unnecessary Apple ID prompts
        // Transaction restoration happens automatically when refreshStatus() is called
        // StoreKit 2 handles transaction syncing in the background

        do {
            // Refresh subscription status directly - this checks for existing transactions
            await refreshEligibility()
            try await refreshStatus()
            await refreshPremiumOverride()
            #if DEBUG
            print("StoreKit: Restore completed successfully")
            #endif
        } catch {
            #if DEBUG
            print("StoreKit: Restore failed with error: \(error)")
            #endif
            // Still try to refresh premium override and eligibility even if status refresh fails
            await refreshEligibility()
            await refreshPremiumOverride()
            throw error
        }
    }

    func manageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            #if DEBUG
            print("StoreKit: No valid window scene found for subscription management")
            #endif
            return
        }

        do {
            // Add timeout to prevent infinite loading
            try await withTimeout(seconds: 10) {
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                    #if DEBUG
                    print("StoreKit: Successfully opened subscription management")
                    #endif
                } catch {
                    #if DEBUG
                    print("StoreKit: Error showing manage subscriptions: \(error)")
                    #endif
                    // If the native sheet fails, fall back to opening subscription URL
                    await self.openSubscriptionManagementURL()
                }
            }
        } catch {
            #if DEBUG
            print("StoreKit: Timeout or error in manageSubscriptions: \(error)")
            #endif
            // Fall back to opening subscription URL directly
            await self.openSubscriptionManagementURL()
        }
    }

    private func openSubscriptionManagementURL() async {
        // Open the App Store subscription management page directly
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }

            group.cancelAll()
            return result
        }
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                #if DEBUG
                print("StoreKit: Transaction update received: \(transaction.id)")
                #endif
                await transaction.finish()
                try? await refreshStatus()
            } catch {
                #if DEBUG
                print("StoreKit: Transaction verification failed: \(error)")
                #endif
            }
        }
    }

    deinit {
        transactionTask?.cancel()
        if let authObserver {
            NotificationCenter.default.removeObserver(authObserver)
        }
    }
}

// MARK: - Verification Helper
func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified(_, let error):
        throw error
    case .verified(let safe):
        return safe
    }
}

extension SubscriptionManager {
    func refreshPremiumOverride() async {
        do {
            isPremiumOverride = try await FirebaseManager.shared.getPremiumOverride()
        } catch {
            isPremiumOverride = false
        }
    }
}

// MARK: - Timeout Error
struct TimeoutError: Error {
    var localizedDescription: String {
        return "The operation timed out"
    }
}