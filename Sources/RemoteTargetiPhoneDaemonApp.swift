import SwiftUI

@main
struct RemoteTargetiPhoneDaemonApp: App {
    init() {
        BackgroundEngine.shared.startAlwaysRunning()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
