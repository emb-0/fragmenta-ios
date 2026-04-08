import Foundation

struct EmptyAPIResponse: Decodable, Sendable {
    init() {}
}

struct DownloadedResponse: Sendable {
    let data: Data
    let filename: String?
    let mimeType: String?
}

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
        let execution = try await performRequest(
            path: endpoint.path,
            method: endpoint.method,
            queryItems: endpoint.queryItems,
            headers: endpoint.headers,
            body: endpoint.body
        )

        if (200 ..< 300).contains(execution.response.statusCode) {
            if execution.data.isEmpty, Response.self == EmptyAPIResponse.self {
                return EmptyAPIResponse() as! Response
            }

            do {
                if endpoint.unwrapEnvelope {
                    return try decoder.decode(APIEnvelope<Response>.self, from: execution.data).data
                } else {
                    return try decoder.decode(Response.self, from: execution.data)
                }
            } catch {
                throw APIError.decoding(error)
            }
        }

        throw mappedError(data: execution.data, response: execution.response)
    }

    func download(path: String, queryItems: [URLQueryItem] = []) async throws -> DownloadedResponse {
        let execution = try await performRequest(
            path: path,
            method: .get,
            queryItems: queryItems,
            headers: [:],
            body: nil
        )

        if (200 ..< 300).contains(execution.response.statusCode) {
            let contentDisposition = execution.response.value(forHTTPHeaderField: "Content-Disposition")
            return DownloadedResponse(
                data: execution.data,
                filename: contentDisposition?.fragmentaSuggestedFilename,
                mimeType: execution.response.value(forHTTPHeaderField: "Content-Type")
            )
        }

        throw mappedError(data: execution.data, response: execution.response)
    }

    private func performRequest(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem],
        headers: [String: String],
        body: AnyEncodable?
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        guard
            var components = URLComponents(
                url: resolvedURL(for: path),
                resolvingAgainstBaseURL: false
            )
        else {
            throw APIError.invalidURL(path)
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = config.requestTimeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let providerHeaders = await headersProvider.headers(for: path)
        for (field, value) in providerHeaders.merging(headers, uniquingKeysWith: { _, endpointValue in endpointValue }) {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw mapTransportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.transport(
                statusCode: -1,
                message: "fragmenta-core returned an invalid HTTP response."
            )
        }

        return (data, httpResponse)
    }

    private func mapTransportError(_ error: Error) -> APIError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return .cancelled()
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .timedOut:
                return .offline(urlError)
            default:
                return .transport(statusCode: urlError.errorCode, message: urlError.localizedDescription)
            }
        }

        return .transport(statusCode: -1, message: error.localizedDescription)
    }

    private func mappedError(data: Data, response: HTTPURLResponse) -> APIError {
        let requestID = response.value(forHTTPHeaderField: "x-request-id")
        let decodedError = try? decoder.decode(APIErrorEnvelope.self, from: data).error
        let fallbackMessage = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackPreview = fallbackMessage.map { String($0.prefix(220)) }

        let resolvedMessage = decodedError?.message
            ?? fallbackPreview
            ?? HTTPURLResponse.localizedString(forStatusCode: response.statusCode)

        return APIError(
            code: decodedError?.code ?? "http_\(response.statusCode)",
            message: resolvedMessage,
            details: decodedError?.details,
            requestID: decodedError?.requestID ?? requestID,
            statusCode: decodedError?.statusCode ?? response.statusCode
        )
    }

    private func resolvedURL(for path: String) -> URL {
        if let url = URL(string: path, relativeTo: config.apiBaseURL)?.absoluteURL {
            return url
        }

        return config.apiBaseURL
    }
}

private extension String {
    var fragmentaSuggestedFilename: String? {
        let parts = components(separatedBy: ";")
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("filename=") {
                return trimmed
                    .replacingOccurrences(of: "filename=", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }

        return nil
    }
}
