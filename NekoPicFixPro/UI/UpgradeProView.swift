//
//  UpgradeProView.swift
//  NekoPicFixPro
//
//  升級 Pro 版本介面（玻璃風格）
//

import SwiftUI
import StoreKit

struct UpgradeProView: View {
    @ObservedObject var appState: AppState
    @StateObject private var store = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Pro 圖標
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#667eea"),
                                        Color(hex: "#764ba2")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "#667eea").opacity(0.5), radius: 20, y: 10)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // 標題
                    Text("升級至 Pro 版本")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    Text("解鎖全部功能，無限制使用")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Pro 功能列表
                VStack(spacing: 16) {
                    ProFeatureRow(
                        icon: "infinity",
                        title: "無限制強化",
                        description: "不限次數，隨時強化任何圖片"
                    )

                    ProFeatureRow(
                        icon: "arrow.up.right.square",
                        title: "完整解析度輸出",
                        description: "4x 超解析度，不受 2048px 限制"
                    )

                    ProFeatureRow(
                        icon: "square.stack.3d.up",
                        title: "批次處理",
                        description: "一次處理最多 30 張圖片"
                    )

                    ProFeatureRow(
                        icon: "cpu",
                        title: "記憶體智慧管理",
                        description: "自動監控並優化處理流程"
                    )

                    ProFeatureRow(
                        icon: "paintbrush.pointed",
                        title: "5 種 AI 模型",
                        description: "完整使用所有強化模式"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 24)

                // 按鈕區域
                VStack(spacing: 12) {
                    // 升級按鈕
                    Button(action: {
                        Task {
                            isPurchasing = true
                            let success = await store.purchase()
                            isPurchasing = false
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isPurchasing || store.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "crown.fill")
                            }

                            if let product = store.proProduct {
                                Text("\(product.displayPrice) - 立即升級 Pro")
                                    .font(.system(size: 16, weight: .semibold))
                            } else {
                                Text("立即升級 Pro")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#667eea"),
                                    Color(hex: "#764ba2")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color(hex: "#667eea").opacity(0.4), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || store.isLoading)

                    // Restore 按鈕
                    Button(action: {
                        Task {
                            await store.restore()
                            if store.isProUser {
                                dismiss()
                            }
                        }
                    }) {
                        Text("恢復購買")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || store.isLoading)

                    // 關閉按鈕
                    Button(action: {
                        dismiss()
                    }) {
                        Text("稍後再說")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)

                    // 錯誤訊息
                    if let error = store.errorMessage {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    // Debug: 測試解鎖按鈕
                    #if DEBUG
                    Button(action: {
                        appState.unlockPro()
                        dismiss()
                    }) {
                        Text("Debug: 直接解鎖")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    #endif
                }
                .padding(24)
            }
            .padding(.bottom, 20)
        }
        .frame(minWidth: 420, maxWidth: 480, maxHeight: 700)
        .background(
            ZStack {
                // 玻璃背景
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)

                // 漸變邊框
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 30, y: 20)
    }
}

// MARK: - Pro Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // 圖標
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            // 文字
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    UpgradeProView(appState: AppState.shared)
}
