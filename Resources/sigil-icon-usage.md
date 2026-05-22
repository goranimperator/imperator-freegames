# Sigil Icon Usage

## Variant som används

**sigil-tight-thick.svg** — tjockare armar och hub-ring, bra synlighet i smaa storlekar.

### SVG

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-80 -80 160 160">
  <defs>
    <g id="unit">
      <path d="
        M 4.5 22.8
        L 4.5 64
        C 4.5 70, 10 69.41, 12 69.41
        A 118.58 118.58 0 0 0 58.51 54.56
        A 80 80 0 0 1 -58.51 54.56
        A 118.58 118.58 0 0 0 -12 69.41
        C -10 69.41, -4.5 70, -4.5 64
        L -4.5 22.8
        A 8 8 0 0 0 -8.65 15.79
        L 8.65 15.79
        A 8 8 0 0 0 4.5 22.8
        Z
      " />
    </g>
  </defs>
  <g fill="#000" stroke="#000" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round">
    <use href="#unit" />
    <use href="#unit" transform="rotate(120)" />
    <use href="#unit" transform="rotate(240)" />
  </g>
  <path fill="#000" fill-rule="evenodd" d="
    M 22.5 0 A 22.5 22.5 0 1 0 -22.5 0 A 22.5 22.5 0 1 0 22.5 0 Z
    M 9 0 A 9 9 0 1 0 -9 0 A 9 9 0 1 0 9 0 Z
  " />
</svg>
```

### Skillnad mot tunna varianten

| Egenskap | Tunn (sigil-tight.svg) | Tjock (sigil-tight-thick.svg) |
|---|---|---|
| Stroke | ingen | `stroke-width="4.5"` |
| Hub outer radius | 18 | 22.5 |
| Hub inner radius (haal) | 9 | 9 (oforaendrad) |

### Swift-implementation

SVG:en baeddas in som en string och renderas med `NSImage(data:)`:

```swift
let svg = """
<svg ...>...</svg>
"""

guard let data = svg.data(using: .utf8),
      let image = NSImage(data: data) else { return nil }

// Template mode: ikonen tar foergfaergen fraan kontexten
// (vit i dark mode, svart i light mode)
image.isTemplate = true

// Saett oenskad storlek i points
image.size = NSSize(width: 14, height: 14)
```

### Storlekar som anvaends i Imperator Free Games

| Plats | Storlek | Beskrivning |
|---|---|---|
| Header (bredvid appnamnet) | 14px | Bredvid "Imperator Free Games" |
| Footer (bredvid Open Website) | 11px | Mindre variant i footer |

### Viktigt

- `isTemplate = true` aer nyckeln — det goer att macOS tonar ikonen automatiskt efter textfaergen i kontexten
- SVG:en har `fill="#000"` och `stroke="#000"` men template mode oeverskrider det
- Funkar med `NSImage` (AppKit) och `Image(nsImage:)` (SwiftUI)
- Kraever macOS 13+
