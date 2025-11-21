//
//  AppState.swift
//  NekoPicFixPro
//
//  App 全域狀態管理（Free / Pro 模式）
//

import Foundation
import AppKit
import Combine

/// App 授權狀態管理器
class AppState: ObservableObject {

    // MARK: - Singleton

    static let shared = AppState()

    // MARK: - Published Properties

    @Published var isProUnlocked: Bool {
        didSet {
            UserDefaults.standard.set(isProUnlocked, forKey: UserDefaultsKeys.isProUnlocked)
        }
    }

    @Published var remainingFreeEnhances: Int {
        didSet {
            UserDefaults.standard.set(remainingFreeEnhances, forKey: UserDefaultsKeys.remainingFreeEnhances)
        }
    }

    // MARK: - Constants

    private enum UserDefaultsKeys {
        static let isProUnlocked = "NekoPicFixPro.isProUnlocked"
        static let remainingFreeEnhances = "NekoPicFixPro.remainingFreeEnhances"
    }

    /// Free 模式總次數
    static let freeModeEnhanceLimit = 10

    /// Free 模式輸出解析度限制（最大邊）
    static let freeModeMaxResolution: CGFloat = 2048

    // MARK: - Computed Properties

    /// 是否可以使用強化功能
    var canEnhance: Bool {
        return isProUnlocked || remainingFreeEnhances > 0
    }

    /// 是否可以使用批次處理
    var canUseBatch: Bool {
        return isProUnlocked
    }

    /// 狀態描述文字
    var statusText: String {
        if isProUnlocked {
            return "Pro"
        } else {
            return "Free (\(remainingFreeEnhances)/\(Self.freeModeEnhanceLimit))"
        }
    }

    // MARK: - Initialization

    private init() {
        // 🐛 Debug: 印出 Bundle ID
        #if DEBUG
        print("📱 Bundle ID = \(Bundle.main.bundleIdentifier ?? "nil")")
        #endif

        // 🐛 Debug: 重置 UserDefaults（僅在需要時取消註解）
        #if DEBUG
        // ⚠️ 取消註解以重置 Free/Pro 設定
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.isProUnlocked)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.remainingFreeEnhances)
        print("🔄 DEBUG: UserDefaults reset")
        #endif

        // 從 UserDefaults 載入
        self.isProUnlocked = UserDefaults.standard.bool(forKey: UserDefaultsKeys.isProUnlocked)

        // 首次啟動時設定為 10 次
        let savedCount = UserDefaults.standard.object(forKey: UserDefaultsKeys.remainingFreeEnhances) as? Int
        self.remainingFreeEnhances = savedCount ?? Self.freeModeEnhanceLimit

        print("🔓 AppState initialized: Pro=\(isProUnlocked), Remaining=\(remainingFreeEnhances)")
    }

    // MARK: - Public Methods

    /// 消耗一次免費強化次數
    /// - Returns: 是否成功消耗（false 表示已用完）
    @discardableResult
    func consumeFreeEnhance() -> Bool {
        guard !isProUnlocked else {
            // Pro 用戶無需消耗
            return true
        }

        guard remainingFreeEnhances > 0 else {
            return false
        }

        remainingFreeEnhances -= 1
        print("📉 Free enhance consumed: \(remainingFreeEnhances) remaining")
        return true
    }

    /// 升級到 Pro（目前是測試用，未來接 IAP）
    func unlockPro() {
        isProUnlocked = true
        print("✨ Pro unlocked!")
    }

    /// 重置為 Free 模式（測試用）
    func resetToFree() {
        isProUnlocked = false
        remainingFreeEnhances = Self.freeModeEnhanceLimit
        print("🔄 Reset to Free mode")
    }

    /// 限制圖片解析度（Free 模式）
    /// - Parameter image: 原始圖片
    /// - Returns: 限制後的圖片（如果是 Pro 或不需要限制則返回原圖）
    func applyResolutionLimit(to image: NSImage) -> NSImage {
        guard !isProUnlocked else {
            // Pro 用戶無限制
            return image
        }

        let size = image.size
        let maxDimension = max(size.width, size.height)

        guard maxDimension > Self.freeModeMaxResolution else {
            // 已經在限制內
            return image
        }

        // 計算縮放比例
        let scale = Self.freeModeMaxResolution / maxDimension
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        // 建立縮小的圖片
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return image
        }

        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        resizedImage.unlockFocus()

        print("📐 Resolution limited: \(Int(size.width))×\(Int(size.height)) → \(Int(newSize.width))×\(Int(newSize.height))")

        return resizedImage
    }
}
