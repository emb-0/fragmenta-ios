import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel

    let config: AppConfig

    init(
        config: AppConfig,
        exportService: ExportServiceProtocol,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.config = config
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                exportService: exportService,
                diagnosticsStore: diagnosticsStore,
                baseURLOverride: ""
            )
        )
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Settings",
                        title: "App configuration",
                        subtitle: "Sprint 2 exposes backend, cache, export, and diagnostics information without turning the app into a debug panel."
                    )

                    backendCard
                    appInfoCard
                    exportCard
                    diagnosticsCard
                    cacheCard
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
        .task {
            if viewModel.baseURLOverrideDraft.isEmpty {
                viewModel.baseURLOverrideDraft = appState.developmentBaseURLOverride
            }
            viewModel.load()
        }
    }

    private var backendCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Backend")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            LabeledSettingRow(label: "Active", value: config.apiBaseURL.absoluteString, monospaced: true)
            LabeledSettingRow(label: "Default", value: config.defaultAPIBaseURL.absoluteString, monospaced: true)

#if DEBUG
            TextField("Development base URL override", text: $viewModel.baseURLOverrideDraft)
                .font(FragmentaTypography.monospacedMetadata)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .fieldSurfaceStyle()

            Button("Apply Override") {
                viewModel.applyBaseURLOverride(using: appState)
            }
            .fragmentaAdaptiveGlassButton(prominent: true)
#endif
        }
        .sectionSurfaceStyle()
    }

    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("App")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            LabeledSettingRow(label: "Name", value: config.appDisplayName)
            LabeledSettingRow(label: "Version", value: config.appVersion)
            LabeledSettingRow(label: "Build", value: config.buildNumber)
            LabeledSettingRow(label: "Authentication", value: "Still disabled in Sprint 2.")
        }
        .sectionSurfaceStyle()
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Exports")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            ForEach(ExportFormat.allCases) { format in
                ExportRow(
                    format: format,
                    state: viewModel.exportState(for: format),
                    exportAction: {
                        viewModel.export(format)
                    }
                )
            }
        }
        .sectionSurfaceStyle()
    }

    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Diagnostics")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            DiagnosticRow(title: "Library", event: viewModel.diagnostics.lastLibraryEvent)
            DiagnosticRow(title: "Search", event: viewModel.diagnostics.lastSearchEvent)
            DiagnosticRow(title: "Import Preview", event: viewModel.diagnostics.lastImportPreviewEvent)
            DiagnosticRow(title: "Import Commit", event: viewModel.diagnostics.lastImportCommitEvent)
            DiagnosticRow(title: "Exports", event: viewModel.diagnostics.lastExportEvent)
            DiagnosticRow(title: "Cache", event: viewModel.diagnostics.lastCacheEvent)
        }
        .sectionSurfaceStyle()
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Local data")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(viewModel.cacheMessage ?? "Library snapshots, book detail payloads, import history, and recent searches are stored locally for a more resilient shell.")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)

            Button("Clear cache") {
                viewModel.clearCache(using: appState)
            }
            .fragmentaAdaptiveGlassButton()
        }
        .sectionSurfaceStyle()
    }
}

private struct LabeledSettingRow: View {
    let label: String
    let value: String
    var monospaced = false

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            Text(value)
                .font(monospaced ? FragmentaTypography.monospacedMetadata : FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct ExportRow: View {
    let format: ExportFormat
    let state: LoadableState<ExportArtifact>
    let exportAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            HStack {
                Text(format.title)
                    .font(FragmentaTypography.bodyEmphasized)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Spacer()

                switch state {
                case .loading:
                    ProgressView()
                        .tint(FragmentaColor.textPrimary)
                case .loaded(let artifact, _):
                    ShareLink(item: artifact.fileURL) {
                        Text("Share")
                            .font(FragmentaTypography.metadata)
                            .foregroundStyle(FragmentaColor.textPrimary)
                            .chipSurfaceStyle()
                    }
                case .idle, .failed:
                    Button("Generate") {
                        exportAction()
                    }
                    .fragmentaAdaptiveGlassButton()
                }
            }

            switch state {
            case .idle:
                Text("Prepare a \(format.title.lowercased()) export from fragmenta-core.")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            case .loading(let previous):
                if let previous {
                    Text(previous.fileURL.lastPathComponent)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                } else {
                    Text("Generating export...")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }
            case .loaded(let artifact, _):
                Text("\(artifact.fileURL.lastPathComponent) · \(ByteCountFormatter.string(fromByteCount: Int64(artifact.byteCount), countStyle: .file))")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            case .failed(let message, _):
                Text(message)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct DiagnosticRow: View {
    let title: String
    let event: DiagnosticEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(title.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            if let event {
                Text(event.detail)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)

                Text("\(event.status.rawValue.capitalized) · \(event.recordedAt.fragmentaDayMonthYearString())")
                    .font(FragmentaTypography.caption)
                    .foregroundStyle(FragmentaColor.textTertiary)
            } else {
                Text("No diagnostics recorded yet.")
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView(
                config: .preview,
                exportService: PreviewExportService(),
                diagnosticsStore: DiagnosticsStore()
            )
            .environmentObject(AppState(container: .preview))
        }
    }
}
#endif
