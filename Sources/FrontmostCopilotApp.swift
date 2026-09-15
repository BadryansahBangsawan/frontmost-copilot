import AppKit
import SwiftUI

@main
struct FrontmostCopilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Frontmost Copilot", systemImage: "sparkles") {
            RootView()
                .environmentObject(CopilotStore.shared)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(CopilotStore.shared)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        CopilotStore.shared.start()
    }
}
