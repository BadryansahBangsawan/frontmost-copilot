<div align="center">

# Frontmost Copilot

**An AI overlay copilot that follows the active macOS app.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/frontmost-copilot?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `FrontmostCopilot-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask frontmost-copilot
```

A **Frontmost Copilot** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/FrontmostCopilot.app && open /Applications/FrontmostCopilot.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `FrontmostCopilot-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)
2. Unzip and drag **FrontmostCopilot** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/frontmost-copilot.git
cd frontmost-copilot
bash package-app.sh
open dist/FrontmostCopilot.app
```

Requires Xcode Command Line Tools and Swift 5.9+.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Control+Shift+Space` | Show / hide copilot panel |

---

## Troubleshooting

**Panel does not follow the active app**  
Grant Accessibility permission: **System Settings → Privacy & Security → Accessibility → enable Frontmost Copilot**, then relaunch the app. The permission prompt only appears once; if you dismissed it, add manually.

**Panel appears behind full-screen windows**  
macOS limits overlay positioning in full-screen Spaces. Switch the target app to a regular window (not full-screen) for the panel to dock correctly.

**Hotkey (`Control+Shift+Space`) not responding**  
Another app may have claimed the same shortcut. Check **System Settings → Keyboard → Keyboard Shortcuts** for conflicts, or reassign the hotkey from the Frontmost Copilot menu bar icon.

---

## Notes

– Requires Accessibility permission to identify the frontmost app.
– Panel stays on top of all windows.
– No Dock icon; lives entirely in the menu bar.
– Optional auto-start: **System Settings → General → Login Items** and add Frontmost Copilot (or enable Open at Login from the menu bar icon if offered).

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>

