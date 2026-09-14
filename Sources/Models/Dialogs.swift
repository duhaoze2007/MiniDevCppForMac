import SwiftUI
import AppKit

// MARK: - Dialogs (left aligned, comfortably wide, matching the app's style)

@MainActor
enum Dialogs {

    enum UnsavedChoice { case save, discard, cancel }

    private static let bodyWidth: CGFloat = 460

    private static func bodyField(_ text: String) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.alignment = .left
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 0
        field.preferredMaxLayoutWidth = bodyWidth
        field.frame = NSRect(x: 0, y: 0, width: bodyWidth, height: 0)
        field.sizeToFit()
        return field
    }

    static func confirmUnsaved(name: String, settings: AppSettings) -> UnsavedChoice {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = settings.t(.msgUnsavedTitle)
        alert.informativeText = ""
        alert.accessoryView = bodyField(settings.t(.msgUnsavedBody, name))
        alert.addButton(withTitle: settings.t(.btnSave))
        alert.addButton(withTitle: settings.t(.btnDiscard))
        alert.addButton(withTitle: settings.t(.btnCancel))
        alert.icon = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: nil)
        switch alert.runModal() {
        case .alertFirstButtonReturn:  return .save
        case .alertSecondButtonReturn: return .discard
        default:                       return .cancel
        }
    }

    static func info(title: String, body: String, icon: String = "info.circle") {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = ""
        alert.accessoryView = bodyField(body)
        alert.addButton(withTitle: "OK")
        alert.icon = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        alert.runModal()
    }

    static func error(title: String, body: String) {
        info(title: title, body: body, icon: "exclamationmark.octagon")
    }
}
