import SwiftUI

struct ImportView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: ImportViewModel
    @State private var lastAppliedIncomingDraftID: UUID?

    init(importService: ImportServiceProtocol) {
        _viewModel = StateObject(wrappedValue: ImportViewModel(importService: importService))
    }

    var body: some View {
        FragmentaScreenBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xxLarge) {
                    FragmentaSectionHeader(
                        eyebrow: "Import",
                        title: "Bring in a Kindle export",
                        subtitle: "Preview the backend parse before committing, whether the source arrives from pasted text or a `.txt` document."
                    )

                    if let pendingIncomingImportErrorMessage = appState.pendingIncomingImportErrorMessage {
                        IncomingImportIssueCard(
                            message: pendingIncomingImportErrorMessage,
                            dismissAction: {
                                appState.dismissPendingIncomingImportError()
                            }
                        )
                    }

                    sourceModePicker
                    importSourceCard
                    workflowCard
                    importHistorySection
                }
                .padding(.horizontal, FragmentaSpacing.large)
                .padding(.top, FragmentaSpacing.large)
                .padding(.bottom, FragmentaSpacing.xxxLarge)
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
            applyPendingIncomingDraftIfNeeded()
        }
        .onChange(of: appState.pendingIncomingImportDraft?.id, initial: false) { _, _ in
            applyPendingIncomingDraftIfNeeded()
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
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Source")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: FragmentaSpacing.small) {
                    sourceModeButtons
                }

                VStack(spacing: FragmentaSpacing.small) {
                    sourceModeButtons
                }
            }
        }
        .sectionSurfaceStyle()
    }

    private var importSourceCard: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            HStack {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                    Text(sourceCardTitle)
                        .font(FragmentaTypography.sectionTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text(sourceCardSubtitle)
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

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

            if let importedFile = viewModel.importedFile, importedFile.source != .pastedText {
                IncomingDraftStatusRow(importedFile: importedFile)
            }

            ImportDraftStats(
                rawText: viewModel.rawText,
                sourceMode: viewModel.sourceMode,
                sourceLabel: viewModel.intakeSourceSummary
            )

            ZStack(alignment: .topLeading) {
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
                    .frame(minHeight: 320)
                    .padding(FragmentaSpacing.small)
                    .background(Color.clear)
            }
            .padding(FragmentaSpacing.small)
            .editorSurfaceStyle()
        }
        .sectionSurfaceStyle()
    }

    @ViewBuilder
    private var workflowCard: some View {
        switch viewModel.workflowState {
        case .idle:
            ImportStatusCard(
                title: "Ready for preview",
                message: "Fragmenta previews the backend parse first, then confirms the import with a second request so the flow feels trustworthy."
            )

        case .editing:
            ImportStatusCard(
                title: "Draft prepared",
                message: "Preview the import to inspect detected books, highlights, notes, duplicates, and warnings before committing."
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
                VStack(alignment: .leading, spacing: FragmentaSpacing.tiny) {
                    Text("Recent imports")
                        .font(FragmentaTypography.sectionTitle)
                        .foregroundStyle(FragmentaColor.textPrimary)

                    Text("Inspect prior sessions without leaving the app shell.")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textSecondary)
                }

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
        ViewThatFits(in: .horizontal) {
            HStack(spacing: FragmentaSpacing.medium) {
                secondaryActionButton
                primaryActionButton
            }

            VStack(spacing: FragmentaSpacing.small) {
                primaryActionButton
                secondaryActionButton
            }
        }
        .padding(.horizontal, FragmentaSpacing.small)
        .padding(.vertical, FragmentaSpacing.small)
        .floatingBarStyle()
        .padding(.horizontal, FragmentaSpacing.large)
        .padding(.bottom, FragmentaSpacing.xSmall)
        .background(Color.clear)
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
            if let importedFile = viewModel.importedFile, importedFile.source != .pastedText {
                return "Preview Incoming Import"
            }

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

    private func iconName(for sourceMode: ImportViewModel.SourceMode) -> String {
        switch sourceMode {
        case .paste:
            return "doc.text"
        case .file:
            return "folder"
        }
    }

    private var sourceCardTitle: String {
        if let importedFile = viewModel.importedFile, importedFile.source == .shareExtension {
            return "Incoming shared text"
        }

        return viewModel.sourceMode == .paste ? "Paste the manuscript" : "Selected document"
    }

    private var sourceCardSubtitle: String {
        if let importedFile = viewModel.importedFile {
            switch importedFile.source {
            case .shareExtension:
                return "Shared text is staged here first, so you can preview the parse before sending anything to fragmenta-core."
            case .documentPicker, .filesApp:
                return "Review the imported text before it reaches the backend, then preview the parse and confirm the commit."
            case .pastedText:
                return "Paste the full Kindle export, then preview before import."
            }
        }

        return viewModel.sourceMode == .paste
            ? "Paste the full Kindle export, then preview before import."
            : "Choose a `.txt` file and review the imported text before it reaches the backend."
    }

    private func applyPendingIncomingDraftIfNeeded() {
        guard let pendingDraft = appState.pendingIncomingImportDraft else {
            return
        }

        guard pendingDraft.id != lastAppliedIncomingDraftID else {
            return
        }

        viewModel.applyIncomingDraft(pendingDraft)
        lastAppliedIncomingDraftID = pendingDraft.id
        appState.consumePendingIncomingImportDraft()
    }

    private var sourceModeButtons: some View {
        ForEach(ImportViewModel.SourceMode.allCases) { sourceMode in
            Button {
                viewModel.selectSourceMode(sourceMode)
            } label: {
                VStack(alignment: .leading, spacing: FragmentaSpacing.xSmall) {
                    Image(systemName: iconName(for: sourceMode))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.sourceMode == sourceMode ? FragmentaColor.textPrimary : FragmentaColor.textTertiary)

                    Text(sourceMode.title)
                        .font(FragmentaTypography.bodyEmphasized)
                        .foregroundStyle(viewModel.sourceMode == sourceMode ? FragmentaColor.textPrimary : FragmentaColor.textSecondary)

                    Text(sourceMode == .paste ? "Paste a raw export directly." : "Read a `.txt` file from Files.")
                        .font(FragmentaTypography.metadata)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(FragmentaSpacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                        .fill(viewModel.sourceMode == sourceMode ? FragmentaColor.surfaceQuaternary.opacity(0.75) : FragmentaColor.surfaceTertiary.opacity(0.58))
                        .overlay(
                            RoundedRectangle(cornerRadius: FragmentaRadius.medium, style: .continuous)
                                .stroke(viewModel.sourceMode == sourceMode ? FragmentaColor.accent.opacity(0.22) : Color.white.opacity(0.04), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var secondaryActionButton: some View {
        Group {
            if viewModel.sourceMode == .file {
                Button("Choose File") {
                    viewModel.presentDocumentPicker()
                }
            } else {
                Button("Clear") {
                    viewModel.reset()
                }
            }
        }
        .fragmentaAdaptiveGlassButton()
    }

    private var primaryActionButton: some View {
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
}

private struct ImportDraftStats: View {
    let rawText: String
    let sourceMode: ImportViewModel.SourceMode
    let sourceLabel: String?

    private var lineCount: Int {
        rawText.isBlank ? 0 : rawText.components(separatedBy: .newlines).count
    }

    private var characterCount: Int {
        rawText.count
    }

    var body: some View {
        HStack(spacing: FragmentaSpacing.medium) {
            stat(value: sourceLabel ?? sourceMode.title, label: "source")
            stat(value: "\(lineCount)", label: "lines")
            stat(value: "\(characterCount)", label: "characters")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.tiny) {
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

private struct FileSelectionCard: View {
    let importedFile: ImportedTextFile

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text(importedFile.filename)
                .font(FragmentaTypography.bodyEmphasized)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text("\(importedFile.source.title) · \(ByteCountFormatter.string(fromByteCount: Int64(importedFile.byteCount), countStyle: .file))")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)

            Text(importedFile.receivedAt.fragmentaDayMonthYearString())
                .font(FragmentaTypography.caption)
                .foregroundStyle(FragmentaColor.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct IncomingDraftStatusRow: View {
    let importedFile: ImportedTextFile

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            Image(systemName: "arrow.down.doc")
                .foregroundStyle(FragmentaColor.accentSoft)

            Text("Incoming \(importedFile.source.title.lowercased()) is staged locally first, then previewed before the backend commit.")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetSurfaceStyle()
    }
}

private struct IncomingImportIssueCard: View {
    let message: String
    let dismissAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.medium) {
            Text("Incoming file issue")
                .font(FragmentaTypography.sectionTitle)
                .foregroundStyle(FragmentaColor.textPrimary)

            Text(message)
                .font(FragmentaTypography.body)
                .foregroundStyle(FragmentaColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Dismiss") {
                dismissAction()
            }
            .fragmentaAdaptiveGlassButton()
        }
        .sectionSurfaceStyle()
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
                .fixedSize(horizontal: false, vertical: true)
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
            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                Text("Preview summary")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(preview.message ?? "Fragmenta will send a second commit request only after you confirm this preview.")
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ImportSummaryGrid(summary: preview.summary)
            ImportPreviewSignals(summary: preview.summary)

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
                WarningSection(warnings: preview.summary.warnings)
            }
        }
        .sectionSurfaceStyle()
    }
}

private struct ImportResultCard: View {
    let response: ImportResponse

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.large) {
            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                Text(response.status == .failed ? "Import issue" : "Import complete")
                    .font(FragmentaTypography.sectionTitle)
                    .foregroundStyle(FragmentaColor.textPrimary)

                Text(response.message ?? response.summaryLine)
                    .font(FragmentaTypography.body)
                    .foregroundStyle(FragmentaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ImportSummaryGrid(summary: response.summary)
            ImportPreviewSignals(summary: response.summary)

            VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
                if let filename = response.filename, filename.isBlank == false {
                    resultMetadataRow(label: "Source", value: filename)
                }

                resultMetadataRow(label: "Status", value: response.status.rawValue.capitalized)

                if let completedAt = response.completedAt ?? response.createdAt {
                    resultMetadataRow(label: "Updated", value: completedAt.fragmentaDayMonthYearString())
                }
            }
        }
        .sectionSurfaceStyle()
    }

    private func resultMetadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: FragmentaSpacing.small) {
            Text(label.uppercased())
                .font(FragmentaTypography.eyebrow)
                .foregroundStyle(FragmentaColor.textTertiary)
                .tracking(1.2)

            Spacer()

            Text(value)
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .insetSurfaceStyle()
    }
}

private struct ImportSummaryGrid: View {
    let summary: ImportSummary

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: FragmentaSpacing.medium)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: FragmentaSpacing.medium) {
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

private struct WarningSection: View {
    let warnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: FragmentaSpacing.small) {
            Text("Warnings")
                .font(FragmentaTypography.metadata)
                .foregroundStyle(FragmentaColor.textSecondary)

            ForEach(warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: FragmentaSpacing.small) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(FragmentaColor.warning)
                        .padding(.top, 2)

                    Text(warning)
                        .font(FragmentaTypography.body)
                        .foregroundStyle(FragmentaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .insetSurfaceStyle()
            }
        }
    }
}

private struct ImportPreviewSignals: View {
    let summary: ImportSummary

    var body: some View {
        HStack(spacing: FragmentaSpacing.small) {
            if summary.duplicatesDetected > 0 {
                signal("Duplicates detected", color: FragmentaColor.warning)
            }

            if summary.resolvedWarningsCount > 0 {
                signal("\(summary.resolvedWarningsCount) warnings", color: FragmentaColor.warning)
            }

            if summary.duplicatesDetected == 0, summary.resolvedWarningsCount == 0 {
                signal("No obvious conflicts", color: FragmentaColor.accentSoft)
            }

            Spacer()
        }
    }

    private func signal(_ title: String, color: Color) -> some View {
        Text(title)
            .font(FragmentaTypography.chip)
            .foregroundStyle(color)
            .chipSurfaceStyle()
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

                if let source = record.source, source.isBlank == false {
                    Text(source.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(FragmentaTypography.chip)
                        .foregroundStyle(FragmentaColor.textTertiary)
                        .chipSurfaceStyle()
                }
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
                        WarningSection(warnings: record.summary.warnings)
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
        .environmentObject(AppState(container: .preview))
    }
}
#endif
