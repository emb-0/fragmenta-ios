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

extension APIEndpoint where Response == [Book] {
    static func books() -> APIEndpoint<[Book]> {
        APIEndpoint(path: "/api/books")
    }
}

extension APIEndpoint where Response == BookMetadataPayload {
    static func book(id: String) -> APIEndpoint<BookMetadataPayload> {
        APIEndpoint(path: "/api/books/\(id)")
    }
}

extension APIEndpoint where Response == [Highlight] {
    static func highlights(bookID: String) -> APIEndpoint<[Highlight]> {
        APIEndpoint(path: "/api/books/\(bookID)/highlights")
    }
}

extension APIEndpoint where Response == [HighlightSearchResult] {
    static func search(query: String) -> APIEndpoint<[HighlightSearchResult]> {
        APIEndpoint(
            path: "/api/search",
            queryItems: [
                URLQueryItem(name: "q", value: query)
            ]
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
