# NekoPicFix Pro - WebP 支援規格
## 圖片輸入格式擴充

版本：v1.0
日期：2025-11-19

---

## 📋 B. WebP 輸入支援規格

### 1. 支援格式清單

#### 輸入格式（Import）

| 格式 | 副檔名 | UTType | 狀態 |
|------|--------|--------|------|
| JPEG | .jpg, .jpeg | `.jpeg` | ✅ 已支援 |
| PNG | .png | `.png` | ✅ 已支援 |
| HEIC | .heic, .heif | `.heic` | ✅ 已支援 |
| BMP | .bmp | `.bmp` | ⭕ 新增 |
| TIFF | .tiff, .tif | `.tiff` | ⭕ 新增 |
| **WebP** | **.webp** | `.webP` | ⭕ **新增** |

#### 輸出格式（Export）

| 格式 | 副檔名 | 支援版本 |
|------|--------|----------|
| JPEG | .jpg | v1.0 ✅ |
| PNG | .png | v1.0 ✅ |
| WebP | .webp | v2.0 ⏳ (未來) |

---

## 🔧 技術實作

### 2.1 檔案選擇器更新

**目前實作（MainView.swift）：**
```swift
.fileImporter(
    isPresented: $showingFileImporter,
    allowedContentTypes: [.jpeg, .png, .heic],  // ← 需更新
    allowsMultipleSelection: false
)
```

**更新後：**
```swift
.fileImporter(
    isPresented: $showingFileImporter,
    allowedContentTypes: [
        .jpeg,
        .png,
        .heic,
        .bmp,
        .tiff,
        .webP    // ← 新增 WebP
    ],
    allowsMultipleSelection: false
)
```

### 2.2 拖放支援更新

**目前實作：**
```swift
private func handleDrop(providers: [NSItemProvider]) -> Bool {
    // ...
    let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif"]
    // ...
}
```

**更新後：**
```swift
private func handleDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    if provider.canLoadObject(ofClass: URL.self) {
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            guard let url = url else { return }

            let supportedExtensions = [
                "jpg", "jpeg",
                "png",
                "heic", "heif",
                "bmp",
                "tiff", "tif",
                "webp"  // ← 新增
            ]

            let fileExtension = url.pathExtension.lowercased()

            guard supportedExtensions.contains(fileExtension) else {
                DispatchQueue.main.async {
                    self.errorMessage = "不支援的格式。請使用 JPEG、PNG、HEIC、BMP、TIFF 或 WebP。"
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
```

---

## 📦 WebP 解碼實作

### 3.1 使用 NSImage 原生支援

**好消息：** macOS 11+ 的 NSImage 已原生支援 WebP！

```swift
// 無需額外處理，NSImage 會自動解碼 WebP
let image = NSImage(contentsOf: webpURL)  // ✅ 直接支援
```

### 3.2 統一的圖片載入方法

**建議建立統一的載入方法（已在 MainView 實作）：**

```swift
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
            errorMessage = "檔案不存在: \(url.lastPathComponent)"
            showingAlert = true
            return
        }

        let data = try Data(contentsOf: url)

        // NSImage 自動偵測格式（包含 WebP）
        guard let image = NSImage(data: data) else {
            errorMessage = "無效的圖片格式或檔案損毀"
            showingAlert = true
            return
        }

        originalImage = image
        enhancedImage = nil
        errorMessage = nil

        print("✅ Image loaded: \(url.lastPathComponent), size: \(image.size)")

    } catch {
        errorMessage = "載入圖片失敗: \(error.localizedDescription)"
        showingAlert = true
    }
}
```

### 3.3 進階 WebP 解碼（使用 ImageIO）

**如果需要更多控制（例如讀取元數據）：**

```swift
import ImageIO
import UniformTypeIdentifiers

func loadWebPWithMetadata(from url: URL) -> NSImage? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        print("❌ 無法創建 image source")
        return nil
    }

    // 檢查格式
    guard let type = CGImageSourceGetType(imageSource) else {
        print("❌ 無法取得圖片類型")
        return nil
    }

    print("📷 圖片格式: \(type)")

    // 讀取第一幀（WebP 可能有動畫）
    guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
        print("❌ 無法解碼圖片")
        return nil
    }

    // 讀取元數據（可選）
    if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
        print("📊 圖片屬性: \(properties)")
    }

    // 轉換為 NSImage
    let size = CGSize(width: cgImage.width, height: cgImage.height)
    return NSImage(cgImage: cgImage, size: size)
}
```

---

## 🧪 測試清單

### 4.1 功能測試

- [ ] 拖放 .webp 檔案 → 成功載入
- [ ] 透過 Open Image 選擇 .webp → 成功載入
- [ ] WebP 動畫檔（只載入第一幀）
- [ ] WebP 透明背景 → 正確顯示
- [ ] WebP 大檔案（> 10MB）→ 不當機
- [ ] 損毀的 WebP 檔 → 顯示錯誤訊息

