//
//  NSImage+Extensions.swift
//  NekoPicFixPro
//
//  Created by Codex (via Claude) on 2025/11/19.
//

import AppKit
import CoreVideo
import CoreImage

extension NSImage {

    // MARK: - Resizing

    /// Resizes the image to the specified size
    /// - Parameter size: Target size for the image
    /// - Returns: Resized image, or nil if resizing fails
    func resized(to size: NSSize) -> NSImage? {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }

        NSGraphicsContext.current?.imageInterpolation = .high
        draw(in: NSRect(origin: .zero, size: size),
             from: NSRect(origin: .zero, size: self.size),
             operation: .copy,
             fraction: 1.0)

        return newImage
    }

    // MARK: - CVPixelBuffer Conversion

    /// Converts NSImage to CVPixelBuffer
    /// - Parameters:
    ///   - width: Target width in pixels
    ///   - height: Target height in pixels
    /// - Returns: CVPixelBuffer in RGB format (8-bit, sRGB, 0-255 range, no normalization)
    func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        // First resize the image if needed
        let targetSize = NSSize(width: width, height: height)
        guard let resized = self.resized(to: targetSize) else {
            return nil
        }

        // Convert to CGImage
        guard let cgImage = resized.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        // Create pixel buffer attributes
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,  // Using BGRA which is native to macOS
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        // Lock the pixel buffer
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),  // sRGB color space
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return nil
        }

        // Draw the image into the pixel buffer
        // Note: CoreML models typically expect RGB, but macOS uses BGRA
        // The model wrapper should handle this conversion if needed
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }

    // MARK: - Create from CVPixelBuffer

    /// Creates an NSImage from a CVPixelBuffer
    /// - Parameter pixelBuffer: Source pixel buffer
    /// - Returns: NSImage created from the pixel buffer, or nil if conversion fails
    static func from(pixelBuffer: CVPixelBuffer) -> NSImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
}
