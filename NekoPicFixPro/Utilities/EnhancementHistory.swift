//
//  EnhancementHistory.swift
//  NekoPicFixPro
//
//  圖片強化歷史管理器（支援撤銷/重做）
//

import Foundation
import AppKit
import Combine

/// 歷史記錄項目
struct HistoryItem {
    let image: NSImage
    let mode: EnhancementMode
    let timestamp: Date

    init(image: NSImage, mode: EnhancementMode) {
        self.image = image
        self.mode = mode
        self.timestamp = Date()
    }
}

/// 圖片強化歷史管理器
class EnhancementHistory: ObservableObject {
    // MARK: - Properties

    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false

    private var history: [HistoryItem] = []
    private var currentIndex: Int = -1
    private let maxHistorySize = 10

    // MARK: - Public Methods

    /// 添加新的歷史記錄
    func addHistory(image: NSImage, mode: EnhancementMode) {
        // 如果當前不在最新位置，移除後面的歷史
        if currentIndex < history.count - 1 {
            history.removeSubrange((currentIndex + 1)...)
        }

        // 添加新記錄
        let item = HistoryItem(image: image, mode: mode)
        history.append(item)

        // 限制歷史大小
        if history.count > maxHistorySize {
            history.removeFirst()
        } else {
            currentIndex += 1
        }

        updateUndoRedoState()
        print("📝 Added to history: \(mode.rawValue) (index: \(currentIndex), total: \(history.count))")
    }

    /// 撤銷到上一個狀態
    func undo() -> HistoryItem? {
        guard canUndo, currentIndex > 0 else { return nil }

        currentIndex -= 1
        updateUndoRedoState()

        let item = history[currentIndex]
        print("↩️ Undo to: \(item.mode.rawValue) (index: \(currentIndex))")
        return item
    }

    /// 重做到下一個狀態
    func redo() -> HistoryItem? {
        guard canRedo, currentIndex < history.count - 1 else { return nil }

        currentIndex += 1
        updateUndoRedoState()

        let item = history[currentIndex]
        print("↪️ Redo to: \(item.mode.rawValue) (index: \(currentIndex))")
        return item
    }

    /// 清空歷史
    func clearHistory() {
        history.removeAll()
        currentIndex = -1
        updateUndoRedoState()
        print("🗑️ History cleared")
    }

    /// 取得當前歷史項目
    func getCurrentItem() -> HistoryItem? {
        guard currentIndex >= 0 && currentIndex < history.count else {
            return nil
        }
        return history[currentIndex]
    }

    // MARK: - Private Methods

    private func updateUndoRedoState() {
        canUndo = currentIndex > 0
        canRedo = currentIndex < history.count - 1
    }
}
