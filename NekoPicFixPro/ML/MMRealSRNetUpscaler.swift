//
//  MMRealSRNetUpscaler.swift
//  NekoPicFixPro
//
//  自然修復（柔）- 自然照片修復（較柔和效果）
//

import AppKit
import CoreML

/// MMRealSRNet 自然修復（柔）模式
/// 適合：自然照片修復，效果較柔和
class MMRealSRNetUpscaler: ImageUpscaler {

    // MARK: - Properties
    private let model: MLModel
    private let config: MLModelConfiguration
    private let inputName: String
    private let outputName: String

    // MARK: - Constants
    private var inputSize: Int = 512  // Will be detected from model
    private var outputSize: Int = 2048  // Will be detected from model
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
                return "MMRealSRNet.mlmodel 未找到"
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

        print("🔍 載入自然修復（柔）模型...")

        // Try compiled model first
        if let compiledURL = Bundle.main.url(forResource: "MMRealSRNet", withExtension: "mlmodelc") {
            print("✅ 找到已編譯模型: MMRealSRNet.mlmodelc")
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 自然修復（柔）模型載入成功")
        }
        // Fallback to .mlmodel
        else if let modelURL = Bundle.main.url(forResource: "MMRealSRNet", withExtension: "mlmodel") {
            print("✅ 找到模型檔案: MMRealSRNet.mlmodel")
            let compiledURL = try MLModel.compileModel(at: modelURL)
            model = try MLModel(contentsOf: compiledURL, configuration: config)
            print("✅ 自然修復（柔）模型編譯並載入成功")
        } else {
            print("❌ 自然修復（柔）模型未找到")
            throw UpscalerError.modelNotFound
        }

        // Detect feature names and sizes
        let modelDescription = model.modelDescription
        guard let firstInput = modelDescription.inputDescriptionsByName.first?.key,
              let firstOutput = modelDescription.outputDescriptionsByName.first?.key else {
            throw UpscalerError.modelConfigurationError("無法取得模型輸入/輸出特徵名稱")
        }

        inputName = firstInput
        outputName = firstOutput

        // Detect input/output sizes from model
        if let inputDesc = modelDescription.inputDescriptionsByName[firstInput],
           let imageConstraint = inputDesc.imageConstraint {
            inputSize = Int(imageConstraint.pixelsWide)
            print("   檢測到輸入尺寸: \(inputSize)×\(inputSize)")
        }

        if let outputDesc = modelDescription.outputDescriptionsByName[firstOutput],
           let imageConstraint = outputDesc.imageConstraint {
            outputSize = Int(imageConstraint.pixelsWide)
            print("   檢測到輸出尺寸: \(outputSize)×\(outputSize)")
        }

        print("   輸入: '\(inputName)', 輸出: '\(outputName)'")
    }

    // MARK: - ImageUpscaler Protocol
    func upscale(_ image: NSImage) throws -> NSImage {
        // 記錄原始尺寸並計算放大倍率
        let originalSize = image.size
        let scale = Double(outputSize) / Double(inputSize)
        let targetSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
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
