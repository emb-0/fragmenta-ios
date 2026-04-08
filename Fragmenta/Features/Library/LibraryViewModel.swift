import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Book]> = .idle
    @Published private(set) var query = LibraryQuery()
    @Published private(set) var viewMode: LibraryViewMode

    private let booksService: BooksServiceProtocol
    private let preferencesStore: AppPreferencesStore
    private var loadTask: Task<Void, Never>?

    init(
        booksService: BooksServiceProtocol,
        preferencesStore: AppPreferencesStore
    ) {
        self.booksService = booksService
        self.preferencesStore = preferencesStore
        self.viewMode = preferencesStore.libraryViewMode
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

    func setViewMode(_ viewMode: LibraryViewMode) {
        guard self.viewMode != viewMode else {
            return
        }

        self.viewMode = viewMode
        preferencesStore.libraryViewMode = viewMode

        if let books = state.value {
            prefetchCoverImages(for: books)
        }
    }

    func updateSort(_ sort: LibraryQuery.Sort) {
        query.sort = sort
        load()
    }

    func updateSource(_ source: LibraryQuery.SourceFilter) {
        query.source = source
        load()
    }

    func toggleRecentOnly() {
        query.recentOnly.toggle()
        load()
    }

    func toggleHasNotesOnly() {
        query.hasNotesOnly.toggle()
        load()
    }

    private func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        let cachedBooks = await booksService.loadCachedBooks(query: query)
        let previousBooks = state.value ?? cachedBooks

        if let cachedBooks {
            prefetchCoverImages(for: cachedBooks)
        }

        if let previousBooks {
            state = .loading(previous: previousBooks)
        } else {
            state = .loading()
        }

        do {
            let books = try await booksService.fetchBooks(query: query)
            prefetchCoverImages(for: books)
            state = .loaded(books, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            if let previousBooks {
                state = .failed(Self.errorMessage(for: error), previous: previousBooks)
            } else if let cachedBooks {
                state = .loaded(cachedBooks, source: .cache)
            } else {
                state = .failed(Self.errorMessage(for: error))
            }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Unable to load the library right now."
    }

    private func prefetchCoverImages(for books: [Book]) {
        let candidates = books.compactMap { $0.coverThumbnailURL ?? $0.coverURL }
        var seen = Set<URL>()
        let urls = candidates
            .filter { seen.insert($0).inserted }
            .prefix(viewMode == .bookshelf ? 30 : 18)

        guard urls.isEmpty == false else {
            return
        }

        Task.detached(priority: .utility) {
            await CoverImagePipeline.shared.prefetch(urls: Array(urls), maxPixelSize: 420)
        }
    }
}
