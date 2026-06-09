# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Imperator Free Games — a native macOS menu bar app (Swift/SwiftUI, SPM) that polls `https://www.goranimperator.com/data/free-games.json` every 30 minutes, shows free games in an NSPopover, sends desktop notifications for new games, and displays a red badge dot on the menu bar icon.

## Build & Run

```bash
# Build release binary, create .app bundle, codesign, install to /Applications
./build.sh

# Build only (no bundle)
swift build -c release

# Kill running instance and relaunch
pkill -x FreeGamesWatcher; sleep 1; open '/Applications/Imperator Free Games.app'
```

There are no tests. No linter. No CI. The verification loop is: build → run → visually confirm in the popover.

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
- `GameStore` persists seen game IDs to `~/Library/Application Support/Imperator Free Games/state.json` with FIFO 50 per platform
- First fetch after fresh install seeds seenIds without triggering notifications (`isInitialFetch` flag)
- `newGameIds` accumulates with `formUnion` and clears on `markAsRead()` when popover opens
- Badge dot is an NSView subview on the status bar button, not a SwiftUI overlay
- All inline SVGs (sigil, gamepad, refresh) use `isTemplate = true` for system appearance adaptation
- The app bundle is built manually by `build.sh` (not Xcode) — copies binary + Info.plist + AppIcon.icns

## Brandbook

This app follows the **Imperator Apps BrandBook** (separate repo: `imperator-mac-apps-brandbook`). Key rules:

- **AppColors enum** — all colors reference `AppColors.brand`, `.badgeRed`, etc. Never use hardcoded color literals or bare `Color.accentColor`
- **Forced dark mode** — `NSApp.appearance = NSAppearance(named: .darkAqua)` at launch
- **Accent color override** — `UserDefaults.standard.set(0, forKey: "AppleAccentColor")` at launch
- **HoverButton** pattern — opacity 0.45→1.0, `.easeInOut(duration: 0.2)`
- **Toggle spec** — `.switch` style, `.scaleEffect(0.55)`, `.frame(width: 36, height: 20)`, `.tint(AppColors.brand)`
- **Popover** — 340pt wide, `.transient`, `.black.opacity(0.15)` background
- **No blue anywhere** — all accent colors are brand red (#A01818) or badge red (#D93333)

## Git

- Remote: `git@gitlab.com:goranimperator/mac-free-games.git` (SSH)
- Commit messages in English
- Push to `main` directly (no branches/MRs)
