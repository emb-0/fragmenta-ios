import Combine
import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Book]> = .idle
    @Published private(set) var query = LibraryQuery()

    private let booksService: BooksServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(booksService: BooksServiceProtocol) {
        self.booksService = booksService
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

        if let previousBooks {
            state = .loading(previous: previousBooks)
        } else {
            state = .loading()
        }

        do {
            let books = try await booksService.fetchBooks(query: query)
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
}
