import AppKit
import Foundation

final class HotkeyMonitor {
    private var local: Any?
    private var global: Any?

    func start(onKey: @escaping (UInt16, NSEvent.ModifierFlags) -> Bool) {
        stop()
        global = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let code = event.keyCode
            let flags = event.modifierFlags
            DispatchQueue.main.async {
                _ = onKey(code, flags)
            }
        }
        local = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let consumed = onKey(event.keyCode, event.modifierFlags)
            return consumed ? nil : event
        }
    }

    func stop() {
        if let local {
            NSEvent.removeMonitor(local)
            self.local = nil
        }
        if let global {
            NSEvent.removeMonitor(global)
            self.global = nil
        }
    }

    deinit {
        stop()
    }
}

enum HotkeyMatch {
    static func normalized(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .numericPad, .help, .function])
    }

    static func matches(code: UInt16, flags: NSEvent.ModifierFlags) -> Bool {
        let storedCode = UInt16(truncatingIfNeeded: Prefs.hotkeyKeyCode)
        let storedFlags = normalized(NSEvent.ModifierFlags(rawValue: UInt(Prefs.hotkeyModifiers)))
        return code == storedCode && normalized(flags) == storedFlags
    }

    static func hasNonShiftModifier(_ flags: NSEvent.ModifierFlags) -> Bool {
        let n = normalized(flags)
        return n.contains(.command) || n.contains(.option) || n.contains(.control)
    }
}
