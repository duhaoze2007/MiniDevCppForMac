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
        // Dev-C++'s menu bar: File, Edit, Search, View, Project, Execute, Tools,
        // Window, Help. The command sets live in AppMenuItems.swift and are shared
        // with the in-window menu bar. Each group is a separate `.commands` block
        // so no builder hits its item limit.
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
            AppMenuFileItems(settings: settings, workspace: workspace)
        }
    }

    // MARK: - Edit

    @CommandsBuilder
    private var editMenus: some Commands {
        CommandGroup(replacing: .undoRedo) { }
        CommandGroup(replacing: .pasteboard) {
            AppMenuEditItems(settings: settings)
        }
        CommandGroup(replacing: .textEditing) { }
    }

    // MARK: - Search

    @CommandsBuilder
    private var searchMenus: some Commands {
        CommandMenu(settings.t(.menuSearch)) {
            AppMenuSearchItems(settings: settings)
        }
    }

    // MARK: - View

    @CommandsBuilder
    private var viewMenus: some Commands {
        CommandGroup(replacing: .toolbar) {
            AppMenuViewItems(settings: settings)
        }
    }

    // MARK: - Project

    @CommandsBuilder
    private var projectMenus: some Commands {
        CommandMenu(settings.t(.menuProject)) {
            AppMenuProjectItems(settings: settings, workspace: workspace)
        }
    }

    // MARK: - Execute

    @CommandsBuilder
    private var executeMenus: some Commands {
        CommandMenu(settings.t(.menuExecute)) {
            AppMenuExecuteItems(settings: settings, compiler: compiler)
        }
    }

    // MARK: - Tools

    @CommandsBuilder
    private var toolMenus: some Commands {
        CommandMenu(settings.t(.menuTools)) {
            AppMenuToolsItems(settings: settings)
        }
    }

    // MARK: - Help

    @CommandsBuilder
    private var helpMenus: some Commands {
        CommandGroup(replacing: .help) {
            AppMenuHelpItems(settings: settings)
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
        openCommandLinePaths()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showFirstLaunchDialogsIfNeeded()
        }
    }

    /// Dev-C++ opens the file it is handed (a double-clicked .c file, a folder,
    /// or paths on the command line). Same here.
    func application(_ application: NSApplication, open urls: [URL]) {
        handle(urls)
    }

    private func openCommandLinePaths() {
        let paths = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
        let urls = paths.map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
        if !urls.isEmpty { handle(urls) }
    }

    private func handle(_ urls: [URL]) {
        var files: [URL] = []
        for url in urls {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory || url.hasDirectoryPath {
                Workspace.shared.loadProject(url)
            } else {
                files.append(url)
            }
        }
        if !files.isEmpty { Workspace.shared.open(urls: files) }
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
