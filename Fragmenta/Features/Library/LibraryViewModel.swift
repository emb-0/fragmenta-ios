import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Book]> = .idle

    private let booksService: BooksServiceProtocol

    init(booksService: BooksServiceProtocol) {
        self.booksService = booksService
    }

    func loadIfNeeded() async {
        if case .idle = state {
            await load()
        }
    }

    func refresh() async {
        await load()
    }

    private func load() async {
        if state.isLoading {
            return
        }

        state = .loading

        do {
            state = .loaded(try await booksService.fetchBooks())
        } catch {
            state = .failed(Self.errorMessage(for: error))
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Unable to load the library right now."
    }
}
