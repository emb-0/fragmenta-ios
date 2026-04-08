import SwiftUI

struct ImportView: View {
    @StateObject private var viewModel: ImportViewModel

    init(importService: ImportServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ImportViewModel(importService: importService))
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Import",
                        title: "Bring in a Kindle export",
                        subtitle: "Preview the backend parse before committing, whether the source arrives from pasted text or a `.txt` document."
                    )

                    sourceModePicker
                    importSourceCard
                    workflowCard
                    importHistorySection
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, 128)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .task {
            viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $viewModel.isShowingDocumentPicker) {
            KindleDocumentPicker { url in
                viewModel.handlePickedDocument(url)
                viewModel.isShowingDocumentPicker = false
            }
        }
        .sheet(item: Binding(
            get: { viewModel.selectedHistoryRecord },
            set: { _ in viewModel.dismissHistoryDetail() }
        )) { record in
            ImportRecordDetailSheet(record: record)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var sourceModePicker: some View {
        HStack(spacing: FragmentaSpacing.small) {
            ForEach(ImportViewModel.SourceMode.allCases) { sourceMode in
                Button(sourceMode.title) {
                    viewModel.selectSourceMode(sourceMode)
                }
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(viewModel.sourceMode == sourceMode ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)
                .frame(maxWidth: .infinity)
                .fieldSurfaceStyle()
            }
        }
    }

    private var importSourceCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack {
                Text(viewModel.sourceMode == .paste ? "Paste text" : "File input")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Spacer()

                if viewModel.sourceMode == .file {
                    Button("Choose .txt") {
                        viewModel.presentDocumentPicker()
                    }
                    .fragmentaAdaptiveGlassButton()
                }
            }

            if let importedFile = viewModel.importedFile {
                FileSelectionCard(importedFile: importedFile)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                    .fill(FragmentaColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FragmentaRadius.large, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )

                if viewModel.rawText.isBlank {
                    Text(viewModel.sourceMode == .paste ? "Paste the full Kindle highlights export here." : "Choose a `.txt` file to load its contents here.")
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .padding(FragmentaSpacing.medium)
                }

                TextEditor(text: $viewModel.rawText)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(FragmentaColor.textPrimary)
                    .frame(minHeight: 280)
                    .padding(FragmentaSpacing.small)
                    .background(Color.clear)
            }
        }
        .sectionSurfaceStyle()
    }

    @ViewBuilder
    private var workflowCard: some View {
        switch viewModel.workflowState {
        case .idle:
            ImportStatusCard(
                title: "Ready for preview",
                message: "Sprint 2 previews the backend parse first, then confirms the import with a second request so the app feels less brittle."
            )

        case .editing:
            ImportStatusCard(
                title: "Draft prepared",
                message: "Preview the import to see detected books, highlights, notes, duplicates, and warnings before committing."
            )

        case .previewLoading:
            ImportLoadingCard(title: "Previewing Kindle export...")

        case .previewReady(let preview):
            ImportPreviewCard(preview: preview)

        case .importing(let preview):
            VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
                ImportLoadingCard(title: "Sending import to fragmenta-core...")

                if let preview {
                    ImportPreviewCard(preview: preview)
                }
            }

        case .success(let response):
            ImportResultCard(response: response)

        case .failure(let message):
            ImportStatusCard(title: "Import issue", message: message)
        }
    }

    @ViewBuilder
    private var importHistorySection: some View {
        let records = viewModel.historyState.value ?? []

        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack {
                Text("Recent imports")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Spacer()

                Button("Refresh") {
                    viewModel.refreshHistory()
                }
                .fragmentaAdaptiveGlassButton()
            }

            if records.isEmpty {
                switch viewModel.historyState {
                case .idle, .loading:
                    ImportLoadingCard(title: "Loading import history...")
                case .failed(let message, _):
                    ImportStatusCard(title: "Import history unavailable", message: message)
                case .loaded:
                    ImportStatusCard(
                        title: "No imports yet",
                        message: "Once the backend accepts Kindle data, recent import sessions will appear here."
                    )
                }
            } else {
                if case .failed(let message, let previous) = viewModel.historyState, previous != nil {
                    ImportStatusCard(title: "Showing saved import history", message: message)
                }

                ForEach(records) { record in
                    Button {
                        viewModel.inspectImport(record)
                    } label: {
                        ImportHistoryRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            if viewModel.sourceMode == .file {
                Button("Choose File") {
                    viewModel.presentDocumentPicker()
                }
                .fragmentaAdaptiveGlassButton()
            } else {
                Button("Clear") {
                    viewModel.reset()
                }
                .fragmentaAdaptiveGlassButton()
            }

            Button(primaryActionTitle) {
                switch viewModel.workflowState {
                case .previewReady:
                    viewModel.confirmImport()
                default:
                    viewModel.previewImport()
                }
            }
            .disabled(primaryActionDisabled)
            .fragmentaAdaptiveGlassButton(prominent: true)
        }
        .padding(.horizontal, FragmentaSpacing.large)
        .padding(.vertical, FragmentaSpacing.medium)
        .background(
            Rectangle()
                .fill(FragmentaColor.background.opacity(0.92))
                .ignoresSafeArea()
        )
    }

    private var primaryActionTitle: String {
        switch viewModel.workflowState {
        case .previewReady:
            return "Import Highlights"
        case .previewLoading:
            return "Previewing..."
        case .importing:
            return "Importing..."
        default:
            return "Preview Import"
        }
    }

    private var primaryActionDisabled: Bool {
        if viewModel.rawText.trimmed.isEmpty {
            return true
        }

        switch viewModel.workflowState {
        case .previewLoading, .importing:
            return true
        default:
            return false
        }
    }
}

private struct FileSelectionCard: View {
    let importedFile: ImportedTextFile

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text(importedFile.filename)
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(ByteCountFormatter.string(fromByteCount: Int64(importedFile.byteCount), countStyle: .file))
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct ImportStatusCard: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text(title)
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

private struct ImportLoadingCard: View {
    let title: String

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            ProgressView()
                .tint(FragmentaColor.textPrimary)

            Text(title)
                .font(FragmentaTypography.subheadline)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurfaceStyle()
    }
}

private struct ImportPreviewCard: View {
    let preview: ImportPreview

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            Text("Preview summary")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            ImportSummaryGrid(summary: preview.summary)

            if preview.detectedBooks.isEmpty == false {
                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    Text("Detected books")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)

                    ForEach(preview.detectedBooks) { book in
                        HStack {
                            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                                Text(book.title)
                                    .font(FragmentaTypography.bodyEmphasized)
                                    .foregroundStyle(FragmentaColor.textPrimary)

                                Text(book.author.flatMap { $0.isBlank ? nil : $0 } ?? "Unknown author")
                                    .font(FragmentaTypography.metadata)
                                    .foregroundStyle(FragmentaColor.textSecondary)
                            }

                            Spacer()

                            Text("\(book.highlightsDetected) highlights")
                                .font(FragmentaTypography.metadata)
                                .foregroundStyle(FragmentaColor.textSecondary)
                        }
                        .insetSurfaceStyle()
                    }
                }
            }

            if preview.summary.warnings.isEmpty == false {
                VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                    Text("Warnings")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)

                    ForEach(preview.summary.warnings, id: \.self) { warning in
                        Text(warning)
                            .font(FragmentaTypography.body)
                            .foregroundStyle(FragmentaColor.textSecondary)
                            .insetSurfaceStyle()
                    }
                }
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct ImportResultCard: View {
    let response: ImportResponse

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            Text("Import complete")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            ImportSummaryGrid(summary: response.summary)

            Text(response.message ?? response.summaryLine)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
        }
        .sectionSurfaceStyle()
    }
}

