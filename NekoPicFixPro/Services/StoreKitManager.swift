//
//  StoreKitManager.swift
//  NekoPicFixPro
//
//  StoreKit 3 IAP Manager (macOS 14+)
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {

    // MARK: - Singleton

    static let shared = StoreKitManager()

    // MARK: - Published Properties

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Constants

    private let productID = "tw.maki.NekoPicFixPro.unlock"

    // MARK: - Computed Properties

    var proProduct: Product? {
        return products.first(where: { $0.id == productID })
    }

    var isProUser: Bool {
        return purchasedProductIDs.contains(productID)
    }

    // MARK: - Initialization

    private init() {
        Task {
            await updatePurchasedProducts()
            await fetchProducts()
        }
    }

    // MARK: - Public Methods

    /// 讀取商品資訊
    func fetchProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let products = try await Product.products(for: [productID])
            self.products = products
            print("✅ Products loaded: \(products.count)")
        } catch {
            errorMessage = "無法載入商品：\(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
        }

        isLoading = false
    }

    /// 購買商品
    func purchase() async -> Bool {
        guard let product = proProduct else {
            errorMessage = "商品未載入"
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // 驗證交易
                let transaction = try checkVerified(verification)

                // 解鎖 Pro
                await unlockPro()

                // 完成交易
                await transaction.finish()

                print("✅ Purchase successful")
                isLoading = false
                return true

            case .userCancelled:
                print("⚠️ User cancelled purchase")
                isLoading = false
                return false

            case .pending:
                print("⏳ Purchase pending")
                errorMessage = "購買正在處理中"
                isLoading = false
                return false

            @unknown default:
                print("⚠️ Unknown purchase result")
                isLoading = false
                return false
            }

        } catch {
            errorMessage = "購買失敗：\(error.localizedDescription)"
            print("❌ Purchase failed: \(error)")
            isLoading = false
            return false
        }
    }

    /// 更新已購買商品（掃描交易記錄）
    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == productID {
                    purchased.insert(productID)
                    await unlockPro()
                }

            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }

        purchasedProductIDs = purchased
        print("✅ Updated purchased products: \(purchased)")
    }

    /// 恢復購買
    func restore() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()

            if isProUser {
                print("✅ Purchase restored")
            } else {
                errorMessage = "未找到購買記錄"
                print("⚠️ No purchases found")
            }

        } catch {
            errorMessage = "恢復購買失敗：\(error.localizedDescription)"
            print("❌ Restore failed: \(error)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    /// 解鎖 Pro 版本
    private func unlockPro() async {
        AppState.shared.unlockPro()
    }

    /// 驗證交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Store Error

enum StoreError: Error, LocalizedError {
    case verificationFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "交易驗證失敗"
        case .productNotFound:
            return "找不到商品"
        }
    }
}
