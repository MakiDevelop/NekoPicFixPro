//
//  BatchProcessor.swift
//  NekoPicFixPro
//
//  批次處理管理器（選項 1 + 2 綜合）
//

import Foundation
import AppKit
import Combine

/// 批次處理項目狀態
enum BatchItemStatus: Equatable {
    case pending       // 等待處理
    case processing    // 處理中
    case completed     // 完成
    case failed(String) // 失敗（錯誤訊息）
    case cancelled     // 取消

    static func == (lhs: BatchItemStatus, rhs: BatchItemStatus) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending),
             (.processing, .processing),
             (.completed, .completed),
             (.cancelled, .cancelled):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

/// 批次處理項目
class BatchItem: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let mode: EnhancementMode

    @Published var status: BatchItemStatus = .pending
    @Published var originalImage: NSImage?
    @Published var enhancedImage: NSImage?
    @Published var progress: Double = 0.0

    init(url: URL, mode: EnhancementMode) {
        self.url = url
        self.mode = mode
    }

    var filename: String {
        return url.lastPathComponent
    }

    var statusText: String {
        switch status {
        case .pending:
            return "等待中"
        case .processing:
            return "處理中"
        case .completed:
            return "完成"
        case .failed:
            return "失敗"
        case .cancelled:
            return "已取消"
        }
    }
}

/// 批次處理管理器
class BatchProcessor: ObservableObject {

    // MARK: - Published Properties

    @Published var items: [BatchItem] = []
    @Published var isProcessing: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentItem: BatchItem?
    @Published var totalProgress: Double = 0.0

    // MARK: - Properties

    private let maxQueueSize = 30
    private let maxImageDimension: CGFloat = 8192  // 8K limit
    private let service = ImageEnhancementService.shared
    private let memoryMonitor = MemoryMonitor.shared

    private var processingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Statistics
    @Published var completedCount: Int = 0
    @Published var failedCount: Int = 0
    @Published var totalCount: Int = 0

    // MARK: - Initialization

    init() {
        setupMemoryMonitoring()
    }

    // MARK: - Public Methods

    /// 添加檔案到批次佇列
    func addFiles(_ urls: [URL], mode: EnhancementMode) -> (added: Int, rejected: [String]) {
        var addedCount = 0
        var rejectedReasons: [String] = []

        for url in urls {
            // 檢查佇列大小
            guard items.count < maxQueueSize else {
                rejectedReasons.append("\(url.lastPathComponent): 佇列已滿（最多 \(maxQueueSize) 個）")
                continue
            }

            // 檢查檔案格式（使用統一的格式定義）
            let fileExtension = url.pathExtension.lowercased()
            guard SupportedImageFormat.allExtensions.contains(fileExtension) else {
                rejectedReasons.append("\(url.lastPathComponent): 不支援的檔案格式")
                continue
            }

            // 檢查檔案是否已在佇列中
            if items.contains(where: { $0.url.path == url.path }) {
                rejectedReasons.append("\(url.lastPathComponent): 已在佇列中")
                continue
            }

            // 預先檢查圖片尺寸
            if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
               let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
               let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {

                if width > maxImageDimension || height > maxImageDimension {
                    rejectedReasons.append("\(url.lastPathComponent): 尺寸過大（\(Int(width))×\(Int(height))，限制 \(Int(maxImageDimension))×\(Int(maxImageDimension))）")
                    continue
                }
            }

            // 添加到佇列
            let item = BatchItem(url: url, mode: mode)
            items.append(item)
            addedCount += 1
        }

        totalCount = items.count

        print("📦 Batch queue: added \(addedCount), rejected \(rejectedReasons.count), total \(items.count)")

        return (addedCount, rejectedReasons)
    }

    /// 開始批次處理
    func startProcessing() {
        guard !isProcessing else { return }
        guard !items.isEmpty else { return }

        isProcessing = true
        isPaused = false
        completedCount = 0
        failedCount = 0

        print("\n🚀 Starting batch processing: \(items.count) items")

        processingTask = Task {
            await processQueue()
        }
    }

    /// 暫停處理
    func pauseProcessing() {
        isPaused = true
        print("⏸️ Batch processing paused")
    }

    /// 繼續處理
    func resumeProcessing() {
        guard isPaused else { return }
        isPaused = false
        print("▶️ Batch processing resumed")

        if processingTask == nil {
            processingTask = Task {
                await processQueue()
            }
        }
    }

    /// 取消批次處理
    func cancelProcessing() {
        isProcessing = false
        isPaused = false
        processingTask?.cancel()
        processingTask = nil

        // Mark remaining items as cancelled
        for item in items where item.status == .pending || item.status == .processing {
            item.status = .cancelled
        }

        currentItem = nil

        print("🛑 Batch processing cancelled")
    }

    /// 清空佇列
    func clearQueue() {
        cancelProcessing()
        items.removeAll()
        totalCount = 0
        completedCount = 0
        failedCount = 0
        totalProgress = 0.0

        print("🗑️ Batch queue cleared")
    }

