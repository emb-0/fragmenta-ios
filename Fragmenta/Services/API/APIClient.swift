import Foundation

final class APIClient {
    private let config: AppConfig
    private let session: URLSession
    private let headersProvider: RequestHeadersProviding
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        config: AppConfig,
        session: URLSession? = nil,
        headersProvider: RequestHeadersProviding
    ) {
        self.config = config
        self.headersProvider = headersProvider

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = config.requestTimeout
        sessionConfiguration.timeoutIntervalForResource = config.requestTimeout
        self.session = session ?? URLSession(configuration: sessionConfiguration)
        self.decoder = JSONDecoder.fragmenta
        self.encoder = JSONEncoder.fragmenta
    }

    func request<Response: Decodable & Sendable>(_ endpoint: APIEndpoint<Response>) async throws -> Response {
        guard
            var components = URLComponents(
                url: resolvedURL(for: endpoint.path),
                resolvingAgainstBaseURL: false
            )
        else {
            throw APIError.invalidURL(endpoint.path)
        }

        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL(endpoint.path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let providerHeaders = await headersProvider.headers(for: endpoint.path)
        for (field, value) in providerHeaders.merging(endpoint.headers, uniquingKeysWith: { _, endpointValue in endpointValue }) {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(
                statusCode: -1,
                message: error.localizedDescription
            )
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.transport(
                statusCode: -1,
                message: "fragmenta-core returned an invalid HTTP response."
            )
        }

        if (200 ..< 300).contains(httpResponse.statusCode) {
            do {
                if endpoint.unwrapEnvelope {
                    return try decoder.decode(APIEnvelope<Response>.self, from: data).data
                } else {
                    return try decoder.decode(Response.self, from: data)
                }
            } catch {
                throw APIError.decoding(error)
            }
        }

        let requestID = httpResponse.value(forHTTPHeaderField: "x-request-id")
        let decodedError = try? decoder.decode(APIErrorEnvelope.self, from: data).error

        throw APIError(
            code: decodedError?.code ?? "http_\(httpResponse.statusCode)",
            message: decodedError?.message ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            details: decodedError?.details,
            requestID: decodedError?.requestID ?? requestID,
            statusCode: decodedError?.statusCode ?? httpResponse.statusCode
        )
    }

    private func resolvedURL(for path: String) -> URL {
        if let url = URL(string: path, relativeTo: config.apiBaseURL)?.absoluteURL {
            return url
        }

        return config.apiBaseURL
    }
}

private extension JSONDecoder {
    static let fragmenta: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)

            if let date = DateParser.fractional.date(from: rawValue) ?? DateParser.standard.date(from: rawValue) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected ISO8601 date string."
            )
        }
        return decoder
    }()
}

private extension JSONEncoder {
    static let fragmenta: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private enum DateParser {
    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
