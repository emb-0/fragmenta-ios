import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: RootTab = .library
    @Published private(set) var container: AppContainer

    private let preferencesStore: AppPreferencesStore

    init(
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        container: AppContainer? = nil
    ) {
        self.preferencesStore = preferencesStore
        self.container = container ?? AppContainer.live(preferencesStore: preferencesStore)
    }

    var developmentBaseURLOverride: String {
        preferencesStore.developmentBaseURLOverride ?? ""
    }

    func applyDevelopmentBaseURLOverride(_ rawValue: String) {
        let trimmed = rawValue.trimmed
        preferencesStore.developmentBaseURLOverride = trimmed.isEmpty ? nil : trimmed
        container = AppContainer.live(preferencesStore: preferencesStore)
    }

    func clearCachedData() async throws {
        try await container.cacheStore.removeAll()
        preferencesStore.clearRecentSearches()
        container.diagnosticsStore.record(
            event: .cache,
            status: .success,
            detail: "Cleared local cache store."
        )
    }
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
