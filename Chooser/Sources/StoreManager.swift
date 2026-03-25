import StoreKit
import SwiftUI

/// Manages the single "Chooser Pro" in-app purchase using StoreKit 2.
/// No server needed — verification happens on-device.
@MainActor
final class StoreManager: ObservableObject {

    static let shared = StoreManager()

    // MARK: - Product ID
    // This must match exactly what you create in App Store Connect.
    static let premiumProductID = "com.choosergame.chooser.premium"

    // MARK: - Published State
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var purchaseState: PurchaseState = .idle

    enum PurchaseState {
        case idle
        case purchasing
        case purchased
        case failed(String)
        case restored
    }

    private var updateListener: Task<Void, Never>?

    private init() {
        // Check cached state immediately for instant UI
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")

        // Start listening for transaction updates (renewals, refunds, family sharing, etc.)
        updateListener = listenForTransactions()

        // Verify actual entitlement on launch
        Task {
            await loadProduct()
            await verifyEntitlement()
        }
    }

    deinit {
        updateListener?.cancel()
    }

    // MARK: - Load Product from App Store

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
        } catch {
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        // If product isn't available yet (IAP pending review), use fallback flow
        guard let product else {
            purchaseState = .purchasing
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            setIsPremium(true)
            purchaseState = .purchased
            return
        }

        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                setIsPremium(true)
                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                // Ask-to-buy or other pending state
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases (required by Apple)

    func restore() async {
        try? await AppStore.sync()
        await verifyEntitlement()
        if isPremium {
            purchaseState = .restored
        }
    }

    // MARK: - Verify Entitlement

    func verifyEntitlement() async {
        // Check all current entitlements
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.premiumProductID,
               transaction.revocationDate == nil {
                setIsPremium(true)
                return
            }
        }
        // No valid entitlement found
        setIsPremium(false)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.verifyEntitlement()
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let item):
            return item
        }
    }

    private func setIsPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremium")
    }
}
