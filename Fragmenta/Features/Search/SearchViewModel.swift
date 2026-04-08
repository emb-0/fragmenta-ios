import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var state: LoadableState<[HighlightSearchResult]> = .idle

    private let searchService: SearchServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(searchService: SearchServiceProtocol) {
        self.searchService = searchService
    }

    func queryDidChange() {
        let trimmedQuery = query.trimmed
        searchTask?.cancel()

        guard trimmedQuery.isEmpty == false else {
            state = .idle
            return
        }

        state = .loading
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard Task.isCancelled == false else { return }
            await self?.performSearch(for: trimmedQuery)
        }
    }

    deinit {
        searchTask?.cancel()
    }

    private func performSearch(for query: String) async {
        do {
            state = .loaded(try await searchService.searchHighlights(query: query))
        } catch {
            state = .failed(Self.errorMessage(for: error))
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Search is temporarily unavailable."
    }
}
