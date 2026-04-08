import SwiftUI

struct FragmentaProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FragmentaTypography.bodyEmphasized)
            .foregroundStyle(FragmentaColor.textPrimary)
            .padding(.horizontal, FragmentaSpacing.large)
            .padding(.vertical, FragmentaSpacing.medium)
            .background(
                Capsule(style: .continuous)
                    .fill(FragmentaColor.surfaceTertiary)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
    }
}

struct FragmentaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FragmentaTypography.subheadline)
            .foregroundStyle(FragmentaColor.textSecondary)
            .padding(.horizontal, FragmentaSpacing.medium)
            .padding(.vertical, FragmentaSpacing.small + 2)
            .background(
                Capsule(style: .continuous)
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
    }
}
