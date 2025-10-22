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

    // TODO: Adjust to your final product ID in App Store Connect
    let productID = "com.nutrasafe.pro.monthly"

    init() {
        Task { try? await load() }
    }

    func load() async throws {
        // Try to fetch StoreKit product; if empty, sync with App Store and retry
        let products = try await Product.products(for: [productID])
        if let first = products.first {
            product = first
            try await refreshStatus()
            return
        }

        // Retry after syncing, which helps when the App Store cache is stale
        do {
            try await AppStore.sync()
            let retryProducts = try await Product.products(for: [productID])
            product = retryProducts.first
            if product != nil {
                try await refreshStatus()
            }
        } catch {
            // Keep product nil; UI will show fallback and allow manual Restore
            print("StoreKit: Failed to sync or load products: \(error)")
        }
    }

    func purchase() async throws {
        isPurchasing = true
        defer { isPurchasing = false }

        // Ensure product is available before attempting purchase
        if product == nil {
            do {
                try await load()
            } catch {
                // ignore, we’ll try sync next
            }
            if product == nil {
                do {
                    try await AppStore.sync()
                    try await load()
                } catch {
                    // Fall through and throw a clear error if still nil
                }
            }
            guard let product = product else {
                throw NSError(domain: "StoreKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Subscription product unavailable. Please try again later."])
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                try await refreshStatus()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
            return
        }

        // Product already available
        guard let product = product else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            try await refreshStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
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
    }

    func manageSubscriptions() async {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // Handle environments where this API may throw
            // If non-throwing in current SDK, the optional try compiles away.
            _ = try? await AppStore.showManageSubscriptions(in: scene)
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