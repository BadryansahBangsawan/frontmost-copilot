<div align="center">

# Frontmost Copilot

**Read the frontmost selection via Accessibility, POST it to an OpenAI-compatible `/v1` chat, then insert or copy the reply.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/frontmost-copilot/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/frontmost-copilot/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/frontmost-copilot?style=flat-square)](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)

<br/>

| | |
|---|---|
| Product | `FrontmostCopilot` |
| Bundle ID | `engineer.badry.frontmostcopilot` |
| Cask | `frontmost-copilot` |
| Status item | SF Symbol `sparkles` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Context** | App name, document path, and selected text via Accessibility. |
| **Prompts** | Explain, Refactor, Tests, Commit. |
| **Hotkey** | Default ⌘⌥Space shows the overlay (not a Dock window). |
| **API** | Keychain service `engineer.badry.frontmostcopilot`, account `api-key`. Default base URL `https://api.openai.com/v1`, model `gpt-4o-mini`. |
| **History** | Local replies under Application Support. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`FrontmostCopilot.app.zip`** | Homebrew cask / unzip, drag **FrontmostCopilot** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/frontmost-copilot/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask frontmost-copilot
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/FrontmostCopilot.app
open /Applications/FrontmostCopilot.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/FrontmostCopilot.app` while `/Applications/FrontmostCopilot.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **sparkles** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

**Show overlay** / the global hotkey open a separate overlay. That is still not a Dock app.

---

## Usage

1. Save an API key in Settings. **Send** stays disabled until a key exists (`Add an API key in Settings`).
2. Select text in another app, then **Refresh context** / **Send**, or press ⌘⌥Space.
3. Modes: Explain, Refactor, Tests, Commit.
4. **Copy context**, copy response, or insert the reply into the frontmost app (Accessibility).
5. Clear history in Settings.
6. **Settings** at the bottom: API key, base URL, model, hotkey, Accessibility status, Open at Login, Quit.

---

## Permissions

**Accessibility** — required to read the focused element and to insert. Without it: **Accessibility is required to read the frontmost selection.** plus Open Settings and **Relaunch**.

Network — only to the base URL you configure, when you press Send.

Ad-hoc `codesign -s -` binds Accessibility to a **cdhash**. Reinstall is a new identity.

1. Privacy & Security → Accessibility: toggle **off**, then **on** for Frontmost Copilot.
2. Click **Relaunch**. macOS does not grant that right to a process that is already running.

---

## Data

| What | Where |
|---|---|
| API key | Keychain service `engineer.badry.frontmostcopilot`, account `api-key` |
| Base URL | UserDefaults `engineer.badry.frontmostcopilot.baseURL` |
| Model | UserDefaults `engineer.badry.frontmostcopilot.model` |
| Hotkey | UserDefaults `engineer.badry.frontmostcopilot.hotkeyKeyCode` / `.hotkeyModifiers` |
| History | `~/Library/Application Support/Frontmost Copilot/` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

Decode failure → empty list plus a red banner. The extra does not crash.

---

## Privacy

The API key never goes in UserDefaults. Network only when you press Send, only to the configured base URL. Selection text is sent to that API.

---

## Uninstall

```bash
brew uninstall --cask frontmost-copilot
```

Or delete `/Applications/FrontmostCopilot.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/Frontmost Copilot"
```

Remove the Keychain item `engineer.badry.frontmostcopilot` / `api-key` if it remains.

Turn off **Frontmost Copilot** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **sparkles** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x FrontmostCopilot` then `open /Applications/FrontmostCopilot.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/FrontmostCopilot.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **Accessibility is required to read the frontmost selection.** | Toggle off/on, then **Relaunch** (cdhash). Same after `brew reinstall --cask frontmost-copilot`. |
| Hotkey does nothing | Default is ⌘⌥Space. Change it in Settings, or another app owns that chord. |
| Send disabled | Add an API key in Settings. |
| Insert failed | Accessibility not trusted for this binary (cdhash). |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/frontmost-copilot.git
cd frontmost-copilot
swift build -c release --product FrontmostCopilot
bash package-app.sh
open dist/FrontmostCopilot.app
```

Tag `v*` runs CI: `FrontmostCopilot.app.zip`. Never commit `dist/` or keys.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the sparkles item on the **right** of the menu bar.

**Where is the API key?**  
Keychain service `engineer.badry.frontmostcopilot`, account `api-key`. Never UserDefaults.

**Does Send leave this Mac?**  
Yes. The selection is POSTed to the configured base URL (default `https://api.openai.com/v1`).

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Frontmost Copilot**.

---

<div align="center">

[MIT](LICENSE)

</div>
