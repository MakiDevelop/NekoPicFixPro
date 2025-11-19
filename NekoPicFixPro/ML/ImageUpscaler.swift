//
//  ImageUpscaler.swift
//  NekoPicFixPro
//
//  Created by Codex (via Claude) on 2025/11/19.
//

import AppKit

/// Protocol for image upscaling implementations
/// WARNING: This protocol definition is fixed per AGENTS.md and must not be modified
protocol ImageUpscaler {
    /// Upscales the given image using the implemented model
    /// - Parameter image: The source image to upscale
    /// - Returns: The upscaled image
    /// - Throws: Errors related to model prediction or image processing
    func upscale(_ image: NSImage) throws -> NSImage
}
