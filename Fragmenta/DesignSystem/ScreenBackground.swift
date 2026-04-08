import SwiftUI

struct FragmentaScreenBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            FragmentaColor.appBackgroundGradient
                .ignoresSafeArea()

            VStack {
                Circle()
                    .fill(FragmentaColor.ambientGlow)
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: 110, y: -160)

                Spacer()
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                Circle()
                    .fill(FragmentaColor.paperGlow)
                    .frame(width: 320, height: 320)
                    .blur(radius: 120)
                    .offset(x: -140, y: 120)
            }
            .ignoresSafeArea()

            content
        }
    }
}

struct FragmentaSectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text(eyebrow.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.4)

            Text(title)
                .font(FragmentaTypography.largeTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(subtitle)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
