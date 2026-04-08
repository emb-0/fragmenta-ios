import Foundation

struct APIEndpoint<Response: Decodable & Sendable>: Sendable {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: AnyEncodable?
    let unwrapEnvelope: Bool

    init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: AnyEncodable? = nil,
        unwrapEnvelope: Bool = true
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.unwrapEnvelope = unwrapEnvelope
    }
}

extension APIEndpoint where Response == PaginatedResponse<Book> {
    static func books(query: LibraryQuery, page: PageRequest = PageRequest(page: 1, limit: 100)) -> APIEndpoint<PaginatedResponse<Book>> {
        APIEndpoint(
            path: "/api/books",
            queryItems: [
                URLQueryItem(name: "sort", value: query.sort.rawValue),
                URLQueryItem(name: "source", value: query.source == .all ? nil : query.source.rawValue),
                URLQueryItem(name: "recent_only", value: query.recentOnly ? "true" : nil),
                URLQueryItem(name: "has_notes", value: query.hasNotesOnly ? "true" : nil),
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ].compactMap { $0.value == nil ? nil : $0 }
        )
    }
}

extension APIEndpoint where Response == BookMetadataPayload {
    static func book(id: String) -> APIEndpoint<BookMetadataPayload> {
        APIEndpoint(path: "/api/books/\(id)")
    }
}

extension APIEndpoint where Response == PaginatedResponse<Highlight> {
    static func highlights(bookID: String, page: PageRequest) -> APIEndpoint<PaginatedResponse<Highlight>> {
        APIEndpoint(
            path: "/api/books/\(bookID)/highlights",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ]
        )
    }
}

extension APIEndpoint where Response == Highlight {
    static func highlight(id: String) -> APIEndpoint<Highlight> {
        APIEndpoint(path: "/api/highlights/\(id)")
    }
}

extension APIEndpoint where Response == PaginatedResponse<HighlightSearchResult> {
    static func search(query: SearchQuery, page: PageRequest) -> APIEndpoint<PaginatedResponse<HighlightSearchResult>> {
        APIEndpoint(
            path: "/api/search",
            queryItems: [
                URLQueryItem(name: "q", value: query.trimmedText),
                URLQueryItem(name: "book_id", value: query.bookID),
                URLQueryItem(name: "author", value: query.author.isBlank ? nil : query.author.trimmed),
                URLQueryItem(name: "has_notes", value: query.hasNotesOnly ? "true" : nil),
                URLQueryItem(name: "mode", value: query.mode == .semantic ? query.mode.rawValue : nil),
                URLQueryItem(name: "sort", value: query.sort.rawValue),
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ].compactMap { $0.value == nil ? nil : $0 }
        )
    }
}

extension APIEndpoint where Response == ImportPreview {
    static func kindleImportPreview(request: ImportRequest) -> APIEndpoint<ImportPreview> {
        APIEndpoint(
            path: "/api/imports/kindle/preview",
            method: .post,
            headers: [
                "Content-Type": "application/json"
            ],
            body: AnyEncodable(request)
        )
    }
}

extension APIEndpoint where Response == ImportResponse {
    static func kindleImport(request: ImportRequest) -> APIEndpoint<ImportResponse> {
        APIEndpoint(
            path: "/api/imports/kindle",
            method: .post,
            headers: [
                "Content-Type": "application/json"
            ],
            body: AnyEncodable(request)
        )
    }
}

extension APIEndpoint where Response == PaginatedResponse<ImportRecord> {
    static func imports(page: PageRequest) -> APIEndpoint<PaginatedResponse<ImportRecord>> {
        APIEndpoint(
            path: "/api/imports",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ]
        )
    }
}

extension APIEndpoint where Response == ImportRecord {
    static func importRecord(id: String) -> APIEndpoint<ImportRecord> {
        APIEndpoint(path: "/api/imports/\(id)")
    }
}

extension APIEndpoint where Response == ReadingInsights {
    static func readingInsights() -> APIEndpoint<ReadingInsights> {
        APIEndpoint(path: "/api/insights/reading")
    }
}

extension APIEndpoint where Response == PaginatedResponse<Collection> {
    static func collections(page: PageRequest = PageRequest(page: 1, limit: 50)) -> APIEndpoint<PaginatedResponse<Collection>> {
        APIEndpoint(
            path: "/api/collections",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ]
        )
    }

    static func collections(bookID: String, page: PageRequest = PageRequest(page: 1, limit: 50)) -> APIEndpoint<PaginatedResponse<Collection>> {
        APIEndpoint(
            path: "/api/books/\(bookID)/collections",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ]
        )
    }
}

extension APIEndpoint where Response == CollectionDetail {
    static func collection(id: String) -> APIEndpoint<CollectionDetail> {
        APIEndpoint(path: "/api/collections/\(id)")
    }
}

extension APIEndpoint where Response == EmptyAPIResponse {
    static func addBook(toCollection collectionID: String, bookID: String) -> APIEndpoint<EmptyAPIResponse> {
        APIEndpoint(
            path: "/api/collections/\(collectionID)/books",
            method: .post,
            queryItems: [],
            headers: [
                "Content-Type": "application/json"
            ],
            body: AnyEncodable(CollectionBookMutationRequest(bookID: bookID)),
            unwrapEnvelope: false
        )
    }

    static func removeBook(fromCollection collectionID: String, bookID: String) -> APIEndpoint<EmptyAPIResponse> {
        APIEndpoint(
            path: "/api/collections/\(collectionID)/books/\(bookID)",
            method: .delete,
            unwrapEnvelope: false
        )
    }
}

extension APIEndpoint where Response == BookSummaryPayload {
    static func bookSummary(id: String) -> APIEndpoint<BookSummaryPayload> {
        APIEndpoint(path: "/api/books/\(id)/summary")
    }
}

extension APIEndpoint where Response == PaginatedResponse<BookDiscovery.RelatedHighlight> {
    static func relatedHighlights(bookID: String, page: PageRequest = PageRequest(page: 1, limit: 8)) -> APIEndpoint<PaginatedResponse<BookDiscovery.RelatedHighlight>> {
        APIEndpoint(
            path: "/api/books/\(bookID)/related-highlights",
            queryItems: [
                URLQueryItem(name: "page", value: "\(page.page)"),
                URLQueryItem(name: "limit", value: "\(page.limit)")
            ]
        )
    }
}

private struct CollectionBookMutationRequest: Encodable, Sendable {
    let bookID: String
}
