import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum FragmentaMaterialLayer: String, Sendable {
    case bar
    case floatingControl
    case content
    case media
}

struct FragmentaAdaptiveGlassButtonModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let prominent: Bool
    let shape: ButtonBorderShape

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), reduceTransparency == false {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(shape)
            } else {
                content
                    .buttonStyle(.glass)
                    .buttonBorderShape(shape)
            }
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    @ViewBuilder
    private func fallback(_ content: Content) -> some View {
        if prominent {
            content.buttonStyle(FragmentaProminentButtonStyle())
        } else {
            content.buttonStyle(FragmentaSecondaryButtonStyle())
        }
    }
}

struct FragmentaAdaptiveGlassModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let shape: S
    let tint: Color?
    let interactive: Bool
    let fallbackFill: Color

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), reduceTransparency == false {
            let glass = interactive && reduceMotion == false ? Glass.regular.interactive(true) : Glass.regular

            if let tint {
                content
                    .glassEffect(glass, in: shape)
                    .tint(tint)
            } else {
                content.glassEffect(glass, in: shape)
            }
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(
                shape
                    .fill(fallbackFill)
                    .overlay(
                        shape
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
    }
}

struct FragmentaGlassCluster<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let spacing: CGFloat
    private let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), reduceTransparency == false {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
#else
        content
#endif
    }
}

struct FragmentaHeroMediaExtensionModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.backgroundExtensionEffect()
        } else {
            content
        }
#else
        content
#endif
    }
}

struct FragmentaTabBarMinimizationModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
#else
        content
#endif
    }
}

struct FragmentaTabBarChromeModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *), reduceTransparency == false {
            content
                .toolbarColorScheme(.dark, for: .tabBar)
                .toolbarBackground(.hidden, for: .tabBar)
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .toolbarColorScheme(.dark, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(FragmentaColor.backgroundElevated.opacity(0.88), for: .tabBar)
    }
}

extension View {
    func fragmentaAdaptiveGlassButton(prominent: Bool = false, shape: ButtonBorderShape = .capsule) -> some View {
        modifier(FragmentaAdaptiveGlassButtonModifier(prominent: prominent, shape: shape))
    }

    func fragmentaCustomGlass<S: Shape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false,
        fallbackFill: Color = FragmentaColor.surfaceOverlay
    ) -> some View {
        modifier(
            FragmentaAdaptiveGlassModifier(
                shape: shape,
                tint: tint,
                interactive: interactive,
                fallbackFill: fallbackFill
            )
        )
    }

    func fragmentaHeroMediaExtension() -> some View {
        modifier(FragmentaHeroMediaExtensionModifier())
    }

    func fragmentaTabBarMinimization() -> some View {
        modifier(FragmentaTabBarMinimizationModifier())
    }

    func fragmentaTabBarChrome() -> some View {
        modifier(FragmentaTabBarChromeModifier())
    }
}

enum HapticFeedback {
#if canImport(UIKit)
    typealias ImpactStyle = UIImpactFeedbackGenerator.FeedbackStyle
    typealias NotificationType = UINotificationFeedbackGenerator.FeedbackType
#else
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }

    enum NotificationType {
        case success
        case warning
        case error
    }
#endif

    static func impact(_ style: ImpactStyle) {
#if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
#endif
    }

    static func notification(_ type: NotificationType) {
#if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
#endif
    }

    static func selectionChanged() {
#if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
#endif
    }
}
