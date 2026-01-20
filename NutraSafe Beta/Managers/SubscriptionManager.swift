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

    /// Convenience property to check if user has premium access (subscribed, in trial, or override)
    var hasAccess: Bool {
        isSubscribed || isInTrial || isPremiumOverride
    }

    // MARK: - Free Tier Limits
    /// Maximum diary entries free users can add per day
    nonisolated static let freeDiaryEntriesPerDay = 5
    /// Maximum reactions visible to free users (older ones blurred)
    nonisolated static let freeReactionsLimit = 5
    /// Maximum Use By items free users can add
    nonisolated static let freeUseByItemsLimit = 5
    /// Free users see limited fasting history (days)
    nonisolated static let freeFastingHistoryDays = 7
    /// Free users see limited weight history entries
    nonisolated static let freeWeightHistoryLimit = 7
    private var authObserver: NSObjectProtocol?
    private var transactionTask: Task<Void, Never>?

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
            isProductLoaded = false
            purchaseError = "Unable to connect to App Store. The subscription may be pending approval or there may be a network issue. Please try again later."
            await refreshPremiumOverride()
        } catch {
            isProductLoaded = false
            purchaseError = "Failed to load subscription: \(error.localizedDescription)"
            await refreshPremiumOverride()
        }
    }

    private func loadProductInternal() async throws {
        // Don't sync on load to avoid triggering authentication popup
        // Products will load from local StoreKit data first
        // Sync only happens during purchase/restore when user explicitly takes action
        let products = try await Product.products(for: [productID])

        if let first = products.first {
            product = first
            isProductLoaded = true
            await refreshEligibility()
            try await refreshStatus()
            await refreshPremiumOverride()
            return
        }

        // Still unavailable; set error state and proceed with override only
        isProductLoaded = false
        purchaseError = "Subscription is currently unavailable. This may be because it's pending Apple approval. Please check back later or contact support."
        await refreshPremiumOverride()
    }

    func purchase() async throws {
        purchaseError = nil

        guard let initialProduct = product else {
            purchaseError = "Unable to load subscription. Please check your internet connection and try again."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        // Note: Removed AppStore.sync() to prevent unnecessary Apple ID prompts
        // The product pricing is already correct from initial load
        // Transaction updates are handled automatically via Transaction.updates listener
        let productToPurchase = initialProduct

        do {
            let result = try await productToPurchase.purchase()
            switch result {
            case .success(let verification):
                do {
                    let transaction = try checkVerified(verification)
                    await transaction.finish()
                    await refreshEligibility()
                    try await refreshStatus()
                    purchaseError = nil
                } catch {
                    purchaseError = "Purchase verification failed. Please try again."
                }
            case .userCancelled:
                purchaseError = nil
            case .pending:
                purchaseError = "Purchase is pending approval. Please check back later."
            @unknown default:
                purchaseError = "Unknown purchase result. Please contact support."
            }
        } catch {
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
    }

    func refreshEligibility() async {
        guard let product = product, let subscription = product.subscription else {
            isEligibleForTrial = false
            return
        }

        // Check if user is eligible for introductory offer (free trial)
        let eligible = await subscription.isEligibleForIntroOffer
        isEligibleForTrial = eligible

    }

    func restore() async throws {

        // IMPORTANT: We MUST call AppStore.sync() when user explicitly requests restore
        // This syncs with Apple's servers to fetch existing purchases
        // Without this, restore won't work after app reinstall or if local data is cleared
        do {
            try await AppStore.sync()

            // Refresh subscription status - this checks for existing transactions
            await refreshEligibility()
            try await refreshStatus()
            await refreshPremiumOverride()
        } catch {
            // Still try to refresh premium override and eligibility even if status refresh fails
            await refreshEligibility()
            await refreshPremiumOverride()
            throw error
        }
    }

    func manageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        do {
            // Add timeout to prevent infinite loading
            try await withTimeout(seconds: 10) {
                do {
                    try await AppStore.showManageSubscriptions(in: scene)
                } catch {
                    // If the native sheet fails, fall back to opening subscription URL
                    await self.openSubscriptionManagementURL()
                }
            }
        } catch {
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
                await transaction.finish()
                try? await refreshStatus()
            } catch {
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