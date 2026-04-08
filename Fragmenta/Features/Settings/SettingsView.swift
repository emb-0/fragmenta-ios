import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: SettingsViewModel

    let config: AppConfig

    init(
        config: AppConfig,
        exportService: ExportServiceProtocol,
        importService: ImportServiceProtocol,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.config = config
        _viewModel = StateObject(
            wrappedValue: SettingsViewModel(
                exportService: exportService,
                importService: importService,
                diagnosticsStore: diagnosticsStore,
                baseURLOverride: ""
            )
        )
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Settings",
                        title: "App configuration",
                        subtitle: "A composed view into the app, the backend it speaks to, and the local shell state it keeps."
                    )

                    aboutCard
                    backendCard
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

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("About")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text("Fragmenta is the native reading artifact for Kindle exports parsed by fragmenta-core. Sprint 6 adds insights, collections, backend share cards, AI-backed discovery surfaces, and deeper cache resilience without shifting the app away from its calm reading focus.")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LabeledSettingRow(label: "Name", value: config.appDisplayName)
            LabeledSettingRow(label: "Version", value: config.appVersion)
            LabeledSettingRow(label: "Build", value: config.buildNumber)
            LabeledSettingRow(label: "Authentication", value: "Intentionally disabled for now.")
            LabeledSettingRow(label: "Share Intake", value: config.appGroupIdentifier ?? "Set FRAGMENTA_APP_GROUP_IDENTIFIER in Xcode before validating shared ingest.")
        }
        .sectionSurfaceStyle()
    }

    private var backendCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Backend")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text("Fragmenta currently speaks to a public fragmenta-core API without auth. Debug builds can override the base URL locally.")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)

            LabeledSettingRow(label: "Active", value: config.apiBaseURL.absoluteString, monospaced: true)
            LabeledSettingRow(label: "Default", value: config.defaultAPIBaseURL.absoluteString, monospaced: true)
            LabeledSettingRow(label: "App Group", value: config.appGroupIdentifier ?? "Not configured", monospaced: true)

#if DEBUG
            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                Text("Development override")
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)

                TextField("Development base URL override", text: $viewModel.baseURLOverrideDraft)
                    .font(FragmentaTypography.monospacedMetadata)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .fieldSurfaceStyle()

                Button("Apply Override") {
                    viewModel.applyBaseURLOverride(using: appState)
                }
                .fragmentaAdaptiveGlassButton(prominent: true)
            }
#endif
        }
        .sectionSurfaceStyle()
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Exports")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text("Prepare library-wide markdown or CSV exports from fragmenta-core, then hand them off through the system share sheet.")
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)

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
            DiagnosticRow(title: "Insights", event: viewModel.diagnostics.lastInsightsEvent)
            DiagnosticRow(title: "Collections", event: viewModel.diagnostics.lastCollectionsEvent)
            DiagnosticRow(title: "Search", event: viewModel.diagnostics.lastSearchEvent)
            DiagnosticRow(title: "Discovery", event: viewModel.diagnostics.lastDiscoveryEvent)
            DiagnosticRow(title: "Share Cards", event: viewModel.diagnostics.lastShareCardEvent)
            DiagnosticRow(title: "Import Preview", event: viewModel.diagnostics.lastImportPreviewEvent)
            DiagnosticRow(title: "Import Commit", event: viewModel.diagnostics.lastImportCommitEvent)
            DiagnosticRow(title: "Exports", event: viewModel.diagnostics.lastExportEvent)
            DiagnosticRow(title: "Cache", event: viewModel.diagnostics.lastCacheEvent)

            if let lastImportResponse = viewModel.lastImportResponse {
                CachedImportRow(response: lastImportResponse)
            }
        }
        .sectionSurfaceStyle()
    }

    private var cacheCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Local data")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(viewModel.cacheMessage ?? "Library snapshots, book detail payloads, insights, collections, discovery summaries, cover thumbnails, import history, diagnostics, and recent searches are stored locally to keep the shell resilient.")
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

private struct CachedImportRow: View {
    let response: ImportResponse

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text("LAST IMPORT".uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            Text(response.message ?? response.summaryLine)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)

            Text("\(response.status.rawValue.capitalized) · \(response.filename ?? "Kindle import")")
                .font(FragmentaTypography.caption)
                .foregroundStyle(FragmentaColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
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
                VStack(alignment: .leading, spacing: FragmentaSpacing.tiny) {
                    Text(format.title)
                        .font(FragmentaTypography.bodyEmphasized)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text("Library-wide export")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }

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
                importService: PreviewImportService(),
                diagnosticsStore: DiagnosticsStore()
            )
            .environmentObject(AppState(container: .preview))
        }
    }
}
#endif
