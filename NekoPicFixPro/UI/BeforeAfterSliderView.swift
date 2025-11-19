//
//  BeforeAfterSliderView.swift
//  NekoPicFixPro
//
//  Before/After 滑桿比較器（重構版）
//  單一預覽框，支援共享 Zoom/Pan 狀態
//

import SwiftUI
import AppKit

/// Before/After 滑桿比較視圖（共享縮放狀態）
struct BeforeAfterSliderView: View {
    let beforeImage: NSImage
    let afterImage: NSImage

    @StateObject private var zoomState = ZoomPanState()
    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging: Bool = false

    // 縮放限制
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 6.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景玻璃材質
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

                // Before/After 圖片比較區
                imageComparisonView(width: geometry.size.width, height: geometry.size.height)
                    .gesture(magnificationGesture)
                    .simultaneousGesture(dragGesture)
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            zoomState.reset()
                        }
                    }

                // 滑桿控制器
                sliderControl(width: geometry.size.width, height: geometry.size.height)

                // Before/After 標籤
                labelOverlay
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Image Comparison View

    @ViewBuilder
    private func imageComparisonView(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // After Image (底層，完整顯示)
            Image(nsImage: afterImage)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .scaleEffect(zoomState.scale)
                .offset(zoomState.offset)

            // Before Image (上層，根據滑桿位置裁切)
            Image(nsImage: beforeImage)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .scaleEffect(zoomState.scale)
                .offset(zoomState.offset)
                .mask(
                    Rectangle()
                        .frame(width: width * sliderPosition)
                        .frame(maxWidth: .infinity, alignment: .leading)
                )
        }
        .clipped()
    }

    // MARK: - Slider Control

    @ViewBuilder
    private func sliderControl(width: CGFloat, height: CGFloat) -> some View {
        let sliderX = width * sliderPosition

        ZStack {
            // Vertical Divider Line
            Rectangle()
                .fill(.white.opacity(0.85))
                .frame(width: 3)
                .blur(radius: 0.5)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 0)

            // Drag Handle (圓形把手)
            ZStack {
                // 外圈背景
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)

                // 內部箭頭圖標
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.white)
                .opacity(0.95)
            }
            .scaleEffect(isDragging ? 1.15 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isDragging)
        }
        .frame(width: 44, height: height)
        .position(x: sliderX, y: height / 2)
        .gesture(sliderDragGesture(width: width))
        .allowsHitTesting(true)
    }

    // MARK: - Magnification Gesture

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / zoomState.lastScale
                let newScale = zoomState.scale * delta
                zoomState.scale = min(max(newScale, minScale), maxScale)
                zoomState.lastScale = value
            }
            .onEnded { _ in
                zoomState.lastScale = 1.0
                withAnimation(.easeOut(duration: 0.2)) {
                    zoomState.offset = limitOffset(zoomState.offset, scale: zoomState.scale)
                }
            }
    }

    // MARK: - Drag Gesture (for Pan)

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if zoomState.scale > 1.0 {
                    let newOffset = CGSize(
                        width: zoomState.lastOffset.width + value.translation.width,
                        height: zoomState.lastOffset.height + value.translation.height
                    )
                    zoomState.offset = limitOffset(newOffset, scale: zoomState.scale)
                }
            }
            .onEnded { _ in
                zoomState.lastOffset = zoomState.offset
            }
    }

    // MARK: - Slider Drag Gesture

    private func sliderDragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = true
                let newPosition = value.location.x / width
                withAnimation(.easeInOut(duration: 0.05)) {
                    sliderPosition = min(max(newPosition, 0), 1)
                }
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    // MARK: - Limit Offset

    private func limitOffset(_ offset: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1.0 else { return .zero }

        let imageSize = beforeImage.size
        let maxOffsetX = (imageSize.width * (scale - 1)) / 2
        let maxOffsetY = (imageSize.height * (scale - 1)) / 2

        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }

    // MARK: - Label Overlay

    private var labelOverlay: some View {
        HStack {
            // Before Label
            Text("Before")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)  // 自動適配深淺模式
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.thinMaterial)  // 使用更不透明的材質提高對比度
                        .overlay(
                            Capsule()
                                .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
                .padding(.leading, 20)
                .padding(.top, 20)

            Spacer()

            // After Label
            Text("After")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)  // 自動適配深淺模式
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.thinMaterial)  // 使用更不透明的材質提高對比度
                        .overlay(
                            Capsule()
                                .strokeBorder(.primary.opacity(0.15), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 2)
                .padding(.trailing, 20)
                .padding(.top, 20)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Preview

#Preview {
    BeforeAfterSliderView(
        beforeImage: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!,
        afterImage: NSImage(systemSymbolName: "photo.fill", accessibilityDescription: nil)!
    )
    .frame(width: 800, height: 600)
    .padding(20)
}
