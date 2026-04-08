import Foundation

final class AppState: ObservableObject {
    @Published var selectedTab: RootTab = .library
}

enum RootTab: String, CaseIterable, Hashable, Identifiable {
    case library
    case search
    case importer
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .library:
            return "Library"
        case .search:
            return "Search"
        case .importer:
            return "Import"
        case .settings:
            return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .library:
            return "books.vertical"
        case .search:
            return "magnifyingglass"
        case .importer:
            return "square.and.arrow.down.on.square"
        case .settings:
            return "slider.horizontal.3"
        }
    }
}
