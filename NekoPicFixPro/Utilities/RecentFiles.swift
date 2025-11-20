//
//  RecentFiles.swift
//  NekoPicFixPro
//
//  最近使用的檔案管理器
//

import Foundation
import Combine

/// 最近使用的檔案管理器
class RecentFiles: ObservableObject {
    static let shared = RecentFiles()

    // MARK: - Properties

    @Published private(set) var recentURLs: [URL] = []

    private let maxRecentFiles = 5
    private let userDefaultsKey = "NekoPicFixPro.RecentFiles"

    // MARK: - Initialization

    private init() {
        loadRecentFiles()
    }

    // MARK: - Public Methods

    /// 添加檔案到最近使用列表
    func addRecentFile(_ url: URL) {
        // 移除已存在的相同路徑
        recentURLs.removeAll { $0.path == url.path }

        // 添加到列表開頭
        recentURLs.insert(url, at: 0)

        // 限制數量
        if recentURLs.count > maxRecentFiles {
            recentURLs = Array(recentURLs.prefix(maxRecentFiles))
        }

        // 保存到 UserDefaults
        saveRecentFiles()

        print("📝 Added to recent files: \(url.lastPathComponent)")
    }

    /// 清空最近使用列表
    func clearRecentFiles() {
        recentURLs.removeAll()
        saveRecentFiles()
        print("🗑️ Recent files cleared")
    }

    /// 檢查檔案是否仍然存在
    func isFileAccessible(_ url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - Private Methods

    private func loadRecentFiles() {
        guard let paths = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] else {
            return
        }

        // 轉換為 URL 並過濾不存在的檔案
        recentURLs = paths
            .map { URL(fileURLWithPath: $0) }
            .filter { isFileAccessible($0) }

        print("📂 Loaded \(recentURLs.count) recent files")
    }

    private func saveRecentFiles() {
        let paths = recentURLs.map { $0.path }
        UserDefaults.standard.set(paths, forKey: userDefaultsKey)
    }
}
