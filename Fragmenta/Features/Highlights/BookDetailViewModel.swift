import Combine
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published private(set) var detailState: LoadableState<BookDetail> = .idle
    @Published private(set) var highlightsState: LoadableState<[Highlight]> = .idle
    @Published private(set) var pageInfo = PageInfo.singlePage(itemCount: 0, limit: 24)
    @Published private(set) var isLoadingMore = false
    @Published private(set) var focusedHighlightID: String?
    @Published private(set) var loadMoreFailureMessage: String?

    private let bookID: String
    private let focusHighlightID: String?
    private let booksService: BooksServiceProtocol
    private var loadTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?

    init(
        bookID: String,
        focusHighlightID: String? = nil,
        booksService: BooksServiceProtocol
    ) {
        self.bookID = bookID
        self.focusHighlightID = focusHighlightID
        self.booksService = booksService
    }

    deinit {
        loadTask?.cancel()
        loadMoreTask?.cancel()
    }

    func loadIfNeeded() {
        if case .idle = detailState {
            load()
        }
    }

    func refresh() {
        load()
    }

    func retryLoadMore() {
        guard pageInfo.hasMore else {
            return
        }

        loadMoreTask?.cancel()
        loadMoreTask = Task { [weak self] in
            await self?.performLoadMore()
        }
    }

    func focus(highlightID: String) {
        focusedHighlightID = highlightID

        guard highlightsState.value?.contains(where: { $0.id == highlightID }) == false else {
            return
        }

        Task { [weak self] in
            await self?.loadFocusedHighlight(id: highlightID)
        }
    }

    func loadMoreIfNeeded(currentHighlight: Highlight) {
        guard
            let highlights = highlightsState.value,
            highlights.last?.id == currentHighlight.id,
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

    private func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performInitialLoad()
        }
    }

    private func performInitialLoad() async {
        let cachedDetail = await booksService.loadCachedBookDetail(bookID: bookID)
        let cachedHighlightsPage = await booksService.loadCachedHighlights(bookID: bookID, page: PageRequest(page: 1, limit: 24))
        loadMoreFailureMessage = nil

        detailState = .loading(previous: detailState.value ?? cachedDetail)
        highlightsState = .loading(previous: highlightsState.value ?? cachedHighlightsPage?.items)

        do {
            async let detail = booksService.fetchBookDetail(bookID: bookID)
            async let highlightsPage = booksService.fetchHighlights(bookID: bookID, page: PageRequest(page: 1, limit: 24))

            let loadedDetail = try await detail
            var firstPage = try await highlightsPage

            if let coverURL = loadedDetail.book.coverURL ?? loadedDetail.book.coverThumbnailURL {
                Task.detached(priority: .utility) {
                    await CoverImagePipeline.shared.prefetch(urls: [coverURL], maxPixelSize: 720)
                }
            }

            if let focusHighlightID {
                let focusedHighlight = try? await booksService.fetchHighlight(id: focusHighlightID)
                let mergedHighlights = mergeHighlights(existing: firstPage.items, inserting: focusedHighlight)
                firstPage = PaginatedResponse(items: mergedHighlights, pageInfo: firstPage.pageInfo)
                self.focusedHighlightID = focusedHighlight?.id ?? focusHighlightID
            } else {
                focusedHighlightID = nil
            }

            detailState = .loaded(loadedDetail, source: .remote)
            highlightsState = .loaded(firstPage.items, source: .remote)
            pageInfo = firstPage.pageInfo
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)

            if let previousDetail = detailState.value ?? cachedDetail {
                detailState = .failed(message, previous: previousDetail)
            } else {
                detailState = .failed(message)
            }

            if let previousHighlights = highlightsState.value ?? cachedHighlightsPage?.items {
                highlightsState = .failed(message, previous: previousHighlights)
                pageInfo = cachedHighlightsPage?.pageInfo ?? .singlePage(itemCount: previousHighlights.count, limit: 24)
            } else {
                highlightsState = .failed(message)
            }
        }
    }

    private func performLoadMore() async {
        guard pageInfo.hasMore else {
            return
        }

        isLoadingMore = true
        loadMoreFailureMessage = nil
        defer { isLoadingMore = false }

        do {
            let nextPage = pageInfo.nextPage ?? (pageInfo.page + 1)
            let response = try await booksService.fetchHighlights(
                bookID: bookID,
                page: PageRequest(page: nextPage, limit: pageInfo.limit)
            )

            let merged = mergeHighlights(existing: highlightsState.value ?? [], inserting: response.items)
            highlightsState = .loaded(merged, source: .remote)
            pageInfo = response.pageInfo
        } catch is CancellationError {
            return
        } catch {
            loadMoreFailureMessage = Self.errorMessage(for: error)
            if let existingHighlights = highlightsState.value {
                highlightsState = .failed(Self.errorMessage(for: error), previous: existingHighlights)
            } else {
                highlightsState = .failed(Self.errorMessage(for: error))
            }
        }
    }

    private func mergeHighlights(existing: [Highlight], inserting incoming: [Highlight]) -> [Highlight] {
        var seen = Set(existing.map(\.id))
        var merged = existing

        for highlight in incoming where seen.insert(highlight.id).inserted {
            merged.append(highlight)
        }

        return merged
    }

    private func mergeHighlights(existing: [Highlight], inserting focusedHighlight: Highlight?) -> [Highlight] {
        guard let focusedHighlight else {
            return existing
        }

        if existing.contains(where: { $0.id == focusedHighlight.id }) {
            return existing
        }

        return [focusedHighlight] + existing
    }

    private func loadFocusedHighlight(id: String) async {
        do {
            let focusedHighlight = try await booksService.fetchHighlight(id: id)
            let merged = mergeHighlights(existing: highlightsState.value ?? [], inserting: focusedHighlight)
            highlightsState = .loaded(merged, source: highlightsState.source ?? .remote)
            focusedHighlightID = focusedHighlight.id
        } catch {
            focusedHighlightID = id
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Unable to load this book right now."
    }
}
