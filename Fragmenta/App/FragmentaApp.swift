import SwiftUI

@main
struct FragmentaApp: App {
    @StateObject private var appState = AppState()
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
