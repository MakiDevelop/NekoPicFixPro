//
//  BeforeAfterSliderView.swift
//  NekoPicFixPro
//
//  Before/After 滑桿比較器
//  macOS Sonoma 玻璃風格
//

import SwiftUI
import AppKit

/// Before/After 滑桿比較視圖
struct BeforeAfterSliderView: View {
    let beforeImage: NSImage?
    let afterImage: NSImage?

    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景（玻璃材質）
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

                // 圖片比較區域
                if let before = beforeImage, let after = afterImage {
                    imageComparisonView(before: before, after: after, width: geometry.size.width, height: geometry.size.height)
                } else {
                    placeholderView
                }

                // 滑桿控制器
                if beforeImage != nil && afterImage != nil {
                    sliderControl(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Image Comparison View

    @ViewBuilder
    private func imageComparisonView(before: NSImage, after: NSImage, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // After Image (底層，完整顯示)
            Image(nsImage: after)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)

            // Before Image (上層，根據滑桿位置裁切)
            Image(nsImage: before)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .mask(
                    Rectangle()
                        .frame(width: width * sliderPosition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
        }
    }

    // MARK: - Slider Control

    @ViewBuilder
    private func sliderControl(width: CGFloat, height: CGFloat) -> some View {
        let sliderX = width * sliderPosition

        ZStack {
            // Vertical Divider Line
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(width: 2)
                .blur(radius: 0.5)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 0)

            // Drag Handle (圓形把手)
            ZStack {
                // 外圈背景
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.25), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // 內部圖標
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.white)
                .opacity(0.9)
            }
            .scaleEffect(isDragging ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isDragging)
        }
        .frame(width: 40, height: height)
        .position(x: sliderX, y: height / 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let newPosition = value.location.x / width
                    withAnimation(.easeInOut(duration: 0.08)) {
                        sliderPosition = min(max(newPosition, 0), 1)
                    }
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))

            Text("載入圖片並強化後\n可使用滑桿比較差異")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Label Overlay (可選)

/// Before/After 標籤覆蓋層
struct BeforeAfterLabelOverlay: View {
    let sliderPosition: CGFloat

    var body: some View {
        HStack {
            // Before Label
            Text("Before")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.leading, 16)
                .padding(.top, 16)

            Spacer()

            // After Label
            Text("After")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.trailing, 16)
                .padding(.top, 16)
        }
    }
}

// MARK: - Preview

#Preview {
    BeforeAfterSliderView(
        beforeImage: nil,
        afterImage: nil
    )
    .frame(width: 800, height: 600)
    .padding(20)
}
