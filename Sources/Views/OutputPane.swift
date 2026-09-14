import SwiftUI

/// Bottom dock: the Dev-C++ "Compiler" tab plus a tab showing what the compiled
/// program prints (with stdin support).
struct OutputPane: View {
    enum Tab { case compiler, program }

    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var compiler: CompilerService
    @Environment(\.colorScheme) private var colorScheme
    @State private var tab: Tab = .compiler
    @State private var stdinText = ""
    @State private var autoScroll = true

    private var theme: EditorTheme { EditorTheme.current(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            switch tab {
            case .compiler: compilerTab
            case .program:  programTab
            }
        }
        .background(Color(nsColor: theme.consoleBackground))
        .onChange(of: compiler.lastBuildDate) { _, _ in tab = .compiler }
        .onChange(of: compiler.isRunning) { _, running in
            if running { tab = .program }
        }
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 0) {
            tabButton(settings.t(.consoleTabCompiler), symbol: "hammer", tab: .compiler)
            tabButton(settings.t(.consoleTabProgram), symbol: "terminal", tab: .program)
            Spacer()
            if compiler.isRunning {
                HStack(spacing: 4) {
                    ProgressView().controlSize(.small).scaleEffect(0.7)
                    Text(settings.t(.statusRunning))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 6)
            }
            if let code = compiler.lastExitCode {
                Text("\(settings.t(.consoleExitCode)) \(code)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(code == 0 ? Color.secondary : Color(nsColor: theme.error))
                    .padding(.trailing, 8)
            }
            ToolButton(symbol: "trash", tooltip: settings.t(.consoleClear)) { compiler.clearOutput() }
            ToolButton(symbol: "folder", tooltip: settings.t(.toolsOpenBuildFolder)) { compiler.revealOutputFolder() }
            ToolButton(symbol: "terminal", tooltip: settings.t(.execTerminal),
                       disabled: compiler.builtExecutable == nil) { AppActions.runInTerminal() }
            ToolButton(symbol: "stop.circle", tooltip: settings.t(.consoleStop),
                       disabled: !compiler.isRunning) { AppActions.stop() }
        }
        .padding(.horizontal, 6)
        .frame(height: 28)
        .background(Color.primary.opacity(0.04))
    }

    private func tabButton(_ title: String, symbol: String, tab target: Tab) -> some View {
        Button {
            tab = target
        } label: {
            HStack(spacing: 5) {
                Image(systemName: symbol).font(.system(size: 10))
                Text(title).font(.system(size: 11.5, weight: tab == target ? .semibold : .regular))
            }
            .foregroundStyle(tab == target ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(tab == target ? Color(nsColor: theme.consoleBackground) : Color.clear)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(tab == target ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: compiler tab

    private var compilerTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                if compiler.log.isEmpty && compiler.diagnostics.isEmpty {
                    Text(settings.t(.consoleIdle))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                ForEach(compiler.diagnostics) { diagnostic in
                    DiagnosticRow(diagnostic: diagnostic, theme: theme)
                }
                if !compiler.log.isEmpty {
                    Text(compiler.log)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(nsColor: theme.consoleText).opacity(0.75))
                        .textSelection(.enabled)
                        .padding(.top, compiler.diagnostics.isEmpty ? 0 : 6)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: program tab

    private var programTab: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(compiler.programOutput.isEmpty
                         ? settings.t(.consoleNoOutput)
                         : compiler.programOutput)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(nsColor: theme.consoleText))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .id("program-output-end")
                }
                .onChange(of: compiler.programOutput) { _, _ in
                    if autoScroll {
                        withAnimation(.linear(duration: 0.08)) {
                            proxy.scrollTo("program-output-end", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField(settings.t(.consoleStdin), text: $stdinText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .onSubmit { sendStdin() }
                Button(settings.t(.consoleSend)) { sendStdin() }
                    .controlSize(.small)
                    .disabled(!compiler.isRunning)
                Button(settings.t(.consoleEof)) { compiler.closeStdin() }
                    .controlSize(.small)
                    .disabled(!compiler.isRunning)
                Toggle("", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .help("Auto scroll")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
    }

    private func sendStdin() {
        guard compiler.isRunning, !stdinText.isEmpty else { return }
        compiler.sendStdin(stdinText)
        stdinText = ""
    }
}

struct DiagnosticRow: View {
    let diagnostic: Diagnostic
    let theme: EditorTheme
    @EnvironmentObject var workspace: Workspace
    @State private var hovering = false

    private var color: Color {
        switch diagnostic.severity {
        case .error, .fatal: return Color(nsColor: theme.error)
        case .warning:       return Color(nsColor: theme.warning)
        case .note:          return Color(nsColor: theme.note)
        }
    }

    private var symbol: String {
        switch diagnostic.severity {
        case .error, .fatal: return "xmark.octagon"
        case .warning:       return "exclamationmark.triangle"
        case .note:          return "info.circle"
        }
    }

    private var location: String {
        let name = diagnostic.shortFileName ?? "clang"
        return "\(name):\(diagnostic.line):\(diagnostic.column)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 10))
                .foregroundStyle(color)
                .padding(.top, 1)
            Text(location)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(color)
            Text(diagnostic.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color(nsColor: theme.consoleText))
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(hovering && diagnostic.filePath != nil ? Color.accentColor.opacity(0.12) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { jumpToLine() }
        .onHover { hovering = $0 }
        .help(diagnostic.filePath == nil ? diagnostic.raw : "\(diagnostic.filePath!):\(diagnostic.line)")
    }

    private func jumpToLine() {
        guard let path = diagnostic.filePath else { return }
        let url = URL(fileURLWithPath: path)
        workspace.open(urls: [url])
        EditorBridge.shared.pendingLine = diagnostic.line
        EditorBridge.shared.goTo(line: diagnostic.line)
    }
}
