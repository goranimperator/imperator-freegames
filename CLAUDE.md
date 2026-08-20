# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Imperator FreeGames — a native macOS menu bar app (Swift/SwiftUI, SPM) that polls `https://www.goranimperator.com/data/free-games.json` every 30 minutes, shows free games in an NSPopover, sends desktop notifications for new games, and displays a red badge dot on the menu bar icon.

## Build & Run

Everything goes through the `Makefile`. There is no `build.sh` and no Xcode project.

```bash
# Build release binary, bundle into build/, codesign, install to /Applications, launch
make install

# Build and bundle only, then open from build/
make run

# Remove build/ and dist/
make clean
```

Signing uses the self-signed `Imperator Dev` identity (`CODESIGN_IDENTITY ?= Imperator Dev`). Do not switch to ad-hoc for anything that ships: the app registers a login item through `SMAppService`, and ad-hoc mints a new cdhash on every build, which drops that registration on update.

There are no tests. No linter. No CI. The verification loop is: build → run → visually confirm in the popover.

## Release

```bash
# Zip only — touches nothing in git, nothing on the remote
make dist VERSION=1.0.0

# Bump Info.plist, commit, tag, push, publish the GitHub release with the zip
make release VERSION=1.0.0
```

Tags are plain semver (`v1.0.0`). `CFBundleShortVersionString` is set by `make release`, never by hand; `CFBundleVersion` comes from `git rev-list --count HEAD`. The About panel reads both keys out of the bundle, so it must never hardcode a version. Requires `gh` and a clean working tree.

**Re-read the whole README before every release, not after.** This is a gate, not a nice-to-have — v1.0.0 needed three corrective passes on an already-published tag, and each one meant deleting the release and re-cutting it. Check at minimum:

- `Resources/AppIcon.png`, the README header, still matches `Resources/AppIcon.icns`. Nothing in the build touches it, so a new icon leaves it stale. Regenerate in the same commit: `iconutil -c iconset Resources/AppIcon.icns -o /tmp/ic.iconset && cp /tmp/ic.iconset/icon_256x256.png Resources/AppIcon.png`. It renders at 256 physical pixels, so do not downscale to 128.
- No stale app name, binary name, or repo slug anywhere: `git ls-files | grep -v AppIcon | xargs grep -ln "<old name>"`.
- The Layout table lists every file in `Sources/ImperatorFreeGames/`.
- The requirements block matches `platforms:` in `Package.swift` (macOS 13) and the arch the binary actually is (arm64).
- Command blocks match the current Makefile targets.

Verify the header against what GitHub serves, not the local file: `curl -sSL https://raw.githubusercontent.com/goranimperator/imperator-freegames/main/Resources/AppIcon.png`.

## Architecture

**Entry point:** `main.swift` — creates NSApplication with `.accessory` policy (no dock icon), instantiates AppDelegate via `MainActor.assumeIsolated`.

**Data flow:**
```
AppDelegate (NSStatusItem + NSPopover + Timer)
  → GameStore (@MainActor ObservableObject, fetches JSON, diffs against seenIds)
    → NotificationManager (singleton, UNUserNotificationCenter)
    → PopoverContentView (SwiftUI, reads GameStore via @EnvironmentObject)
```

**Key design decisions:**
- `GameStore` persists seen game IDs to `~/Library/Application Support/Imperator FreeGames/state.json` with FIFO 50 per platform
- First fetch after fresh install seeds seenIds without triggering notifications (`isInitialFetch` flag)
- `newGameIds` accumulates with `formUnion` and clears on `markAsRead()` when popover opens
- Badge dot is an NSView subview on the status bar button, not a SwiftUI overlay
- All inline SVGs (sigil, gamepad, refresh) use `isTemplate = true` for system appearance adaptation
- The app bundle is assembled by the `Makefile` (not Xcode) — copies binary + Info.plist + AppIcon.icns, then codesigns

## Brandbook

This app follows the **Imperator Apps BrandBook** (separate repo: `imperator-apps-brandbook`). Key rules:

- **AppColors enum** — all colors reference `AppColors.brand`, `.badgeRed`, etc. Never use hardcoded color literals or bare `Color.accentColor`
- **Forced dark mode** — `NSApp.appearance = NSAppearance(named: .darkAqua)` at launch
- **Accent color override** — `UserDefaults.standard.set(0, forKey: "AppleAccentColor")` at launch
- **HoverButton** pattern — opacity 0.45→1.0, `.easeInOut(duration: 0.2)`
- **Toggle spec** — `.switch` style, `.scaleEffect(0.55)`, `.frame(width: 36, height: 20)`, `.tint(AppColors.brand)`
- **Popover** — 340pt wide, `.transient`, `.black.opacity(0.15)` background
- **No blue anywhere** — all accent colors are brand red (#A01818) or badge red (#D93333)
- **About panel copyright** — `© 1986-\(currentYear)`, computed from `Calendar`, never a hardcoded end year

## Git

- Remote: `git@github.com:goranimperator/imperator-freegames.git` (SSH)
- Commit messages in English; all filenames, comments and file content in English
- Push to `main` directly (no branches/PRs)
