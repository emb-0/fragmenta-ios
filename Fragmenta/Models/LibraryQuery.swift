import Foundation

struct LibraryQuery: Hashable, Sendable {
    enum Sort: String, CaseIterable, Identifiable, Sendable {
        case recentlyImported = "recently_imported"
        case title
        case author
        case highlightCount = "highlight_count"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recentlyImported:
                return "Recent"
            case .title:
                return "Title"
            case .author:
                return "Author"
            case .highlightCount:
                return "Highlights"
            }
        }
    }

    enum SourceFilter: String, CaseIterable, Identifiable, Sendable {
        case all
        case kindleExport = "kindle_export"
        case manualImport = "manual_import"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .kindleExport:
                return "Kindle"
            case .manualImport:
                return "Manual"
            }
        }
    }

    var sort: Sort = .recentlyImported
    var source: SourceFilter = .all
    var recentOnly = false
    var hasNotesOnly = false
}
