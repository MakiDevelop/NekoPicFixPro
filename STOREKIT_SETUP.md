# NekoPicFix Pro - StoreKit 3 IAP 設定指南

## ✅ 已實作功能

### 📦 StoreKitManager.swift
- ✅ `fetchProducts()` - 載入商品資訊
- ✅ `purchase()` - 購買處理 + 驗證
- ✅ `updatePurchasedProducts()` - 啟動時掃描交易
- ✅ `restore()` - 恢復購買
- ✅ `checkVerified()` - 交易驗證包裝
- ✅ 所有函式標註 `@MainActor`

### 🎨 UI 整合
- ✅ UpgradeProView - 整合真實 IAP
- ✅ 顯示商品價格 (`product.displayPrice`)
- ✅ Loading 狀態 + 錯誤訊息
- ✅ 恢復購買按鈕
- ✅ Debug 直接解鎖按鈕

### 🔐 狀態管理
- ✅ 與 `AppState` 整合
- ✅ UserDefaults 持久化
- ✅ `isProUser` 狀態同步

---

## 🧪 測試方式

### 1️⃣ Sandbox 測試

#### A. 創建 StoreKit Configuration File
```
File → New → File → StoreKit Configuration File
名稱：Products.storekit
```

#### B. 添加商品
```json
{
  "Product ID": "tw.maki.NekoPicFixPro.unlock",
  "Type": "Non-Consumable",
  "Reference Name": "NekoPicFix Pro Unlock",
  "Price": "$9.99"
}
```

#### C. 設定測試環境
```
Product → Scheme → Edit Scheme
Run → Options → StoreKit Configuration
選擇：Products.storekit
```

#### D. 運行測試
```
1. 啟動 App
2. Console 顯示：
   📱 Bundle ID = tw.maki.NekoPicFixPro
   ✅ Products loaded: 1

3. 點擊 Free 標籤 → 升級視窗
4. 顯示：$9.99 - 立即升級 Pro
5. 點擊購買 → Sandbox 付款視窗
6. 輸入 Sandbox Apple ID（測試帳號）
7. 購買成功 → Toolbar 變為 👑 Pro
```

### 2️⃣ 本機測試（無需 Sandbox）

#### 使用 Debug 直接解鎖
```swift
// UpgradeProView 底部有：
#if DEBUG
Button("Debug: 直接解鎖") {
    appState.unlockPro()
    dismiss()
}
#endif
```

### 3️⃣ TestFlight 測試

#### 上傳 TestFlight 後：
```
1. App Store Connect → TestFlight
2. 添加測試人員
3. 測試人員可用真實信用卡測試（會扣款）
4. 或使用 Sandbox 帳號測試（不扣款）
```

---

## 🚀 上架準備

### 1️⃣ App Store Connect 設定

#### A. 商品設定
```
App Store Connect → 我的 App → NekoPicFix Pro
→ 功能 → App 內購買項目
→ 非消耗性項目

商品 ID: tw.maki.NekoPicFixPro.unlock
參考名稱: NekoPicFix Pro Unlock
價格層級: $9.99（或其他）
```

#### B. 審核資訊
```
螢幕截圖（顯示購買流程）
審核備註：
- 測試帳號資訊
- 購買流程說明
```

### 2️⃣ 程式碼確認

#### ✅ 移除 Debug 代碼（上架前）
```swift
// 確認 UpgradeProView.swift 中：
#if DEBUG
// ... Debug 按鈕不會出現在 Release 版本
#endif
```

#### ✅ Bundle ID 確認
```
1. 啟動 App（Debug）
2. Console 顯示：📱 Bundle ID = tw.maki.NekoPicFixPro
3. 確認與 App Store Connect 一致
```

#### ✅ Product ID 確認
```swift
// StoreKitManager.swift
private let productID = "tw.maki.NekoPicFixPro.unlock"
// ⚠️ 必須與 App Store Connect 完全一致
```

### 3️⃣ 建置 & 上傳

```bash
# Archive
Xcode → Product → Archive

# 上傳
Window → Organizer → Distribute App
→ App Store Connect
```

---

## 🔧 常見問題

### Q1: 商品載入失敗（products.count = 0）
```
原因：Product ID 不匹配
解決：
1. 檢查 StoreKitManager.productID
2. 檢查 App Store Connect 商品 ID
3. 確認 Bundle ID 一致
```

### Q2: 購買後未解鎖
```
檢查：
1. Console 是否顯示 "✅ Purchase successful"
2. AppState.isProUnlocked 是否為 true
3. UserDefaults 是否儲存成功
```

### Q3: Restore 失敗
```
原因：未找到交易記錄
解決：
1. 確認使用相同 Apple ID
2. 確認購買成功（非取消）
3. 等待 App Store 同步（可能需要幾分鐘）
```

### Q4: Sandbox 測試無效
```
檢查：
1. Scheme → StoreKit Configuration 已設定
2. Sandbox 帳號已登入
3. 商品狀態為「準備提交」或「已批准」
```

---

## 📝 最佳實踐

### ✅ DO
- 使用 Transaction.verify() 驗證所有交易
- 使用 transaction.finish() 完成交易
- App 啟動時呼叫 updatePurchasedProducts()
- 提供 Restore 按鈕
- 處理所有錯誤情況

### ❌ DON'T
- 不要略過交易驗證
- 不要忘記 finish() 交易
- 不要在 UI 執行緒阻塞購買流程
- 不要硬編碼價格（使用 displayPrice）
- 不要在 Release 版本留 Debug 解鎖

---

## 🎯 檢查清單

### 上架前確認
- [ ] Product ID 與 App Store Connect 一致
- [ ] Bundle ID 與 App Store Connect 一致
- [ ] 測試購買流程（Sandbox）
- [ ] 測試恢復購買
- [ ] 移除 Debug 直接解鎖按鈕
- [ ] 準備審核截圖
- [ ] 準備測試帳號資訊
- [ ] 確認價格設定正確

### Runtime 檢查
- [ ] Console 顯示 Bundle ID
- [ ] Products loaded: 1
- [ ] Purchase successful
- [ ] Transaction verified
- [ ] Pro unlocked
- [ ] Transaction finished

---

## 📚 相關文件

- [StoreKit 3 官方文件](https://developer.apple.com/documentation/storekit)
- [In-App Purchase 最佳實踐](https://developer.apple.com/app-store/in-app-purchase/)
- [App Store 審核指南](https://developer.apple.com/app-store/review/guidelines/)

---

**實作完成日期**: 2025-11-21
**StoreKit 版本**: StoreKit 3
**最低系統**: macOS 14.0+
