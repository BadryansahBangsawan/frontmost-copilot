import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: CopilotStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var baseURL = Prefs.baseURL
    @State private var model = Prefs.model
    @State private var apiKeyDraft = ""
    @State private var keyMessage: String?
    @State private var keyError: String?
    @State private var loginError: String?
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("API") {
                TextField("Base URL", text: $baseURL)
                    .onChange(of: baseURL) { _, value in
                        Prefs.baseURL = value
                    }
                TextField("Model", text: $model)
                    .onChange(of: model) { _, value in
                        Prefs.model = value
                    }
                SecureField("API key", text: $apiKeyDraft)
                HStack {
                    Button("Save key") {
                        saveKey()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Remove key") {
                        removeKey()
                    }
                    .buttonStyle(.bordered)
                }
                if let keyError {
                    Label(keyError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                } else if let keyMessage {
                    Text(keyMessage)
                        .foregroundStyle(.secondary)
                } else if store.hasAPIKey {
                    Text("A key is saved in Keychain.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Add an API key in Settings")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Hotkey") {
                Text("Current: \(hotkeyLabel)")
                if store.recordingHotkey {
                    Text("Press a shortcut…")
                        .foregroundStyle(.secondary)
                    Button("Cancel") {
                        store.recordingHotkey = false
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Change hotkey") {
                        store.recordingHotkey = true
                    }
                    .buttonStyle(.bordered)
                }
                Text("Default is ⌘⌥Space. Requires Accessibility for the global monitor.")
                    .foregroundStyle(.secondary)
            }

            Section("Accessibility") {
                if store.accessibilityTrusted {
                    Text("Accessibility is allowed.")
                } else {
                    Text("Accessibility is required to read selection and insert text.")
                    Text("If the switch is already on, turn it off and on, then Relaunch.")
                        .foregroundStyle(.secondary)
                    Button("Open Accessibility Settings") {
                        store.requestAccessibility()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Relaunch") {
                        store.relaunch()
                    }
                }
            }

            Section("History") {
                Text("\(store.history.count) saved responses")
                Button("Clear history") {
                    store.clearHistory()
                }
                .buttonStyle(.bordered)
                if let historyError = store.historyError, !historyError.isEmpty {
                    Label(historyError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }

            Section("General") {
                Toggle("Open at Login", isOn: $openAtLogin)
                    .onChange(of: openAtLogin) { _, on in
                        setLogin(on)
                    }
                if let loginError {
                    Label(loginError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 520)
        .animation(reduceMotion ? nil : FunTheme.spring, value: store.recordingHotkey)
        .onAppear {
            store.start()
            store.refreshKeyStatus()
            store.accessibilityTrusted = AXSupport.isTrusted(prompt: false)
            openAtLogin = SMAppService.mainApp.status == .enabled
            baseURL = Prefs.baseURL
            model = Prefs.model
        }
    }

    private var hotkeyLabel: String {
        KeyNames.chord(
            keyCode: Prefs.hotkeyKeyCode,
            modifiers: NSEvent.ModifierFlags(rawValue: UInt(Prefs.hotkeyModifiers))
        )
    }

    private func saveKey() {
        keyError = nil
        keyMessage = nil
        do {
            let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                try KeychainStore.delete()
                keyMessage = "Key removed"
            } else {
                try KeychainStore.save(trimmed)
                keyMessage = "Key saved"
            }
            apiKeyDraft = ""
            store.refreshKeyStatus()
        } catch {
            keyError = error.localizedDescription
        }
    }

    private func removeKey() {
        keyError = nil
        keyMessage = nil
        do {
            try KeychainStore.delete()
            apiKeyDraft = ""
            store.refreshKeyStatus()
            keyMessage = "Key removed"
        } catch {
            keyError = error.localizedDescription
        }
    }

    private func setLogin(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            openAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
