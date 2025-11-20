//
//  ImageCache.swift
//  NekoPicFixPro
//
//  高效能圖片快取系統
//

import Foundation
import AppKit

/// 智慧圖片快取管理器
class ImageCache {
    static let shared = ImageCache()

    // MARK: - Properties

    private let cache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    // 快取配置
    private let maxCacheSize: Int = 100 * 1024 * 1024  // 100MB
    private let maxCacheItems: Int = 50

    // MARK: - Initialization

    private init() {
        // 設定快取目錄
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("NekoPicFixPro/ImageCache", isDirectory: true)

        // 建立目錄
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // 配置 NSCache
        cache.countLimit = maxCacheItems
        cache.totalCostLimit = maxCacheSize

        // 監聽記憶體警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        print("✅ ImageCache initialized")
        print("   Cache directory: \(cacheDirectory.path)")
    }

    // MARK: - Cache Operations

    /// 儲存圖片到快取
    func set(_ image: NSImage, forKey key: String) {
        let nsKey = key as NSString

        // 記憶體快取
        let cost = estimatedImageSize(image)
        cache.setObject(image, forKey: nsKey, cost: cost)

        // 磁碟快取（背景執行）
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.saveToDisk(image, key: key)
        }

        print("📦 Cached image: \(key) (\(cost / 1024)KB)")
    }

    /// 從快取讀取圖片
    func get(forKey key: String) -> NSImage? {
        let nsKey = key as NSString

        // 先查記憶體快取
        if let cachedImage = cache.object(forKey: nsKey) {
            print("✅ Cache HIT (memory): \(key)")
            return cachedImage
        }

        // 再查磁碟快取
        if let diskImage = loadFromDisk(key: key) {
            print("✅ Cache HIT (disk): \(key)")
            // 重新放入記憶體快取
            let cost = estimatedImageSize(diskImage)
            cache.setObject(diskImage, forKey: nsKey, cost: cost)
            return diskImage
        }

        print("❌ Cache MISS: \(key)")
        return nil
    }

    /// 移除特定快取
    func remove(forKey key: String) {
        let nsKey = key as NSString
        cache.removeObject(forKey: nsKey)

        // 同時移除磁碟快取
        let diskURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? fileManager.removeItem(at: diskURL)
    }

    /// 清空所有快取
    func clearAll() {
        cache.removeAllObjects()

        // 清空磁碟快取
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        print("🗑️ All cache cleared")
    }

    /// 取得快取統計資訊
    func getCacheStats() -> (memoryItems: Int, diskSize: Int64) {
        let diskSize = try? fileManager
            .contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            .reduce(Int64(0)) { total, url in
                let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                return total + Int64(size ?? 0)
            }

        return (memoryItems: cache.countLimit, diskSize: diskSize ?? 0)
    }

    // MARK: - Private Methods

    private func estimatedImageSize(_ image: NSImage) -> Int {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        return width * height * 4  // RGBA = 4 bytes per pixel
    }

    private func saveToDisk(_ image: NSImage, key: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }

        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? pngData.write(to: fileURL)
    }

    private func loadFromDisk(key: String) -> NSImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = NSImage(data: data) else {
            return nil
        }

        return image
    }

    @objc private func handleMemoryWarning() {
        // 記憶體警告時清空記憶體快取（保留磁碟快取）
        cache.removeAllObjects()
        print("⚠️ Memory warning - cleared memory cache")
    }
}

// MARK: - String Extension (MD5 Hash)

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &digest)
        }

        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// 需要引入 CommonCrypto
import CommonCrypto
