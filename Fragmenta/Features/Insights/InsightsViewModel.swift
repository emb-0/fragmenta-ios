import Foundation

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<ReadingInsights> = .idle

    private let insightsService: InsightsServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(insightsService: InsightsServiceProtocol) {
        self.insightsService = insightsService
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        if case .idle = state {
            load()
        }
    }

    func refresh() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        let cachedInsights = await insightsService.loadCachedInsights()
        state = .loading(previous: state.value ?? cachedInsights)

        do {
            let insights = try await insightsService.fetchInsights()
            state = .loaded(insights, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previous = state.value ?? cachedInsights {
                state = .failed(message, previous: previous)
            } else {
                state = .failed(message)
            }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Reading insights are temporarily unavailable."
    }
}
