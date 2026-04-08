import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: RootTab = .library
    @Published private(set) var container: AppContainer
    @Published private(set) var pendingIncomingImportDraft: IncomingImportDraft?
    @Published private(set) var pendingIncomingImportErrorMessage: String?

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

    func refreshPendingSharedImportIfAvailable() async {
        guard let draft = await container.sharedImportStore.loadPendingDraft() else {
            return
        }

        pendingIncomingImportDraft = draft
        pendingIncomingImportErrorMessage = nil
        selectedTab = .importer

        try? await container.sharedImportStore.clearPendingDraft()
    }

    func handleIncomingURL(_ url: URL) async {
        do {
            let draft = try TextImportLoader.draft(from: url, source: .filesApp)
            pendingIncomingImportDraft = draft
            pendingIncomingImportErrorMessage = nil
        } catch {
            pendingIncomingImportErrorMessage = Self.errorMessage(for: error)
        }

        selectedTab = .importer
    }

    func consumePendingIncomingImportDraft() {
        pendingIncomingImportDraft = nil
    }

    func dismissPendingIncomingImportError() {
        pendingIncomingImportErrorMessage = nil
    }

    func clearCachedData() async throws {
        try await container.cacheStore.removeAll()
        try? await container.sharedImportStore.clearPendingDraft()
        preferencesStore.clearRecentSearches()
        pendingIncomingImportDraft = nil
        pendingIncomingImportErrorMessage = nil
        container.diagnosticsStore.record(
            event: .cache,
            status: .success,
            detail: "Cleared local cache store and pending shared import drafts."
        )
    }

    private static func errorMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        if let apiError = error as? APIError {
            return apiError.message
        }

        return "Fragmenta could not open that incoming document."
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
