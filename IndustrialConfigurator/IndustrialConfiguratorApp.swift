import SwiftUI

@main
struct IndustrialConfiguratorApp: App {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var configurationManager = ConfigurationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userManager)
                .environmentObject(configurationManager)
        }
    }
}
