import Foundation
import StoreKit
#if DEBUG && canImport(StoreKitTest)
import StoreKitTest
#endif
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

    #if DEBUG && canImport(StoreKitTest)
    private func ensureLocalStoreKitActivated() {
        if #available(iOS 15.0, *) {
            // If StoreKitTest is available but no default session, try to initialize from bundle
            if SKTestSession.default == nil {
                if let url = Bundle.main.url(forResource: "NutraSafe", withExtension: "storekit") {
                    do {
                        let session = try SKTestSession(configurationFileURL: url)
                        session.resetToDefaultState()
                        SKTestSession.default = session
                        print("StoreKitTest: Activated session in SubscriptionManager from \(url)")
                    } catch {
                        print("StoreKitTest: Failed to activate session in SubscriptionManager: \(error)")
                    }
                } else {
                    print("StoreKitTest: NutraSafe.storekit not found in bundle (SubscriptionManager)")
                }
            }
        }
    }
    #endif

    func load() async throws {
        #if DEBUG && canImport(StoreKitTest)
        // Proactively ensure local StoreKit session is activated before fetching products
        ensureLocalStoreKitActivated()
        #endif

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
        print("StoreKit: Loading products for id: \(productID)")
        let products = try await Product.products(for: [productID])
        print("StoreKit: Initial product fetch count: \(products.count)")
        if let first = products.first {
            print("StoreKit: Loaded product: \(first.id) price=\(first.displayPrice)")
            product = first
            isProductLoaded = true
            try await refreshStatus()
            await refreshPremiumOverride()
            return
        }

        do {
            print("StoreKit: No products found; attempting AppStore.sync()")
            try await AppStore.sync()
            // Give StoreKit a brief moment to update local state
            try? await Task.sleep(nanoseconds: 300_000_000)
            let retryProducts = try await Product.products(for: [productID])
            print("StoreKit: Retry product fetch count: \(retryProducts.count)")
            product = retryProducts.first
            if let p = product {
                print("StoreKit: Loaded product after sync: \(p.id) price=\(p.displayPrice)")
                isProductLoaded = true
                try await refreshStatus()
                await refreshPremiumOverride()
                return
            }
        } catch {
            print("StoreKit: Failed to sync or load products: \(error)")
        }

        #if DEBUG && canImport(StoreKitTest)
        // As a final fallback, re-activate test session and try one more time
        print("StoreKit: Products still unavailable; re-activating StoreKitTest and retrying")
        ensureLocalStoreKitActivated()
        try? await Task.sleep(nanoseconds: 300_000_000)
        let finalProducts = try await Product.products(for: [productID])
        print("StoreKit: Final product fetch count: \(finalProducts.count)")
        if let p = finalProducts.first {
            product = p
            isProductLoaded = true
            print("StoreKit: Loaded product after StoreKitTest fallback: \(p.id) price=\(p.displayPrice)")
            try await refreshStatus()
            await refreshPremiumOverride()
            return
        }
        #endif

        // Still unavailable; set error state and proceed with override only
        print("StoreKit: Products still unavailable after all attempts. Using premium override only.")
        isProductLoaded = false
        purchaseError = "Subscription is currently unavailable. This may be because it's pending Apple approval. Please check back later or contact support."
        await refreshPremiumOverride()
    }

    func purchase() async throws {
        purchaseError = nil

        guard let product = product else {
            print("StoreKit: purchase() ignored — product is nil (not loaded)")
            purchaseError = "Unable to load subscription. Please check your internet connection and try again."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        print("StoreKit: Starting purchase for \(product.id)")

        do {
            let result = try await product.purchase()
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
        guard let product = product, let subscription = product.subscription else { return }
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