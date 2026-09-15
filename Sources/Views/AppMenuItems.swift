import SwiftUI
import AppKit

// The command sets behind the menus. Both the macOS menu bar (`.commands`) and
// the in-window Dev-C++ style menu bar render these same views, so the two can
// never drift apart.

struct AppMenuFileItems: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var workspace: Workspace

    var body: some View {
        Group {
            Button(settings.t(.fileNew)) { AppActions.newFile() }
                .keyboardShortcut("n", modifiers: .command)
            Button(settings.t(.fileOpen)) { AppActions.openFile() }
                .keyboardShortcut("o", modifiers: .command)
            Button(settings.t(.fileOpenFolder)) { AppActions.openFolder() }
                .keyboardShortcut("o", modifiers: [.command, .shift])
        }
        Divider()
        Group {
            Button(settings.t(.fileSave)) { AppActions.save() }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileSaveAs)) { AppActions.saveAs() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileSaveAll)) { AppActions.saveAll() }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .disabled(workspace.files.isEmpty)
        }
        Divider()
        Group {
            Button(settings.t(.fileClose)) { AppActions.closeFile() }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(workspace.activeFile == nil)
            Button(settings.t(.fileCloseAll)) { AppActions.closeAll() }
                .keyboardShortcut("w", modifiers: [.command, .option])
                .disabled(workspace.files.isEmpty)
            Button(settings.t(.fileCloseProject)) { AppActions.closeProject() }
                .disabled(workspace.projectRoot == nil)
        }
        Divider()
        Button(settings.t(.filePrint)) { AppActions.printDocument() }
            .keyboardShortcut("p", modifiers: .command)
    }
}

struct AppMenuEditItems: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Group {
            Button(settings.t(.editUndo)) { AppActions.undo() }
                .keyboardShortcut("z", modifiers: .command)
            Button(settings.t(.editRedo)) { AppActions.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        Divider()
        Group {
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
        Divider()
        Button(settings.t(.editToggleComment)) { AppActions.toggleComment() }
            .keyboardShortcut("/", modifiers: .command)
    }
}

struct AppMenuSearchItems: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Group {
            Button(settings.t(.searchFind)) { AppActions.find() }
                .keyboardShortcut("f", modifiers: .command)
            Button(settings.t(.searchFindNext)) { AppActions.findNext() }
                .keyboardShortcut("g", modifiers: .command)
            Button(settings.t(.searchFindPrev)) { AppActions.findPrevious() }
                .keyboardShortcut("g", modifiers: [.command, .shift])
        }
        Divider()
        Button(settings.t(.searchReplace)) { AppActions.replace() }
            .keyboardShortcut("f", modifiers: [.command, .option])
        Button(settings.t(.searchGoToLine)) { AppActions.goToLine() }
            .keyboardShortcut("l", modifiers: .command)
    }
}

struct AppMenuViewItems: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Button(settings.t(.viewProjectPane)) { settings.showProjectPane.toggle() }
            .keyboardShortcut("1", modifiers: .command)
        Button(settings.t(.viewOutputPane)) { settings.showConsole.toggle() }
            .keyboardShortcut("2", modifiers: .command)
        Button(settings.t(.viewToolbarLabels)) { settings.showToolbarLabels.toggle() }
        Divider()
        Group {
            Toggle(settings.t(.viewLineNumbers), isOn: $settings.showLineNumbers)
            Toggle(settings.t(.viewWrapLines), isOn: $settings.wrapLines)
            Toggle(settings.t(.viewHighlight), isOn: $settings.highlight)
            Toggle(settings.t(.viewHighlightLine), isOn: $settings.highlightCurrentLine)
        }
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

struct AppMenuProjectItems: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var workspace: Workspace

    var body: some View {
        Button(settings.t(.projectOpenFolder)) { AppActions.openFolder() }
        Button(settings.t(.projectReload)) { AppActions.reloadProject() }
            .disabled(workspace.projectRoot == nil)
        Divider()
        Button(settings.t(.projectNewFile)) { AppActions.newFile() }
        Button(settings.t(.projectShowInFinder)) { AppActions.revealInFinder() }
    }
}

struct AppMenuExecuteItems: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var compiler: CompilerService

    var body: some View {
        Group {
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
        }
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

struct AppMenuToolsItems: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Button(settings.t(.toolsEditorOptions)) { AppWindows.showSettings() }
        Button(settings.t(.toolsCompilerOptions)) { AppWindows.showSettings() }
        Divider()
        Button(settings.t(.toolsClearConsole)) { AppActions.clearOutput() }
        Button(settings.t(.toolsOpenBuildFolder)) { AppActions.revealOutput() }
    }
}

struct AppMenuHelpItems: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Button(settings.t(.helpUsage)) { AppWindows.showHelp() }
            .keyboardShortcut("?", modifiers: .command)
        Button(settings.t(.helpAbout)) { AppWindows.showAbout() }
    }
}
