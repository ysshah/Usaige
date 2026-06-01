# Usaige

A tiny macOS menu bar app that shows how close you are to your **5-hour** and **weekly**
usage limits for **Claude** (Claude Code) and **Codex**.

The menu bar shows each tool's five-hour window, e.g. `C 4% · X 37%`. Open the dropdown
for the full breakdown (both windows, reset times, credits, last updated), a refresh button,
a launch-at-login toggle, and quit.

Personal tool, macOS 26+, no distribution.

## How it works

Both numbers come from credentials already on your machine — no extra login:

- **Claude** → `GET https://api.anthropic.com/api/oauth/usage`, authed with the OAuth token
  in the Keychain item `Claude Code-credentials` (written by Claude Code).
- **Codex** → `GET https://chatgpt.com/backend-api/wham/usage`, authed with the token +
  account id in `~/.codex/auth.json` (written by Codex).

Credentials are read fresh on every poll (default every 300s, plus on demand), so the app
picks up tokens that the CLIs refresh in place. If a token has expired, that tool shows `⚠`
in the bar and a hint in the dropdown — just use the CLI once to refresh it.

## Build & run

```sh
# Quick check that both endpoints work (prints to stdout, no UI):
swift run Usaige --probe

# Build the menu bar app bundle and launch it:
./scripts/make-app.sh
open ./Usaige.app
```

### First launch: Keychain prompt

The first time the app reads the Claude credentials, macOS shows a dialog:

> "Usaige" wants to use information stored in "Claude Code-credentials" in your keychain.

Click **Always Allow**. The app is ad-hoc signed, so this decision sticks for that build.
(Codex reads a plain file, so it never prompts.) Rebuilding the binary changes its identity
and may prompt again.

Because the app is unsigned for distribution, Gatekeeper may require a right-click → **Open**
the first time you launch `Usaige.app`.

## Project layout

- `Sources/Usaige/UsaigeApp.swift` — app entry, `MenuBarExtra` scene, `--probe` mode.
- `Sources/Usaige/MenuContentView.swift` — dropdown UI.
- `Sources/Usaige/UsageStore.swift` — observable model + polling loop.
- `Sources/Usaige/Models.swift` — response decoders + unified `UsageSummary`.
- `Sources/Usaige/ClaudeClient.swift`, `CodexClient.swift` — the two fetchers.
- `Sources/Usaige/Keychain.swift`, `LoginItem.swift` — Keychain read, login-item toggle.
- `scripts/make-app.sh` — builds release + wraps the binary into `Usaige.app`.

## Note

The endpoints are the unofficial ones the CLIs themselves use; they could change with CLI
updates. Each tool fails independently and shows an error in the dropdown if a response shape
changes.
