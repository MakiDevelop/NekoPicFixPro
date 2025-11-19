//
//  ImageEnhancementService.swift
//  NekoPicFixPro
//
//  Created by Codex (via Claude) on 2025/11/19.
//  Updated: 模型切換功能
//

import AppKit
import Foundation
import Combine

/// 強化模式列舉
enum EnhancementMode: String, CaseIterable {
    case general = "日常強化"
    case naturalStrong = "自然修復（強）"
    case naturalSoft = "自然修復（柔）"
    case anime = "插畫模式"
    case experimental = "實驗模式"

    var description: String {
        switch self {
        case .general:
            return "一般照片最佳，風景、建築、物品、人物都通用"
        case .naturalStrong:
            return "自然照片修復，效果較強"
        case .naturalSoft:
            return "自然照片修復，效果較柔和"
        case .anime:
            return "適合漫畫、動漫、二次元、遊戲截圖、手繪線稿"
        case .experimental:
            return "進階使用者使用，畫面較銳利，可能產生 artifacts"
        }
    }
}

/// Service for managing image enhancement operations
/// Provides a high-level interface for UI to interact with ML models
class ImageEnhancementService: ObservableObject {

    // MARK: - Singleton

    static let shared = ImageEnhancementService()

    // MARK: - Published Properties

    @Published var currentMode: EnhancementMode = .general

    // MARK: - Properties

    private var upscalers: [EnhancementMode: ImageUpscaler] = [:]
    private let processingQueue = DispatchQueue(label: "com.nekopicfix.processing", qos: .userInitiated)

    // MARK: - Errors

    enum EnhancementError: LocalizedError {
        case modelNotInitialized(EnhancementMode)
        case enhancementFailed(Error)

        var errorDescription: String? {
            switch self {
            case .modelNotInitialized(let mode):
                return "模型「\(mode.rawValue)」未初始化"
            case .enhancementFailed(let error):
                return "強化失敗: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        print("\n🚀 ImageEnhancementService 初始化...")
        print("📦 載入所有可用模型...\n")

        // Try to load all models individually
        // 日常強化
        do {
            let upscaler = try RealESRGANUpscaler()
            upscalers[.general] = upscaler
            print("✅ 日常強化 已就緒")
        } catch {
            print("⚠️  日常強化 無法載入: \(error.localizedDescription)")
        }

        // 自然修復（強）
        do {
            let upscaler = try MMRealSRGANUpscaler()
            upscalers[.naturalStrong] = upscaler
            print("✅ 自然修復（強）已就緒")
        } catch {
            print("⚠️  自然修復（強）無法載入: \(error.localizedDescription)")
        }

        // 自然修復（柔）
        do {
            let upscaler = try MMRealSRNetUpscaler()
            upscalers[.naturalSoft] = upscaler
            print("✅ 自然修復（柔）已就緒")
        } catch {
            print("⚠️  自然修復（柔）無法載入: \(error.localizedDescription)")
        }

        // 插畫模式
        do {
            let upscaler = try AnimeESRGANUpscaler()
            upscalers[.anime] = upscaler
            print("✅ 插畫模式 已就緒")
        } catch {
            print("⚠️  插畫模式 無法載入: \(error.localizedDescription)")
        }

        // 實驗模式
        do {
            let upscaler = try AESRGANUpscaler()
            upscalers[.experimental] = upscaler
            print("✅ 實驗模式 已就緒")
        } catch {
            print("⚠️  實驗模式 無法載入: \(error.localizedDescription)")
        }

        print("\n✅ ImageEnhancementService 就緒")
        print("   可用模式: \(upscalers.keys.map { $0.rawValue }.joined(separator: ", "))")
        print("   預設模式: \(currentMode.rawValue)\n")
    }

    // MARK: - Public Methods

    /// 切換強化模式
    /// - Parameter mode: 目標模式
    func setMode(_ mode: EnhancementMode) {
        currentMode = mode
        print("🔄 切換至：\(mode.rawValue)")
    }

    /// 檢查指定模式是否可用
    /// - Parameter mode: 要檢查的模式
    /// - Returns: 是否可用
    func isAvailable(_ mode: EnhancementMode) -> Bool {
        return upscalers[mode] != nil
    }

    /// Enhances the given image using the selected model
    /// - Parameter image: Source image to enhance
    /// - Returns: Enhanced image (4x upscaled)
    /// - Throws: EnhancementError if enhancement fails
    func enhance(_ image: NSImage) throws -> NSImage {
        print("\n🎨 開始強化（模式：\(currentMode.rawValue)）...")

        do {
            guard let upscaler = upscalers[currentMode] else {
                throw EnhancementError.modelNotInitialized(currentMode)
            }

            let enhanced = try upscaler.upscale(image)

            print("✅ 強化完成\n")
            return enhanced
        } catch {
            print("❌ 強化失敗: \(error.localizedDescription)\n")
            throw EnhancementError.enhancementFailed(error)
        }
    }

    /// Enhances the image asynchronously
    /// - Parameters:
    ///   - image: Source image to enhance
    ///   - completion: Completion handler called on main queue with result
    func enhanceAsync(_ image: NSImage, completion: @escaping (Result<NSImage, Error>) -> Void) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            do {
                let enhanced = try self.enhance(image)
                DispatchQueue.main.async {
                    completion(.success(enhanced))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// 取得所有可用的模式
    var availableModes: [EnhancementMode] {
        return EnhancementMode.allCases.filter { isAvailable($0) }
    }

    /// Checks if the enhancement service is ready to use
    var isReady: Bool {
        return !upscalers.isEmpty
    }
}
