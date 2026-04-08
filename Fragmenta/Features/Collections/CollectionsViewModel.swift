import Foundation

@MainActor
final class CollectionsViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Collection]> = .idle

    private let collectionsService: CollectionsServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(collectionsService: CollectionsServiceProtocol) {
        self.collectionsService = collectionsService
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
        let cachedCollections = await collectionsService.loadCachedCollections()
        state = .loading(previous: state.value ?? cachedCollections)

        do {
            let response = try await collectionsService.fetchCollections(page: PageRequest(page: 1, limit: 40))
            state = .loaded(response.items, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previous = state.value ?? cachedCollections {
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

        return "Collections are temporarily unavailable."
    }
}

@MainActor
final class CollectionDetailViewModel: ObservableObject {
    @Published private(set) var state: LoadableState<CollectionDetail> = .idle
    @Published private(set) var removingBookIDs = Set<String>()

    private let collectionID: String
    private let collectionsService: CollectionsServiceProtocol
    private var loadTask: Task<Void, Never>?

    init(collectionID: String, collectionsService: CollectionsServiceProtocol) {
        self.collectionID = collectionID
        self.collectionsService = collectionsService
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        if case .idle = state {
            refresh()
        }
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    func remove(_ book: Book) {
        guard removingBookIDs.contains(book.id) == false else {
            return
        }

        removingBookIDs.insert(book.id)

        Task { [weak self] in
            guard let self else { return }
            defer { removingBookIDs.remove(book.id) }

            do {
                try await collectionsService.removeBook(book.id, fromCollection: collectionID)
                await performLoad()
            } catch {}
        }
    }

    private func performLoad() async {
        let cachedDetail = await collectionsService.loadCachedCollectionDetail(id: collectionID)
        state = .loading(previous: state.value ?? cachedDetail)

        do {
            let detail = try await collectionsService.fetchCollectionDetail(id: collectionID)
            state = .loaded(detail, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previous = state.value ?? cachedDetail {
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

        return "This collection is temporarily unavailable."
    }
}

@MainActor
final class BookCollectionsSheetModel: ObservableObject {
    @Published private(set) var state: LoadableState<[Collection]> = .idle
    @Published private(set) var updatingCollectionIDs = Set<String>()
    @Published private(set) var errorMessage: String?

    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }

    func load(bookID: String, service: CollectionsServiceProtocol) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad(bookID: bookID, service: service)
        }
    }

    func toggleMembership(for collection: Collection, bookID: String, service: CollectionsServiceProtocol) {
        guard updatingCollectionIDs.contains(collection.id) == false else {
            return
        }

        updatingCollectionIDs.insert(collection.id)
        errorMessage = nil

        Task { [weak self] in
            guard let self else { return }
            defer { updatingCollectionIDs.remove(collection.id) }

            do {
                if collection.containsBook == true {
                    try await service.removeBook(bookID, fromCollection: collection.id)
                } else {
                    try await service.addBook(bookID, toCollection: collection.id)
                }

                await performLoad(bookID: bookID, service: service)
            } catch {
                errorMessage = Self.errorMessage(for: error)
            }
        }
    }

    private func performLoad(bookID: String, service: CollectionsServiceProtocol) async {
        let cachedCollections = await service.loadCachedCollections(forBookID: bookID)
        state = .loading(previous: state.value ?? cachedCollections)

        do {
            let response = try await service.fetchCollections(forBookID: bookID, page: PageRequest(page: 1, limit: 50))
            state = .loaded(response.items, source: .remote)
        } catch is CancellationError {
            return
        } catch {
            let message = Self.errorMessage(for: error)
            if let previous = state.value ?? cachedCollections {
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

        return "Collection membership is temporarily unavailable."
    }
}
