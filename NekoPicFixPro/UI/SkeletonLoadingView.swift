//
//  SkeletonLoadingView.swift
//  NekoPicFixPro
//
//  Apple 風格骨架屏載入動畫
//

import SwiftUI

/// Apple 風格骨架屏載入視圖
struct SkeletonLoadingView: View {
    @State private var animationPhase: CGFloat = -1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 基礎背景
                RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.xlarge)
                    .fill(.ultraThinMaterial)

                // 骨架內容
                VStack(spacing: GlassDesign.Spacing.m) {
                    // 圖片區域骨架
                    RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.medium)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: geometry.size.height * 0.6)
                        .overlay(shimmerEffect(width: geometry.size.width))

                    // 文字區域骨架
                    VStack(spacing: GlassDesign.Spacing.xxs) {
                        ForEach(0..<3) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.12))
                                .frame(
                                    width: geometry.size.width * (index == 2 ? 0.5 : 0.7),
                                    height: 12
                                )
                                .overlay(shimmerEffect(width: geometry.size.width))
                        }
                    }
                }
                .padding(GlassDesign.Spacing.m)
            }
            .glassCard()
        }
        .onAppear {
            withAnimation(
                .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                animationPhase = 1.0
            }
        }
    }

    // MARK: - Shimmer Effect

    private func shimmerEffect(width: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: width * 0.5)
        .offset(x: width * animationPhase)
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white,
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
}

/// 簡化版骨架屏（用於小型載入狀態）
struct CompactSkeletonView: View {
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: GlassDesign.Spacing.s) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(.circular)

            Text("載入中...")
                .font(GlassDesign.Typography.caption)
                .foregroundColor(GlassDesign.Colors.textSecondary)
        }
        .padding(GlassDesign.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.medium)
                .fill(.ultraThinMaterial)
                .opacity(pulseAnimation ? 0.8 : 1.0)
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Skeleton Loading") {
    SkeletonLoadingView()
        .frame(width: 400, height: 500)
        .padding()
}

#Preview("Compact Skeleton") {
    CompactSkeletonView()
        .padding()
}
