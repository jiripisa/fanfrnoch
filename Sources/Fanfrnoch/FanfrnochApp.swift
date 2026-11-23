import SwiftUI

@main
struct FanfrnochApp: App {

    @State private var updates = UpdateService()
    @State private var model = AppModel()

    var body: some Scene {
        Window("Fanfrnoch", id: "main") {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)
        .commands {
            // Auto-update: manual check next to About.
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { updates.checkNow() }
                    .disabled(!updates.canCheck)
            }
            CommandGroup(replacing: .newItem) {}
        }
    }
}
