//
//  MainView.swift
//  NekoPicFixPro
//
//  Premium Apple Glass Design
//  已優化：拖放視覺回饋 + 鍵盤快捷鍵
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
    @StateObject private var recentFiles = RecentFiles.shared
    @StateObject private var history = EnhancementHistory()
    @StateObject private var batchProcessor = BatchProcessor()
    @StateObject private var memoryMonitor = MemoryMonitor.shared

    @State private var originalImage: NSImage?
    @State private var enhancedImage: NSImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingFileImporter = false
    @State private var showingAlert = false
    @State private var originalFileName: String = ""
    @State private var selectedExportFormat: ImageExportFormat = .jpeg

    // 🎯 優化 16: 匯出品質控制
    @AppStorage("jpegQuality") private var jpegQuality: Double = 0.90

    // 🎯 優化 1: 拖放視覺回饋
    @State private var isDropTargeted = false

    // 🎯 優化 6: 模式切換動畫
    @Namespace private var modeAnimation

    // 🎯 優化 8: 處理時間顯示
    @State private var processingTime: TimeInterval = 0
    @State private var processingStartTime: Date?

    // 🎯 優化 13: 處理進度指示
    @State private var processingProgress: Double = 0.0

    // 🎯 優化 14: 大圖片警告
    @State private var showingLargeImageWarning = false
    @State private var pendingLargeImage: (image: NSImage, url: URL)?
    private let maxImageDimension: CGFloat = 8192  // 8K

    // 🎯 優化 18: 批次處理模式
    @State private var isBatchMode: Bool = false
    @State private var showingBatchRejectedAlert = false
    @State private var batchRejectedReasons: [String] = []

    // MARK: - Body
    var body: some View {
        ZStack {
            // 背景玻璃效果
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 頂部工具列
                topToolbar

                Divider()
                    .opacity(0.2)

                // 主內容區
                HStack(spacing: GlassDesign.Spacing.s) {
                    // 側邊模式選擇列
                    // 🎯 優化 17: 增加寬度以容納現代化卡片
                    modeSidebar
                        .frame(width: 260)

                    // 主預覽區（單一預覽框）
                    mainPreviewArea
                }
                .padding(GlassDesign.Spacing.m)

                Divider()
                    .opacity(0.2)

                // 底部工具列
                bottomToolbar
            }
        }
        .frame(minWidth: 1200, minHeight: 800)
        // 🎯 優化 1: 拖放回饋（isTargeted 綁定）
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: SupportedImageFormat.allUTTypes,
            allowsMultipleSelection: isBatchMode
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
        // 🎯 優化 14: 大圖片警告對話框
        .alert("大型圖片警告", isPresented: $showingLargeImageWarning) {
            Button("繼續處理", role: .destructive) {
                if let pending = pendingLargeImage {
                    let cacheKey = pending.url.path
                    ImageCache.shared.set(pending.image, forKey: cacheKey)
                    originalImage = pending.image
                    enhancedImage = nil
                    errorMessage = nil
                    recentFiles.addRecentFile(pending.url)
                    pendingLargeImage = nil
                }
            }
            Button("取消", role: .cancel) {
                pendingLargeImage = nil
            }
        } message: {
            if let pending = pendingLargeImage {
                let width = Int(pending.image.size.width)
                let height = Int(pending.image.size.height)
                Text("此圖片尺寸為 \(width) × \(height) 像素，超過建議的 \(Int(maxImageDimension)) × \(Int(maxImageDimension)) 限制。\n\n處理超大圖片可能導致記憶體不足或效能問題。\n\n是否仍要繼續？")
            }
        }
        // 🎯 優化 18: 批次檔案被拒絕警告
        .alert("部分檔案無法加入", isPresented: $showingBatchRejectedAlert) {
            Button("OK") {
                batchRejectedReasons = []
            }
        } message: {
            if !batchRejectedReasons.isEmpty {
                Text(batchRejectedReasons.prefix(5).joined(separator: "\n") + (batchRejectedReasons.count > 5 ? "\n... 及其他 \(batchRejectedReasons.count - 5) 個檔案" : ""))
            }
        }
        // 🎯 優化 2: 鍵盤快捷鍵
        .onKeyPress(.init("1"), phases: .down, action: { _ in
            if service.isAvailable(.general) {
                service.setMode(.general)
                return .handled
            }
            return .ignored
        })
        .onKeyPress(.init("2"), phases: .down, action: { _ in
            if service.isAvailable(.naturalStrong) {
                service.setMode(.naturalStrong)
                return .handled
            }
            return .ignored
        })
        .onKeyPress(.init("3"), phases: .down, action: { _ in
            if service.isAvailable(.naturalSoft) {
                service.setMode(.naturalSoft)
                return .handled
            }
            return .ignored
        })
        .onKeyPress(.init("4"), phases: .down, action: { _ in
            if service.isAvailable(.anime) {
                service.setMode(.anime)
                return .handled
            }
            return .ignored
        })
        .onKeyPress(.init("5"), phases: .down, action: { _ in
            if service.isAvailable(.experimental) {
                service.setMode(.experimental)
                return .handled
            }
            return .ignored
        })
        // 🎯 優化 12: 撤銷/重做快捷鍵
        .onKeyPress(.init("z"), phases: .down, action: { event in
            if event.modifiers.contains(.command) && !event.modifiers.contains(.shift) {
                if history.canUndo {
                    undoEnhancement()
                    return .handled
                }
            }
            return .ignored
        })
        .onKeyPress(.init("z"), phases: .down, action: { event in
            if event.modifiers.contains(.command) && event.modifiers.contains(.shift) {
                if history.canRedo {
                    redoEnhancement()
                    return .handled
                }
            }
            return .ignored
        })
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: GlassDesign.Spacing.s) {
            // App Title
            HStack(spacing: GlassDesign.Spacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("NekoPicFix Pro")
                    .font(GlassDesign.Typography.title)
                    .foregroundColor(GlassDesign.Colors.textPrimary)
            }

            Spacer()

            // 🎯 快捷鍵提示
            Text("⌘O 開啟 • ⌘E 強化 • ⌘C 複製 • ⌘S 儲存 • ⌘Z 撤銷")
                .font(.system(size: 10))
                // 🎯 優化 10: 提升深色模式對比度
                .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.7))

            Spacer()

            // 🎯 優化 11: 最近使用的檔案選單
            if !recentFiles.recentURLs.isEmpty {
                Menu {
                    ForEach(recentFiles.recentURLs, id: \.path) { url in
                        Button(action: {
                            loadImage(from: url)
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        recentFiles.clearRecentFiles()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("清除列表")
                        }
                    }
                } label: {
                    Label("Recent", systemImage: "clock")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            // 🎯 優化 18: 批次模式切換
            Picker("", selection: $isBatchMode) {
                Text("單張模式").tag(false)
                Text("批次模式").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .onChange(of: isBatchMode) { _, newValue in
                if newValue && !batchProcessor.items.isEmpty {
                    // Switching to batch mode - do nothing
                } else if !newValue {
                    // Switching to single mode - clear batch queue if empty
                    if batchProcessor.completedCount == batchProcessor.totalCount {
                        batchProcessor.clearQueue()
                    }
                }
            }

            // Open Image Button
            Button(action: openImage) {
                Label(isBatchMode ? "Add Files" : "Open Image", systemImage: isBatchMode ? "plus.rectangle.on.folder.fill" : "folder.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: .command)
        }
        .glassToolbar()
    }

    // MARK: - Mode Sidebar

    private var modeSidebar: some View {
        VStack(alignment: .leading, spacing: GlassDesign.Spacing.s) {
            // 🎯 優化 17: 現代化標題設計
            VStack(alignment: .leading, spacing: 4) {
                Text("強化模式")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("選擇適合的 AI 處理模式")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            // 🎯 優化 17: 現代化模式卡片
            VStack(spacing: 10) {
                ForEach(Array(EnhancementMode.allCases.enumerated()), id: \.element) { index, mode in
                    ModernModeCard(
                        mode: mode,
                        isSelected: service.currentMode == mode,
                        isAvailable: service.isAvailable(mode),
                        shortcutKey: "⌘\(index + 1)",
                        action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                service.setMode(mode)
                            }
                        }
                    )
                }
            }

            Spacer()
        }
        .padding(GlassDesign.Spacing.s)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: GlassDesign.Shadow.card.color,
                    radius: GlassDesign.Shadow.card.radius,
                    y: GlassDesign.Shadow.card.y
                )
        )
    }

    // MARK: - Main Preview Area

    private var mainPreviewArea: some View {
        ZStack {
            if isBatchMode {
                // 🎯 優化 18: 批次處理介面
                batchProcessingView
            } else {
                if let original = originalImage, let enhanced = enhancedImage, !isProcessing {
                    // Case 2: 強化後 → Before/After 分割
                    BeforeAfterSliderView(
                        beforeImage: original,
                        afterImage: enhanced
                    )
                } else if let original = originalImage {
                    // Case 1: 尚未強化 → 單一可縮放預覽
                    singleImagePreview(image: original)
                } else {
                    // 空狀態
                    emptyStateView
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Single Image Preview

    private func singleImagePreview(image: NSImage) -> some View {
        ZStack {
            // 可縮放圖片容器
            ZoomableImageContainer(image: image)
                .padding(GlassDesign.Spacing.s)

            // 🎯 優化 4: 骨架屏載入動畫
            if isProcessing {
                CompactSkeletonView()
            }

            // 提示標籤
            if !isProcessing {
                VStack {
                    HStack {
                        Text("雙擊重置 • 捏合縮放 • 拖曳移動")
                            .font(GlassDesign.Typography.caption)
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, GlassDesign.Spacing.xs)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(.thinMaterial)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                    .shadow(
                                        color: GlassDesign.Shadow.subtle.color,
                                        radius: GlassDesign.Shadow.subtle.radius,
                                        y: GlassDesign.Shadow.subtle.y
                                    )
                            )
                        Spacer()
                    }
                    .padding(GlassDesign.Spacing.s)
                    Spacer()
                }
            }
        }
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: GlassDesign.Spacing.m) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .thin))
                // 🎯 優化 10: 提升深色模式對比度
                .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.5))

            VStack(spacing: GlassDesign.Spacing.xxs) {
                Text("拖曳圖片至此")
                    .font(GlassDesign.Typography.title)
                    .foregroundColor(GlassDesign.Colors.textPrimary)

                Text("或點擊「Open Image」開啟檔案")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
            }

            Text("支援 \(SupportedImageFormat.supportedFormatsString) 格式")
                .font(GlassDesign.Typography.caption)
                .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.7))
                .padding(.top, GlassDesign.Spacing.xxs)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassCard()
        // 🎯 優化 1: 拖放高亮效果
        .overlay(
            RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                .strokeBorder(
                    Color.accentColor.opacity(isDropTargeted ? 0.6 : 0),
                    lineWidth: 3
                )
                .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
        )
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: GlassDesign.Spacing.s) {
            // 狀態指示
            statusIndicator
                .frame(minWidth: 200, alignment: .leading)

            Spacer()

            // 強化按鈕
            Button(action: enhanceImage) {
                Label("強化圖片", systemImage: "wand.and.stars")
            }
            .buttonStyle(PrimaryGlassButtonStyle(isEnabled: originalImage != nil && !isProcessing))
            .disabled(originalImage == nil || isProcessing)
            .keyboardShortcut("e", modifiers: .command)

            Spacer()

            // 匯出區域
            exportControls
                .frame(minWidth: 200, alignment: .trailing)
        }
        .padding(.horizontal, GlassDesign.Spacing.m)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                .fill(.thinMaterial)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 6,
                    y: 0
                )
        )
        .padding(.horizontal, GlassDesign.Spacing.m)
        .padding(.bottom, GlassDesign.Spacing.s)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        HStack(spacing: GlassDesign.Spacing.xs) {
            if isProcessing {
                // 🎯 優化 13: 顯示進度條和百分比
                ProgressView(value: processingProgress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 100)

                Text("處理中 \(Int(processingProgress * 100))%")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
                    .monospacedDigit()
            } else if let error = errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error)
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
                    .lineLimit(1)
            } else if enhancedImage != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                // 🎯 優化 8: 顯示處理時間
                Text(processingTime > 0 ? "強化完成 (\(String(format: "%.1f", processingTime))秒)" : "強化完成")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
            } else if originalImage != nil {
                Image(systemName: "photo.fill")
                    .foregroundColor(.blue)
                Text("準備強化")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
            } else {
                Image(systemName: "arrow.up.doc.fill")
                    // 🎯 優化 10: 提升深色模式對比度
                    .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.6))
                Text("開啟圖片以開始")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)
            }
        }
    }

    // MARK: - Batch Processing View

    private var batchProcessingView: some View {
        VStack(spacing: 0) {
            // Batch queue list
            if batchProcessor.items.isEmpty {
                // Empty state for batch mode
                VStack(spacing: GlassDesign.Spacing.m) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.5))

                    VStack(spacing: GlassDesign.Spacing.xxs) {
                        Text("拖曳多個圖片至此")
                            .font(GlassDesign.Typography.title)
                            .foregroundColor(GlassDesign.Colors.textPrimary)

                        Text("或點擊「Add Files」選擇檔案")
                            .font(GlassDesign.Typography.label)
                            .foregroundColor(GlassDesign.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("批次處理限制：")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(GlassDesign.Colors.textSecondary)

                        Text("• 最多 30 張圖片")
                        Text("• 單張最大 8192×8192 像素")
                        Text("• 自動儲存至原檔案目錄")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(GlassDesign.Colors.textSecondary.opacity(0.8))
                    .padding(.top, GlassDesign.Spacing.xs)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassCard()
                .overlay(
                    RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                        .strokeBorder(
                            Color.accentColor.opacity(isDropTargeted ? 0.6 : 0),
                            lineWidth: 3
                        )
                        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
                )
            } else {
                // Batch queue list with items
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(batchProcessor.items) { item in
                            batchItemRow(item)
                        }
                    }
                    .padding(GlassDesign.Spacing.s)
                }
                .glassCard()
            }

            // Batch controls
            HStack(spacing: GlassDesign.Spacing.s) {
                // Memory indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(memoryPressureColor)
                        .frame(width: 8, height: 8)

                    Text("記憶體: \(Int(memoryMonitor.memoryUsagePercentage))%")
                        .font(.system(size: 11))
                        .foregroundColor(GlassDesign.Colors.textSecondary)
                }

                Spacer()

                // Batch progress
                if batchProcessor.isProcessing || batchProcessor.isPaused {
                    ProgressView(value: batchProcessor.totalProgress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 150)

                    Text("\(batchProcessor.completedCount + batchProcessor.failedCount)/\(batchProcessor.totalCount)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(GlassDesign.Colors.textSecondary)
                }

                Spacer()

                // Control buttons
                if batchProcessor.isProcessing {
                    if batchProcessor.isPaused {
                        Button(action: {
                            batchProcessor.resumeProcessing()
                        }) {
                            Label("Resume", systemImage: "play.fill")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(action: {
                            batchProcessor.pauseProcessing()
                        }) {
                            Label("Pause", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(action: {
                        batchProcessor.cancelProcessing()
                    }) {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: {
                        batchProcessor.startProcessing()
                    }) {
                        Label("Start Processing", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(batchProcessor.items.isEmpty)

                    Button(action: {
                        batchProcessor.clearQueue()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(batchProcessor.items.isEmpty)
                }
            }
            .padding(GlassDesign.Spacing.s)
            .background(
                RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.large)
                    .fill(.ultraThinMaterial)
            )
            .padding(.top, GlassDesign.Spacing.s)
        }
    }

    private func batchItemRow(_ item: BatchItem) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(batchItemStatusColor(item).opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: batchItemStatusIcon(item))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(batchItemStatusColor(item))
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(GlassDesign.Colors.textPrimary)
                    .lineLimit(1)

                Text(item.statusText)
                    .font(.system(size: 11))
                    .foregroundColor(GlassDesign.Colors.textSecondary)
            }

            Spacer()

            // Progress or action
            if case .processing = item.status {
                ProgressView(value: item.progress, total: 1.0)
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
                    .frame(width: 20, height: 20)
            } else if case .pending = item.status {
                Button(action: {
                    batchProcessor.removeItem(item)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var memoryPressureColor: Color {
        switch memoryMonitor.memoryPressure {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }

    private func batchItemStatusColor(_ item: BatchItem) -> Color {
        switch item.status {
        case .pending:
            return .gray
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        }
    }

    private func batchItemStatusIcon(_ item: BatchItem) -> String {
        switch item.status {
        case .pending:
            return "clock"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark"
        case .failed:
            return "xmark"
        case .cancelled:
            return "slash.circle"
        }
    }

    // MARK: - Export Controls

    private var exportControls: some View {
        HStack(spacing: GlassDesign.Spacing.xs) {
            // 格式選擇
            HStack(spacing: GlassDesign.Spacing.xxs) {
                Text("格式:")
                    .font(GlassDesign.Typography.label)
                    .foregroundColor(GlassDesign.Colors.textSecondary)

                Picker("", selection: $selectedExportFormat) {
                    ForEach(ImageExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 110)
                .disabled(enhancedImage == nil || isProcessing)
            }

            // 🎯 優化 16: JPEG 品質滑桿
            if selectedExportFormat == .jpeg {
                HStack(spacing: GlassDesign.Spacing.xxs) {
                    Text("品質:")
                        .font(GlassDesign.Typography.label)
                        .foregroundColor(GlassDesign.Colors.textSecondary)

                    Slider(value: $jpegQuality, in: 0.6...1.0, step: 0.05)
                        .frame(width: 80)
                        .disabled(enhancedImage == nil || isProcessing)

                    Text("\(Int(jpegQuality * 100))%")
                        .font(GlassDesign.Typography.label)
                        .foregroundColor(GlassDesign.Colors.textPrimary)
                        .frame(width: 35, alignment: .trailing)
                        .monospacedDigit()
                }
            }

            // 🎯 優化 15: 複製按鈕
            Button(action: copyToClipboard) {
                Label("Copy", systemImage: "doc.on.doc.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(enhancedImage == nil || isProcessing)
            .keyboardShortcut("c", modifiers: .command)
            .help("複製強化後的圖片到剪貼簿 (⌘C)")

            // Save As 按鈕
            Button(action: saveImage) {
                Label("Save As...", systemImage: "square.and.arrow.down.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(enhancedImage == nil || isProcessing)
            .keyboardShortcut("s", modifiers: .command)
        }
    }

    // MARK: - Actions

    private func openImage() {
        showingFileImporter = true
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        if isBatchMode {
            // Batch mode: Handle multiple files
            let group = DispatchGroup()
            var urls: [URL] = []

            for provider in providers {
                if provider.canLoadObject(ofClass: URL.self) {
                    group.enter()
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        defer { group.leave() }
                        if let url = url {
                            urls.append(url)
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                let result = self.batchProcessor.addFiles(urls, mode: self.service.currentMode)
                if !result.rejected.isEmpty {
                    self.batchRejectedReasons = result.rejected
                    self.showingBatchRejectedAlert = true
                }
            }

            return true
        } else {
            // Single mode: Handle one file
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
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if isBatchMode {
                // Batch mode: Add multiple files
                let result = batchProcessor.addFiles(urls, mode: service.currentMode)
                if !result.rejected.isEmpty {
                    batchRejectedReasons = result.rejected
                    showingBatchRejectedAlert = true
                }
            } else {
                // Single mode: Load one file
                guard let url = urls.first else { return }
                loadImage(from: url)
            }

        case .failure(let error):
            errorMessage = "Failed to open file: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    /// 載入圖片 - 使用 ImageIO 自動偵測格式
    /// 支援：JPEG, PNG, HEIC, BMP, TIFF, WebP
    /// 🎯 優化 5: 整合圖片快取機制
    private func loadImage(from url: URL) {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        originalFileName = url.deletingPathExtension().lastPathComponent

        // 🎯 優化 5: 快取 key（使用檔案路徑）
        let cacheKey = url.path

        // 🎯 優化 5: 先檢查快取
        if let cachedImage = ImageCache.shared.get(forKey: cacheKey) {
            print("✅ Image loaded from cache: \(url.lastPathComponent)")
            originalImage = cachedImage
            enhancedImage = nil
            errorMessage = nil
            return
        }

        do {
            guard FileManager.default.fileExists(atPath: url.path) else {
                errorMessage = "File not found: \(url.lastPathComponent)"
                showingAlert = true
                return
            }

            // 使用 ImageIO 自動偵測格式（包含 WebP）
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
                // Fallback to NSImage
                let data = try Data(contentsOf: url)
                guard let image = NSImage(data: data) else {
                    errorMessage = "Invalid image format or corrupted file"
                    showingAlert = true
                    return
                }
                // 🎯 優化 5: 儲存到快取
                ImageCache.shared.set(image, forKey: cacheKey)
                originalImage = image
                enhancedImage = nil
                errorMessage = nil
                // 🎯 優化 11: 添加到最近使用列表
                recentFiles.addRecentFile(url)
                print("✅ Image loaded (NSImage): \(url.lastPathComponent)")
                return
            }

            // 轉換 CGImage → NSImage
            let size = CGSize(width: cgImage.width, height: cgImage.height)
            let image = NSImage(cgImage: cgImage, size: size)

            // 取得格式資訊
            if let typeIdentifier = CGImageSourceGetType(imageSource) {
                print("✅ Image loaded (ImageIO): \(url.lastPathComponent)")
                print("   UTI: \(typeIdentifier)")
                print("   Size: \(size.width) × \(size.height)")
            }

            // 🎯 優化 14: 檢查圖片尺寸
            if size.width > maxImageDimension || size.height > maxImageDimension {
                pendingLargeImage = (image, url)
                showingLargeImageWarning = true
                print("⚠️ Large image detected: \(size.width) × \(size.height)")
                return
            }

            // 🎯 優化 5: 儲存到快取
            ImageCache.shared.set(image, forKey: cacheKey)
            originalImage = image
            enhancedImage = nil
            errorMessage = nil

            // 🎯 優化 11: 添加到最近使用列表
            recentFiles.addRecentFile(url)

        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func enhanceImage() {
        guard let original = originalImage else { return }

        isProcessing = true
        errorMessage = nil
        // 🎯 優化 8: 記錄處理開始時間
        processingStartTime = Date()

        // 🎯 優化 13: 模擬處理進度（0% → 90%）
        processingProgress = 0.0
        simulateProgress()

        ImageEnhancementService.shared.enhanceAsync(original) { result in
            // 🎯 優化 8: 計算處理時間
            if let startTime = self.processingStartTime {
                self.processingTime = Date().timeIntervalSince(startTime)
            }

            switch result {
            case .success(let enhanced):
                // 🎯 優化 13: 完成時進度設為 100%
                self.processingProgress = 1.0

                self.enhancedImage = enhanced
                self.isProcessing = false

                // 🎯 優化 12: 添加到歷史記錄
                self.history.addHistory(image: enhanced, mode: self.service.currentMode)

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showingAlert = true
                self.isProcessing = false
                self.processingProgress = 0.0
            }
        }
    }

    // 🎯 優化 13: 模擬處理進度
    private func simulateProgress() {
        // 在 2 秒內從 0% 逐漸增加到 90%
        let steps = 18
        let interval = 0.1
        let increment = 0.9 / Double(steps)

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval * Double(i))) {
                if self.isProcessing && self.processingProgress < 0.9 {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.processingProgress = min(increment * Double(i), 0.9)
                    }
                }
            }
        }
    }

    // 🎯 優化 12: 撤銷功能
    private func undoEnhancement() {
        guard let item = history.undo() else { return }
        enhancedImage = item.image
        service.setMode(item.mode)
        print("↩️ Undone to mode: \(item.mode.rawValue)")
    }

    // 🎯 優化 12: 重做功能
    private func redoEnhancement() {
        guard let item = history.redo() else { return }
        enhancedImage = item.image
        service.setMode(item.mode)
        print("↪️ Redone to mode: \(item.mode.rawValue)")
    }

    // 🎯 優化 15: 複製到剪貼簿
    private func copyToClipboard() {
        guard let enhanced = enhancedImage else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if let tiffData = enhanced.tiffRepresentation {
            pasteboard.setData(tiffData, forType: .tiff)
            print("✅ Image copied to clipboard")
        } else {
            errorMessage = "Failed to copy image"
            showingAlert = true
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
        // 🎯 優化 9: 根據模式添加智慧後綴
        let modeSuffix = service.currentMode.filenameSuffix
        savePanel.nameFieldStringValue = "\(defaultFileName)\(modeSuffix).\(selectedExportFormat.fileExtension)"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }

            DispatchQueue.global(qos: .userInitiated).async {
                guard let tiffData = enhanced.tiffRepresentation,
                      let bitmapImage = NSBitmapImageRep(data: tiffData) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to convert image"
                        self.showingAlert = true
                    }
                    return
                }

                let imageData: Data?
                switch self.selectedExportFormat {
                case .jpeg:
                    // 🎯 優化 16: 使用動態品質設定
                    imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: self.jpegQuality])
                case .png:
                    imageData = bitmapImage.representation(using: .png, properties: [:])
                }

                guard let data = imageData else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to encode image"
                        self.showingAlert = true
                    }
                    return
                }

                do {
                    try data.write(to: url)
                    print("✅ Image saved: \(url.lastPathComponent)")
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to save: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .frame(width: 1400, height: 900)
}
