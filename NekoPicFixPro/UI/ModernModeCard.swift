//
//  ModernModeCard.swift
//  NekoPicFixPro
//
//  現代化模式卡片設計
//

import SwiftUI

/// 現代化模式卡片視圖
struct ModernModeCard: View {
    let mode: EnhancementMode
    let isSelected: Bool
    let isAvailable: Bool
    let shortcutKey: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 左側圖標
                ZStack {
                    // 漸變背景圓形
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [
                                    Color(hex: mode.gradientColors.start),
                                    Color(hex: mode.gradientColors.end)
                                ] : [
                                    Color(hex: mode.gradientColors.start).opacity(0.3),
                                    Color(hex: mode.gradientColors.end).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(
                            color: isSelected ? Color(hex: mode.gradientColors.start).opacity(0.4) : .clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )

                    // SF Symbol 圖標
                    Image(systemName: mode.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                // 右側文字內容
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(isSelected ? .primary : .primary.opacity(0.8))

                        Spacer()

                        // 快捷鍵標籤
                        Text(shortcutKey)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(isSelected ? .white : .secondary.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(hex: mode.gradientColors.start).opacity(0.5) : Color.secondary.opacity(0.1))
                            )
                    }

                    if isSelected {
                        Text(mode.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isSelected ? [
                                        Color(hex: mode.gradientColors.start).opacity(0.6),
                                        Color(hex: mode.gradientColors.end).opacity(0.6)
                                    ] : [
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color(hex: mode.gradientColors.start).opacity(0.2) : .clear,
                        radius: isSelected ? 16 : 0,
                        x: 0,
                        y: isSelected ? 8 : 0
                    )
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 12) {
        ModernModeCard(
            mode: .general,
            isSelected: true,
            isAvailable: true,
            shortcutKey: "⌘1",
            action: {}
        )

        ModernModeCard(
            mode: .naturalStrong,
            isSelected: false,
            isAvailable: true,
            shortcutKey: "⌘2",
            action: {}
        )

        ModernModeCard(
            mode: .anime,
            isSelected: false,
            isAvailable: true,
            shortcutKey: "⌘4",
            action: {}
        )
    }
    .padding()
    .frame(width: 240)
    .background(Color.black.opacity(0.1))
}
