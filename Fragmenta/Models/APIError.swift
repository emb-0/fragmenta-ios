import Foundation

struct APIEnvelope<Value: Decodable & Sendable>: Decodable, Sendable {
    let data: Value
}

struct APIErrorEnvelope: Decodable, Sendable {
    let error: APIError

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        if let nestedError = try container.decodeIfPresent(APIError.self, forKey: AnyCodingKey("error")) {
            self.error = nestedError
            return
        }

        if let message = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("error")) {
            self.error = APIError(code: "unknown_error", message: message, details: nil, requestID: nil, statusCode: nil)
            return
        }

        if let message = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("message")) {
            let code = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("code")) ?? "unknown_error"
            let details = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("details"))
            let requestID = try container.decodeIfPresent(String.self, forKey: AnyCodingKey("request_id"))
            let statusCode = try container.decodeIfPresent(Int.self, forKey: AnyCodingKey("status_code"))
            self.error = APIError(code: code, message: message, details: details, requestID: requestID, statusCode: statusCode)
            return
        }

        self.error = APIError(code: "unknown_error", message: "fragmenta-core returned an unknown error.", details: nil, requestID: nil, statusCode: nil)
    }
}

struct APIError: Error, Codable, Hashable, LocalizedError, Sendable {
    enum Category: String, Codable, Hashable, Sendable {
        case offline
        case cancelled
        case server
        case client
        case decoding
        case invalidRequest
        case unknown
    }

    let code: String
    let message: String
    let details: String?
    let requestID: String?
    let statusCode: Int?

    var errorDescription: String? {
        message
    }

    var category: Category {
        if code == "offline" {
            return .offline
        }

        if code == "cancelled" {
            return .cancelled
        }

        if code == "decoding_error" {
            return .decoding
        }

        if code == "invalid_url" {
            return .invalidRequest
        }

        if let statusCode {
            if statusCode >= 500 {
                return .server
            }

            if statusCode >= 400 {
                return .client
            }
        }

        return .unknown
    }

    var userFacingTitle: String {
        switch category {
        case .offline:
            return "Offline"
        case .cancelled:
            return "Cancelled"
        case .server:
            return "Backend error"
        case .client:
            return "Request failed"
        case .decoding:
            return "Response error"
        case .invalidRequest:
            return "Configuration error"
        case .unknown:
            return "Something went wrong"
        }
    }

    var isRetryable: Bool {
        switch category {
        case .offline, .server:
            return true
        case .cancelled, .client, .decoding, .invalidRequest, .unknown:
            return false
        }
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

    static func cancelled() -> APIError {
        APIError(
            code: "cancelled",
            message: "The request was cancelled.",
            details: nil,
            requestID: nil,
            statusCode: nil
        )
    }

    static func offline(_ error: URLError) -> APIError {
        APIError(
            code: "offline",
            message: "Fragmenta couldn't reach the backend. Check your connection or base URL.",
            details: error.localizedDescription,
            requestID: nil,
            statusCode: nil
        )
    }
}

struct AnyCodingKey: CodingKey, Hashable {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where Key == AnyCodingKey {
    func decodeFirstPresent<Value: Decodable>(_ type: Value.Type, keys: [String]) throws -> Value? {
        for key in keys {
            if let value = try decodeIfPresent(type, forKey: AnyCodingKey(key)) {
                return value
            }
        }

        return nil
    }
}
