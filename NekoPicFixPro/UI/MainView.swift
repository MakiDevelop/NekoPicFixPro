//
//  MainView.swift
//  NekoPicFixPro
//
//  Created by Claude on 2025/11/19.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MainView: View {
    // MARK: - State Properties
    @State private var originalImage: NSImage?
    @State private var enhancedImage: NSImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingFileImporter = false
    @State private var showingAlert = false
    @State private var originalFileName: String = ""

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Main Content - Before/After Preview
            HStack(spacing: 1) {
                // Before Panel
                ImagePanel(
                    title: "Original",
                    image: originalImage,
                    isProcessing: false
                )

                Divider()

                // After Panel
                ImagePanel(
                    title: "Enhanced",
                    image: enhancedImage,
                    isProcessing: isProcessing
                )
            }

            Divider()

            // Status Bar
            statusBarView
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 800, minHeight: 600)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.jpeg, .png, .heic],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
        .alert("Error", isPresented: $showingAlert, presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Toolbar View
    private var toolbarView: some View {
        HStack {
            // Open Button
            Button(action: openImage) {
                Label("Open Image", systemImage: "folder.fill")
            }
            .keyboardShortcut("o", modifiers: .command)

            Spacer()

            // Enhance Button
            Button(action: enhanceImage) {
                Label("Enhance", systemImage: "wand.and.stars")
            }
            .disabled(originalImage == nil || isProcessing)
            .keyboardShortcut("e", modifiers: .command)
            .buttonStyle(.borderedProminent)

            Spacer()

            // Save Button
            Button(action: saveImage) {
                Label("Save As...", systemImage: "square.and.arrow.down.fill")
            }
            .disabled(enhancedImage == nil || isProcessing)
            .keyboardShortcut("s", modifiers: .command)
        }
    }

    // MARK: - Status Bar View
    private var statusBarView: some View {
        HStack {
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
                Text("Processing...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else if enhancedImage != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Enhancement complete")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else if originalImage != nil {
                Text("Ready to enhance")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                Text("Open an image to begin")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Image dimensions info
            if let original = originalImage {
                Text("Original: \(Int(original.size.width))×\(Int(original.size.height))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            if let enhanced = enhancedImage {
                Text("Enhanced: \(Int(enhanced.size.width))×\(Int(enhanced.size.height))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions
    private func openImage() {
        showingFileImporter = true
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Check if provider can load file URL
        if provider.canLoadObject(ofClass: URL.self) {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Drop failed: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                    return
                }

                guard let url = url else { return }

                // Validate file extension
                let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif"]
                let fileExtension = url.pathExtension.lowercased()

                guard supportedExtensions.contains(fileExtension) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unsupported file format. Please use JPEG, PNG, or HEIC."
                        self.showingAlert = true
                    }
                    return
                }

                // Load the image on main thread
                DispatchQueue.main.async {
                    self.loadImage(from: url)
                }
            }
            return true
        }

        return false
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            loadImage(from: url)

        case .failure(let error):
            errorMessage = "Failed to open file: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func loadImage(from url: URL) {
        // Start accessing security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // Store the original filename for later use when saving
        originalFileName = url.deletingPathExtension().lastPathComponent

        // Try to load the image with better error handling
        do {
            // Check if file exists
            guard FileManager.default.fileExists(atPath: url.path) else {
                errorMessage = "File not found: \(url.lastPathComponent)"
                showingAlert = true
                return
            }

            // Try to load image data
            let data = try Data(contentsOf: url)

            // Create NSImage from data
            guard let image = NSImage(data: data) else {
                errorMessage = "Invalid image format or corrupted file"
                showingAlert = true
                return
            }

            // Successfully loaded
            originalImage = image
            enhancedImage = nil // Clear previous enhanced image
            errorMessage = nil

            print("✅ Image loaded: \(url.lastPathComponent), size: \(image.size)")

        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func enhanceImage() {
        guard let original = originalImage else { return }

        isProcessing = true
        errorMessage = nil

        // Use ImageEnhancementService to enhance the image
        ImageEnhancementService.shared.enhanceAsync(original) { result in
            switch result {
            case .success(let enhanced):
                self.enhancedImage = enhanced
                self.isProcessing = false

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showingAlert = true
                self.isProcessing = false
            }
        }
    }

    private func saveImage() {
        guard let enhanced = enhancedImage else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save Enhanced Image"

        // Set default filename with _neko suffix
        let defaultFileName = originalFileName.isEmpty ? "image" : originalFileName
        savePanel.nameFieldStringValue = "\(defaultFileName)_neko.jpg"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            // Convert NSImage to JPEG data
            guard let tiffData = enhanced.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) else {
                errorMessage = "Failed to convert image to JPEG"
                showingAlert = true
                return
            }

            do {
                try jpegData.write(to: url)
            } catch {
                errorMessage = "Failed to save image: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .frame(width: 1000, height: 700)
}
