# 🐱 NekoPicFix Pro

### 專業圖片強化工具 for macOS - 採用 macOS Sonoma Glass Design

NekoPicFix Pro 是一款**完全離線、基於 CoreML 的 macOS 圖片放大與增強工具**。
使用 Real-ESRGAN 系列 AI 模型，提供五種強化模式，支援多種圖片格式輸入輸出。

🛡 **不需要 Python、不需要外部伺服器、不需要網路**
所有推論皆在本機 GPU / Neural Engine 完成，完全保護您的隱私。

---

## ✨ 主要功能

### 🎨 五種 AI 強化模式

| 模式 | 說明 | 適用場景 | AI 模型 |
|------|------|----------|---------|
| **日常強化** | 一般照片最佳化 | 風景、建築、物品、人物通用 | RealESRGAN |
| **自然修復（強）** | 自然照片強力修復 | 老照片修復、嚴重損壞 | MMRealSRGAN |
| **自然修復（柔）** | 自然照片柔和修復 | 輕微瑕疵、保留原始質感 | MMRealSRNet |
| **插畫模式** | 動漫、插畫專用 | 動漫截圖、手繪插畫 | AnimeESRGAN |
| **實驗模式** | 藝術風格強化 | 創意項目、實驗效果 | AESRGAN |

所有模式均提供 **4× 超解析度放大**（256×256 → 1024×1024）

### 📥 支援格式

#### 輸入格式（Import）

✅ **JPEG** (.jpg, .jpeg) - 常見照片格式
✅ **PNG** (.png) - 支援透明背景
✅ **HEIC** (.heic, .heif) - Apple 高效率圖片格式
✅ **BMP** (.bmp) - Windows 點陣圖
✅ **TIFF** (.tiff, .tif) - 高品質圖片格式
✅ **WebP** (.webp) - 現代網頁圖片格式

**系統需求：** macOS 11.0+ 原生支援所有格式（包含 WebP）

#### 輸出格式（Export）

- **JPEG** - 適用於照片，檔案較小（可調整品質 0.9）
- **PNG** - 適用於需要透明背景或無損壓縮

### 🔍 互動功能

- **Before/After 滑桿比較器**
  - 拖曳滑桿即時比較強化前後效果
  - 同步縮放與平移狀態
  - 玻璃質感拖曳把手

- **圖片縮放與平移**
  - 雙擊重置縮放與位置
  - 捏合手勢縮放（1× ~ 4×）
  - 拖曳移動圖片位置
  - 支援 Before/After 同步縮放

### 🎨 Glass UI 設計

- **macOS Sonoma/Ventura 玻璃質感**
  - 半透明材質 (.ultraThinMaterial)
  - 柔和光影、無粗重邊框
  - 類似 Apple Photos / Safari 風格

- **深淺模式自動適配**
  - 自動切換配色系統
  - 符合 WCAG AA 無障礙標準（對比度 ≥ 4.5:1）

- **流暢動畫反饋**
  - 所有按鈕、滑桿、縮放都有細膩動畫
  - 0.15s ~ 0.3s 標準動畫時長

---

## 🚀 使用方法

### 1. 載入圖片

**方法 A - 拖放：**
- 直接將圖片拖曳至應用程式視窗
- 支援所有格式（JPEG, PNG, HEIC, WebP, BMP, TIFF）

**方法 B - Open Image：**
- 點擊工具列的 **"Open Image"** 按鈕
- 選擇要強化的圖片

### 2. 選擇強化模式

1. 在 **"選擇強化模式"** 區域選擇適合的模式
2. 每種模式下方都有適用場景說明
3. 點擊膠囊按鈕切換

### 3. 執行強化

1. 點擊 **"增強圖片"** 按鈕（魔杖圖標）
2. 等待處理完成（通常 3-20 秒，視圖片大小而定）
3. 自動顯示 Before/After 滑桿比較

### 4. 比較效果

**使用 Before/After 滑桿：**
- 拖曳中央的圓形把手左右移動
- 左側顯示原圖（Before）
- 右側顯示強化後（After）

**縮放檢視細節：**
- 使用觸控板的捏合手勢縮放
- 拖曳圖片移動位置
- 雙擊重置縮放到 1×

### 5. 儲存結果

