//
//  GlassUIStyles.swift
//  NekoPicFixPro
//
//  Premium Apple Glass Design System
//  已整合設計 Token 與樣式組件
//

import SwiftUI

// MARK: - Glass Design Tokens

/// Apple Glass 設計系統
enum GlassDesign {

    // MARK: - Spacing (Apple HIG Grid)

    enum Spacing {
        static let xxxs: CGFloat = 4
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let s: CGFloat = 16
        static let m: CGFloat = 24
        static let l: CGFloat = 32
        static let xl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 14
        static let xlarge: CGFloat = 20
    }

    // MARK: - Typography

    enum Typography {
        static let title = Font.system(size: 17, weight: .semibold, design: .default)
        static let label = Font.system(size: 13, weight: .medium, design: .default)
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let beforeAfter = Font.system(size: 11, weight: .semibold, design: .default)
    }

    // MARK: - Colors

    enum Colors {
        // Light Mode
        static let textPrimaryLight = Color(hex: "1A1A1A").opacity(0.85)
        static let textSecondaryLight = Color(hex: "3A3A3A").opacity(0.65)

        // Dark Mode
        static let textPrimaryDark = Color.white.opacity(0.95)
        static let textSecondaryDark = Color.white.opacity(0.60)

        // Adaptive
        static var textPrimary: Color {
            Color.primary
        }

        static var textSecondary: Color {
            Color.secondary
        }
    }

    // MARK: - Shadows

    enum Shadow {
        static let card = (color: Color.black.opacity(0.12), radius: CGFloat(6), y: CGFloat(2))
        static let toolbar = (color: Color.black.opacity(0.08), radius: CGFloat(8), y: CGFloat(0))
        static let button = (color: Color.black.opacity(0.25), radius: CGFloat(8), y: CGFloat(4))
        static let subtle = (color: Color.black.opacity(0.10), radius: CGFloat(3), y: CGFloat(1))
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Glass Card Modifier

/// Premium Glass Card Style
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = GlassDesign.CornerRadius.xlarge

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(
                        color: GlassDesign.Shadow.card.color,
                        radius: GlassDesign.Shadow.card.radius,
                        y: GlassDesign.Shadow.card.y
                    )
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = GlassDesign.CornerRadius.xlarge) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Primary Button Style

/// Premium Primary Button (Enhance Button)
struct PrimaryGlassButtonStyle: ButtonStyle {
    let isEnabled: Bool
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GlassDesign.Typography.label)
            .foregroundColor(.white)
            .padding(.horizontal, GlassDesign.Spacing.s)
            .padding(.vertical, GlassDesign.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [
                                Color.accentColor,
                                Color.accentColor.opacity(0.85)
                            ] : [Color.gray, Color.gray.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .brightness(isHovered && isEnabled ? 0.05 : 0)
                    .shadow(
                        color: isEnabled ? GlassDesign.Shadow.button.color : .clear,
                        radius: GlassDesign.Shadow.button.radius,
                        y: GlassDesign.Shadow.button.y
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Secondary Button Style

/// Secondary Glass Button
struct SecondaryGlassButtonStyle: ButtonStyle {
    let isSelected: Bool
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GlassDesign.Typography.label)
            .foregroundColor(
                isSelected ? .white : GlassDesign.Colors.textPrimary
            )
            .padding(.horizontal, GlassDesign.Spacing.xs)
            .padding(.vertical, GlassDesign.Spacing.xxs)
            .background(
                RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.medium)
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.medium)
                            .fill(.thinMaterial)
                            .opacity(isSelected ? 0 : 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GlassDesign.CornerRadius.medium)
                            .strokeBorder(
                                Color.white.opacity(isSelected ? 0 : 0.12),
                                lineWidth: 1
                            )
                    )
                    .brightness(isHovered && !isSelected ? 0.05 : 0)
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 6,
                        y: 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Glass Toolbar Modifier

struct GlassToolbarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(GlassDesign.Spacing.xs)
            .background(.regularMaterial)
            .shadow(
                color: GlassDesign.Shadow.toolbar.color,
                radius: GlassDesign.Shadow.toolbar.radius,
                y: GlassDesign.Shadow.toolbar.y
            )
    }
}

extension View {
    func glassToolbar() -> some View {
        modifier(GlassToolbarStyle())
    }
}

// MARK: - Mode Capsule Button Style (Legacy, kept for compatibility)

/// 模式膠囊按鈕樣式
struct ModeCapsuleButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isAvailable: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            .foregroundColor(
                isSelected ? .white :
                    (isAvailable ? .primary : .secondary.opacity(0.5))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.clear)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? Color.clear : Color.secondary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.3) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Prominent Action Button Style (Legacy, kept for compatibility)

/// 主要動作按鈕樣式
struct ProminentActionButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isEnabled ? Color.accentColor : Color.gray)
                    .shadow(
                        color: isEnabled ? Color.accentColor.opacity(0.4) : .clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
