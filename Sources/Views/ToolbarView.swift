import SwiftUI

/// A toolbar button: an SF Symbol with an optional caption underneath, like the
/// labelled command bars in classic Windows IDEs.
struct ToolButton: View {
    let symbol: String
    let tooltip: String
    var caption: String?
    var disabled: Bool = false
    var active: Bool = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                if let caption {
                    Text(caption)
                        .font(.system(size: 9.5))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .frame(minWidth: caption == nil ? 28 : 30)
            .padding(.horizontal, caption == nil ? 3 : 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(active ? Color.accentColor.opacity(0.20)
                          : (hovering && !disabled ? Color.primary.opacity(0.10) : Color.clear))
            )
            .foregroundStyle(disabled ? Color.secondary.opacity(0.45) : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .help(tooltip)
        .onHover { hovering = $0 }
    }
}

/// Dev-C++ style command bar: file group, build group, tools group — each button
/// captioned with its command name (can be switched off in the View menu).
struct ToolbarView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace
    @EnvironmentObject var compiler: CompilerService
    @EnvironmentObject var ui: UIState

    private var hasFile: Bool { workspace.activeFile != nil }
    private var busy: Bool { compiler.isBuilding }
    private var labels: Bool { settings.showToolbarLabels }

    var body: some View {
        HStack(spacing: 2) {
            ToolButton(symbol: "doc.badge.plus", tooltip: settings.t(.tbNew),
                       caption: caption(.btNew)) { AppActions.newFile() }
            ToolButton(symbol: "folder", tooltip: settings.t(.tbOpen),
                       caption: caption(.btOpen)) { AppActions.openFile() }
            ToolButton(symbol: "folder.badge.plus", tooltip: settings.t(.tbOpenFolder),
                       caption: caption(.btOpenFolder)) { AppActions.openFolder() }

            separator

            ToolButton(symbol: "square.and.arrow.down", tooltip: settings.t(.tbSave),
                       caption: caption(.btSave), disabled: !hasFile) { AppActions.save() }
            ToolButton(symbol: "square.and.arrow.down.on.square", tooltip: settings.t(.tbSaveAll),
                       caption: caption(.btSaveAll), disabled: !hasFile) { AppActions.saveAll() }
            ToolButton(symbol: "xmark.square", tooltip: settings.t(.tbClose),
                       caption: caption(.btClose), disabled: !hasFile) { AppActions.closeFile() }

            separator

            ToolButton(symbol: "hammer", tooltip: settings.t(.tbCompile),
                       caption: caption(.btCompile), disabled: busy) { AppActions.compile() }
            ToolButton(symbol: "play", tooltip: settings.t(.tbRun),
                       caption: caption(.btRun), disabled: compiler.isRunning) { AppActions.run() }
            ToolButton(symbol: "play.circle", tooltip: settings.t(.tbCompileRun),
                       caption: caption(.btCompileRun), disabled: busy) { AppActions.compileAndRun() }
            ToolButton(symbol: "arrow.triangle.2.circlepath", tooltip: settings.t(.tbRebuild),
                       caption: caption(.btRebuild), disabled: busy) { AppActions.compile() }
            ToolButton(symbol: "stop.circle", tooltip: settings.t(.tbStop),
                       caption: caption(.btStop), disabled: !compiler.isRunning) { AppActions.stop() }

            separator

            ToolButton(symbol: "magnifyingglass", tooltip: settings.t(.tbFind),
                       caption: caption(.btFind)) { AppActions.find() }
            ToolButton(symbol: "slider.horizontal.3", tooltip: settings.t(.tbParameters),
                       caption: caption(.btParams)) { ui.showRunParameters = true }
            ToolButton(symbol: "terminal", tooltip: settings.t(.tbTerminal),
                       caption: caption(.btTerminal),
                       disabled: compiler.builtExecutable == nil) { AppActions.runInTerminal() }

            Spacer(minLength: 8)

            if compiler.isBuilding {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.8)
            }

            ToolButton(symbol: settings.showProjectPane ? "sidebar.left" : "sidebar.leading",
                       tooltip: settings.t(.viewProjectPane),
                       caption: caption(.btProject),
                       active: settings.showProjectPane) {
                settings.showProjectPane.toggle()
            }
            ToolButton(symbol: "rectangle.bottomthird.inset.filled",
                       tooltip: settings.t(.viewOutputPane),
                       caption: caption(.btOutput),
                       active: settings.showConsole) {
                settings.showConsole.toggle()
            }
            ToolButton(symbol: "gearshape", tooltip: settings.t(.tbOptions),
                       caption: caption(.btOptions)) { AppWindows.showSettings() }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func caption(_ key: LKey) -> String? {
        labels ? settings.t(key) : nil
    }

    private var separator: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: 1, height: labels ? 28 : 16)
            .padding(.horizontal, 4)
    }
}