    /// 移除單個項目
    func removeItem(_ item: BatchItem) {
        // Check if status is pending or failed
        let canRemove: Bool
        switch item.status {
        case .pending, .failed:
            canRemove = true
        default:
            canRemove = false
        }

        guard canRemove else { return }

        items.removeAll { $0.id == item.id }
        totalCount = items.count
        updateProgress()

        print("🗑️ Removed item: \(item.filename)")
    }

    // MARK: - Private Methods

    /// 處理佇列（序列處理）
    private func processQueue() async {
        let pendingItems = items.filter { item in
            if case .pending = item.status {
                return true
            }
            return false
        }

        for item in pendingItems {
            // Check if cancelled or paused
            if Task.isCancelled || !isProcessing {
                break
            }

            // Wait while paused
            while isPaused {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                if Task.isCancelled || !isProcessing {
                    break
                }
            }

            // Check memory pressure before processing
            if memoryMonitor.shouldPauseProcessing {
                print("⚠️ Memory pressure high, pausing batch processing")
                await MainActor.run {
                    pauseProcessing()
                }

                // Wait for memory to recover
                while memoryMonitor.shouldPauseProcessing {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                    if Task.isCancelled || !isProcessing {
                        break
                    }
                }

                print("✅ Memory pressure relieved, resuming")
                await MainActor.run {
                    resumeProcessing()
                }
            }

            await processItem(item)
        }

        await MainActor.run {
            isProcessing = false
            currentItem = nil
            processingTask = nil

            print("\n✅ Batch processing complete")
            print("   Total: \(totalCount), Completed: \(completedCount), Failed: \(failedCount)")
        }
    }

    /// 處理單個項目
    private func processItem(_ item: BatchItem) async {
        await MainActor.run {
            currentItem = item
            item.status = .processing
            item.progress = 0.1
        }

        print("\n🎨 Processing: \(item.filename)")

        do {
            // Load image
            guard let image = NSImage(contentsOf: item.url) else {
                throw NSError(domain: "BatchProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "無法載入圖片"])
            }

            await MainActor.run {
                item.originalImage = image
                item.progress = 0.3
            }

            // Switch to correct mode and enhance image
            let enhanced = try await MainActor.run {
                service.setMode(item.mode)
                return try service.enhance(image)
            }

            await MainActor.run {
                item.enhancedImage = enhanced
                item.progress = 0.9
            }

            // Save enhanced image
            try await saveEnhancedImage(item)

            await MainActor.run {
                item.status = .completed
                item.progress = 1.0
                completedCount += 1
                updateProgress()
            }

            print("✅ Completed: \(item.filename)")

        } catch {
            await MainActor.run {
                item.status = .failed(error.localizedDescription)
                failedCount += 1
                updateProgress()
            }

            print("❌ Failed: \(item.filename) - \(error.localizedDescription)")
        }
    }

    /// 儲存強化後的圖片
    private func saveEnhancedImage(_ item: BatchItem) async throws {
        guard let enhanced = item.enhancedImage else {
            throw NSError(domain: "BatchProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "無強化圖片"])
        }

        // Generate output filename
        let fileURL = item.url
        let directory = fileURL.deletingLastPathComponent()
        let filename = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension

        let suffix = item.mode.filenameSuffix
        let outputFilename = "\(filename)\(suffix)_4x.\(ext)"
        let outputURL = directory.appendingPathComponent(outputFilename)

        // Convert NSImage to data
        guard let tiffData = enhanced.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw NSError(domain: "BatchProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "無法轉換圖片格式"])
        }

        // 根據原始格式選擇輸出格式和品質
        let imageData: Data?
        let originalExt = fileURL.pathExtension.lowercased()

        switch originalExt {
        case "jpg", "jpeg":
            // JPEG：使用 85% 品質（平衡品質與檔案大小）
            imageData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])

        case "webp":
            // WebP 來源：轉為 JPEG 85%（因為 NSBitmapImageRep 不直接支援 WebP 寫入）
            imageData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])

        case "png", "heic", "heif", "bmp", "tiff", "tif":
            // 無損格式：保持 PNG
            imageData = bitmap.representation(using: .png, properties: [:])

        default:
            // 預設使用 JPEG 85%
            imageData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        }

        guard let data = imageData else {
            throw NSError(domain: "BatchProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "無法產生圖片資料"])
        }

        // Write to file
        try data.write(to: outputURL)

        print("💾 Saved: \(outputFilename)")
    }

    /// 更新整體進度
    private func updateProgress() {
        guard totalCount > 0 else {
            totalProgress = 0.0
            return
        }

        let finishedCount = completedCount + failedCount
        totalProgress = Double(finishedCount) / Double(totalCount)
    }

    /// 設定記憶體監控
    private func setupMemoryMonitoring() {
        memoryMonitor.$memoryPressure
            .sink { [weak self] pressure in
                guard let self = self else { return }

                if pressure == .critical && self.isProcessing && !self.isPaused {
                    print("🚨 Critical memory pressure detected!")
                    self.pauseProcessing()
                }
            }
            .store(in: &cancellables)
    }
}
