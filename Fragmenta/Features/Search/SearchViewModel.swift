import Combine
import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[HighlightSearchResult]> = .idle
    @Published private(set) var query = SearchQuery()
    @Published private(set) var recentSearches: [String] = []
    @Published private(set) var availableBooks: [Book] = []
    @Published private(set) var pageInfo = PageInfo.singlePage(itemCount: 0, limit: 20)
    @Published private(set) var isLoadingMore = false

    private let searchService: SearchServiceProtocol
    private let booksService: BooksServiceProtocol
    private var searchTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?
    private var booksTask: Task<Void, Never>?

    init(
        searchService: SearchServiceProtocol,
        booksService: BooksServiceProtocol
    ) {
        self.searchService = searchService
        self.booksService = booksService
        self.recentSearches = searchService.recentSearches(limit: 8)
    }

    deinit {
        searchTask?.cancel()
        loadMoreTask?.cancel()
        booksTask?.cancel()
    }

    func loadIfNeeded() {
        if availableBooks.isEmpty {
            loadAvailableBooks()
        }

        recentSearches = searchService.recentSearches(limit: 8)
    }

    func setQueryText(_ text: String) {
        query.text = text
        scheduleSearch()
    }

    func setAuthorFilter(_ author: String) {
        query.author = author
        scheduleSearch()
    }

    func setSort(_ sort: SearchQuery.Sort) {
        query.sort = sort
        scheduleSearch(immediate: true)
    }

    func toggleNotesOnly() {
        query.hasNotesOnly.toggle()
        scheduleSearch(immediate: true)
    }

    func selectBook(_ book: Book?) {
        query.bookID = book?.id
        scheduleSearch(immediate: true)
    }

    func applyRecentSearch(_ text: String) {
        query.text = text
        scheduleSearch(immediate: true)
    }

    func clearRecentSearches() {
        searchService.clearRecentSearches()
        recentSearches = []
    }

    func retryCurrentSearch() {
        scheduleSearch(immediate: true)
    }

    func loadMoreIfNeeded(currentResult: HighlightSearchResult) {
        guard
            let results = state.value,
            results.last?.id == currentResult.id,
            pageInfo.hasMore,
            isLoadingMore == false
        else {
            return
        }

        loadMoreTask?.cancel()
        loadMoreTask = Task { [weak self] in
            await self?.performLoadMore()
        }
    }

    private func loadAvailableBooks() {
        booksTask?.cancel()
        booksTask = Task { [weak self] in
            await self?.performLoadAvailableBooks()
        }
    }

    private func scheduleSearch(immediate: Bool = false) {
        searchTask?.cancel()

        guard query.trimmedText.isEmpty == false || query.hasActiveFilters else {
            state = .idle
            pageInfo = .singlePage(itemCount: 0, limit: query.pageSize)
            return
        }

        state = .loading(previous: state.value)

        searchTask = Task { [weak self] in
            guard let self else { return }
            if immediate == false {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            guard Task.isCancelled == false else { return }
            await self.performSearch()
        }
    }

    private func performSearch() async {
        do {
            let response = try await searchService.searchHighlights(
                query: query,
                page: PageRequest(page: 1, limit: query.pageSize)
            )
            state = .loaded(response.items, source: .remote)
            pageInfo = response.pageInfo
            recentSearches = searchService.recentSearches(limit: 8)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previousResults = state.value, previousResults.isEmpty == false {
                state = .failed(message, previous: previousResults)
            } else {
                state = .failed(message)
            }
        }
    }

    private func performLoadMore() async {
        guard pageInfo.hasMore else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = pageInfo.nextPage ?? (pageInfo.page + 1)
            let response = try await searchService.searchHighlights(
                query: query,
                page: PageRequest(page: nextPage, limit: query.pageSize)
            )

            let mergedResults = mergeResults(existing: state.value ?? [], incoming: response.items)
            state = .loaded(mergedResults, source: .remote)
            pageInfo = response.pageInfo
        } catch is CancellationError {
            return
        } catch {
            if let existingResults = state.value {
                state = .failed(Self.errorMessage(for: error), previous: existingResults)
            } else {
                state = .failed(Self.errorMessage(for: error))
            }
        }
    }

    private func mergeResults(
        existing: [HighlightSearchResult],
        incoming: [HighlightSearchResult]
    ) -> [HighlightSearchResult] {
        var seen = Set(existing.map(\.id))
        var merged = existing

        for result in incoming where seen.insert(result.id).inserted {
            merged.append(result)
        }

        return merged
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Search is temporarily unavailable."
    }

    private func performLoadAvailableBooks() async {
        if let cached = await booksService.loadCachedBooks(query: LibraryQuery()) {
            availableBooks = cached
        }

        do {
            availableBooks = try await booksService.fetchBooks(query: LibraryQuery())
        } catch {
            if availableBooks.isEmpty {
                availableBooks = []
            }
        }
    }
}
