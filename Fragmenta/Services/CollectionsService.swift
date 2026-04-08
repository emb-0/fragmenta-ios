import Foundation

protocol CollectionsServiceProtocol {
    func loadCachedCollections() async -> [Collection]?
    func fetchCollections(page: PageRequest) async throws -> PaginatedResponse<Collection>
    func loadCachedCollectionDetail(id: String) async -> CollectionDetail?
    func fetchCollectionDetail(id: String) async throws -> CollectionDetail
    func loadCachedCollections(forBookID bookID: String) async -> [Collection]?
    func fetchCollections(forBookID bookID: String, page: PageRequest) async throws -> PaginatedResponse<Collection>
    func addBook(_ bookID: String, toCollection collectionID: String) async throws
    func removeBook(_ bookID: String, fromCollection collectionID: String) async throws
}

struct CollectionsService: CollectionsServiceProtocol {
    private let apiClient: APIClient
    private let cacheStore: FragmentaCacheStore
    private let diagnosticsStore: DiagnosticsStore

    init(
        apiClient: APIClient,
        cacheStore: FragmentaCacheStore,
        diagnosticsStore: DiagnosticsStore
    ) {
        self.apiClient = apiClient
        self.cacheStore = cacheStore
        self.diagnosticsStore = diagnosticsStore
    }

    func loadCachedCollections() async -> [Collection]? {
        await cacheStore.load([Collection].self, forKey: CacheKey.collections)
    }

    func fetchCollections(page: PageRequest = PageRequest(page: 1, limit: 50)) async throws -> PaginatedResponse<Collection> {
        do {
            let response: PaginatedResponse<Collection> = try await apiClient.request(.collections(page: page))
            if page.page == 1 {
                try await cacheStore.save(response.items, forKey: CacheKey.collections)
            }
            diagnosticsStore.record(
                event: .collections,
                status: .success,
                detail: "Fetched \(response.items.count) collections."
            )
            return response
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .collections,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    func loadCachedCollectionDetail(id: String) async -> CollectionDetail? {
        await cacheStore.load(CollectionDetail.self, forKey: CacheKey.collectionDetail(id))
    }

    func fetchCollectionDetail(id: String) async throws -> CollectionDetail {
        let detail: CollectionDetail = try await apiClient.request(.collection(id: id))
        try await cacheStore.save(detail, forKey: CacheKey.collectionDetail(id))
        return detail
    }

    func loadCachedCollections(forBookID bookID: String) async -> [Collection]? {
        await cacheStore.load([Collection].self, forKey: CacheKey.bookCollections(bookID))
    }

    func fetchCollections(forBookID bookID: String, page: PageRequest = PageRequest(page: 1, limit: 50)) async throws -> PaginatedResponse<Collection> {
        let response: PaginatedResponse<Collection> = try await apiClient.request(.collections(bookID: bookID, page: page))
        if page.page == 1 {
            try await cacheStore.save(response.items, forKey: CacheKey.bookCollections(bookID))
        }
        return response
    }

    func addBook(_ bookID: String, toCollection collectionID: String) async throws {
        do {
            _ = try await apiClient.request(.addBook(toCollection: collectionID, bookID: bookID)) as EmptyAPIResponse
            try await invalidateCaches(bookID: bookID, collectionID: collectionID)
            diagnosticsStore.record(
                event: .collections,
                status: .success,
                detail: "Added book \(bookID) to collection \(collectionID)."
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .collections,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    func removeBook(_ bookID: String, fromCollection collectionID: String) async throws {
        do {
            _ = try await apiClient.request(.removeBook(fromCollection: collectionID, bookID: bookID)) as EmptyAPIResponse
            try await invalidateCaches(bookID: bookID, collectionID: collectionID)
            diagnosticsStore.record(
                event: .collections,
                status: .success,
                detail: "Removed book \(bookID) from collection \(collectionID)."
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            diagnosticsStore.record(
                event: .collections,
                status: .failure,
                detail: Self.errorMessage(for: error)
            )
            throw error
        }
    }

    private func invalidateCaches(bookID: String, collectionID: String) async throws {
        try await cacheStore.removeValue(forKey: CacheKey.collections)
        try await cacheStore.removeValue(forKey: CacheKey.bookCollections(bookID))
        try await cacheStore.removeValue(forKey: CacheKey.collectionDetail(collectionID))
    }

    private static func errorMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.message
        }

        return error.localizedDescription
    }
}

private enum CacheKey {
    static let collections = "collections-list"

    static func collectionDetail(_ id: String) -> String {
        "collection-detail-\(id)"
    }

    static func bookCollections(_ bookID: String) -> String {
        "book-collections-\(bookID)"
    }
}
