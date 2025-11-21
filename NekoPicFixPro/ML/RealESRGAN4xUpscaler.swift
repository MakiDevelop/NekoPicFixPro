//
//  RealESRGAN4xUpscaler.swift
//  NekoPicFixPro
//
//  Created by Codex (via Claude) on 2025/11/19.
//

import AppKit
import CoreML
import Vision

/// Real-ESRGAN 4x upscaler implementation
/// Performs 4x super-resolution using the Real-ESRGAN CoreML model
class RealESRGAN4xUpscaler: ImageUpscaler {

    // MARK: - Properties

    /// CoreML model instance
    private let model: MLModel

    /// Model configuration
    private let config: MLModelConfiguration

    /// Model input and output feature names (detected dynamically)
    private let inputName: String
    private let outputName: String
    private static let modelDisplayName = L10n.string("mode.general.name")
    private static let modelFileIdentifier = "realesrgan512.mlmodel"

    // MARK: - Constants

    private let inputSize = 512      // Model input: 512×512
    private let outputSize = 2048    // Model output: 2048×2048 (4x)
    private let maxInputDimension = 2048  // Max dimension before downscaling

    // MARK: - Errors

    enum UpscalerError: LocalizedError {
        case modelNotFound
        case invalidInput
        case predictionFailed(String)
        case conversionFailed
        case modelConfigurationError(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return L10n.formatted("ml.error.model_not_found", RealESRGAN4xUpscaler.modelDisplayName, RealESRGAN4xUpscaler.modelFileIdentifier)
            case .invalidInput:
                return L10n.string("ml.error.invalid_input")
            case .predictionFailed(let detail):
                return L10n.formatted("ml.error.prediction_failed", detail)
            case .conversionFailed:
                return L10n.string("ml.error.conversion_failed")
            case .modelConfigurationError(let detail):
                return L10n.formatted("ml.error.configuration_failed", detail)
            }
        }
    }

    // MARK: - Initialization

    init() throws {
        // Configure model for optimal performance
        config = MLModelConfiguration()
        config.computeUnits = .all  // Use Neural Engine + GPU + CPU

        print("🔍 Attempting to load Real-ESRGAN model...")

        // Try to load the compiled model first (preferred)
        if let compiledURL = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodelc") {
            print("✅ Found compiled model at: \(compiledURL.path)")
            do {
                model = try MLModel(contentsOf: compiledURL, configuration: config)
                print("✅ Model loaded successfully from .mlmodelc")
            } catch {
                print("❌ Failed to load .mlmodelc: \(error.localizedDescription)")
                throw UpscalerError.modelConfigurationError(
                    L10n.formatted("ml.error.compiled_model_failed", error.localizedDescription)
                )
            }
        }
        // Fallback: Try to compile from .mlmodel file
        else if let modelURL = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodel") {
            print("✅ Found .mlmodel at: \(modelURL.path)")
            do {
                print("🔨 Compiling model...")
                let compiledURL = try MLModel.compileModel(at: modelURL)
                print("✅ Model compiled at: \(compiledURL.path)")

                model = try MLModel(contentsOf: compiledURL, configuration: config)
                print("✅ Model loaded successfully from .mlmodel")
            } catch {
                print("❌ Failed to compile/load .mlmodel: \(error.localizedDescription)")
                throw UpscalerError.modelConfigurationError(error.localizedDescription)
            }
        }
        // Neither found
        else {
            print("❌ Neither .mlmodelc nor .mlmodel found in Bundle")
            throw UpscalerError.modelNotFound
        }

        do {

            // Detect input and output names
            let modelDescription = model.modelDescription
            print("\n📋 Model Information:")
            print("   Input features:")
            for input in modelDescription.inputDescriptionsByName {
                print("      - \(input.key): \(input.value.type)")
            }
            print("   Output features:")
            for output in modelDescription.outputDescriptionsByName {
                print("      - \(output.key): \(output.value.type)")
            }

            // Get the first input and output feature names
            guard let firstInput = modelDescription.inputDescriptionsByName.first?.key else {
                throw UpscalerError.modelConfigurationError(L10n.string("ml.error.no_input_features"))
            }
            guard let firstOutput = modelDescription.outputDescriptionsByName.first?.key else {
                throw UpscalerError.modelConfigurationError(L10n.string("ml.error.no_output_features"))
            }

            inputName = firstInput
            outputName = firstOutput

            print("   Using input key: '\(inputName)'")
            print("   Using output key: '\(outputName)'\n")

        } catch {
            print("❌ Failed to load model: \(error.localizedDescription)")
            throw UpscalerError.modelConfigurationError(error.localizedDescription)
        }
    }

    // MARK: - ImageUpscaler Protocol

    func upscale(_ image: NSImage) throws -> NSImage {
        print("\n🎨 Starting image upscaling...")
        print("   Input size: \(image.size)")

        // Step 1: Preprocess - Check and resize if needed
        let preprocessed = preprocessImage(image)
        print("   Preprocessed size: \(preprocessed.size)")

        // Step 2: Convert to 512×512 for model input
        guard let inputBuffer = preprocessed.toPixelBuffer(width: inputSize, height: inputSize) else {
            print("❌ Failed to convert image to pixel buffer")
            throw UpscalerError.conversionFailed
        }
        print("✅ Created input buffer: \(inputSize)×\(inputSize)")

        // Step 3: Run CoreML prediction
        do {
            let outputBuffer = try predict(inputBuffer: inputBuffer)
            print("✅ Prediction successful")

            // Step 4: Convert output back to NSImage
            guard let resultImage = NSImage.from(pixelBuffer: outputBuffer) else {
                print("❌ Failed to convert output buffer to NSImage")
                throw UpscalerError.conversionFailed
            }

            print("✅ Output size: \(resultImage.size)")
            print("🎉 Upscaling complete!\n")

            return resultImage
        } catch let error as UpscalerError {
            throw error
        } catch {
            print("❌ Prediction error: \(error.localizedDescription)")
            throw UpscalerError.predictionFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Methods

    /// Preprocesses the input image according to AGENTS.md specifications
    /// If image dimension > 2048px, downscale to 2048px on the long edge
    private func preprocessImage(_ image: NSImage) -> NSImage {
        let size = image.size
        let maxDimension = max(size.width, size.height)

        // Check if downscaling is needed
        if maxDimension > CGFloat(maxInputDimension) {
            let scale = CGFloat(maxInputDimension) / maxDimension
            let newSize = NSSize(
                width: size.width * scale,
                height: size.height * scale
            )
            return image.resized(to: newSize) ?? image
        }

        return image
    }

    /// Performs CoreML prediction
    /// - Parameter inputBuffer: Input pixel buffer (512×512 RGB)
    /// - Returns: Output pixel buffer (2048×2048 RGB)
    private func predict(inputBuffer: CVPixelBuffer) throws -> CVPixelBuffer {
        // Create input feature using the dynamically detected input name
        let inputFeature: MLFeatureProvider
        do {
            inputFeature = try MLDictionaryFeatureProvider(dictionary: [
                inputName: MLFeatureValue(pixelBuffer: inputBuffer)
            ])
        } catch {
            throw UpscalerError.predictionFailed(
                L10n.formatted("ml.error.create_input_feature_failed", error.localizedDescription)
            )
        }

        // Perform prediction
        let prediction: MLFeatureProvider
        do {
            prediction = try model.prediction(from: inputFeature)
        } catch {
            throw UpscalerError.predictionFailed(
                L10n.formatted("ml.error.prediction_runtime_failed", error.localizedDescription)
            )
        }

        // Extract output using the dynamically detected output name
        guard let outputFeature = prediction.featureValue(for: outputName) else {
            throw UpscalerError.predictionFailed(
                L10n.formatted("ml.error.output_not_found", outputName)
            )
        }

        guard let outputBuffer = outputFeature.imageBufferValue else {
            throw UpscalerError.predictionFailed(L10n.string("ml.error.output_not_image"))
        }

        return outputBuffer
    }
}
