//
//  ImagePanel.swift
//  NekoPicFixPro
//
//  Created by Claude on 2025/11/19.
//

import SwiftUI
import AppKit

struct ImagePanel: View {
    // MARK: - Properties
    let title: String
    let image: NSImage?
    let isProcessing: Bool

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Title Header
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Image size info
                if let img = image {
                    Text("\(Int(img.size.width)) × \(Int(img.size.height)) px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Image Content Area
            ZStack {
                // Background
                Color(NSColor.textBackgroundColor)

                if isProcessing {
                    // Processing State
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Processing...")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                } else if let img = image {
                    // Display Image
                    GeometryReader { geometry in
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    .padding(20)
                } else {
                    // Empty State
                    VStack(spacing: 12) {
                        Image(systemName: title == "Original" ? "photo.on.rectangle.angled" : "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(title == "Original" ? "No Image Loaded" : "Waiting for Enhancement")
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if title == "Original" {
                            VStack(spacing: 4) {
                                Text("Drag & drop an image here")
                                    .font(.callout)
                                    .foregroundColor(.secondary.opacity(0.7))
                                Text("or click 'Open Image'")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("With Image") {
    ImagePanel(
        title: "Original",
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
        isProcessing: false
    )
    .frame(width: 400, height: 500)
}

#Preview("Processing") {
    ImagePanel(
        title: "Enhanced",
        image: nil,
        isProcessing: true
    )
    .frame(width: 400, height: 500)
}

#Preview("Empty") {
    ImagePanel(
        title: "Original",
        image: nil,
        isProcessing: false
    )
    .frame(width: 400, height: 500)
}
