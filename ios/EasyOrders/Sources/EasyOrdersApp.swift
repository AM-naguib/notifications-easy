import SwiftUI

@main
struct EasyOrdersApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = AppViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        BackgroundRefreshManager.shared.scheduleNextRefresh()
                    }
                }
        }
    }
}

