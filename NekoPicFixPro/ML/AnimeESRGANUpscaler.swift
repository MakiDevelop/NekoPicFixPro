//
//  AnimeESRGANUpscaler.swift
//  NekoPicFixPro
//
//  插畫模式 - 適合漫畫、動漫、二次元
//

import AppKit
import CoreML

/// Anime ESRGAN 插畫模式
/// 適合：漫畫、動漫、二次元、遊戲截圖、手繪線稿
class AnimeESRGANUpscaler: ImageUpscaler {

    // MARK: - Properties
    private let model: MLModel
    private let config: MLModelConfiguration
    private let inputName: String
    private let outputName: String

    // MARK: - Constants
    private let inputSize = 512
    private let outputSize = 2048
    private let maxInputDimension = 2048

    // MARK: - Errors
    enum UpscalerError: LocalizedError {
        case modelNotFound
        case conversionFailed
        case predictionFailed(String)
        case modelConfigurationError(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "realesrganAnime512.mlmodel 未找到"
            case .conversionFailed:
                return "圖片轉換失敗"
            case .predictionFailed(let detail):
                return "模型推論失敗: \(detail)"
            case .modelConfigurationError(let detail):
                return "模型配置錯誤: \(detail)"
            }
        }
    }

    // MARK: - Initialization
    init() throws {
        config = MLModelConfiguration()
        config.computeUnits = .all

        print("🔍 載入插畫模式模型...")

        // Try compiled model first
        if let compiledURL = Bundle.main.url(forResource: "realesrganAnime512", withExtension: "mlmodelc") {
            print("✅ 找到已編譯模型: realesrganAnime512.mlmodelc")
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 插畫模式模型載入成功")
        }
        // Fallback to .mlmodel
        else if let modelURL = Bundle.main.url(forResource: "realesrganAnime512", withExtension: "mlmodel") {
            print("✅ 找到模型檔案: realesrganAnime512.mlmodel")
            let compiledURL = try MLModel.compileModel(at: modelURL)
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 插畫模式模型編譯並載入成功")
        } else {
            print("❌ 插畫模式模型未找到")
            throw UpscalerError.modelNotFound
        }

        // Detect feature names
        let modelDescription = model.modelDescription
        guard let firstInput = modelDescription.inputDescriptionsByName.first?.key,
              let firstOutput = modelDescription.outputDescriptionsByName.first?.key else {
            throw UpscalerError.modelConfigurationError("無法取得模型輸入/輸出特徵名稱")
        }

        inputName = firstInput
        outputName = firstOutput
        print("   輸入: '\(inputName)', 輸出: '\(outputName)'")
    }

    // MARK: - ImageUpscaler Protocol
    func upscale(_ image: NSImage) throws -> NSImage {
        // 記錄原始尺寸
        let originalSize = image.size
        let targetSize = NSSize(
            width: originalSize.width * 4,
            height: originalSize.height * 4
        )

        let preprocessed = preprocessImage(image)

        guard let inputBuffer = preprocessed.toPixelBuffer(width: inputSize, height: inputSize) else {
            throw UpscalerError.conversionFailed
        }

        let outputBuffer = try predict(inputBuffer: inputBuffer)

        guard let resultImage = NSImage.from(pixelBuffer: outputBuffer) else {
            throw UpscalerError.conversionFailed
        }

        // 調整輸出尺寸以保持原始寬高比例（4x）
        guard let finalImage = resultImage.resized(to: targetSize) else {
            throw UpscalerError.conversionFailed
        }

        return finalImage
    }

    // MARK: - Private Methods
    private func preprocessImage(_ image: NSImage) -> NSImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)

        if maxDimension > CGFloat(maxInputDimension) {
            let scale = CGFloat(maxInputDimension) / maxDimension
            let newSize = NSSize(width: size.width * scale, height: size.height * scale)
            return image.resized(to: newSize) ?? image
        }

        return image
    }

    private func predict(inputBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        let inputFeature = try MLDictionaryFeatureProvider(dictionary: [
            inputName: MLFeatureValue(pixelBuffer: inputBuffer)
        ])

        let prediction = try model.prediction(from: inputFeature)

        guard let outputFeature = prediction.featureValue(for: outputName),
              let outputBuffer = outputFeature.imageBufferValue else {
            throw UpscalerError.predictionFailed("無法取得輸出")
        }

        return outputBuffer
    }
}
