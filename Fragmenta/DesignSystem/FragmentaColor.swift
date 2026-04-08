import SwiftUI

enum FragmentaColor {
    static let background = Color(hex: 0x07090C)
    static let backgroundElevated = Color(hex: 0x0E1218)
    static let surfacePrimary = Color(hex: 0x121821)
    static let surfaceSecondary = Color(hex: 0x171E28)
    static let surfaceTertiary = Color(hex: 0x1E2632)
    static let surfaceQuaternary = Color(hex: 0x253040)
    static let surfaceMuted = Color(hex: 0x0C1016)
    static let surfaceOverlay = Color.white.opacity(0.05)
    static let divider = Color.white.opacity(0.08)
    static let shadow = Color.black.opacity(0.32)
    static let accent = Color(hex: 0x6D8AA8)
    static let accentSoft = Color(hex: 0x8E7D68)
    static let success = Color(hex: 0x6BAA8F)
    static let positive = Color(hex: 0x7AC3A2)
    static let warning = Color(hex: 0xC09158)
    static let negative = Color(hex: 0xD06C63)
    static let textPrimary = Color(hex: 0xF3F5F8)
    static let textSecondary = Color(hex: 0xB5BEC9)
    static let textTertiary = Color(hex: 0x7F8A96)
    static let ambientGlow = accent.opacity(0.18)
    static let paperGlow = accentSoft.opacity(0.18)

    static let appBackgroundGradient = LinearGradient(
        colors: [
            background,
            Color(hex: 0x090D12),
            backgroundElevated
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
