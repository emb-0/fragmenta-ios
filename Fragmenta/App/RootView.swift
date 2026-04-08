import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let container = appState.container

        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                LibraryView(
                    booksService: container.booksService,
                    preferencesStore: container.preferencesStore
                )
            }
            .tabItem {
                Label(RootTab.library.title, systemImage: RootTab.library.systemImage)
            }
            .tag(RootTab.library)

            NavigationStack {
                SearchView(
                    searchService: container.searchService,
                    booksService: container.booksService
                )
            }
            .tabItem {
                Label(RootTab.search.title, systemImage: RootTab.search.systemImage)
            }
            .tag(RootTab.search)

            NavigationStack {
                ImportView(importService: container.importService)
            }
            .tabItem {
                Label(RootTab.importer.title, systemImage: RootTab.importer.systemImage)
            }
            .tag(RootTab.importer)

            NavigationStack {
                SettingsView(
                    config: container.config,
                    exportService: container.exportService,
                    importService: container.importService,
                    diagnosticsStore: container.diagnosticsStore
                )
            }
            .tabItem {
                Label(RootTab.settings.title, systemImage: RootTab.settings.systemImage)
            }
            .tag(RootTab.settings)
        }
        .tint(FragmentaColor.textPrimary)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: appState.selectedTab)
        .toolbarColorScheme(.dark, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(FragmentaColor.backgroundElevated.opacity(0.94), for: .tabBar)
        .fragmentaTabBarMinimization()
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppState(container: .preview))
    }
}
#endif
