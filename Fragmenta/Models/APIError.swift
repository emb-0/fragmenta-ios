import Foundation

struct APIEnvelope<Value: Decodable & Sendable>: Decodable, Sendable {
    let data: Value
}

struct APIErrorEnvelope: Decodable, Sendable {
    let error: APIError
}

struct APIError: Error, Codable, Hashable, LocalizedError, Sendable {
    let code: String
    let message: String
    let details: String?
    let requestID: String?
    let statusCode: Int?

    var errorDescription: String? {
        message
    }

    static func transport(statusCode: Int, message: String, requestID: String? = nil) -> APIError {
        APIError(
            code: "transport_error",
            message: message,
            details: nil,
            requestID: requestID,
            statusCode: statusCode
        )
    }

    static func decoding(_ error: Error) -> APIError {
        APIError(
            code: "decoding_error",
            message: "Unable to decode response from fragmenta-core.",
            details: error.localizedDescription,
            requestID: nil,
            statusCode: nil
        )
    }

    static func invalidURL(_ path: String) -> APIError {
        APIError(
            code: "invalid_url",
            message: "Unable to build a request URL for \(path).",
            details: nil,
            requestID: nil,
            statusCode: nil
        )
    }
}
