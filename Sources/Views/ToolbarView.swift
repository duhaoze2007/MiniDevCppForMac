import SwiftUI

struct ToolButton: View {
    let symbol: String
    let tooltip: String
    var disabled: Bool = false
    var active: Bool = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .frame(width: 30, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.18)
                              : (hovering && !disabled ? Color.primary.opacity(0.10) : Color.clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(disabled ? Color.secondary.opacity(0.45) : Color.primary)
        .disabled(disabled)
        .help(tooltip)
        .onHover { hovering = $0 }
    }
}

/// Dev-C++ style command bar: file group, build group, tools group.
struct ToolbarView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace
    @EnvironmentObject var compiler: CompilerService
    @EnvironmentObject var ui: UIState

    private var hasFile: Bool { workspace.activeFile != nil }
    private var busy: Bool { compiler.isBuilding }

    var body: some View {
        HStack(spacing: 3) {
            ToolButton(symbol: "doc.badge.plus", tooltip: settings.t(.tbNew)) { AppActions.newFile() }
            ToolButton(symbol: "folder", tooltip: settings.t(.tbOpen)) { AppActions.openFile() }
            ToolButton(symbol: "folder.badge.plus", tooltip: settings.t(.tbOpenFolder)) { AppActions.openFolder() }

            separator

            ToolButton(symbol: "square.and.arrow.down", tooltip: settings.t(.tbSave),
                       disabled: !hasFile) { AppActions.save() }
            ToolButton(symbol: "square.and.arrow.down.on.square", tooltip: settings.t(.tbSaveAll),
                       disabled: !hasFile) { AppActions.saveAll() }
            ToolButton(symbol: "xmark.square", tooltip: settings.t(.tbClose),
                       disabled: !hasFile) { AppActions.closeFile() }

            separator

            ToolButton(symbol: "hammer", tooltip: settings.t(.tbCompile),
                       disabled: busy) { AppActions.compile() }
            ToolButton(symbol: "play", tooltip: settings.t(.tbRun),
                       disabled: compiler.isRunning) { AppActions.run() }
            ToolButton(symbol: "play.circle", tooltip: settings.t(.tbCompileRun),
                       disabled: busy) { AppActions.compileAndRun() }
            ToolButton(symbol: "arrow.triangle.2.circlepath", tooltip: settings.t(.tbRebuild),
                       disabled: busy) { AppActions.compile() }
            ToolButton(symbol: "stop.circle", tooltip: settings.t(.tbStop),
                       disabled: !compiler.isRunning) { AppActions.stop() }

            separator

            ToolButton(symbol: "magnifyingglass", tooltip: settings.t(.tbFind)) { AppActions.find() }
            ToolButton(symbol: "slider.horizontal.3", tooltip: settings.t(.tbParameters)) { ui.showRunParameters = true }
            ToolButton(symbol: "terminal", tooltip: settings.t(.tbTerminal),
                       disabled: compiler.builtExecutable == nil) { AppActions.runInTerminal() }

            Spacer(minLength: 12)

            if compiler.isBuilding {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
            }

            ToolButton(symbol: settings.showProjectPane ? "sidebar.left" : "sidebar.leading",
                       tooltip: settings.t(.viewProjectPane),
                       active: settings.showProjectPane) {
                settings.showProjectPane.toggle()
            }
            ToolButton(symbol: "rectangle.bottomthird.inset.filled",
                       tooltip: settings.t(.viewOutputPane),
                       active: settings.showConsole) {
                settings.showConsole.toggle()
            }
            ToolButton(symbol: "gearshape", tooltip: settings.t(.tbOptions)) { AppWindows.showSettings() }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1, height: 16)
            .padding(.horizontal, 4)
    }
}