private struct ImportSummaryGrid: View {
    let summary: ImportSummary

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            metric(value: "\(summary.booksDetected)", label: "books")
            metric(value: "\(summary.highlightsDetected)", label: "highlights")
            metric(value: "\(summary.notesDetected)", label: "notes")
            metric(value: "\(summary.duplicatesDetected)", label: "duplicates")
            metric(value: "\(summary.resolvedWarningsCount)", label: "warnings")
        }
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
            Text(value)
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct ImportHistoryRow: View {
    let record: ImportRecord

    var body: some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.medium) {
            VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                Text(record.filename ?? "Kindle import")
                    .font(FragmentaTypography.bodyEmphasized)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(record.summaryLine)
                    .font(FragmentaTypography.metadata)
                    .foregroundStyle(FragmentaColor.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: FragmentaSpacing.xSmall) {
                Text(record.status.rawValue.capitalized)
                    .font(FragmentaTypography.caption)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .chipSurfaceStyle()

                if let createdAt = record.createdAt {
                    Text(createdAt.fragmentaDayMonthYearString())
                        .font(FragmentaTypography.caption)
                        .foregroundStyle(FragmentaColor.textTertiary)
                }
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct ImportRecordDetailSheet: View {
    let record: ImportRecord

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Import",
                        title: record.filename ?? "Import detail",
                        subtitle: record.message ?? record.summaryLine
                    )

                    ImportSummaryGrid(summary: record.summary)

                    if record.summary.warnings.isEmpty == false {
                        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                            Text("Warnings")
                                .font(FragmentaTypography.sectionTitle)
                                .foregroundStyle(FragmentaColor.textPrimary)

                            ForEach(record.summary.warnings, id: \.self) { warning in
                                Text(warning)
                                    .font(FragmentaTypography.body)
                                    .foregroundStyle(FragmentaColor.textSecondary)
                                    .insetSurfaceStyle()
                            }
                        }
                    }
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.vertical, FragmentaSpacing.large)
            }
        }
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ImportView(importService: PreviewImportService())
        }
    }
}
#endif
