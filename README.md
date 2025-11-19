# 🐱 NekoPicFix Lite
### A lightweight, offline macOS image upscaler powered by CoreML + Real-ESRGAN (4×)

NekoPicFix Lite 是一款 **完全離線、基於 CoreML 的 macOS 圖片放大與增強工具**。  
它使用 Real-ESRGAN 4× 模型，能將低解析度影像放大至 4 倍並提升細節，適合處理：

- 老舊手機拍攝的小圖  
- 壓縮後的網路圖片  
- 低解析人物或場景照  
- 插畫、物品、風景等需要放大的影像  

🛡 **不需要 Python、不需要外部伺服器、不需要網路**。  
所有推論皆在本機 GPU / Neural Engine 完成。

---

## ✨ Features (v1.1)

- 🖼 載入單張圖片（PNG / JPG / HEIC）
- 🔍 左右對照的 Before / After 預覽模式
- ⚡ 使用 Real-ESRGAN 4× CoreML 模型進行超解析度推論
- 🧠 所有處理都在本地進行（無雲端、無外部 API）
- 💾 將強化後影像存為 JPEG
- 🛑 大圖安全機制（自動縮放避免 GPU 記憶體爆掉）
- 🍎 100% Swift + SwiftUI + CoreML，完全原生 macOS 技術棧

---

## 🧠 Model

NekoPicFix Lite 使用 **Real-ESRGAN 4× CoreML** 模型。

模型來源（Google Drive）：

- RealESRGAN 4×  
  https://drive.google.com/file/d/1XpLndNmSOjkBpTolQwQ8qXG9uuV0uUQO/view?usp=sharing

### 模型放置位置
請將下載後的 `.mlmodel` 放到：

```
NekoPicFixPro/Models/RealESRGAN4x.mlmodel
```

Xcode 會在 Build 時自動將 `.mlmodel` 轉換為 `.mlmodelc`。

---

## 📁 Project Structure

```
NekoPicFixPro/
 ├── NekoPicFixProApp.swift
 ├── App/
 ├── UI/
 │    ├── MainView.swift
 │    └── ImagePanel.swift
 ├── ML/
 │    ├── ImageUpscaler.swift
 │    └── RealESRGAN4xUpscaler.swift
 ├── Services/
 │    └── ImageEnhancementService.swift
 ├── Models/
 │    └── RealESRGAN4x.mlmodel  ← (User-provided)
 └── Resources/
	  └── Assets.xcassets
```

---

## 🚧 Roadmap

### v1.2  
- Blend Mix Mode（避免臉過度平滑）
- 輕微銳化 / 降噪選項  

### v1.3  
- Face Protection（人臉區域不做 4×，只做溫和增強）
- 自動偵測人臉與局部處理  

### v2.0（Pro）  
- GFPGAN（臉部修復）  
- CodeFormer（嚴重臉部補全）  
- SwinIR（更高品質降噪）  
- Tile-based 無接縫大圖增強  

---

## 💻 Build Instructions

1. Clone 專案  
2. 下載 RealESRGAN4x `.mlmodel` 放入 `Models/`  
3. 使用 Xcode 15+ 開啟 `NekoPicFixPro.xcodeproj`  
4. Build & Run  
5. 模型會在第一次執行時編譯為 `.mlmodelc`  

---

## 🔒 License

本專案以 MIT License 授權釋出。  
Real-ESRGAN 模型採 BSD 3-Clause，允許商用。

---

## 🐱 About

NekoPicFix Lite 是 Neko 工具系列的一部分。  
此版本專注於 **乾淨、純粹、可離線執行的增強功能**。

如有建議、錯誤回報或功能需求，歡迎開 Issue！
