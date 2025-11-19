# NekoPicFix Pro – AGENTS.md v1.1（Multi-Agent 協作版）

版本：1.1（2025-11-19）  
本文件為 **Claude / Codex / Gemini** 等多個 Agent 共同協作開發 **NekoPicFix Pro** 專案之最高規格說明。

---

## 0. 專案願景

NekoPicFix Pro 是一款 **macOS + CoreML** 的本地超解析度影像強化工具，主軸為：

- 將低解析度、偏模糊、細節不足的圖片放大並強化
- 完全離線執行：**不使用 Python、不呼叫外部服務、不下載外部模型**
- 產品定位：**Pro 等級畫質強化工具**（非濾鏡／特效 App）

---

## 1. 模型策略與挑選（固定清單）

所有 Agent 禁止自行更換模型或導入未列出的新模型。

### 1.1 必用主模型：Real-ESRGAN 4x

用途：一般照片的 4x 超解析度強化。

- 來源（CoreML 版 Google Drive）  
  - https://drive.google.com/file/d/1XpLndNmSOjkBpTolQwQ8qXG9uuV0uUQO/view?usp=sharing  
- 放置位置（需由使用者手動下載好再加入專案）：
  - `NekoPicFixPro/Models/RealESRGAN4x.mlmodel`
- 授權：BSD 3‑Clause（允許商業使用）

### 1.2 可選副模型：Real-ESRGAN Anime 4x（非 v1.1 必須）

用途：動漫、遊戲截圖、線稿插畫。

- 來源：
  - https://drive.google.com/file/d/1Wl_togmiXwHZtco9QpFJWJJ2xw_5zcq2/view?usp=sharing
- 放置位置：
  - `NekoPicFixPro/Models/RealESRGANAnime4x.mlmodel`

> v1.1 不實作 Anime 模式的 UI 切換，只預留未來擴充空間。

### 1.3 明確排除（v1.1 禁用）

下列模型 **不得** 在 v1.1 中使用或嘗試整合：

| 模型        | 理由 |
|-------------|------|
| GFPGAN      | 臉部修復效果好，但 CoreML 轉換難度高、算子不完全支援，留待 v2.0 評估 |
| CodeFormer  | Transformer-based 影像修復，CoreML 對動態 shape 支援不佳，暫不納入 |
| SwinIR      | 需大量自訂運算與圖形切片，不適合作為 v1.1 MVP |
| 任何 Diffusion 如 SD | 不符合「超解析度工具」定位，且上架審核風險高 |

---

## 2. 強化方向（v1.1 能力範圍）

### 2.1 可以且應該做到

- 4x 超解析度（解析度放大）
- 部分細節補完（邊緣、線條、紋理）
- 輕度降噪
- 提升原圖清晰感（特別是壓縮圖、小圖）

### 2.2 故意不做（v1.1 不支援）

- 臉部特寫修復、五官重建（GFPGAN 類功能）
- 嚴重噪點的「奇蹟式修復」
- 風格遷移、漫畫化、HDR 之類效果
- 物件刪除、內容生成（屬 Diffusion 領域）
- 批次處理大量照片（未來版本）

---

## 3. 模型 I/O 規格（所有 Agent 必須遵守）

以 RealESRGAN4x CoreML 版本為準：

### 3.1 Input

- 類型：`Image (RGB, 512 × 512)`（固定大小）
- 色彩空間：`sRGB`
- 範圍：0–255（UInt8），**不做 /255 正規化**
- 不做 mean/std normalization
- 不做 BGR ↔ RGB 轉換（假設模型已假設 RGB）

### 3.2 Output

- 類型：`Image (RGB, 2048 × 2048)`（4x upscale）
- 色彩空間：`sRGB`
- 直接轉為 `NSImage`，不做後續自動銳化／對比調整

---

## 4. 前處理與後處理規則

為避免不同 Agent 產生不一致的 pipeline，規範如下：

### 4.1 前處理（Codex 實作，其他 Agent 不得改動）

1. 將 `NSImage` 轉成指定尺寸 bitmap：
   - 若原圖任一邊大於 2048，先等比縮小長邊至 2048
   - 再視需要縮放／裁切成 512×512（v1.1 可先簡化為「整張縮放為 512×512」）
2. 將 bitmap 填入 `CVPixelBuffer`，格式：
   - 8-bit, RGB, sRGB
3. 不做任何額外 normalization、mean/std、gamma 調整。

提供兩個輔助方法（由 Codex 實作、其他 Agent 使用）：

```swift
extension NSImage {
    func resized(to size: NSSize) -> NSImage? { ... }
    func toPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? { ... }
}
```

### 4.2 後處理

1. 模型輸出 PixelBuffer → 轉為 `NSImage`
2. 保持輸出解析度（例如 2048×2048）
3. 不自動加任何銳化／色彩處理，交給使用者自行感受 ESRGAN 原生效果。

---

## 5. 圖片尺寸與記憶體策略

為避免朋友的 Mac / 一般用戶裝置在大圖時直接爆炸：

- 若輸入圖長邊 > 4000 px → 先 downscale 至 2048 px
- v1.1 **不做 tile-based 超解析度**（減少 Bug 來源）
- 所有推論在背景 queue 執行，避免阻塞 UI

