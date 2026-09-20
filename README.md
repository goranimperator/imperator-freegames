<p align="center">
  <img src="Resources/AppIcon.png" width="128" height="128" alt="Imperator FreeGames app icon">
</p>

<h1 align="center">Imperator FreeGames</h1>

<p align="center">
  A macOS menu bar watcher for game giveaways. It polls a public feed of games
  that are currently free to keep on Steam, Epic and GOG, notifies you when a
  new one shows up, and lists them all in a menu bar panel.
</p>

## Install

Download the latest zip from [Releases](https://github.com/goranimperator/imperator-freegames/releases),
unzip, and move `Imperator FreeGames.app` to `/Applications`.

The app is signed with a self-signed certificate and is not notarized, so
Gatekeeper blocks the first launch. Right-click the app and choose **Open**, or
clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine "/Applications/Imperator FreeGames.app"
```

Requires macOS 13 or later, Apple silicon. Built and tested on macOS 27 only --
older versions are expected to work but have not been verified.

Install at your own risk. The app is not notarized and carries no Apple
Developer signature, so macOS cannot vouch for it. It is provided as is, with no
warranty, under the [MIT license](LICENSE).

## Permissions

No Accessibility, Input Monitoring, or Automation grants. The app declares no
`NSUsage` keys and reads nothing on your machine.

Two system integrations:

| Integration | What it does |
|-------------|--------------|
| **Notifications** | On first launch the app asks for notification permission through `UNUserNotificationCenter`. Decline it and everything still works -- you just lose the alerts and keep the badge dot. |
| **Open at Login** | The footer toggle calls `SMAppService.mainApp.register()`, which adds the app to Login Items in System Settings. Turning it off unregisters it. |

Network access is one outbound HTTPS request every 30 minutes to
`https://www.goranimperator.com/data/free-games.json`. Nothing is sent -- no
identifiers, no telemetry, no account. Clicking a game opens its store page in
your default browser.

## Use

Click the menu bar icon to open the panel. Games are grouped by platform with
a count per section; each row shows the title, the regular price it was before
the giveaway, release year, developer and a short description. Click a row to
open the store page.

A red dot on the menu bar icon means something new arrived since you last
looked. Opening the panel clears it, and the new titles keep a red **NEW**
pill until then.

The footer holds the controls:

| Control | What it does |
|---------|--------------|
| Open at Login | Register or unregister the login item |
| Website | Open the full free-games page in a browser |
| About | Version, build and copyright panel |
| Quit | Terminate the app |

The refresh arrow in the header forces a fetch instead of waiting for the next
30-minute tick.

State lives in
`~/Library/Application Support/Imperator FreeGames/state.json`: the IDs already
seen, capped at the 50 most recent per platform. The first fetch after a fresh
install seeds that list silently, so installing the app does not fire a
notification for every game already on offer.

## Build from source

```bash
make install
```

Builds release, bundles, codesigns, installs to `/Applications`, and launches.
Other targets:

```bash
make run
```

```bash
make clean
```

Signing uses the self-signed `Imperator Dev` identity by default. Override it:

```bash
make build CODESIGN_IDENTITY=-
```

Ad-hoc signing (`-`) mints a new code hash on every build, which drops the
login-item registration on update. Fine for local iteration, wrong for a
release.

Building needs Swift 6.4 or later, because `Package.swift` declares
`swift-tools-version:6.4`. That is a build requirement only; the app itself
still runs on macOS 13.

### Why the build passes a linker flag

AppKit decides which generation of a control to draw from the `sdk` field in the
binary's `LC_BUILD_VERSION`, and SwiftPM fills that field from `platforms:`
rather than from the SDK it compiled against. Left alone, a package pinned to
macOS 13 would ship macOS 13 era controls on every system, so the Open at Login
switch would be a narrow track with a round knob instead of the wide capsule
with an oval knob that macOS 27 draws.

Raising `platforms:` would fix the drawing and lock out every Mac below macOS
27, so the Makefile stamps the SDK through the linker instead and leaves the
minimum alone:

```bash
swift build -c release -Xlinker -platform_version -Xlinker macos -Xlinker 13.0 -Xlinker 27.0
```

Check the result on any build:

```bash
otool -l "build/Imperator FreeGames.app/Contents/MacOS/ImperatorFreeGames" | awk '/LC_BUILD_VERSION/,/^$/' | grep -E "minos|sdk"
```

It has to print `minos 13.0` and `sdk 27.0`. If `sdk` matches `minos`, the app
is drawing the old controls.

## Release

Build a zip without touching git or the remote:

```bash
make dist VERSION=1.0.0
```

Cut a full release -- bumps `Info.plist`, commits, tags `v1.0.0`, pushes, and
publishes a GitHub release with the zip attached:

```bash
make release VERSION=1.0.0
```

Requires the [GitHub CLI](https://cli.github.com) (`brew install gh`, then
`gh auth login`). The working tree must be clean. Tags are plain semver
(`v1.0.0`); the release title carries the app name. `CFBundleVersion` is set
from `git rev-list --count HEAD` and is never edited by hand.

## Layout

| Path | Role |
|------|------|
| `Sources/ImperatorFreeGames/main.swift` | Entry point, `.accessory` activation policy |
| `Sources/ImperatorFreeGames/AppDelegate.swift` | Status item, panel lifecycle, 30-minute timer, badge dot |
| `Sources/ImperatorFreeGames/GameStore.swift` | Feed fetch, diff against seen IDs, state persistence |
| `Sources/ImperatorFreeGames/Models.swift` | Feed and state types |
| `Sources/ImperatorFreeGames/NotificationManager.swift` | Notification authorization, delivery, click handling |
| `Sources/ImperatorFreeGames/PopoverContentView.swift` | SwiftUI panel layout and controls |
| `Sources/ImperatorFreeGames/MenuBarPanel.swift` | The panel surface: system popover material, 17.5pt corner, click and Escape dismissal |
| `Sources/ImperatorFreeGames/AboutPanel.swift` | About panel |
| `Sources/ImperatorFreeGames/AppColors.swift` | Brand colours |
| `Sources/ImperatorFreeGames/SigilIcon.swift` | Inline SVG icons rendered as template images |
| `Resources/` | `Info.plist`, app icon, sigil source vector |

A SwiftPM executable with no dependencies. `LSUIElement` is true, so there is no
Dock icon and no menu -- the status item is the entire interface. Because
SwiftPM does not compile asset catalogs, the panel and menu bar icons are
inline SVG strings decoded through `NSImage(data:)` with `isTemplate = true`, so
they follow the system appearance.

The menu bar panel is drawn by the app, in `MenuBarPanel.swift`, rather than by
`NSPopover`. `NSPopover` gives no way to set its radius, and neither radius it
draws is the one macOS uses in the menu bar: a binary stamped `sdk 27.0` gets a
26.25pt squircle and one stamped `sdk 14.0` gets a 9.5pt circular corner.

The target is the system's own menu bar panel. Control Centre's Wi-Fi panel,
captured with `screencapture -o -l` and fitted on its bottom corner, measures
17.50pt at 309 x 290 drawn points, rms 0.38, and fits a circle rather than a
squircle. A plain titled window measures 17.25pt by the same method, so a menu
bar panel carries a window corner, not a popover one.

`MenuBarPanel` is therefore a borderless `NSPanel` holding an
`NSVisualEffectView` on the `.popover` material, with a circular layer corner.
The constant is `18.25`, not `17.5`, because `NSVisualEffectView` blends its
edge and draws about 0.75pt tighter than the radius it is given: at 17.5 this
app's panel measured 16.75, at 18.25 it measures 17.50, which is the Wi-Fi panel
exactly.

There is no arrow and no open or close animation, because macOS 27 gives its own
menu bar panels neither. The panel owns its own dismissal, a global click
monitor plus an Escape key monitor, which is what `NSPopover`'s `.transient`
behaviour used to provide.

## License

[MIT](LICENSE) &copy; Goran Imperator
