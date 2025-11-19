# NekoPicFix Pro - UI 高階設計稿
## macOS Sonoma Glass Design Language

版本：v1.0
日期：2025-11-19
設計語言：Apple macOS Sonoma / Ventura Glass UI

---

## 📐 A. UI 高階設計規格

### 1. 設計哲學

**核心原則：**
- 清爽、輕盈、半透明
- 柔和光影、無粗重邊框
- 類似 Apple Photos / Safari / Control Center
- 所有內容都有呼吸感（spacing）

**視覺層次：**
```
背景層 (.hudWindow material)
  └─ 工具列層 (.regularMaterial)
  └─ 內容層 (.ultraThinMaterial cards)
      └─ 互動層 (buttons, sliders)
```

---

## 🎨 顏色規範（Color Tokens）

### Light Mode（淺色模式）

| 用途 | 顏色值 | 範例 |
|------|--------|------|
| **主要文字** | `Color.primary` (系統預設深灰) | 標題、按鈕文字 |
| **次要文字** | `Color.secondary` | 提示文字、描述 |
| **禁用文字** | `Color.secondary.opacity(0.5)` | 不可用選項 |
| **強調文字** | `Color.accentColor` | 選中狀態 |
| **警告文字** | `Color.orange` | 錯誤提示 |
| **成功文字** | `Color.green` | 完成狀態 |
| **卡片邊框** | `Color.white.opacity(0.12)` | 玻璃卡片描邊 |
| **分隔線** | `Color.gray.opacity(0.2)` | Divider |

### Dark Mode（深色模式）

| 用途 | 顏色值 | 範例 |
|------|--------|------|
| **主要文字** | `Color.primary` (系統預設白色) | 標題、按鈕文字 |
| **次要文字** | `Color.secondary` | 提示文字、描述 |
| **禁用文字** | `Color.secondary.opacity(0.5)` | 不可用選項 |
| **強調文字** | `Color.accentColor` | 選中狀態 |
| **警告文字** | `Color.orange` | 錯誤提示 |
| **成功文字** | `Color.green` | 完成狀態 |
| **卡片邊框** | `Color.white.opacity(0.15)` | 玻璃卡片描邊（深色模式稍亮） |
| **分隔線** | `Color.white.opacity(0.1)` | Divider |

### 文字可讀性規則

✅ **必須遵守：**
1. 主要文字永遠使用 `Color.primary`（系統自動適配深淺）
2. 次要文字使用 `Color.secondary`（系統自動適配）
3. 玻璃材質上的文字需額外背景：
   ```swift
   Text("標題")
       .foregroundColor(.primary)
       .padding(8)
       .background(.ultraThinMaterial)  // 提供背景對比
   ```
4. 小字（< 12pt）禁止使用 opacity < 0.7
5. 所有文字與背景對比度 ≥ 4.5:1（符合 WCAG AA）

---

## 📦 組件規格

### 1.1 主預覽區（Glass Card）

**佈局：**
```
┌─────────────────────────────────────────┐
│  [Before/After Slider or Single Image]  │ ← .ultraThinMaterial
│                                         │
│  ┌───────────────────────────────────┐ │
│  │   圖片內容區                       │ │
│  │   (ZoomableImageContainer)        │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

**視覺規格：**
- **背景材質：** `.ultraThinMaterial`
- **圓角：** 20pt
- **邊框：** `strokeBorder(.white.opacity(0.12), lineWidth: 1)`
- **陰影：** `shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)`
- **內距：** 24pt（外）、16pt（內）
- **最小尺寸：** 800×600

**SwiftUI 代碼範例：**
```swift
RoundedRectangle(cornerRadius: 20)
    .fill(.ultraThinMaterial)
    .overlay(
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
    )
    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