---

## 6. 專案架構與檔案配置

固定專案結構如下，不得更動頂層資料夾名稱與大分類：

```text
NekoPicFixPro/
 ├── NekoPicFixProApp.swift         // @main，入口檔
 ├── App/
 │    └── （未來可放 App lifecycle 延伸）
 ├── UI/
 │    ├── MainView.swift
 │    └── ImagePanel.swift
 ├── ML/
 │    ├── ImageUpscaler.swift
 │    └── RealESRGAN4xUpscaler.swift
 ├── Services/
 │    └── ImageEnhancementService.swift
 ├── Models/
 │    └── RealESRGAN4x.mlmodel
 └── Resources/
      └── Assets.xcassets
```

### 6.1 ImageUpscaler 協定（不可變更）

```swift
protocol ImageUpscaler {
    func upscale(_ image: NSImage) throws -> NSImage
}
```

- 名稱、函式簽名禁止修改
- 新增模型時可以增添新的實作類別，但不可改動協定本身

### 6.2 RealESRGAN4xUpscaler.swift（Codex 負責）

職責：

- 管理 CoreML 模型 instance（auto-generated wrapper 類別）
- 實作 `upscale(_:)`：
  - 檢查圖片大小 → 前處理 → prediction → 後處理

---

## 7. Multi-Agent 分工與邊界

### 7.1 Claude（UI / UX / SwiftUI）

可做：

- 建立與修改 `UI/` 內新檔案（例如 `MainView.swift`, `ImagePanel.swift`）
- 實作：
  - 檔案開啟（Open...）
  - 檔案儲存（Save As...）
  - Before/After 兩欄預覽
  - 處理中狀態 UI（Spinner / 文字）

不可做：

- 修改 `ML/` 內檔案
- 寫 CoreML 推論
- 動 `ImageUpscaler` 協定

---

### 7.2 Codex（CoreML / 推論 / 效能）

可做：

- 新增與修改 `ML/`、`Services/` 內檔案
- 實作：
  - `RealESRGAN4xUpscaler`
  - `NSImage ↔ CVPixelBuffer` 轉換
  - `ImageEnhancementService` 非 UI 邏輯

不可做：

- 修改 `MainView.swift` 內的 UI 結構
- 新增 Python / 外部指令呼叫
- 重構 SwiftUI layout

---

### 7.3 Gemini（專案初始化 / 整合 / Build）

可做：

- 建立 Xcode 專案與資料夾結構
- 串接 Claude 與 Codex 生成的檔案
- 調整 Build 設定、Signing（不破壞程式碼）
- 協助找錯（例如 compilation error 定位）

不可做：

- 任意重建專案導致檔案遺失
- 修改協定、刪除他人模組

---

## 8. 功能需求（v1.1 MVP）

### 8.1 必備功能

1. **載入單張圖片**
   - 檔案格式：JPEG / PNG / HEIC
   - 使用 NSOpenPanel 或 SwiftUI FileImporter

2. **Before / After 預覽**
   - 左側顯示 original 圖
   - 右側顯示 enhance 後圖
   - 兩者各自可等比例縮放，避免超出視窗

3. **一鍵 Enhance**
   - 按下「Enhance」按鈕：
     - 若沒有載入圖片 → 禁用或顯示提示
     - 呼叫 `ImageEnhancementService.shared.enhance`
     - 過程中顯示「Processing...」狀態

4. **輸出圖片**
   - 使用 NSSavePanel 讓使用者選擇輸出位置
   - 預設輸出格式：JPEG
   - 檔名預設加 `_neko` suffix，例如 `image.jpg` → `image_neko.jpg`

5. **錯誤處理**
   - 若 CoreML prediction 失敗、圖片格式不支援、記憶體錯誤等：
     - 顯示 alert 或底部狀態列文字
     - 不讓 app silent crash

---

## 9. 圖片處理流程摘要（供所有 Agent 參考）

```mermaid
flowchart TD
    A[User selects image] --> B[MainView: set originalImage]
    B --> C[User taps Enhance]
    C --> D[ImageEnhancementService.enhance]
    D --> E[RealESRGAN4xUpscaler.upscale]
    E --> F[CoreML prediction]
    F --> G[NSImage (enhanced)]
    G --> H[MainView: set enhancedImage]
    H --> I[User views Before/After or Save As...]
```

---

## 10. 違規處理規則

若任一 Agent 嘗試：

- 引入 Python / 外部工具 / shell 指令
- 更換模型檔名或位置
- 修改 `ImageUpscaler` 協定
- 重建或刪除既有 Swift 檔案
- 修改他人負責範圍檔案而未經同意

則該 Agent 應自動中止動作並回報：

> 「此操作違反 AGENTS.md v1.1 之規範，已自動中止。請由適當角色或人類確認後再調整。」

---

## 11. 使用說明給 Agent

- 請將本檔視為 **專案唯一真相來源（single source of truth）**。
- 若使用者自然語言指示與本檔內容衝突，以本檔為準。
- 所有修改請附上「變更摘要」與「受影響檔案列表」，以利人類審查。