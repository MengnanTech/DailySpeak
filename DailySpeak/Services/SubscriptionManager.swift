import Foundation
import StoreKit

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - State

    private(set) var products: [Product] = []
    private(set) var isPro: Bool = false
    private(set) var currentSubscription: StoreKit.Transaction? = nil
    private(set) var purchaseError: String? = nil
    private(set) var isLoading: Bool = false

    var monthlyProduct: Product? { products.first { $0.id == Constants.SubscriptionProductIDs.monthly } }
    var yearlyProduct: Product? { products.first { $0.id == Constants.SubscriptionProductIDs.yearly } }

    private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        transactionListener = listenForTransactions()
        Task { [weak self] in
            await self?.loadProducts()
            await self?.updateSubscriptionStatus()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: Constants.SubscriptionProductIDs.all)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

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
                await updateSubscriptionStatus()

            case .userCancelled:
                break

            case .pending:
                purchaseError = "购买正在等待审批"

            @unknown default:
                break
            }
        } catch {
            purchaseError = "购买失败：\(error.localizedDescription)"
            print("[SubscriptionManager] Purchase error: \(error)")
        }
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        var foundActive = false
        var latestTransaction: StoreKit.Transaction?

        for productID in Constants.SubscriptionProductIDs.all {
            guard let result = await Transaction.currentEntitlement(for: productID) else { continue }
            if let transaction = try? checkVerified(result) {
                foundActive = true
                if latestTransaction == nil || transaction.purchaseDate > latestTransaction!.purchaseDate {
                    latestTransaction = transaction
                }
            }
        }

        isPro = foundActive
        currentSubscription = latestTransaction
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Verification

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
