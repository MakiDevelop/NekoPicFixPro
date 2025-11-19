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

                // 主內容區 - 單一預覽框
                ZStack {
                    if let original = originalImage, let enhanced = enhancedImage, !isProcessing {
                        // Case B: 已強化 → 顯示 Before/After Slider
                        BeforeAfterSliderView(
                            beforeImage: original,
                            afterImage: enhanced
                        )
                    } else if let original = originalImage {
                        // Case A: 尚未強化 → 顯示單一可縮放圖片
                        singleImagePreview(image: original, isProcessing: isProcessing)
                    } else {
                        // 空狀態
                        emptyStateView
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
            allowedContentTypes: SupportedImageFormat.allUTTypes,
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

    // MARK: - Single Image Preview

    @ViewBuilder
    private func singleImagePreview(image: NSImage, isProcessing: Bool) -> some View {
        ZStack {
            // 玻璃卡片背景
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

            // 可縮放圖片容器
            ZoomableImageContainer(image: image)
                .padding(16)

            // 處理中遮罩
            if isProcessing {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)

                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .progressViewStyle(.circular)

                        Text("處理中...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // 提示標籤（非處理中時顯示）
            if !isProcessing {
                VStack {
                    HStack {
                        Text("雙擊重置 • 捏合縮放 • 拖曳移動")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ZStack {
            // 玻璃卡片背景
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

            // 空狀態內容
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary.opacity(0.3))

                VStack(spacing: 8) {
                    Text("拖曳圖片至此")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("或點擊「Open Image」開啟檔案")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Text("支援 \(SupportedImageFormat.supportedFormatsString) 格式")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.top, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
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

                let fileExtension = url.pathExtension.lowercased()

                guard SupportedImageFormat.allExtensions.contains(fileExtension) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "不支援的檔案格式。請使用 \(SupportedImageFormat.supportedFormatsString)。"
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
        print("🔵 [SAVE] Step 1: saveImage() called")

        guard let enhanced = enhancedImage else {
            print("🔴 [SAVE] Error: No enhanced image")
            return
        }

        print("🔵 [SAVE] Step 2: Enhanced image exists, size: \(enhanced.size)")

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [selectedExportFormat.contentType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save Enhanced Image"

        let defaultFileName = originalFileName.isEmpty ? "image" : originalFileName
        savePanel.nameFieldStringValue = "\(defaultFileName)_neko.\(selectedExportFormat.fileExtension)"

        print("🔵 [SAVE] Step 3: Opening save panel...")

        savePanel.begin { response in
            print("🔵 [SAVE] Step 4: Save panel closed, response: \(response.rawValue)")

            guard response == .OK, let url = savePanel.url else {
                print("🟡 [SAVE] User cancelled or no URL")
                return
            }

            print("🔵 [SAVE] Step 5: Save path: \(url.path)")
            print("🔵 [SAVE] Step 6: Starting background conversion...")

            // 在後台線程執行圖片轉換和保存
            DispatchQueue.global(qos: .userInitiated).async {
                print("🔵 [SAVE] Step 7: Background thread started")

                // 轉換圖片
                print("🔵 [SAVE] Step 8: Getting TIFF representation...")
                guard let tiffData = enhanced.tiffRepresentation else {
                    print("🔴 [SAVE] Error: Failed to get TIFF representation")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to convert image (TIFF)"
                        self.showingAlert = true
                    }
                    return
                }

                print("🔵 [SAVE] Step 9: TIFF data size: \(tiffData.count) bytes")
                print("🔵 [SAVE] Step 10: Creating bitmap image rep...")

                guard let bitmapImage = NSBitmapImageRep(data: tiffData) else {
                    print("🔴 [SAVE] Error: Failed to create bitmap image rep")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to convert image (Bitmap)"
                        self.showingAlert = true
                    }
                    return
                }

                print("🔵 [SAVE] Step 11: Bitmap created, converting to \(self.selectedExportFormat.rawValue)...")

                let imageData: Data?
                switch self.selectedExportFormat {
                case .jpeg:
                    print("🔵 [SAVE] Step 12: Encoding as JPEG...")
                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
                case .png:
                    print("🔵 [SAVE] Step 12: Encoding as PNG...")
                    imageData = bitmapImage.representation(using: .png, properties: [:])
                }

                guard let data = imageData else {
                    print("🔴 [SAVE] Error: Failed to encode image")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to convert image to \(self.selectedExportFormat.rawValue)"
                        self.showingAlert = true
                    }
                    return
                }

                print("🔵 [SAVE] Step 13: Encoded data size: \(data.count) bytes")
                print("🔵 [SAVE] Step 14: Writing to file...")

                // 保存檔案
                do {
                    try data.write(to: url)
                    print("✅ [SAVE] Step 15: SUCCESS! Image saved: \(url.lastPathComponent)")
                } catch {
                    print("🔴 [SAVE] Error writing file: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to save image: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }

        print("🔵 [SAVE] Step 3.5: Save panel.begin() returned (async)")
    }
}

// MARK: - Preview
#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