```

---

### 1.2 模式選擇區（Mode Selection）

**佈局：**
```
┌──────────────────────────────────────────────────┐
│  選擇強化模式                                      │ ← .secondary 文字
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐        │
│  │日常 │ │自然 │ │自然 │ │插畫 │ │實驗 │        │
│  │強化 │ │(強) │ │(柔) │ │模式 │ │模式 │        │
│  └─────┘ └─────┘ └─────┘ └─────┘ └─────┘        │
│  一般照片最佳，風景、建築、物品、人物都通用        │ ← .secondary 描述
└──────────────────────────────────────────────────┘
```

**膠囊按鈕規格（ModeCapsuleButtonStyle）：**

| 狀態 | 背景 | 文字顏色 | 邊框 | 陰影 |
|------|------|----------|------|------|
| **Normal** | `.clear` | `.primary` | `.secondary.opacity(0.2), 1pt` | 無 |
| **Selected** | `.accentColor` | `.white` | 無 | `accentColor.opacity(0.3), radius 8` |
| **Disabled** | `.clear` | `.secondary.opacity(0.5)` | `.secondary.opacity(0.1)` | 無 |
| **Hover** | `.gray.opacity(0.1)` | `.primary` | `.secondary.opacity(0.3)` | 無 |

**尺寸規格：**
- **字體：** 13pt, weight: .regular (normal) / .semibold (selected)
- **內距：** horizontal 16pt, vertical 8pt
- **圓角：** Capsule（完全圓角）
- **間距：** 12pt between buttons
- **最小寬度：** 80pt

**SwiftUI 代碼範例：**
```swift
Button("日常強化") {
    selectMode(.general)
}
.buttonStyle(ModeCapsuleButtonStyle(
    isSelected: currentMode == .general,
    isAvailable: true
))
```

---

### 1.3 主要動作按鈕（Enhance Button）

**視覺規格：**

| 狀態 | 背景 | 文字 | 陰影 | 尺寸變化 |
|------|------|------|------|----------|
| **Normal** | `.accentColor` | `.white, 15pt, .semibold` | `accentColor.opacity(0.4), radius 12` | 1.0 |
| **Hover** | `.accentColor.opacity(0.9)` | `.white` | `accentColor.opacity(0.5), radius 14` | 1.02 |
| **Pressed** | `.accentColor.opacity(0.8)` | `.white` | `accentColor.opacity(0.3), radius 10` | 0.98 |
| **Processing** | `.gray` | `.white` | 無 | 1.0 + spinner |
| **Disabled** | `.gray.opacity(0.3)` | `.secondary` | 無 | 1.0 |

**尺寸規格：**
- **形狀：** Capsule（完全圓角）
- **內距：** horizontal 32pt, vertical 14pt
- **圖標：** `wand.and.stars` (SF Symbol, 16pt)
- **最小寬度：** 180pt

**動畫：**
```swift
.scaleEffect(isPressed ? 0.98 : isHovered ? 1.02 : 1.0)
.animation(.easeInOut(duration: 0.15), value: isPressed)
.animation(.easeInOut(duration: 0.2), value: isHovered)
```

---

### 1.4 Before/After Slider

**分割線規格：**
- **寬度：** 3pt
- **顏色：** `.white.opacity(0.85)`
- **模糊：** `blur(radius: 0.5)`
- **陰影：** `shadow(color: .black.opacity(0.4), radius: 3)`

**拖曳把手（Drag Handle）：**
- **尺寸：** 44×44pt (符合 Apple HIG 最小觸控區域)
- **背景：** `.thinMaterial`
- **邊框：** `.white.opacity(0.3), 2.5pt`
- **陰影：** `shadow(color: .black.opacity(0.25), radius: 6, y: 3)`
- **圖標：** `chevron.left` + `chevron.right` (9pt, bold)
- **拖曳時縮放：** 1.15x
- **動畫：** `.easeInOut(duration: 0.15)`

**Before/After 標籤：**
- **字體：** 11pt, .semibold
- **文字顏色：** `.primary`（自動適配深淺模式）
- **背景：** `.thinMaterial`（比 ultraThin 更不透明，提供更好對比度）
- **形狀：** Capsule
- **內距：** horizontal 12pt, vertical 6pt
- **邊框：** `.primary.opacity(0.15), 1pt`
- **陰影：** `shadow(color: .black.opacity(0.15), radius: 6, y: 2)`
- **位置：** 左上角 20pt, 右上角 20pt
- **可讀性：** 符合 WCAG AA 標準（對比度 ≥ 4.5:1）

---

### 1.5 工具列（Top Toolbar）

**背景材質：** `.regularMaterial`

**App 標題區：**
```swift
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
        .foregroundColor(.primary)  // 自動適配深淺
}
```

**Open Image 按鈕：**
- **樣式：** `.bordered`
- **大小：** `.large`
- **文字：** `.primary`
- **圖標：** `folder.fill`

---

### 1.6 底部操作區（Bottom Action Bar）

**背景材質：** `.regularMaterial`

**狀態指示器：**

| 狀態 | 圖標 | 文字顏色 | 文字內容 |
|------|------|----------|----------|
| 空閒 | `arrow.up.doc.fill` | `.secondary.opacity(0.5)` | "開啟圖片以開始" |
| 載入 | `photo.fill` | `.blue` | "準備強化" |
| 處理中 | `ProgressView` | `.secondary` | "處理中..." |
| 完成 | `checkmark.circle.fill` | `.green` | "強化完成" |
| 錯誤 | `exclamationmark.triangle.fill` | `.orange` | 錯誤訊息 |

**格式選擇器：**
- **樣式：** `.segmented`
- **選項：** JPEG / PNG / WebP
- **寬度：** 150pt
- **文字：** `.primary` (normal), `.white` (selected)

**Save As 按鈕：**
- **樣式：** `.bordered`
- **大小：** `.large`
- **文字：** `.primary`
- **圖標：** `square.and.arrow.down.fill`

---

## 🎭 Material 使用規則

### Material 層級定義

| Material | 用途 | 透明度 | 適用場景 |
|----------|------|--------|----------|
| `.hudWindow` | 主背景 | 最高 | Window 底層 |
| `.regularMaterial` | 工具列 | 中等 | Toolbar, Sidebar |
| `.thinMaterial` | 次要元素 | 較高 | Drag handle, Popover |
| `.ultraThinMaterial` | 內容卡片 | 極高 | Image cards, Labels |

### 堆疊規則

❌ **禁止：**
- `.ultraThinMaterial` 疊在 `.ultraThinMaterial` 上（會太模糊）
- 超過 3 層 Material 堆疊

✅ **建議：**
```
.hudWindow (background)
  └─ .regularMaterial (toolbar)
      └─ .ultraThinMaterial (cards)
          └─ solid colors (text, icons)
