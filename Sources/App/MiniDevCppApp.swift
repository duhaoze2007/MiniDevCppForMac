import SwiftUI
import AppKit

@main
struct MiniDevCppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var workspace = Workspace.shared
    @StateObject private var compiler = CompilerService.shared
    @StateObject private var ui = UIState.shared

    var body: some Scene {
        Window(settings.t(.appName), id: "main") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(workspace)
                .environmentObject(compiler)
                .environmentObject(ui)
        }
        // The menu bar is Dev-C++ 4.9.9.2's: File, Edit, Search, View, Project,
        // Execute, Tools, Window, Help. Each group is a separate `.commands`
        // block so no builder hits its item limit.
        .commands { appMenus }
        .commands { fileMenus }
        .commands { editMenus }
        .commands { searchMenus }
        .commands { viewMenus }
        .commands { projectMenus }
        .commands { executeMenus }
        .commands { toolMenus }
        .commands { helpMenus }
    }

    // MARK: - Application menu

    @CommandsBuilder
    private var appMenus: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(settings.t(.helpAbout)) { AppWindows.showAbout() }
        }
        CommandGroup(replacing: .appSettings) {
            Button(settings.t(.settingsTitle)) { AppWindows.showSettings() }
                .keyboardShortcut(",", modifiers: .command)
        }
    }

    // MARK: - File

    @CommandsBuilder
    private var fileMenus: some Commands {
        // AppKit adds its own Close/Close All items to this group; the File menu
        // already provides them (Dev-C++ has a single close entry).
        CommandGroup(replacing: .saveItem) { }
        CommandGroup(replacing: .newItem) {
            Button(settings.t(.fileNew)) { AppActions.newFile() }
                .keyboardShortcut("n", modifiers: .command)
            Button(settings.t(.fileOpen)) { AppActions.openFile() }
                .keyboardShortcut("o", modifiers: .command)
            Button(settings.t(.fileOpenFolder)) { AppActions.openFolder() }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            Divider()
            Button(settings.t(.fileSave)) { AppActions.save() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileSaveAs)) { AppActions.saveAs() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileSaveAll)) { AppActions.saveAll() }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .disabled(workspace.files.isEmpty)
            Divider()
            Button(settings.t(.fileClose)) { AppActions.closeFile() }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileCloseAll)) { AppActions.closeAll() }
                .keyboardShortcut("w", modifiers: [.command, .option])
                .disabled(workspace.files.isEmpty)
            Button(settings.t(.fileCloseProject)) { AppActions.closeProject() }
                .disabled(workspace.projectRoot == nil)
            Divider()
            Button(settings.t(.filePrint)) { AppActions.printDocument() }
                .keyboardShortcut("p", modifiers: .command)
        }
    }

    // MARK: - Edit

    @CommandsBuilder
    private var editMenus: some Commands {
        CommandGroup(replacing: .undoRedo) {
            Button(settings.t(.editUndo)) { AppActions.undo() }
                .keyboardShortcut("z", modifiers: .command)
            Button(settings.t(.editRedo)) { AppActions.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .pasteboard) {
            Button(settings.t(.editCut)) { AppActions.cut() }
                .keyboardShortcut("x", modifiers: .command)
            Button(settings.t(.editCopy)) { AppActions.copy() }
                .keyboardShortcut("c", modifiers: .command)
            Button(settings.t(.editPaste)) { AppActions.paste() }
                .keyboardShortcut("v", modifiers: .command)
            Button(settings.t(.editDelete)) { AppActions.delete() }
            Button(settings.t(.editSelectAll)) { AppActions.selectAll() }
                .keyboardShortcut("a", modifiers: .command)
        }
        CommandGroup(replacing: .textEditing) {
            Button(settings.t(.editToggleComment)) { AppActions.toggleComment() }
                .keyboardShortcut("/", modifiers: .command)
        }
    }

    // MARK: - Search

    @CommandsBuilder
    private var searchMenus: some Commands {
        CommandMenu(settings.t(.menuSearch)) {
            Button(settings.t(.searchFind)) { AppActions.find() }
                .keyboardShortcut("f", modifiers: .command)
            Button(settings.t(.searchFindNext)) { AppActions.findNext() }
                .keyboardShortcut("g", modifiers: .command)
            Button(settings.t(.searchFindPrev)) { AppActions.findPrevious() }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            Divider()
            Button(settings.t(.searchReplace)) { AppActions.replace() }
                .keyboardShortcut("f", modifiers: [.command, .option])
            Button(settings.t(.searchGoToLine)) { AppActions.goToLine() }
                .keyboardShortcut("l", modifiers: .command)
        }
    }

    // MARK: - View

    @CommandsBuilder
    private var viewMenus: some Commands {
        CommandGroup(replacing: .toolbar) {
            Button(settings.t(.viewProjectPane)) { settings.showProjectPane.toggle() }
                .keyboardShortcut("1", modifiers: .command)
            Button(settings.t(.viewOutputPane)) { settings.showConsole.toggle() }
                .keyboardShortcut("2", modifiers: .command)
            Divider()
            Toggle(settings.t(.viewLineNumbers), isOn: $settings.showLineNumbers)
            Toggle(settings.t(.viewWrapLines), isOn: $settings.wrapLines)
            Toggle(settings.t(.viewHighlight), isOn: $settings.highlight)
            Toggle(settings.t(.viewHighlightLine), isOn: $settings.highlightCurrentLine)
            Divider()
            Menu(settings.t(.viewAppearance)) {
                ForEach(AppTheme.allCases) { theme in
                    Toggle(settings.t(theme.lkey), isOn: Binding(
                        get: { settings.theme == theme },
                        set: { isOn in if isOn { settings.theme = theme } }
                    ))
                }
            }
            Menu(settings.t(.settingsFontSize)) {
                Button(settings.t(.viewFontBigger)) { AppActions.biggerFont() }
                    .keyboardShortcut("+", modifiers: .command)
                Button(settings.t(.viewFontSmaller)) { AppActions.smallerFont() }
                    .keyboardShortcut("-", modifiers: .command)
                Divider()
                Button(settings.t(.viewFontReset)) { AppActions.resetFont() }
            }
            Button(settings.t(.viewFullScreen)) { AppActions.toggleFullScreen() }
                .keyboardShortcut("f", modifiers: [.command, .control])
        }
    }

    // MARK: - Project

    @CommandsBuilder
    private var projectMenus: some Commands {
        CommandMenu(settings.t(.menuProject)) {
            Button(settings.t(.projectOpenFolder)) { AppActions.openFolder() }
            Button(settings.t(.projectReload)) { AppActions.reloadProject() }
                .disabled(workspace.projectRoot == nil)
            Divider()
            Button(settings.t(.projectNewFile)) { AppActions.newFile() }
            Button(settings.t(.projectShowInFinder)) { AppActions.revealInFinder() }
        }
    }

    // MARK: - Execute

    @CommandsBuilder
    private var executeMenus: some Commands {
        CommandMenu(settings.t(.menuExecute)) {
            Button(settings.t(.execCompile)) { AppActions.compile() }
                .keyboardShortcut("b", modifiers: .command)
                .disabled(compiler.isBuilding)
            Button(settings.t(.execRebuild)) { AppActions.compile() }
                .keyboardShortcut("b", modifiers: [.command, .shift])
                .disabled(compiler.isBuilding)
            Button(settings.t(.execRun)) { AppActions.run() }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(compiler.isRunning)
            Button(settings.t(.execCompileRun)) { AppActions.compileAndRun() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(compiler.isBuilding)
            Divider()
            Button(settings.t(.execStop)) { AppActions.stop() }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!compiler.isRunning)
            Button(settings.t(.execTerminal)) { AppActions.runInTerminal() }
                .disabled(compiler.builtExecutable == nil)
            Divider()
            Button(settings.t(.execParameters)) { AppActions.showRunParameters() }
            Button(settings.t(.execClean)) { AppActions.clean() }
        }
    }

    // MARK: - Tools

    @CommandsBuilder
    private var toolMenus: some Commands {
        CommandMenu(settings.t(.menuTools)) {
            Button(settings.t(.toolsEditorOptions)) { AppWindows.showSettings() }
            Button(settings.t(.toolsCompilerOptions)) { AppWindows.showSettings() }
            Divider()
            Button(settings.t(.toolsClearConsole)) { AppActions.clearOutput() }
            Button(settings.t(.toolsOpenBuildFolder)) { AppActions.revealOutput() }
        }
    }

    // MARK: - Help

    @CommandsBuilder
    private var helpMenus: some Commands {
        CommandGroup(replacing: .help) {
            Button(settings.t(.helpUsage)) { AppWindows.showHelp() }
                .keyboardShortcut("?", modifiers: .command)
            Button(settings.t(.helpAbout)) { AppWindows.showAbout() }
        }
    }
}