1. 在底部工具列選擇輸出格式（**JPEG** 或 **PNG**）
2. 點擊 **"Save As..."** 按鈕
3. 選擇儲存位置與檔名
4. 確認儲存

---

## 🧠 AI 模型

### 模型來源

所有模型皆基於 Real-ESRGAN 系列，使用 CoreML 格式：

1. **RealESRGAN.mlmodel** - 日常強化模式
   https://drive.google.com/file/d/1XpLndNmSOjkBpTolQwQ8qXG9uuV0uUQO/view

2. **MMRealSRGAN.mlmodel** - 自然修復（強）
   （需自行轉換為 CoreML 格式）

3. **MMRealSRNet.mlmodel** - 自然修復（柔）
   （需自行轉換為 CoreML 格式）

4. **AnimeESRGAN.mlmodel** - 插畫模式
   （需自行轉換為 CoreML 格式）

5. **AESRGAN.mlmodel** - 實驗模式
   （需自行轉換為 CoreML 格式）

### 模型放置位置

將下載的 `.mlmodel` 檔案放入專案的 `Resources/` 目錄：

```
NekoPicFixPro/Resources/
 ├── RealESRGAN.mlmodel
 ├── MMRealSRGAN.mlmodel
 ├── MMRealSRNet.mlmodel
 ├── AnimeESRGAN.mlmodel
 └── AESRGAN.mlmodel
```

Xcode 會在 Build 時自動將 `.mlmodel` 編譯為 `.mlmodelc`。

**注意：** 如果缺少某些模型檔案，該模式按鈕會顯示為灰色（不可用）。

---

## 📁 專案結構

```
NekoPicFixPro/
├── NekoPicFixProApp.swift           # App 進入點
├── ML/                              # AI 模型包裝層
│   ├── RealESRGANUpscaler.swift         # 日常強化
│   ├── MMRealSRGANUpscaler.swift        # 自然修復（強）
│   ├── MMRealSRNetUpscaler.swift        # 自然修復（柔）
│   ├── AnimeESRGANUpscaler.swift        # 插畫模式
│   └── AESRGANUpscaler.swift            # 實驗模式
├── Services/                        # 業務邏輯層
│   └── ImageEnhancementService.swift    # 增強服務（Singleton）
├── UI/                              # 使用者介面
│   ├── MainView.swift                   # 主視圖
│   ├── BeforeAfterSliderView.swift      # Before/After 比較器
│   ├── ZoomableImageContainer.swift     # 可縮放容器
│   ├── GlassUIStyles.swift              # Glass UI 樣式組件
│   └── VisualEffectBlur.swift           # NSVisualEffectView 包裝
├── Utilities/                       # 工具類
│   └── ImageFormatSupport.swift         # 格式支援定義
├── Resources/                       # 資源檔案
│   ├── Assets.xcassets
│   └── *.mlmodel                        # CoreML 模型（需手動加入）
├── DESIGN_SPEC.md                   # UI 設計規格
├── WEBP_SUPPORT_SPEC.md             # WebP 支援規格
└── NekoPicFixPro.entitlements       # App 權限配置
```

---

## ⚙️ 技術規格

### 架構設計

**Protocol-Oriented：**
```swift
protocol ImageUpscaler {
    var isAvailable: Bool { get }
    func upscale(_ image: NSImage) throws -> NSImage
}
```

**Service Layer (Singleton)：**
```swift
class ImageEnhancementService {
    static let shared = ImageEnhancementService()

    enum EnhancementMode: String, CaseIterable {
        case general = "日常強化"
        case naturalStrong = "自然修復（強）"
        case naturalSoft = "自然修復（柔）"
        case anime = "插畫模式"
        case experimental = "實驗模式"
    }

    func enhance(_ image: NSImage, mode: EnhancementMode) throws -> NSImage
}
```

**State Management：**
```swift
class ZoomPanState: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
}
```

### 系統需求

- **作業系統：** macOS 11.0 Big Sur 或更新版本
- **建議配備：**
  - Apple Silicon (M1/M2/M3/M4) 或 Intel CPU
  - 8GB RAM 以上
  - 支援 Metal 的 GPU

### 效能表現

| 圖片尺寸 | 處理時間 (M1) | 記憶體使用 |
|---------|--------------|-----------|
| 1000×1000 | ~3 秒 | ~100MB |
| 2000×2000 | ~8 秒 | ~300MB |
| 4000×4000 | ~20 秒 | ~800MB |

