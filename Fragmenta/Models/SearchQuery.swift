import Foundation

struct SearchQuery: Hashable, Sendable {
    enum Mode: String, CaseIterable, Identifiable, Sendable {
        case exact
        case semantic

        var id: String { rawValue }

        var title: String {
            switch self {
            case .exact:
                return "Exact"
            case .semantic:
                return "Semantic"
            }
        }
    }

    enum Sort: String, CaseIterable, Identifiable, Sendable {
        case relevance
        case newest
        case oldest

        var id: String { rawValue }

        var title: String {
            switch self {
            case .relevance:
                return "Relevance"
            case .newest:
                return "Newest"
            case .oldest:
                return "Oldest"
            }
        }
    }

    var text: String = ""
    var bookID: String?
    var author: String = ""
    var hasNotesOnly = false
    var mode: Mode = .exact
    var sort: Sort = .relevance
    var pageSize: Int = 20

    var trimmedText: String {
        text.trimmed
    }

    var hasActiveFilters: Bool {
        bookID != nil || author.isBlank == false || hasNotesOnly
    }
}
