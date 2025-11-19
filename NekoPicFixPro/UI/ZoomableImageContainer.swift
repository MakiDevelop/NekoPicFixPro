//
//  ZoomableImageContainer.swift
//  NekoPicFixPro
//
//  可縮放、可拖曳的圖片容器
//  支援 Zoom / Pan / 滾輪縮放 / 雙擊重置
//

import SwiftUI
import AppKit
import Combine

/// 縮放和拖曳狀態（可外部控制，用於 Before/After 同步）
class ZoomPanState: ObservableObject {
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var lastScale: CGFloat = 1.0
    @Published var lastOffset: CGSize = .zero

    func reset() {
        scale = 1.0
        offset = .zero
        lastScale = 1.0
        lastOffset = .zero
    }
}

/// 可縮放圖片容器
struct ZoomableImageContainer: View {
    let image: NSImage?
    @StateObject private var state = ZoomPanState()
    @State private var imageSize: CGSize = .zero

    // 縮放限制
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 6.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let nsImage = image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(state.scale)
                        .offset(state.offset)
                        .gesture(magnificationGesture)
                        .simultaneousGesture(dragGesture)
                        .onTapGesture(count: 2) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                state.reset()
                            }
                        }
                        .onAppear {
                            imageSize = nsImage.size
                        }
                } else {
                    placeholderView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    handleScrollWheel(at: location, in: geometry.size)
                case .ended:
                    break
                }
            }
        }
    }

    // MARK: - Magnification Gesture

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / state.lastScale
                let newScale = state.scale * delta
                state.scale = min(max(newScale, minScale), maxScale)
                state.lastScale = value
            }
            .onEnded { _ in
                state.lastScale = 1.0
                // 確保縮放後不會超出邊界
                withAnimation(.easeOut(duration: 0.2)) {
                    state.offset = limitOffset(state.offset, scale: state.scale)
                }
            }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if state.scale > 1.0 {
                    let newOffset = CGSize(
                        width: state.lastOffset.width + value.translation.width,
                        height: state.lastOffset.height + value.translation.height
                    )
                    state.offset = limitOffset(newOffset, scale: state.scale)
                }
            }
            .onEnded { _ in
                state.lastOffset = state.offset
            }
    }

    // MARK: - Scroll Wheel (Placeholder)

    private func handleScrollWheel(at location: CGPoint, in size: CGSize) {
        // macOS 滾輪縮放需要使用 NSEvent，在 SwiftUI 中較複雜
        // 這裡保留接口，實際實現需要 NSViewRepresentable
    }

    // MARK: - Limit Offset

    private func limitOffset(_ offset: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1.0 else { return .zero }

        // 計算允許的最大偏移量
        let maxOffsetX = (imageSize.width * (scale - 1)) / 2
        let maxOffsetY = (imageSize.height * (scale - 1)) / 2

        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.3))
            Text("無圖片")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

/// 帶共享狀態的可縮放圖片容器（用於 Before/After 同步）
struct ZoomableImageContainerWithState: View {
    let image: NSImage?
    @ObservedObject var state: ZoomPanState

    var body: some View {
        GeometryReader { geometry in
            if let nsImage = image {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(state.scale)
                    .offset(state.offset)
            }
        }
        .clipped()
    }
}

// MARK: - Preview

#Preview {
    ZoomableImageContainer(image: nil)
        .frame(width: 600, height: 400)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
}
