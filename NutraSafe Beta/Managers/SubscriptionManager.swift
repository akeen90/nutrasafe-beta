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
    private var authObserver: NSObjectProtocol?

    // TODO: Adjust to your final product ID in App Store Connect
    let productID = "com.nutrasafe.pro.monthly"

    init() {
        Task { try? await load() }
        authObserver = NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: .main) { [weak self] _ in
            Task { await self?.refreshPremiumOverride() }
        }
        // Ensure override is evaluated at startup, independent of StoreKit product load timing
        Task { await refreshPremiumOverride() }
    }

    func load() async throws {
        // Try to fetch StoreKit product; if empty, sync with App Store and retry
        let products = try await Product.products(for: [productID])
        if let first = products.first {
            product = first
            try await refreshStatus()
            // Also refresh domain-based premium override immediately when product loads successfully
            await refreshPremiumOverride()
            return
        }

        // Retry after syncing, which helps when the App Store cache is stale
        do {
            try await AppStore.sync()
            let retryProducts = try await Product.products(for: [productID])
            product = retryProducts.first
            if product != nil {
                try await refreshStatus()
                await refreshPremiumOverride()
            } else {
                // Even if products are unavailable, still evaluate premium override (e.g., domain-based access)
                await refreshPremiumOverride()
            }
        } catch {
            // Keep product nil; UI will show fallback and allow manual Restore
            print("StoreKit: Failed to sync or load products: \(error)")
            // Still evaluate premium override in error scenarios
            await refreshPremiumOverride()
        }
    }

    func purchase() async throws {
        guard let product = product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            do {
                _ = try checkVerified(verification)
                try await refreshStatus()
            } catch {
                print("Purchase verification failed: \(error)")
            }
        case .userCancelled, .pending:
            break
        default:
            break
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
    }

    func restore() async throws {
        try await AppStore.sync()
        try await refreshStatus()
        await refreshPremiumOverride()
    }

    func manageSubscriptions() async {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Handle environments where this API may throw
            // If non-throwing in current SDK, the optional try compiles away.
            _ = try? await AppStore.showManageSubscriptions(in: scene)
        }
    }

    deinit {
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