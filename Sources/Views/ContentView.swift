import SwiftUI
import AppKit

// MARK: - Main window layout (Dev-C++ arrangement: toolbar, explorer, editor, output, status)

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace
    @EnvironmentObject var compiler: CompilerService
    @EnvironmentObject var ui: UIState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView()
            Divider()
            HSplitView {
                if settings.showProjectPane {
                    ProjectPane()
                        .frame(minWidth: 150, idealWidth: 215, maxWidth: 420)
                }
                VSplitView {
                    EditorArea()
                        .frame(minWidth: 320, minHeight: 160)
                    if settings.showConsole {
                        OutputPane()
                            .frame(minHeight: 96, idealHeight: 180, maxHeight: 520)
                    }
                }
                .frame(minWidth: 320)
            }
            Divider()
            StatusBarView()
        }
        .frame(minWidth: 880, minHeight: 560)
        .background(WindowConfigurator(title: workspace.windowTitle))
        .sheet(isPresented: $ui.showRunParameters) {
            RunParametersView(isPresented: $ui.showRunParameters)
                .environmentObject(settings)
        }
        .onAppear {
            if workspace.files.isEmpty {
                workspace.newFile()
            }
        }
    }
}

/// Keeps the window title and minimum size in sync (SPM builds cannot use
/// `.defaultSize`/`.windowStyle` safely).
struct WindowConfigurator: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView.window)
        }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        if window.title != title { window.title = title }
        window.minSize = NSSize(width: 880, height: 560)
        window.isRestorable = false
    }
}

// MARK: - Editor area: tab strip + code editor

struct EditorArea: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if !workspace.files.isEmpty {
                EditorTabBar()
                Divider()
            }
            if let file = workspace.activeFile {
                EditorView(file: file,
                           settings: settings,
                           theme: EditorTheme.current(colorScheme))
            } else {
                WelcomePane()
            }
        }
        .background(Color(nsColor: EditorTheme.current(colorScheme).background))
    }
}

struct EditorTabBar: View {
    @EnvironmentObject var workspace: Workspace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(workspace.files) { file in
                    EditorTab(file: file, isActive: workspace.activeID == file.id)
                }
            }
        }
        .frame(height: 29)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct EditorTab: View {
    @ObservedObject var file: SourceFile
    @EnvironmentObject var workspace: Workspace
    let isActive: Bool
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: file.isCHeader ? "h.square" : "doc.text")
                .font(.system(size: 10))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            Text(file.displayName)
                .font(.system(size: 12))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
            if file.isDirty {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
            }
            Button {
                _ = workspace.close(file)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(hovering || isActive ? 1 : 0)
            .help("Close")
        }
        .padding(.horizontal, 9)
        .frame(height: 28)
        .background(isActive ? Color(nsColor: .textBackgroundColor) : (hovering ? Color.primary.opacity(0.05) : Color.clear))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(isActive ? Color.accentColor : Color.clear)
                .frame(height: 2)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1, height: 16)
        }
        .contentShape(Rectangle())
        .onTapGesture { workspace.select(file) }
        .onHover { hovering = $0 }
    }
}

struct WelcomePane: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text(settings.t(.welcomeTitle))
                .font(.system(size: 15, weight: .medium))
            Text(settings.t(.welcomeHint))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                Button(settings.t(.welcomeNew)) { workspace.newFile() }
                Button(settings.t(.welcomeOpen)) { workspace.openFromPanel() }
            }
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}

// MARK: - Status bar

struct StatusBarView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace
    @EnvironmentObject var compiler: CompilerService

    var body: some View {
        HStack(spacing: 14) {
            if let file = workspace.activeFile {
                CursorInfo(file: file, settings: settings)
            } else {
                Text(settings.t(.statusNoFile))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Divider().frame(height: 12)
            Text(compilerStatus)
                .font(.system(size: 11))
                .foregroundStyle(compiler.buildSucceeded == false ? Color(nsColor: .systemRed) : .secondary)
                .lineLimit(1)
            Spacer(minLength: 8)
            if !compiler.diagnostics.isEmpty {
                Text(settings.t(.statusProblems, compiler.errorCount, compiler.warningCount))
                    .font(.system(size: 11))
                    .foregroundStyle(compiler.errorCount > 0 ? Color(nsColor: .systemRed) : .secondary)
            }
            Text(settings.t(.settingsCompiler) + ": clang")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var compilerStatus: String {
        if compiler.isBuilding { return settings.t(.statusCompiling) }
        if compiler.isRunning { return settings.t(.statusRunning) }
        return compiler.statusMessage.isEmpty ? settings.t(.statusReady) : compiler.statusMessage
    }
}

struct CursorInfo: View {
    @ObservedObject var file: SourceFile
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            Text("\(settings.t(.statusLine)) \(file.cursorLine), \(settings.t(.statusColumn)) \(file.cursorColumn)")
                .font(.system(size: 11))
                .monospacedDigit()
            if file.selectionLength > 0 {
                Text("\(settings.t(.statusSel)) \(file.selectionLength)")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            if file.isDirty {
                Text(settings.t(.statusModified))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .foregroundStyle(.primary)
    }
}
