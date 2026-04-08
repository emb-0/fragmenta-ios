import Foundation

@MainActor
final class ImportViewModel: ObservableObject {
    enum WorkflowState: Equatable {
        case idle
        case editing
        case importing
        case success(ImportResponse)
        case failure(String)
    }

    @Published var rawText = "" {
        didSet {
            syncDraftState()
        }
    }
    @Published private(set) var state: WorkflowState = .idle

    private let highlightService: HighlightServiceProtocol
    private var lastSubmittedDraft: String?

    init(highlightService: HighlightServiceProtocol) {
        self.highlightService = highlightService
    }

    func submit() async {
        let trimmed = rawText.trimmed

        guard trimmed.isEmpty == false else {
            state = .failure("Paste Kindle export text before importing.")
            return
        }

        state = .importing
        lastSubmittedDraft = trimmed

        do {
            state = .success(
                try await highlightService.importKindleHighlights(
                    rawText: trimmed,
                    filename: "kindle-highlights.txt"
                )
            )
        } catch {
            if let apiError = error as? APIError {
                state = .failure(apiError.message)
            } else {
                state = .failure("The import request could not be completed.")
            }
        }
    }

    func reset() {
        lastSubmittedDraft = nil
        rawText = ""
        state = .idle
    }

    private func syncDraftState() {
        let trimmed = rawText.trimmed

        if case .importing = state {
            return
        }

        if trimmed.isEmpty {
            state = .idle
            return
        }

        if lastSubmittedDraft == trimmed, case .success = state {
            return
        }

        if lastSubmittedDraft == trimmed, case .failure = state {
            return
        }

        state = .editing
    }
}
