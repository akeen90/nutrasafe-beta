import Foundation
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isSubscribed = false
    @Published var isInTrial = false
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
            print("StoreKit: Product loading timed out after 10 seconds")
            isProductLoaded = false
            purchaseError = "Unable to connect to App Store. The subscription may be pending approval or there may be a network issue. Please try again later."
            await refreshPremiumOverride()
        } catch {
            print("StoreKit: Product loading failed with error: \(error)")
            isProductLoaded = false
            purchaseError = "Failed to load subscription: \(error.localizedDescription)"
            await refreshPremiumOverride()
        }
    }

    private func loadProductInternal() async throws {
        // Don't sync on load to avoid triggering authentication popup
        // Products will load from local StoreKit data first
        // Sync only happens during purchase/restore when user explicitly takes action
        print("StoreKit: Loading products for id: \(productID)")
        let products = try await Product.products(for: [productID])
        print("StoreKit: Product fetch count: \(products.count)")

        if let first = products.first {
            print("StoreKit: Loaded product: \(first.id) price=\(first.displayPrice)")
            product = first
            isProductLoaded = true
            try await refreshStatus()
            await refreshPremiumOverride()
            return
        }

        // Still unavailable; set error state and proceed with override only
        print("StoreKit: Products still unavailable after all attempts. Using premium override only.")
        isProductLoaded = false
        purchaseError = "Subscription is currently unavailable. This may be because it's pending Apple approval. Please check back later or contact support."
        await refreshPremiumOverride()
    }

    func purchase() async throws {
        purchaseError = nil

        guard let initialProduct = product else {
            print("StoreKit: purchase() ignored — product is nil (not loaded)")
            purchaseError = "Unable to load subscription. Please check your internet connection and try again."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        // Sync with App Store before purchase to ensure pricing matches user's Apple ID region
        print("StoreKit: Syncing with App Store before purchase")
        var productToPurchase = initialProduct
        do {
            try await AppStore.sync()
            // Reload products after sync to get pricing for authenticated account
            let products = try await Product.products(for: [productID])
            if let updatedProduct = products.first {
                self.product = updatedProduct
                productToPurchase = updatedProduct
                print("StoreKit: Updated product pricing: \(updatedProduct.displayPrice)")
            }
        } catch {
            print("StoreKit: Pre-purchase sync failed: \(error), continuing with existing product")
        }

        print("StoreKit: Starting purchase for \(productToPurchase.id) at \(productToPurchase.displayPrice)")

        do {
            let result = try await productToPurchase.purchase()
            switch result {
            case .success(let verification):
                do {
                    let transaction = try checkVerified(verification)
                    print("StoreKit: Purchase verified. Finishing transaction \(transaction.id)")
                    await transaction.finish()
                    try await refreshStatus()
                    purchaseError = nil
                } catch {
                    print("StoreKit: Purchase verification failed: \(error)")
                    purchaseError = "Purchase verification failed. Please try again."
                }
            case .userCancelled:
                print("StoreKit: Purchase cancelled by user")
                purchaseError = nil
            case .pending:
                print("StoreKit: Purchase pending")
                purchaseError = "Purchase is pending approval. Please check back later."
            @unknown default:
                print("StoreKit: Purchase result: \(result)")
                purchaseError = "Unknown purchase result. Please contact support."
            }
        } catch {
            print("StoreKit: Purchase error: \(error)")
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
        print("StoreKit: refreshStatus — isSubscribed=\(isSubscribed) isInTrial=\(isInTrial) statusCount=\(status.count)")
    }

    func restore() async throws {
        print("StoreKit: Starting restore purchases")
        do {
            // Add timeout to prevent hanging on sync
            try await withTimeout(seconds: 10) {
                try await AppStore.sync()
            }
            print("StoreKit: Successfully synced with App Store")

            // Refresh subscription status and product pricing after sync
            if self.product != nil {
                let products = try await Product.products(for: [productID])
                if let first = products.first {
                    self.product = first
                    print("StoreKit: Updated product pricing after restore: \(first.displayPrice)")
                }
            }

            try await refreshStatus()
            await refreshPremiumOverride()
            print("StoreKit: Restore completed successfully")
        } catch is TimeoutError {
            print("StoreKit: Restore timed out, but will still refresh status")
            // Even if sync times out, try to refresh status
            try? await refreshStatus()
            await refreshPremiumOverride()
            throw TimeoutError()
        } catch {
            print("StoreKit: Restore failed with error: \(error)")
            throw error
        }
    }

    func manageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("StoreKit: No valid window scene found for subscription management")
            return
        }

        do {
            // Add timeout to prevent infinite loading
            try await withTimeout(seconds: 10) {
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                    print("StoreKit: Successfully opened subscription management")
                } catch {
                    print("StoreKit: Error showing manage subscriptions: \(error)")
                    // If the native sheet fails, fall back to opening subscription URL
                    await self.openSubscriptionManagementURL()
                }
            }
        } catch {
            print("StoreKit: Timeout or error in manageSubscriptions: \(error)")
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
                print("StoreKit: Transaction update received: \(transaction.id)")
                await transaction.finish()
                try? await refreshStatus()
            } catch {
                print("StoreKit: Transaction verification failed: \(error)")
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