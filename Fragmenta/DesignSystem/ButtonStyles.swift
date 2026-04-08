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
                    .fill(
                        LinearGradient(
                            colors: [
                                FragmentaColor.surfaceQuaternary,
                                FragmentaColor.surfaceTertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.34), radius: 10, x: 0, y: 4)
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
                    .fill(FragmentaColor.surfaceSecondary.opacity(0.94))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.94 : 1)
    }
}
