//
//  ImageEnhancementService.swift
//  NekoPicFixPro
//
//  Created by Codex (via Claude) on 2025/11/19.
//

import AppKit
import Foundation

/// Service for managing image enhancement operations
/// Provides a high-level interface for UI to interact with ML models
class ImageEnhancementService {

    // MARK: - Singleton

    static let shared = ImageEnhancementService()

    // MARK: - Properties

    private var upscaler: ImageUpscaler?
    private let processingQueue = DispatchQueue(label: "com.nekopicfix.processing", qos: .userInitiated)

    // MARK: - Errors

    enum EnhancementError: LocalizedError {
        case modelNotInitialized
        case enhancementFailed(Error)

        var errorDescription: String? {
            switch self {
            case .modelNotInitialized:
                return "Model not initialized. Please ensure RealESRGAN4x.mlmodel is in the project."
            case .enhancementFailed(let error):
                return "Enhancement failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        print("\n🚀 ImageEnhancementService initializing...")

        // Check bundle resources first
        print("📦 Checking Bundle resources...")
        if let modelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodel") {
            print("   ✅ Found .mlmodel at: \(modelPath)")
        } else {
            print("   ❌ .mlmodel NOT found in Bundle")
        }

        if let compiledPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc") {
            print("   ✅ Found .mlmodelc at: \(compiledPath)")
        } else {
            print("   ⚠️  .mlmodelc NOT found (will be compiled on first load)")
        }

        if let urlModel = Bundle.main.url(forResource: "realesrgan512", withExtension: "mlmodel") {
            print("   ✅ Bundle.main.url found: \(urlModel)")
        } else {
            print("   ❌ Bundle.main.url returned nil")
        }

        // Attempt to initialize the upscaler
        print("\n🔧 Attempting to initialize RealESRGAN4xUpscaler...")
        do {
            upscaler = try RealESRGAN4xUpscaler()
            print("✅ ImageEnhancementService ready!\n")
        } catch {
            print("❌ Failed to initialize upscaler:")
            print("   Error: \(error)")
            print("   Localized: \(error.localizedDescription)")
            if let upscalerError = error as? RealESRGAN4xUpscaler.UpscalerError {
                print("   Type: UpscalerError")
                print("   Description: \(upscalerError.errorDescription ?? "no description")")
            }
            print("\n⚠️  Model not available - enhancement will not work")
            print("   Please check that realesrgan512.mlmodel is:")
            print("   1. Added to Xcode project")
            print("   2. Target Membership includes NekoPicFixPro")
            print("   3. Listed in Build Phases → Copy Bundle Resources\n")
        }
    }

    // MARK: - Public Methods

    /// Enhances the given image using the Real-ESRGAN 4x model
    /// - Parameter image: Source image to enhance
    /// - Returns: Enhanced image (4x upscaled)
    /// - Throws: EnhancementError if enhancement fails
    func enhance(_ image: NSImage) throws -> NSImage {
        guard let upscaler = upscaler else {
            throw EnhancementError.modelNotInitialized
        }

        do {
            let enhanced = try upscaler.upscale(image)
            return enhanced
        } catch {
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

    /// Checks if the enhancement service is ready to use
    var isReady: Bool {
        return upscaler != nil
    }
}
