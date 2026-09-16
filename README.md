# Frontmost Copilot

Read the frontmost app’s selected text, send it to an OpenAI-compatible API, and insert or copy the reply.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Floating overlay and menu-bar panel.
- Reads app name, document path, and selected text via Accessibility.
- Prompts: Explain, Refactor, Tests, Commit.
- Global hotkey (default ⌘⌥Space) to show the overlay.
- API key stored in Keychain (`engineer.badry.frontmostcopilot` / `api-key`), never UserDefaults.
- Configurable base URL (default `https://api.openai.com/v1`) and model (default `gpt-4o-mini`).

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- Accessibility to read selection and insert text
- An API key for an OpenAI-compatible chat endpoint

## Install

Homebrew (macOS 14+):

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask frontmost-copilot
```

Opens as a menu extra (no Dock icon). The cask is ad-hoc signed. If Gatekeeper blocks it:

```bash
xattr -cr /Applications/FrontmostCopilot.app
```

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/frontmost-copilot.git
cd frontmost-copilot
bash package-app.sh
open dist/FrontmostCopilot.app
```

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- Save an API key in Settings. Send stays disabled until a key exists (`Add an API key in Settings`).
- Select text in another app, then **Send** or press the overlay hotkey.
- **Show overlay** / **Hide overlay** from the menu extra. Default hotkey is ⌘⌥Space (change it in Settings).
- History of replies is stored locally and can be cleared.

## Permissions

- **Accessibility** — required to read the focused element and to insert. Without it you get a CTA to open Accessibility Settings.
- Network — only to the base URL you configure, when you press Send.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

The API key never goes in UserDefaults or logs. Chat content is sent only to the configured endpoint when you send. No other telemetry.

Bundle ID: `engineer.badry.frontmostcopilot`.

## Development

```bash
swift build
swift build -c release --product FrontmostCopilot
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## Security

Treat the Keychain item as a secret. Rotate the key if it leaks. Do not paste keys into issues or commit them.


## License

[MIT](LICENSE)