*以 M1 MacBook Pro 為測試環境*

---

## 💻 建置說明

### 1. Clone 專案

```bash
git clone <repository-url>
cd NekoPicFixPro
```

### 2. 安裝 AI 模型

將 `.mlmodel` 檔案放入 `Resources/` 目錄（至少需要 RealESRGAN.mlmodel）

### 3. 配置 Entitlements

確認 `NekoPicFixPro.entitlements` 已加入專案：

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<false/>
```

在 Xcode 中設定：
1. 選擇專案 → Target → Signing & Capabilities
2. 確認 **App Sandbox** 已啟用
3. 確認 **User Selected File: Read/Write** 已勾選
4. Build Settings → Code Signing Entitlements 設為 `NekoPicFixPro/NekoPicFixPro.entitlements`

### 4. Build & Run

```bash
# 使用 Xcode
open NekoPicFixPro.xcodeproj

# 或使用 xcodebuild
xcodebuild -scheme NekoPicFixPro -configuration Debug build
```

首次執行時，CoreML 會自動將 `.mlmodel` 編譯為 `.mlmodelc`。

---

## 🔒 隱私與安全

- ✅ **完全離線運作** - 所有圖片處理在本機完成
- ✅ **無網路連線** - 應用程式不會傳送任何資料
- ✅ **App Sandbox** - 符合 macOS 安全標準
- ✅ **使用者授權存取** - 僅能存取您明確選擇的檔案
- ✅ **不收集遙測** - 無任何使用數據追蹤

---

## 📝 版本歷史

### v1.2.0 (2025-11-19)

**新增功能：**
- ✨ WebP 輸入格式支援（macOS 11+ 原生）
- ✨ BMP 與 TIFF 格式支援
- 🎨 完整 Glass UI 重新設計（macOS Sonoma 風格）
- 🔍 Before/After 滑桿比較器
- 🔍 圖片縮放與平移功能（1× ~ 4×）
- 🔍 雙擊重置縮放

**架構改進：**
- 🏗️ 五種 AI 強化模式（移除人臉修復）
- 💾 JPEG/PNG 輸出格式選擇
- 🎯 單一預覽框架設計
- 📦 ImageFormatSupport 統一格式管理
- 🧩 ZoomableImageContainer 共用縮放狀態

**Bug 修復：**
- 🐛 修復「另存新檔」功能當機問題
- 🐛 新增 Entitlements 正確配置
- 🐛 背景執行緒處理圖片轉換

**技術文件：**
- 📄 新增 DESIGN_SPEC.md（UI 設計規格）
- 📄 新增 WEBP_SUPPORT_SPEC.md（WebP 技術規格）

### v1.0.0 (2025-11-01)

- 🎉 初始發布
- 基礎 AI 圖片強化功能
- JPEG、PNG、HEIC 支援

---

## 🛣️ Roadmap

### v1.3（計劃中）

- [ ] 批次處理模式
- [ ] 自訂輸出尺寸
- [ ] 更多 AI 模型（SwinIR、CodeFormer）
- [ ] 偏好設定面板
- [ ] 鍵盤快捷鍵自訂

### v2.0（未來）

- [ ] 多圖拖放支援
- [ ] 匯出歷史記錄
- [ ] Tile-based 無接縫大圖處理
- [ ] 更多輸出格式（WebP export、AVIF）

---

## 📄 授權條款

本專案以 **MIT License** 授權釋出。

使用的 AI 模型來自開源社群：
- **Real-ESRGAN**: [xinntao/Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) (BSD 3-Clause)
- 請遵循各模型的原始授權條款

---

## 🤝 貢獻與支援

如有問題、建議或功能需求，歡迎：

- 🐛 **問題回報：** GitHub Issues
- 💡 **功能建議：** GitHub Discussions
- 📖 **技術支援：** 參閱專案 Wiki 或 [DESIGN_SPEC.md](DESIGN_SPEC.md)

---

## 🐱 關於

NekoPicFix Pro 是 Neko 工具系列的一部分。
此版本專注於**專業級、可離線執行、注重隱私的 AI 圖片增強功能**。

**Made with ❤️ for macOS**
*Designed with Apple Human Interface Guidelines*
