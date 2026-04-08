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

            LinearGradient(
                colors: [
                    Color.white.opacity(0.02),
                    Color.clear,
                    FragmentaColor.background.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
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

            RoundedRectangle(cornerRadius: 220, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .rotationEffect(.degrees(18))
                .scaleEffect(1.3)
                .blur(radius: 2)
                .offset(x: 180, y: -220)
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
            HStack(spacing: FragmentaSpacing.small) {
                Text(eyebrow.uppercased())
                    .font(FragmentaTypography.eyebrow)
                    .foregroundStyle(FragmentaColor.textTertiary)
                    .tracking(1.4)

                Rectangle()
                    .fill(FragmentaColor.divider)
                    .frame(width: 40, height: 1)
            }

            Text(title)
                .font(FragmentaTypography.largeTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(subtitle)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
