import Combine
import Foundation

struct ImportedTextFile: Identifiable, Hashable, Sendable {
    let id = UUID()
    let filename: String
    let rawText: String
    let byteCount: Int
}

@MainActor
final class ImportViewModel: ObservableObject {
    enum SourceMode: String, CaseIterable, Identifiable {
        case paste
        case file

        var id: String { rawValue }

        var title: String {
            switch self {
            case .paste:
                return "Paste"
            case .file:
                return "File"
            }
        }
    }

    enum WorkflowState: Equatable {
        case idle
        case editing
        case previewLoading
        case previewReady(ImportPreview)
        case importing(ImportPreview?)
        case success(ImportResponse)
        case failure(String)
    }

    @Published var sourceMode: SourceMode = .paste
    @Published var rawText = "" {
        didSet {
            syncDraftState()
        }
    }
    @Published private(set) var importedFile: ImportedTextFile?
    @Published private(set) var workflowState: WorkflowState = .idle
    @Published private(set) var historyState: LoadableState<[ImportRecord]> = .idle
    @Published private(set) var selectedHistoryRecord: ImportRecord?
    @Published var isShowingDocumentPicker = false

    private let importService: ImportServiceProtocol
    private var previewTask: Task<Void, Never>?
    private var importTask: Task<Void, Never>?
    private var historyTask: Task<Void, Never>?
    private var inspectTask: Task<Void, Never>?
    private var restoreTask: Task<Void, Never>?

    init(importService: ImportServiceProtocol) {
        self.importService = importService
    }

    deinit {
        previewTask?.cancel()
        importTask?.cancel()
        historyTask?.cancel()
        inspectTask?.cancel()
        restoreTask?.cancel()
    }

    func loadIfNeeded() {
        if case .idle = historyState {
            refreshHistory()
        }

        if case .idle = workflowState {
            restoreTask?.cancel()
            restoreTask = Task { [weak self] in
                await self?.restoreCachedImportStateIfNeeded()
            }
        }
    }

    func selectSourceMode(_ sourceMode: SourceMode) {
        self.sourceMode = sourceMode
    }

    func presentDocumentPicker() {
        isShowingDocumentPicker = true
    }

    func handlePickedDocument(_ url: URL) {
        Task { [weak self] in
            await self?.loadDocument(url)
        }
    }

    func previewImport() {
        let trimmed = rawText.trimmed

        guard trimmed.isEmpty == false else {
            workflowState = .failure("Paste or choose a Kindle export before previewing.")
            return
        }

        previewTask?.cancel()
        previewTask = Task { [weak self] in
            await self?.performPreviewImport(rawText: trimmed)
        }
    }

    func confirmImport() {
        let trimmed = rawText.trimmed

        guard trimmed.isEmpty == false else {
            workflowState = .failure("Paste or choose a Kindle export before importing.")
            return
        }

        let currentPreview = previewState
        importTask?.cancel()
        importTask = Task { [weak self] in
            await self?.performImport(rawText: trimmed, preview: currentPreview)
        }
    }

    func refreshHistory() {
        historyTask?.cancel()
        historyTask = Task { [weak self] in
            await self?.performRefreshHistory()
        }
    }

    func inspectImport(_ record: ImportRecord) {
        inspectTask?.cancel()
        inspectTask = Task { [weak self] in
            await self?.performInspectImport(record)
        }
    }

    func dismissHistoryDetail() {
        selectedHistoryRecord = nil
    }

    func reset() {
        rawText = ""
        importedFile = nil
        workflowState = .idle
    }

    private func loadDocument(_ url: URL) async {
        let didStartSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if didStartSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            guard let rawText = Self.decodeText(from: data) else {
                workflowState = .failure("The selected file could not be decoded as text.")
                return
            }

            importedFile = ImportedTextFile(
                filename: url.lastPathComponent,
                rawText: rawText,
                byteCount: data.count
            )
            sourceMode = .file
            self.rawText = rawText
            workflowState = .editing
        } catch {
            workflowState = .failure("The selected file could not be opened.")
        }
    }

    private func performPreviewImport(rawText: String) async {
        workflowState = .previewLoading

        do {
            let preview = try await importService.previewKindleImport(
                rawText: rawText,
                filename: activeFilename
            )
            workflowState = .previewReady(preview)
        } catch is CancellationError {
            return
        } catch {
            workflowState = .failure(Self.errorMessage(for: error))
        }
    }

    private func performImport(rawText: String, preview: ImportPreview?) async {
        workflowState = .importing(preview)

        do {
            let response = try await importService.importKindleHighlights(
                rawText: rawText,
                filename: activeFilename
            )
            workflowState = .success(response)
            refreshHistory()
        } catch is CancellationError {
            return
        } catch {
            workflowState = .failure(Self.errorMessage(for: error))
        }
    }

    private func performRefreshHistory() async {
        let cachedHistory = await importService.loadCachedImports()
        historyState = .loading(previous: historyState.value ?? cachedHistory)

        do {
            let response = try await importService.fetchImports(page: PageRequest(page: 1, limit: 10))
            historyState = .loaded(response.items, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            if let previous = historyState.value ?? cachedHistory {
                historyState = .failed(Self.errorMessage(for: error), previous: previous)
            } else {
                historyState = .failed(Self.errorMessage(for: error))
            }
        }
    }

    private func performInspectImport(_ record: ImportRecord) async {
        do {
            selectedHistoryRecord = try await importService.fetchImport(id: record.id)
        } catch {
            selectedHistoryRecord = record
        }
    }

    private func restoreCachedImportStateIfNeeded() async {
        guard rawText.trimmed.isEmpty else {
            return
        }

        guard case .idle = workflowState else {
            return
        }

        if let cachedResponse = await importService.loadCachedLastImportResponse() {
            workflowState = .success(cachedResponse)
        }
    }

    private var activeFilename: String? {
        importedFile?.filename ?? "kindle-highlights.txt"
    }

    private var previewState: ImportPreview? {
        if case .previewReady(let preview) = workflowState {
            return preview
        }

        if case .importing(let preview) = workflowState {
            return preview
        }

        return nil
    }

    private func syncDraftState() {
        let trimmed = rawText.trimmed

        if case .previewLoading = workflowState {
            return
        }

        if case .importing = workflowState {
            return
        }

        if trimmed.isEmpty {
            workflowState = .idle
            return
        }

        workflowState = .editing
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "The import flow hit an unexpected problem."
    }

    private static func decodeText(from data: Data) -> String? {
        let candidateEncodings: [String.Encoding] = [.utf8, .utf16, .unicode, .ascii, .windowsCP1252]

        for encoding in candidateEncodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        return nil
    }
}
