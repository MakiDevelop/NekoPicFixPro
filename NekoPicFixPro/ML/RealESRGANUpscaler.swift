//
//  RealESRGANUpscaler.swift
//  NekoPicFixPro
//
//  日常強化模式 - 一般照片最佳
//

import AppKit
import CoreML

/// Real-ESRGAN 日常強化模式
/// 適合：風景、建築、物品、人物等一般照片
class RealESRGANUpscaler: ImageUpscaler {

    // MARK: - Properties
    private let model: MLModel
    private let config: MLModelConfiguration
    private let inputName: String
    private let outputName: String
    private static let modelDisplayName = L10n.string("mode.general.name")
    private static let modelFileIdentifier = "realesrgan512.mlmodel"

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
                return L10n.formatted("ml.error.model_not_found", RealESRGANUpscaler.modelDisplayName, RealESRGANUpscaler.modelFileIdentifier)
            case .conversionFailed:
                return L10n.string("ml.error.conversion_failed")
            case .predictionFailed(let detail):
                return L10n.formatted("ml.error.prediction_failed", detail)
            case .modelConfigurationError(let detail):
                return L10n.formatted("ml.error.configuration_failed", detail)
            }
        }
    }

    // MARK: - Initialization
    init() throws {
        config = MLModelConfiguration()
        config.computeUnits = .all

        print("🔍 載入日常強化模型...")

        // Try compiled model first
        if let compiledURL = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodelc") {
            print("✅ 找到已編譯模型: realesrgan512.mlmodelc")
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 日常強化模型載入成功")
        }
        // Fallback to .mlmodel
        else if let modelURL = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodel") {
            print("✅ 找到模型檔案: realesrgan512.mlmodel")
            let compiledURL = try MLModel.compileModel(at: modelURL)
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 日常強化模型編譯並載入成功")
        } else {
            print("❌ 日常強化模型未找到")
            throw UpscalerError.modelNotFound
        }

        // Detect feature names
        let modelDescription = model.modelDescription
        guard let firstInput = modelDescription.inputDescriptionsByName.first?.key,
              let firstOutput = modelDescription.outputDescriptionsByName.first?.key else {
            throw UpscalerError.modelConfigurationError(L10n.string("ml.error.missing_features"))
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
            throw UpscalerError.predictionFailed(L10n.string("ml.error.no_output"))
        }

        return outputBuffer
    }
}
