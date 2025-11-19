//
//  MainView.swift
//  NekoPicFixPro
//
//  Created by Claude on 2025/11/19.
//  Updated: 玻璃風格 UI
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 圖片儲存格式
enum ImageExportFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        }
    }

    var contentType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        }
    }
}

struct MainView: View {
    // MARK: - State Properties
    @StateObject private var service = ImageEnhancementService.shared
    @State private var originalImage: NSImage?
    @State private var enhancedImage: NSImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingFileImporter = false
    @State private var showingAlert = false
    @State private var originalFileName: String = ""
    @State private var selectedExportFormat: ImageExportFormat = .jpeg

    // MARK: - Body
    var body: some View {
        ZStack {
            // 背景玻璃效果
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 頂部工具列
                topToolbarView
                    .glassToolbar()

                Divider()
                    .opacity(0.3)

                // 模式選擇區
                modeSelectionView
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(.regularMaterial)

                Divider()
                    .opacity(0.3)

                // 主內容區 - Before/After 預覽
                Group {
                    if let original = originalImage, let enhanced = enhancedImage, !isProcessing {
                        // 顯示滑桿比較器（兩張圖片都存在且未處理中）
                        ZStack(alignment: .topLeading) {
                            BeforeAfterSliderView(
                                beforeImage: original,
                                afterImage: enhanced
                            )

                            // Before/After 標籤
                            BeforeAfterLabelOverlay(sliderPosition: 0.5)
                        }
                    } else {
                        // 顯示傳統雙卡片視圖
                        HStack(spacing: 16) {
                            // Before Panel
                            ImagePreviewCard(
                                title: "Original",
                                image: originalImage,
                                isProcessing: false
                            )

                            // After Panel
                            ImagePreviewCard(
                                title: "Enhanced",
                                image: enhancedImage,
                                isProcessing: isProcessing
                            )
                        }
                    }
                }
                .padding(24)

                Divider()
                    .opacity(0.3)

                // 底部操作區
                bottomActionView
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(.regularMaterial)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
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

    // MARK: - Top Toolbar View
    private var topToolbarView: some View {
        HStack(spacing: 16) {
            // App Title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Text("NekoPicFix Pro")
                    .font(.system(size: 16, weight: .semibold))
            }

            Spacer()

            // Open Button
            Button(action: openImage) {
                Label("Open Image", systemImage: "folder.fill")
            }
            .keyboardShortcut("o", modifiers: .command)
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
    }

    // MARK: - Mode Selection View
    private var modeSelectionView: some View {
        VStack(spacing: 12) {
            Text("選擇強化模式")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(EnhancementMode.allCases, id: \.self) { mode in
                    Button(action: {
                        service.setMode(mode)
                    }) {
                        Text(mode.rawValue)
                    }
                    .buttonStyle(ModeCapsuleButtonStyle(
                        isSelected: service.currentMode == mode,
                        isAvailable: service.isAvailable(mode)
                    ))
                    .disabled(!service.isAvailable(mode))
                    .help(mode.description)
                }
            }

            // Current mode description
            Text(service.currentMode.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        HStack(spacing: 24) {
            // Status Info
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 16, height: 16)
                    Text("處理中...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else if let error = errorMessage {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if enhancedImage != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("強化完成")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else if originalImage != nil {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.blue)
                    Text("準備強化")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("開啟圖片以開始")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 200, alignment: .leading)

            Spacer()

            // Main Enhance Button
            Button(action: enhanceImage) {
                Label("強化圖片", systemImage: "wand.and.stars")
            }
            .buttonStyle(ProminentActionButtonStyle(isEnabled: originalImage != nil && !isProcessing))
            .disabled(originalImage == nil || isProcessing)
            .keyboardShortcut("e", modifiers: .command)

            Spacer()

            // Export Format & Save
            HStack(spacing: 12) {
                // Format Picker
                HStack(spacing: 8) {
                    Text("格式:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Picker("", selection: $selectedExportFormat) {
                        ForEach(ImageExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .disabled(enhancedImage == nil || isProcessing)
                }

                // Save Button
                Button(action: saveImage) {
                    Label("Save As...", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(enhancedImage == nil || isProcessing)
                .keyboardShortcut("s", modifiers: .command)
            }
            .frame(minWidth: 200, alignment: .trailing)
        }
    }

    // MARK: - Actions
    private func openImage() {
        showingFileImporter = true
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

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

                let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif"]
                let fileExtension = url.pathExtension.lowercased()

                guard supportedExtensions.contains(fileExtension) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unsupported file format. Please use JPEG, PNG, or HEIC."
                        self.showingAlert = true
                    }
                    return
                }

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
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        originalFileName = url.deletingPathExtension().lastPathComponent

        do {
            guard FileManager.default.fileExists(atPath: url.path) else {
                errorMessage = "File not found: \(url.lastPathComponent)"
                showingAlert = true
                return
            }

            let data = try Data(contentsOf: url)

            guard let image = NSImage(data: data) else {
                errorMessage = "Invalid image format or corrupted file"
                showingAlert = true
                return
            }

            originalImage = image
            enhancedImage = nil
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
        savePanel.allowedContentTypes = [selectedExportFormat.contentType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save Enhanced Image"

        let defaultFileName = originalFileName.isEmpty ? "image" : originalFileName
        savePanel.nameFieldStringValue = "\(defaultFileName)_neko.\(selectedExportFormat.fileExtension)"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            guard let tiffData = enhanced.tiffRepresentation,
                  let bitmapImage = NSBitmapImageRep(data: tiffData) else {
                DispatchQueue.main.async { [self] in
                    self.errorMessage = "Failed to convert image"
                    self.showingAlert = true
                }
                return
            }

            let imageData: Data?
            switch self.selectedExportFormat {
            case .jpeg:
                imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
            case .png:
                imageData = bitmapImage.representation(using: .png, properties: [:])
            }

            guard let data = imageData else {
                DispatchQueue.main.async { [self] in
                    self.errorMessage = "Failed to convert image to \(self.selectedExportFormat.rawValue)"
                    self.showingAlert = true
                }
                return
            }

            do {
                try data.write(to: url)
                print("✅ Image saved: \(url.lastPathComponent)")
            } catch {
                DispatchQueue.main.async { [self] in
                    self.errorMessage = "Failed to save image: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
