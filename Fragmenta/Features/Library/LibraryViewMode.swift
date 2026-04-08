import Foundation

enum LibraryViewMode: String, CaseIterable, Identifiable, Sendable {
    case journal
    case bookshelf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal:
            return "Journal"
        case .bookshelf:
            return "Bookshelf"
        }
    }

    var systemImage: String {
        switch self {
        case .journal:
            return "list.bullet.rectangle"
        case .bookshelf:
            return "rectangle.grid.2x2"
        }
    }

    var subtitle: String {
        switch self {
        case .journal:
            return "Text-first shelf"
        case .bookshelf:
            return "Cover-first shelf"
        }
    }
}
