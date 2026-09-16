import AppKit
import Combine
import Foundation

final class CopilotStore: ObservableObject {
    static let shared = CopilotStore()

    @Published var appName: String = ""
    @Published var documentPath: String = ""
    @Published var selection: String = ""
    @Published var targetPid: pid_t = 0
    @Published var prompt: CopilotPrompt = .explain
    @Published var response: String = ""
    @Published var isSending = false
    @Published var hasAPIKey = false
    @Published var overlayVisible = false
    @Published var accessibilityTrusted = false
    @Published var recordingHotkey = false
    @Published var history: [HistoryEntry] = []
    @Published var actionError: String?
    @Published var contextError: String?
    @Published var historyError: String?
    @Published var statusMessage: String?

    private var lastForeignApp: NSRunningApplication?
    private var workspaceObserver: NSObjectProtocol?
    private let hotkey = HotkeyMonitor()
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        OverlayPanelController.shared.setup()
        refreshKeyStatus()
        loadHistory()
        refreshContext()
        hotkey.start { [weak self] code, flags in
            self?.handleKey(code: code, flags: flags) ?? false
        }
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.handleActivation(note)
        }
    }

    func refreshKeyStatus() {
        hasAPIKey = KeychainStore.hasKey
    }

    func refreshContext() {
        accessibilityTrusted = AXSupport.isTrusted(prompt: false)
        rememberFrontmost()
        let snap = AXSupport.read(
            preferredPid: lastForeignApp?.processIdentifier,
            preferredName: lastForeignApp?.localizedName
        )
        appName = snap.appName
        documentPath = snap.path
        selection = snap.selection
        targetPid = snap.pid
        if let axError = snap.axError, accessibilityTrusted {
            contextError = axError
        } else {
            contextError = nil
        }
    }

    func requestAccessibility() {
        AXSupport.openAccessibilitySettings()
        accessibilityTrusted = AXSupport.isTrusted(prompt: false)
    }

    func relaunch() {
        AXSupport.relaunch()
    }

    func copyContext() {
        let text = selection
        guard !text.isEmpty else {
            actionError = "Nothing to copy. Select text in another app."
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        actionError = nil
        statusMessage = "Context copied"
    }

    func copyResponse() {
        guard !response.isEmpty else {
            actionError = "No response to copy."
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(response, forType: .string)
        actionError = nil
        statusMessage = "Response copied"
    }

    func insertResponse() {
        let text = response
        guard !text.isEmpty else {
            actionError = "No response to insert."
            return
        }
        do {
            try AXSupport.insert(text, pid: targetPid)
            actionError = nil
            statusMessage = "Inserted"
        } catch {
            actionError = error.localizedDescription
        }
    }

    func send() {
        guard !isSending else { return }
        refreshKeyStatus()
        guard hasAPIKey else {
            actionError = "Add an API key in Settings"
            return
        }
        refreshContext()
        let system = prompt.systemString
        let user = "App: \(appName)\nPath: \(documentPath)\n\n\(selection)"
        let promptTitle = prompt.title
        isSending = true
        actionError = nil
        statusMessage = nil
        response = ""

        Task {
            do {
                guard let key = KeychainStore.load(), !key.isEmpty else {
                    await finishSend(result: .failure(ChatError.emptyKey), promptTitle: promptTitle)
                    return
                }
                let content = try await ChatClient.complete(
                    baseURL: Prefs.baseURL,
                    model: Prefs.model,
                    apiKey: key,
                    system: system,
                    user: user
                )
                await finishSend(result: .success(content), promptTitle: promptTitle)
            } catch {
                await finishSend(result: .failure(error), promptTitle: promptTitle)
            }
        }
    }

    func clearHistory() {
        history = []
        do {
            try HistoryStore.save(history)
            historyError = nil
        } catch {
            historyError = error.localizedDescription
        }
    }

    func toggleOverlay() {
        OverlayPanelController.shared.toggle()
    }

    func handleKey(code: UInt16, flags: NSEvent.ModifierFlags) -> Bool {
        if recordingHotkey {
            guard !KeyNames.modifierKeyCodes.contains(code) else { return false }
            guard HotkeyMatch.hasNonShiftModifier(flags) else { return false }
            Prefs.hotkeyKeyCode = Int(code)
            Prefs.hotkeyModifiers = Int(HotkeyMatch.normalized(flags).rawValue)
            recordingHotkey = false
            objectWillChange.send()
            return true
        }
        if HotkeyMatch.matches(code: code, flags: flags) {
            OverlayPanelController.shared.toggle()
            return true
        }
        return false
    }

    private func finishSend(result: Result<String, Error>, promptTitle: String) async {
        await MainActor.run {
            isSending = false
            switch result {
            case .success(let content):
                response = content
                actionError = nil
                appendHistory(prompt: promptTitle, response: content)
            case .failure(let error):
                actionError = error.localizedDescription
            }
        }
    }

    private func appendHistory(prompt: String, response: String) {
        let entry = HistoryEntry(time: Date(), prompt: prompt, response: response)
        history.insert(entry, at: 0)
        if history.count > HistoryStore.cap {
            history = Array(history.prefix(HistoryStore.cap))
        }
        do {
            try HistoryStore.save(history)
            historyError = nil
        } catch {
            historyError = error.localizedDescription
        }
    }

    private func loadHistory() {
        let loaded = HistoryStore.load()
        history = loaded.entries
        if let error = loaded.error {
            historyError = error.localizedDescription
        } else {
            historyError = nil
        }
    }

    private func handleActivation(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        if app.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastForeignApp = app
            refreshContext()
        }
    }

    private func rememberFrontmost() {
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastForeignApp = front
        }
    }
}
