import Foundation
import StoreKit

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - Published State

    /// All loaded products
    private(set) var products: [Product] = []
    /// Active subscription → all stages unlocked
    private(set) var isPro: Bool = false
    /// Set of individually purchased stage IDs (2-9)
    private(set) var purchasedStageIDs: Set<Int> = []
    /// Error message from last purchase attempt
    private(set) var purchaseError: String? = nil
    /// Loading indicator
    private(set) var isLoading: Bool = false

    // MARK: - Product Accessors

    var weeklyProduct: Product?  { products.first { $0.id == Constants.ProductIDs.weekly } }
    var monthlyProduct: Product? { products.first { $0.id == Constants.ProductIDs.monthly } }
    var yearlyProduct: Product?  { products.first { $0.id == Constants.ProductIDs.yearly } }

    /// Subscription products sorted by price ascending
    var subscriptionProducts: [Product] {
        products.filter { Constants.ProductIDs.subscriptions.contains($0.id) }
            .sorted { $0.price < $1.price }
    }

    /// Get the Product for a specific stage
    func stageProduct(for stageId: Int) -> Product? {
        products.first { $0.id == Constants.ProductIDs.stage(stageId) }
    }

    /// Whether a specific stage is accessible (subscription OR purchased)
    func isStageAccessible(_ stageId: Int) -> Bool {
        if stageId == 1 { return true }
        return isPro || purchasedStageIDs.contains(stageId)
    }

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        transactionListener = listenForTransactions()
        Task { [weak self] in
            await self?.loadProducts()
            await self?.refreshPurchaseState()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Constants.ProductIDs.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase (subscription or stage)

    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchaseState()

            case .userCancelled:
                break

            case .pending:
                purchaseError = String(localized: "Purchase is pending approval")
                ToastManager.shared.show(String(localized: "Purchase is pending approval"), style: .warning)

            @unknown default:
                break
            }
        } catch {
            purchaseError = String(localized: "Purchase failed: \(error.localizedDescription)")
            ToastManager.shared.show(String(localized: "Purchase failed, please try again later"), style: .error)
            print("[SubscriptionManager] Purchase error: \(error)")
        }
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        try? await AppStore.sync()
        await refreshPurchaseState()
    }

    // MARK: - Refresh All Purchase State

    func refreshPurchaseState() async {
        var hasActiveSub = false
        var stages = Set<Int>()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if Constants.ProductIDs.subscriptions.contains(transaction.productID) {
                hasActiveSub = true
            } else if Constants.ProductIDs.stages.contains(transaction.productID) {
                // Extract stage number from product ID
                if let stageId = stageIdFromProductID(transaction.productID) {
                    stages.insert(stageId)
                }
            }
        }

        isPro = hasActiveSub
        purchasedStageIDs = stages
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshPurchaseState()
                }
            }
        }
    }

    // MARK: - Helpers

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private nonisolated func stageIdFromProductID(_ productID: String) -> Int? {
        // "com.levi.dailyspeak.stage.5" → 5
        guard let last = productID.split(separator: ".").last else { return nil }
        return Int(last)
    }
}
