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

    private var isOriginalPanel: Bool {
        title == L10n.string("panel.original.title")
    }

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
                        Text(L10n.string("status.processing"))
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
                        Image(systemName: isOriginalPanel ? "photo.on.rectangle.angled" : "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))

                        Text(isOriginalPanel ? L10n.string("panel.empty.no_image") : L10n.string("panel.empty.waiting"))
                            .font(.title3)
                            .foregroundColor(.secondary)

                        if isOriginalPanel {
                            VStack(spacing: 4) {
                                Text(L10n.string("panel.empty.drag"))
                                    .font(.callout)
                                    .foregroundColor(.secondary.opacity(0.7))
                                Text(L10n.formatted("panel.empty.or_click", L10n.string("button.open_image")))
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
        title: L10n.string("panel.original.title"),
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil),
        isProcessing: false
    )
    .frame(width: 400, height: 500)
}

#Preview("Processing") {
    ImagePanel(
        title: L10n.string("panel.enhanced.title"),
        image: nil,
        isProcessing: true
    )
    .frame(width: 400, height: 500)
}

#Preview("Empty") {
    ImagePanel(
        title: L10n.string("panel.original.title"),
        image: nil,
        isProcessing: false
    )
    .frame(width: 400, height: 500)
}
