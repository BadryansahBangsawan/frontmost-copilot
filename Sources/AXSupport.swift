import AppKit
import ApplicationServices
import Foundation

struct AppContext {
    var appName: String
    var path: String
    var selection: String
    var pid: pid_t
    var axError: String?
}

enum AXSupport {
    static func isTrusted(prompt: Bool) -> Bool {
        _ = prompt
        return AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] as CFDictionary
        )
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    static func relaunch() {
        let path = Bundle.main.bundlePath
        let escaped = "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", "sleep 0.4; /usr/bin/open \(escaped)"]
        try? proc.run()
        NSApp.terminate(nil)
    }

    static func read(preferredPid: pid_t?, preferredName: String?) -> AppContext {
        let selfBundle = Bundle.main.bundleIdentifier
        let front = NSWorkspace.shared.frontmostApplication
        let foreign: NSRunningApplication? = {
            if let front, front.bundleIdentifier != selfBundle {
                return front
            }
            if let preferredPid, preferredPid > 0,
               let match = NSRunningApplication(processIdentifier: preferredPid) {
                return match
            }
            return nil
        }()

        let appName = foreign?.localizedName ?? preferredName ?? front?.localizedName ?? ""
        let pid = foreign?.processIdentifier ?? preferredPid ?? front?.processIdentifier ?? 0

        guard isTrusted(prompt: false) else {
            return AppContext(appName: appName, path: "", selection: "", pid: pid, axError: nil)
        }

        guard pid > 0 else {
            return AppContext(
                appName: appName,
                path: "",
                selection: "",
                pid: pid,
                axError: "No target application."
            )
        }

        let appEl = AXUIElementCreateApplication(pid)
        var focusedRef: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            appEl,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )

        var focused: AXUIElement?
        if focusedStatus == .success, let focusedRef {
            focused = asElement(focusedRef)
        }

        if focused == nil {
            var systemFocused: CFTypeRef?
            let systemWide = AXUIElementCreateSystemWide()
            if AXUIElementCopyAttributeValue(
                systemWide,
                kAXFocusedUIElementAttribute as CFString,
                &systemFocused
            ) == .success, let systemFocused {
                focused = asElement(systemFocused)
            }
        }

        guard let element = focused else {
            let path = documentPath(app: appEl)
            return AppContext(
                appName: appName,
                path: path,
                selection: "",
                pid: pid,
                axError: axMessage(focusedStatus, fallback: "No focused element.")
            )
        }

        var selection = copyString(element, kAXSelectedTextAttribute as CFString) ?? ""
        if selection.isEmpty {
            let value = copyString(element, kAXValueAttribute as CFString) ?? ""
            if value.count > 8000 {
                selection = String(value.prefix(8000))
            } else {
                selection = value
            }
        }

        var path = documentPath(fromElement: element)
        if path.isEmpty {
            path = documentPath(app: appEl)
        }

        return AppContext(appName: appName, path: path, selection: selection, pid: pid, axError: nil)
    }

    static func insert(_ text: String, pid: pid_t) throws {
        guard isTrusted(prompt: false) else {
            throw AXActionError("Accessibility is not trusted.")
        }
        guard pid > 0 else {
            throw AXActionError("No target application to insert into.")
        }

        let appEl = AXUIElementCreateApplication(pid)
        var focusedRef: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            appEl,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        if status == .success, let focusedRef, let element = asElement(focusedRef) {
            var settable = DarwinBoolean(false)
            let settableStatus = AXUIElementIsAttributeSettable(
                element,
                kAXSelectedTextAttribute as CFString,
                &settable
            )
            if settableStatus == .success, settable.boolValue {
                let setStatus = AXUIElementSetAttributeValue(
                    element,
                    kAXSelectedTextAttribute as CFString,
                    text as CFTypeRef
                )
                if setStatus == .success {
                    return
                }
            }
        }

        NSPasteboard.general.clearContents()
        if !NSPasteboard.general.setString(text, forType: .string) {
            throw AXActionError("Could not write the pasteboard.")
        }

        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            throw AXActionError("Could not create an event source.")
        }
        let vKey: CGKeyCode = 9
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else {
            throw AXActionError("Could not synthesize ⌘V.")
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
    }

    private static func documentPath(fromElement element: AXUIElement) -> String {
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXWindowAttribute as CFString, &windowRef) == .success,
           let windowRef, let window = asElement(windowRef) {
            return documentPath(window: window)
        }
        return ""
    }

    private static func documentPath(app: AXUIElement) -> String {
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
           let windowRef, let window = asElement(windowRef) {
            return documentPath(window: window)
        }
        return ""
    }

    private static func documentPath(window: AXUIElement) -> String {
        var docRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXDocumentAttribute as CFString, &docRef) == .success,
              let docRef else {
            return ""
        }
        if let string = docRef as? String {
            if let url = URL(string: string), url.isFileURL {
                return url.path
            }
            return string
        }
        if let url = docRef as? URL {
            return url.path
        }
        return ""
    }

    private static func copyString(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &ref) == .success else { return nil }
        return ref as? String
    }

    private static func axMessage(_ error: AXError, fallback: String) -> String {
        if error == .success { return fallback }
        return "Accessibility error (\(error.rawValue)). \(fallback)"
    }

    private static func asElement(_ value: CFTypeRef) -> AXUIElement? {
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return unsafeBitCast(value, to: AXUIElement.self)
    }
}

struct AXActionError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
