import SwiftUI

struct SettingsView: View {
    let config: AppConfig

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Settings",
                        title: "App configuration",
                        subtitle: "Sprint 1 keeps this light, but the screen already exposes the backend base URL and the current architecture shape."
                    )

                    settingsCard(
                        title: "Backend",
                        body: config.apiBaseURL.absoluteString
                    )

                    settingsCard(
                        title: "Authentication",
                        body: "No auth flow is wired in Sprint 1. The API layer is prepared for header injection later through a request headers provider."
                    )

                    settingsCard(
                        title: "Roadmap hooks",
                        body: "Document picker import, highlight filtering, import history, offline caching, and user-facing account settings can all attach here without rewriting the app shell."
                    )
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, FragmentaSpacing.xxLarge)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private func settingsCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(body)
                .font(title == "Backend" ? FragmentaTypography.monospacedMetadata : FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(config: .preview)
        }
    }
}
#endif
