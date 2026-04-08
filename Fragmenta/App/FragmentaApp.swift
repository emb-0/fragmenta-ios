import SwiftUI

@main
struct FragmentaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .task {
                    await appState.refreshPendingSharedImportIfAvailable()
                }
                .onOpenURL { url in
                    Task {
                        await appState.handleIncomingURL(url)
                    }
                }
                .onChange(of: scenePhase, initial: false) { _, newValue in
                    guard newValue == .active else {
                        return
                    }

                    Task {
                        await appState.refreshPendingSharedImportIfAvailable()
                    }
                }
        }
    }
}