```

---

## 🎬 動畫規範

### 標準動畫時長

| 動作 | 時長 | Easing | 用途 |
|------|------|--------|------|
| 按鈕 Hover | 0.2s | `.easeInOut` | 滑鼠懸停 |
| 按鈕 Press | 0.15s | `.easeInOut` | 點擊反饋 |
| Slider 拖曳 | 0.05s | `.easeInOut` | 即時反饋 |
| Modal 出現 | 0.3s | `.easeOut` | 彈窗進入 |
| Zoom/Pan | 0.3s | `.easeInOut` | 圖片縮放重置 |

### 動畫示例

```swift
// 按鈕縮放
.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.easeInOut(duration: 0.15), value: isPressed)

// 滑桿移動
withAnimation(.easeInOut(duration: 0.05)) {
    sliderPosition = newValue
}

// 視圖切換
withAnimation(.easeOut(duration: 0.3)) {
    showBeforeAfter = true
}
```

---

## 📏 Spacing 系統

**8pt Grid System：**
- **XS：** 4pt
- **S：** 8pt
- **M：** 12pt
- **L：** 16pt
- **XL：** 24pt
- **XXL：** 32pt
- **XXXL：** 48pt

**應用範例：**
```swift
.padding(.horizontal, 24)  // XL
.padding(.vertical, 16)    // L
HStack(spacing: 12)        // M
```

---

## 🖼️ 圖片預覽區詳細規格

### 空狀態（Empty State）

```
┌─────────────────────────────────────┐
│                                     │
│        📷 (photo.on.rectangle)      │ ← 64pt icon
│                                     │
│        拖曳圖片至此                  │ ← 16pt, .semibold, .primary
│   或點擊「Open Image」開啟檔案      │ ← 13pt, .secondary
│                                     │
│   支援 JPEG、PNG、HEIC、WebP 格式   │ ← 11pt, .secondary.opacity(0.7)
│                                     │
└─────────────────────────────────────┘
```

### 單圖預覽（Processing）

```
┌─────────────────────────────────────┐
│  雙擊重置 • 捏合縮放 • 拖曳移動      │ ← Hint label
│                                     │
│                                     │
│        [圖片內容]                    │
│                                     │
│         ◌ 處理中...                 │ ← Overlay (when processing)
│                                     │
└─────────────────────────────────────┘
```

### Before/After 滑桿

```
┌─────────────────────────────────────┐
│ Before              │      After    │ ← Labels
├─────────────────────┼───────────────┤
│                     │               │
│   [Before Image]    │ [After Image] │
│                     ◉               │ ← Drag handle
│                     │               │
└─────────────────────┴───────────────┘
```

---

## 🎯 實作優先級

### Phase 1（已完成）
- ✅ 基礎玻璃 UI
- ✅ Before/After Slider
- ✅ Zoom/Pan 功能

### Phase 2（建議優化）
- [ ] Hover 狀態動畫
- [ ] 鍵盤快捷鍵提示
- [ ] 拖曳放下動畫反饋

### Phase 3（未來）
- [ ] 偏好設定面板
- [ ] 多圖批次處理
- [ ] 匯出歷史記錄

---

**設計稿結束**
*此設計稿符合 Apple Human Interface Guidelines (macOS)*
