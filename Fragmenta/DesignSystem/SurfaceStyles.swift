import SwiftUI

struct JournalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(FragmentaSpacing.large)
            .background(
                RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                    .fill(FragmentaColor.surfacePrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.8), radius: 14, x: 0, y: 8)
    }
}

struct SectionSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(FragmentaSpacing.large)
            .background(
                RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
    }
}

struct InsetSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(FragmentaSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                    .fill(FragmentaColor.surfaceTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
    }
}

struct ChipSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, FragmentaSpacing.small + 2)
            .padding(.vertical, FragmentaSpacing.xSmall)
            .background(
                Capsule(style: .continuous)
                    .fill(FragmentaColor.surfaceTertiary)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}

struct FieldSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, FragmentaSpacing.medium)
            .padding(.vertical, FragmentaSpacing.medium)
            .background(
                RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
    }
}

struct PaperGlassCardModifier: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)

        content
            .padding(FragmentaSpacing.large)
            .background(
                shape
                    .fill(Color.clear)
                    .fragmentaCustomGlass(
                        in: shape,
                        tint: tint,
                        fallbackFill: FragmentaColor.surfacePrimary.opacity(0.92)
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.85), radius: 24, x: 0, y: 16)
            .shadow(color: FragmentaColor.paperGlow.opacity(0.35), radius: 18, x: 0, y: 10)
    }
}

extension View {
    func journalCardStyle() -> some View {
        modifier(JournalCardModifier())
    }

    func sectionSurfaceStyle() -> some View {
        modifier(SectionSurfaceModifier())
    }

    func insetSurfaceStyle() -> some View {
        modifier(InsetSurfaceModifier())
    }

    func chipSurfaceStyle() -> some View {
        modifier(ChipSurfaceModifier())
    }

    func fieldSurfaceStyle() -> some View {
        modifier(FieldSurfaceModifier())
    }

    func paperGlassCardStyle(tint: Color? = FragmentaColor.accent.opacity(0.14)) -> some View {
        modifier(PaperGlassCardModifier(tint: tint))
    }
}
