import Foundation

protocol RequestHeadersProviding: Sendable {
    func headers(for path: String) async -> [String: String]
}

struct PublicRequestHeadersProvider: RequestHeadersProviding {
    func headers(for path: String) async -> [String: String] {
        [
            "X-Fragmenta-Platform": "ios",
            "X-Fragmenta-Client": "fragmenta-ios-sprint1"
        ]
    }
}
