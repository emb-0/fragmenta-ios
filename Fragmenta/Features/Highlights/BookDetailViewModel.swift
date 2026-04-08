import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<BookDetail> = .idle

    private let bookID: String
    private let booksService: BooksServiceProtocol

    init(bookID: String, booksService: BooksServiceProtocol) {
        self.bookID = bookID
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
            state = .loaded(try await booksService.fetchBookDetail(bookID: bookID))
        } catch {
            state = .failed(Self.errorMessage(for: error))
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Unable to load this book right now."
    }
}
