import Foundation

struct BackendHealthCheck: Hashable, Sendable {
    enum Status: String, Hashable, Sendable {
        case healthy
        case reachableWithoutHealthEndpoint
        case invalidConfiguration
        case unreachable
        case serverError
        case decodingMismatch
        case requestFailed

        var title: String {
            switch self {
            case .healthy:
                return "Healthy"
            case .reachableWithoutHealthEndpoint:
                return "Reachable"
            case .invalidConfiguration:
                return "Configuration issue"
            case .unreachable:
                return "Unreachable"
            case .serverError:
                return "Server error"
            case .decodingMismatch:
                return "Response mismatch"
            case .requestFailed:
                return "Request failed"
            }
        }
    }

    let status: Status
    let summary: String
    let detail: String?
    let checkedAt: Date
    let primaryPath: String
    let fallbackPath: String?
}
