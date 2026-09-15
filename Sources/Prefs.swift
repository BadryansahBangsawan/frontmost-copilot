import AppKit
import Foundation

enum Prefs {
    static let prefix = "engineer.badry.frontmostcopilot."
    static let baseURLKey = prefix + "baseURL"
    static let modelKey = prefix + "model"
    static let hotkeyKeyCodeKey = prefix + "hotkeyKeyCode"
    static let hotkeyModifiersKey = prefix + "hotkeyModifiers"

    static let defaultBaseURL = "https://api.openai.com/v1"
    static let defaultModel = "gpt-4o-mini"
    static let defaultKeyCode = 49
    static let defaultModifiers = Int(
        NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue
    )

    static var baseURL: String {
        get {
            let value = UserDefaults.standard.string(forKey: baseURLKey) ?? ""
            return value.isEmpty ? defaultBaseURL : value
        }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    static var model: String {
        get {
            let value = UserDefaults.standard.string(forKey: modelKey) ?? ""
            return value.isEmpty ? defaultModel : value
        }
        set { UserDefaults.standard.set(newValue, forKey: modelKey) }
    }

    static var hotkeyKeyCode: Int {
        get {
            if UserDefaults.standard.object(forKey: hotkeyKeyCodeKey) == nil {
                return defaultKeyCode
            }
            return UserDefaults.standard.integer(forKey: hotkeyKeyCodeKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hotkeyKeyCodeKey) }
    }

    static var hotkeyModifiers: Int {
        get {
            if UserDefaults.standard.object(forKey: hotkeyModifiersKey) == nil {
                return defaultModifiers
            }
            return UserDefaults.standard.integer(forKey: hotkeyModifiersKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hotkeyModifiersKey) }
    }
}

enum CopilotPrompt: String, CaseIterable, Identifiable {
    case explain
    case refactor
    case tests
    case commit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .refactor: return "Refactor"
        case .tests: return "Tests"
        case .commit: return "Commit"
        }
    }

    var systemString: String {
        switch self {
        case .explain: return "Explain this code concisely."
        case .refactor: return "Refactor for clarity. Return only the replacement code."
        case .tests: return "Write tests for this code. Return only test code."
        case .commit: return "Write a one-line conventional commit message for this diff."
        }
    }
}

enum KeyNames {
    static func chord(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var parts = ""
        if modifiers.contains(.control) { parts += "⌃" }
        if modifiers.contains(.option) { parts += "⌥" }
        if modifiers.contains(.shift) { parts += "⇧" }
        if modifiers.contains(.command) { parts += "⌘" }
        parts += name(keyCode: keyCode)
        return parts
    }

    static func name(keyCode: Int) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Esc"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 118: return "F4"
        case 120: return "F2"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return "Key\(keyCode)"
        }
    }

    static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
}