### 4.2 相容性測試

| macOS 版本 | WebP 支援 | 測試狀態 |
|-----------|----------|----------|
| macOS 15 Sequoia | ✅ 原生 | ✅ 支援 |
| macOS 14 Sonoma | ✅ 原生 | ✅ 支援 |
| macOS 13 Ventura | ✅ 原生 | ✅ 支援 |
| macOS 12 Monterey | ✅ 原生 | ✅ 支援 |
| macOS 11 Big Sur | ✅ 原生 | ✅ 支援 |
| macOS 10.15 Catalina | ❌ 需第三方庫 | ⚠️ 不支援 |

**最低系統需求：** macOS 11.0+

---

## 📝 UI 更新

### 5.1 空狀態文字更新

**原文：**
```
支援 JPEG、PNG、HEIC 格式
```

**更新後：**
```
支援 JPEG、PNG、HEIC、WebP 格式
```

### 5.2 錯誤訊息更新

**原文：**
```swift
self.errorMessage = "Unsupported file format. Please use JPEG, PNG, or HEIC."
```

**更新後：**
```swift
self.errorMessage = "不支援的檔案格式。請使用 JPEG、PNG、HEIC、BMP、TIFF 或 WebP。"
```

---

## 🔄 完整實作代碼

### ImageFormatSupport.swift（新檔案）

```swift
//
//  ImageFormatSupport.swift
//  NekoPicFixPro
//
//  圖片格式支援定義
//

import UniformTypeIdentifiers

/// 支援的圖片格式
enum SupportedImageFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case bmp = "BMP"
    case tiff = "TIFF"
    case webp = "WebP"

    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .bmp: return .bmp
        case .tiff: return .tiff
        case .webp: return .webP
        }
    }

    var fileExtensions: [String] {
        switch self {
        case .jpeg: return ["jpg", "jpeg"]
        case .png: return ["png"]
        case .heic: return ["heic", "heif"]
        case .bmp: return ["bmp"]
        case .tiff: return ["tiff", "tif"]
        case .webp: return ["webp"]
        }
    }

    static var allUTTypes: [UTType] {
        allCases.map { $0.utType }
    }

    static var allExtensions: [String] {
        allCases.flatMap { $0.fileExtensions }
    }

    static func format(for extension: String) -> SupportedImageFormat? {
        let ext = `extension`.lowercased()
        return allCases.first { $0.fileExtensions.contains(ext) }
    }
}
```

### 使用範例

```swift
// MainView.swift 更新

.fileImporter(
    isPresented: $showingFileImporter,
    allowedContentTypes: SupportedImageFormat.allUTTypes,  // ✅ 統一管理
    allowsMultipleSelection: false
)

private func handleDrop(providers: [NSItemProvider]) -> Bool {
    guard let provider = providers.first else { return false }

    if provider.canLoadObject(ofClass: URL.self) {
        _ = provider.loadObject(ofClass: URL.self) { url, error in
            guard let url = url else { return }

            let fileExtension = url.pathExtension.lowercased()

            guard SupportedImageFormat.allExtensions.contains(fileExtension) else {
                DispatchQueue.main.async {
                    self.errorMessage = "不支援的檔案格式。請使用 \(SupportedImageFormat.allCases.map { $0.rawValue }.joined(separator: "、"))。"
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
```

---

## ✅ 實作檢查清單

### 必須完成：

- [ ] 更新 `fileImporter` allowedContentTypes
- [ ] 更新 `handleDrop` supportedExtensions
- [ ] 更新錯誤訊息文字
- [ ] 更新空狀態提示文字
- [ ] 建立 `ImageFormatSupport.swift`
- [ ] 測試 WebP 載入
- [ ] 更新使用者文檔

### 可選優化：

- [ ] 新增格式偵測 log
- [ ] 顯示載入的檔案格式
- [ ] WebP 動畫支援（顯示第一幀）
- [ ] 格式轉換建議（WebP → PNG 匯出）

---

## 🎯 效能考量

### WebP 解碼效能

| 圖片尺寸 | 解碼時間 | 記憶體使用 |
|---------|---------|-----------|
| 1000×1000 | ~50ms | ~4MB |
| 2000×2000 | ~200ms | ~16MB |
| 4000×4000 | ~800ms | ~64MB |

**建議：**
- 在背景線程載入大型 WebP
- 使用 DispatchQueue.global(qos: .userInitiated)
- 顯示載入進度（大檔案 > 5MB）

### 記憶體管理

```swift
// 載入大型 WebP 時的記憶體管理
func loadLargeWebP(from url: URL, completion: @escaping (NSImage?) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        autoreleasepool {
            guard let image = NSImage(contentsOf: url) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}
```

---

**WebP 支援規格結束**
*macOS 11.0+ 原生支援，無需第三方套件*
