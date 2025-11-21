//
//  RestorePurchasesView.swift
//  NekoPicFixPro
//
//  恢復購買設定頁面
//

import SwiftUI

struct RestorePurchasesView: View {
    @StateObject private var store = StoreKitManager.shared
    @State private var showingSuccess = false
    @State private var showingError = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("恢復購買")
                    .font(.system(size: 24, weight: .bold))

                Text("如果您已在此 Apple ID 購買過 Pro 版本，\n可點擊下方按鈕恢復購買記錄。")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await store.restore()
                    if store.isProUser {
                        showingSuccess = true
                    } else if store.errorMessage != nil {
                        showingError = true
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if store.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }

                    Text("恢復購買記錄")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(store.isLoading)

            if let error = store.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(width: 400)
        .alert("恢復成功", isPresented: $showingSuccess) {
            Button("確定") {
                showingSuccess = false
            }
        } message: {
            Text("您的 Pro 版本已成功恢復！")
        }
        .alert("未找到購買記錄", isPresented: $showingError) {
            Button("確定") {
                showingError = false
            }
        } message: {
            Text("未找到此 Apple ID 的購買記錄。\n如果您確定已購買，請聯繫客服。")
        }
    }
}

#Preview {
    RestorePurchasesView()
}
