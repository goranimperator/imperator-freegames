import AppKit
import SwiftUI

enum SigilIcon {
    private static let svgString = """
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
    """

    static func menuBarImage() -> NSImage? {
        guard let data = svgString.data(using: .utf8),
              let image = NSImage(data: data) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    private static let svgThin = """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="-80 -80 160 160">
      <defs>
        <g id="u">
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
      <g fill="#000">
        <use href="#u" />
        <use href="#u" transform="rotate(120)" />
        <use href="#u" transform="rotate(240)" />
        <path fill-rule="evenodd" d="
          M 18 0 A 18 18 0 1 0 -18 0 A 18 18 0 1 0 18 0 Z
          M 9 0 A 9 9 0 1 0 -9 0 A 9 9 0 1 0 9 0 Z
        " />
      </g>
    </svg>
    """

    static func headerImage(size: CGFloat = 16) -> NSImage? {
        guard let data = svgString.data(using: .utf8),
              let image = NSImage(data: data) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: size, height: size)
        return image
    }

    private static let gamepadSvg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="6" x2="10" y1="12" y2="12"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="15" x2="15.01" y1="13" y2="13"/><line x1="18" x2="18.01" y1="11" y2="11"/><rect width="20" height="12" x="2" y="6" rx="2"/></svg>
    """

    static func gamepadImage(size: CGFloat = 16) -> NSImage? {
        guard let data = gamepadSvg.data(using: .utf8),
              let image = NSImage(data: data) else { return nil }
        image.isTemplate = true
        image.size = NSSize(width: size, height: size)
        return image
    }
}
