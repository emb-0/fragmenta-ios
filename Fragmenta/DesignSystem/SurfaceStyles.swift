import SwiftUI

struct JournalCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)

        content
            .padding(FragmentaSpacing.large)
            .background(
                shape
                    .fill(FragmentaColor.surfacePrimary)
                    .overlay(
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.05),
                                        Color.clear,
                                        FragmentaColor.accent.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.82), radius: 20, x: 0, y: 10)
    }
}

struct SectionSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)

        content
            .padding(FragmentaSpacing.large)
            .background(
                shape
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.035),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.42), radius: 14, x: 0, y: 8)
    }
}

struct InsetSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)

        content
            .padding(FragmentaSpacing.medium)
            .background(
                shape
                    .fill(FragmentaColor.surfaceTertiary)
                    .overlay(
                        shape
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
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)

        content
            .padding(.horizontal, FragmentaSpacing.medium)
            .padding(.vertical, FragmentaSpacing.medium)
            .background(
                shape
                    .fill(FragmentaColor.surfaceSecondary.opacity(0.9))
                    .overlay(
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.04),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}

struct EditorSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)

        content
            .background(
                shape
                    .fill(FragmentaColor.surfaceMuted.opacity(0.94))
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.3), radius: 16, x: 0, y: 8)
    }
}

struct FloatingBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: FragmentaRadius.hero, style: .continuous)

        content
            .padding(FragmentaSpacing.small)
            .background(
                shape
                    .fill(Color.clear)
                    .fragmentaCustomGlass(
                        in: shape,
                        tint: FragmentaColor.accent.opacity(0.08),
                        fallbackFill: FragmentaColor.backgroundElevated.opacity(0.96)
                    )
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: FragmentaColor.shadow.opacity(0.55), radius: 22, x: 0, y: 10)
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

    func editorSurfaceStyle() -> some View {
        modifier(EditorSurfaceModifier())
    }

    func floatingBarStyle() -> some View {
        modifier(FloatingBarModifier())
    }

    func paperGlassCardStyle(tint: Color? = FragmentaColor.accent.opacity(0.14)) -> some View {
        modifier(PaperGlassCardModifier(tint: tint))
    }
}
