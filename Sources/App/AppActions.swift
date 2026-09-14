import SwiftUI
import AppKit

/// Small pieces of transient UI state shared by the menus and the toolbar.
@MainActor
final class UIState: ObservableObject {
    static let shared = UIState()
    @Published var showRunParameters = false
    private init() {}
}

/// Every command the menus and toolbar can trigger.
@MainActor
enum AppActions {

    // MARK: file

    static func newFile() { Workspace.shared.newFile() }
    static func openFile() { Workspace.shared.openFromPanel() }
    static func openFolder() { Workspace.shared.openFolderFromPanel() }
    static func save() { Workspace.shared.saveActive() }
    static func saveAs() {
        guard let file = Workspace.shared.activeFile else { return }
        _ = Workspace.shared.saveAs(file)
    }
    static func saveAll() { Workspace.shared.saveAll() }
    static func closeFile() { Workspace.shared.closeActive() }
    static func closeAll() { Workspace.shared.closeAll() }
    static func closeProject() { Workspace.shared.closeProject() }
    static func reloadProject() { Workspace.shared.reloadProject() }
    static func revealInFinder() { Workspace.shared.revealInFinder() }
    static func printDocument() { EditorBridge.shared.textView?.printView(nil) }

    // MARK: edit

    static func undo() { send("undo:") }
    static func redo() { send("redo:") }
    static func cut() { send("cut:") }
    static func copy() { send("copy:") }
    static func paste() { send("paste:") }
    static func delete() { send("delete:") }
    static func selectAll() { send("selectAll:") }
    static func toggleComment() { EditorBridge.shared.toggleComment() }

    private static func send(_ selectorName: String) {
        NSApp.sendAction(Selector(selectorName), to: nil, from: nil)
    }

    // MARK: search

    private final class FindSender: NSObject, NSValidatedUserInterfaceItem {
        let tag: Int
        init(_ action: NSTextFinder.Action) { self.tag = action.rawValue }
        var action: Selector? { nil }
    }

    private static func findPanel(_ action: NSTextFinder.Action) {
        EditorBridge.shared.focus()
        NSApp.sendAction(#selector(NSTextView.performTextFinderAction(_:)), to: nil, from: FindSender(action))
    }

    static func find() { findPanel(.showFindInterface) }
    static func replace() { findPanel(.showReplaceInterface) }
    static func findNext() { findPanel(.nextMatch) }
    static func findPrevious() { findPanel(.previousMatch) }

    static func goToLine() {
        let settings = AppSettings.shared
        let alert = NSAlert()
        alert.messageText = settings.t(.gotoTitle)
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.alignment = .left
        field.placeholderString = settings.t(.gotoLabel)
        alert.accessoryView = field
        alert.addButton(withTitle: settings.t(.gotoOK))
        alert.addButton(withTitle: settings.t(.btnCancel))
        alert.window.initialFirstResponder = field
        if alert.runModal() == .alertFirstButtonReturn {
            let raw = field.stringValue.trimmingCharacters(in: .whitespaces)
            if let line = Int(raw), line >= 1 {
                EditorBridge.shared.goTo(line: line)
            } else {
                Dialogs.info(title: settings.t(.gotoTitle), body: settings.t(.msgInvalidLine))
            }
        }
    }

    // MARK: execute

    static func compile() { CompilerService.shared.compile() }
    static func compileAndRun() { CompilerService.shared.compile(runAfter: true) }
    static func run() { CompilerService.shared.run() }
    static func clean() { CompilerService.shared.clean() }
    static func stop() { CompilerService.shared.stop() }
    static func runInTerminal() { CompilerService.shared.runInTerminal() }
    static func clearOutput() { CompilerService.shared.clearOutput() }
    static func revealOutput() { CompilerService.shared.revealOutputFolder() }
    static func showRunParameters() { UIState.shared.showRunParameters = true }

    // MARK: view

    static func biggerFont() { AppSettings.shared.fontSize = min(30, AppSettings.shared.fontSize + 1) }
    static func smallerFont() { AppSettings.shared.fontSize = max(9, AppSettings.shared.fontSize - 1) }
    static func resetFont() { AppSettings.shared.fontSize = 13 }
    static func toggleFullScreen() { NSApp.keyWindow?.toggleFullScreen(nil) }
    static func setTheme(_ theme: AppTheme) { AppSettings.shared.theme = theme }

    // MARK: windows

    static func showAbout() { AppWindows.showAbout() }
    static func showSettings() { AppWindows.showSettings() }
    static func showHelp() { AppWindows.showHelp() }
}
