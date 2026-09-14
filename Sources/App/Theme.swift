import SwiftUI
import AppKit

/// Editor palette. The light variant replicates the shipped Dev-C++ 4.9.9.2
/// defaults (white paper, bold blue reserved words, navy preprocessor lines and
/// strings, grey comments); the dark variant is the same scheme adapted for a
/// dark background.
struct EditorTheme {
    let id: String
    let background: NSColor
    let text: NSColor
    let keyword: NSColor
    let preprocessor: NSColor
    let comment: NSColor
    let string: NSColor
    let number: NSColor

    let gutterBackground: NSColor
    let gutterText: NSColor
    let gutterSeparator: NSColor

    let caret: NSColor
    let selection: NSColor
    let currentLine: NSColor

    let consoleBackground: NSColor
    let consoleText: NSColor
    let error: NSColor
    let warning: NSColor
    let note: NSColor

    // MARK: fonts

    static func monoFont(size: CGFloat) -> NSFont {
        NSFont(name: "Menlo", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func monoBoldFont(size: CGFloat) -> NSFont {
        NSFont(name: "Menlo-Bold", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
    }

    // MARK: schemes

    static let classicLight = EditorTheme(
        id: "classic-light",
        background: .white,
        text: NSColor(calibratedWhite: 0.0, alpha: 1),
        keyword: NSColor(calibratedRed: 0, green: 0, blue: 1, alpha: 1),
        preprocessor: NSColor(calibratedRed: 0, green: 0, blue: 0.5, alpha: 1),
        comment: NSColor(calibratedWhite: 0.5, alpha: 1),
        string: NSColor(calibratedRed: 0, green: 0, blue: 0.5, alpha: 1),
        number: NSColor(calibratedWhite: 0.0, alpha: 1),
        gutterBackground: NSColor(calibratedWhite: 0.94, alpha: 1),
        gutterText: NSColor(calibratedWhite: 0.45, alpha: 1),
        gutterSeparator: NSColor(calibratedWhite: 0.80, alpha: 1),
        caret: NSColor(calibratedWhite: 0.0, alpha: 1),
        selection: NSColor(calibratedRed: 0.70, green: 0.80, blue: 0.95, alpha: 1),
        currentLine: NSColor(calibratedWhite: 0.0, alpha: 0.05),
        consoleBackground: .white,
        consoleText: NSColor(calibratedWhite: 0.10, alpha: 1),
        error: NSColor(calibratedRed: 0.75, green: 0.0, blue: 0.0, alpha: 1),
        warning: NSColor(calibratedRed: 0.62, green: 0.38, blue: 0.0, alpha: 1),
        note: NSColor(calibratedRed: 0.0, green: 0.35, blue: 0.55, alpha: 1)
    )

    static let classicDark = EditorTheme(
        id: "classic-dark",
        background: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 1),
        text: NSColor(calibratedWhite: 0.86, alpha: 1),
        keyword: NSColor(calibratedRed: 0.42, green: 0.61, blue: 0.91, alpha: 1),
        preprocessor: NSColor(calibratedRed: 0.56, green: 0.74, blue: 0.94, alpha: 1),
        comment: NSColor(calibratedRed: 0.53, green: 0.60, blue: 0.44, alpha: 1),
        string: NSColor(calibratedRed: 0.85, green: 0.65, blue: 0.45, alpha: 1),
        number: NSColor(calibratedRed: 0.72, green: 0.81, blue: 0.66, alpha: 1),
        gutterBackground: NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.16, alpha: 1),
        gutterText: NSColor(calibratedWhite: 0.52, alpha: 1),
        gutterSeparator: NSColor(calibratedWhite: 0.26, alpha: 1),
        caret: NSColor(calibratedWhite: 0.90, alpha: 1),
        selection: NSColor(calibratedRed: 0.20, green: 0.34, blue: 0.53, alpha: 1),
        currentLine: NSColor(calibratedWhite: 1.0, alpha: 0.05),
        consoleBackground: NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.11, alpha: 1),
        consoleText: NSColor(calibratedWhite: 0.85, alpha: 1),
        error: NSColor(calibratedRed: 0.96, green: 0.53, blue: 0.44, alpha: 1),
        warning: NSColor(calibratedRed: 0.86, green: 0.78, blue: 0.42, alpha: 1),
        note: NSColor(calibratedRed: 0.44, green: 0.75, blue: 0.92, alpha: 1)
    )

    static func current(_ scheme: ColorScheme) -> EditorTheme {
        scheme == .dark ? .classicDark : .classicLight
    }
}