// MARK: - Application delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        AppSettings.shared.applyTheme()
        AppSettings.shared.applyLanguagePreference()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showFirstLaunchDialogsIfNeeded()
        }
    }

    /// Closing the last window quits the app, like Dev-C++.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        for file in Workspace.shared.files where file.isDirty {
            switch Dialogs.confirmUnsaved(name: file.displayName, settings: AppSettings.shared) {
            case .cancel:
                return .terminateCancel
            case .save:
                if !Workspace.shared.save(file) { return .terminateCancel }
            case .discard:
                break
            }
        }
        return .terminateNow
    }

    // MARK: first launch

    private func showFirstLaunchDialogsIfNeeded() {
        // Only for real installs in /Applications: development launches stay quiet.
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        let key = "MiniDevCpp_FirstRun_" + Bundle.main.bundlePath
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let settings = AppSettings.shared
        let agreedCopyright = agreementAlert(title: settings.t(.flTitle),
                                            body: settings.t(.flBody),
                                            agree: settings.t(.btnAgree),
                                            disagree: settings.t(.btnDisagree),
                                            symbol: "c.circle")
        guard agreedCopyright else { NSApp.terminate(nil); return }

        let agreedPrivacy = agreementAlert(title: settings.t(.flPrivacyTitle),
                                           body: settings.t(.flBody2),
                                           agree: settings.t(.btnAgree),
                                           disagree: settings.t(.btnDisagree),
                                           symbol: "hand.raised")
        guard agreedPrivacy else { NSApp.terminate(nil); return }

        UserDefaults.standard.set(true, forKey: key)
    }

    private func agreementAlert(title: String,
                                body: String,
                                agree: String,
                                disagree: String,
                                symbol: String) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = ""
        alert.icon = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 480, height: 250))
        textView.string = body
        textView.isEditable = false
        textView.isSelectable = true
        textView.alignment = .left
        textView.font = .systemFont(ofSize: 12)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 480, height: 250))
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        alert.accessoryView = scrollView

        alert.addButton(withTitle: agree)
        alert.addButton(withTitle: disagree)
        return alert.runModal() == .alertFirstButtonReturn
    }
}
