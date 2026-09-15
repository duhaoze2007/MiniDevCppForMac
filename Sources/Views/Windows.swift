import SwiftUI
import AppKit

// MARK: - About

struct AboutView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var compilerVersion = "…"
    @State private var compilerTarget = ""

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    credits
                    Divider()
                    license
                    Divider()
                    runtime
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            footer
        }
        .frame(width: 540, height: 620)
        .task {
            let path = settings.compilerPath
            let version = await Task.detached(priority: .utility) {
                AppSettings.compilerVersion(path: path)
            }.value
            let target = await Task.detached(priority: .utility) {
                AppSettings.compilerTarget(path: path)
            }.value
            compilerVersion = version
            compilerTarget = target
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.appName))
                    .font(.system(size: 17, weight: .semibold))
                Text(settings.t(.settingsVersion, version))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text(settings.t(.appTagline))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(settings.t(.aboutCopyright))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(settings.t(.aboutCreditsTitle))
                .font(.system(size: 13, weight: .semibold))
            Text(settings.t(.aboutCreditsIntro))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            creditEntry(settings.t(.aboutCreditDevCppTitle), settings.t(.aboutCreditDevCppText))
            creditEntry(settings.t(.aboutCreditOrwellTitle), settings.t(.aboutCreditOrwellText))
            creditEntry(settings.t(.aboutCreditClangTitle), settings.t(.aboutCreditClangText))
            creditEntry(settings.t(.aboutCreditSwiftTitle), settings.t(.aboutCreditSwiftText))
        }
    }

    private func creditEntry(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var license: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(settings.t(.aboutLicenseTitle))
                .font(.system(size: 13, weight: .semibold))
            Text(settings.t(.aboutLicenseText))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var runtime: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(settings.t(.aboutSystemTitle))
                .font(.system(size: 13, weight: .semibold))
            Text("Apple clang \(compilerVersion) — \(compilerTarget)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text(settings.compilerPath)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
        }
    }

    private var footer: some View {
        HStack {
            Text("MIT License")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Button("OK") { AppWindows.closeAbout() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(14)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                generalTab.tabItem { Label(settings.t(.settingsGeneral), systemImage: "gearshape") }
                editorTab.tabItem { Label(settings.t(.settingsEditor), systemImage: "textformat") }
                compilerTab.tabItem { Label(settings.t(.settingsCompiler), systemImage: "hammer") }
            }
            .padding(.top, 8)

            Divider()
            HStack {
                Text(settings.t(.settingsOfflineNote))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button(settings.t(.settingsDefaults)) { settings.resetToDefaults() }
                Button(settings.t(.settingsDone)) { AppWindows.closeSettings() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 560, height: 470)
    }

    // MARK: general

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsRow(label: settings.t(.settingsAppearance)) {
                Picker("", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(settings.t(theme.lkey)).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 300)
            }

            SettingsRow(label: settings.t(.settingsLanguage)) {
                Picker("", selection: $settings.language) {
                    Text(settings.t(.viewThemeSystem)).tag(AppLanguage.system)
                    ForEach(AppLanguage.allCases.filter { $0 != .system }) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 220)
            }

            Text(settings.t(.settingsLanguageHint))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.leading, 190)

            Divider().padding(.vertical, 4)

            Toggle(settings.t(.settingsShowProject), isOn: $settings.showProjectPane)
            Toggle(settings.t(.settingsShowConsole), isOn: $settings.showConsole)

            Spacer()
        }
        .padding(20)
    }

    // MARK: editor

    private var editorTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsRow(label: settings.t(.settingsFontSize)) {
                HStack(spacing: 8) {
                    Slider(value: $settings.fontSize, in: 9...30, step: 1)
                        .frame(width: 200)
                    Text("\(Int(settings.fontSize)) pt")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .leading)
                }
            }
            SettingsRow(label: settings.t(.settingsTabWidth)) {
                Stepper(value: $settings.tabWidth, in: 1...12) {
                    Text("\(settings.tabWidth)")
                        .font(.system(size: 11, design: .monospaced))
                }
                .frame(width: 120)
            }
            Toggle(settings.t(.settingsInsertSpaces), isOn: $settings.insertSpaces)
            Toggle(settings.t(.settingsSmartIndent), isOn: $settings.smartIndent)
            Toggle(settings.t(.settingsLineNumbers), isOn: $settings.showLineNumbers)
            Toggle(settings.t(.settingsHighlight), isOn: $settings.highlight)
            Toggle(settings.t(.settingsHighlightLine), isOn: $settings.highlightCurrentLine)
            Toggle(settings.t(.settingsWrap), isOn: $settings.wrapLines)
            Toggle(settings.t(.viewToolbarLabels), isOn: $settings.showToolbarLabels)
            Spacer()
        }
        .padding(20)
    }

    // MARK: compiler

    private var compilerTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsRow(label: settings.t(.settingsCompilerPath)) {
                TextField("", text: $settings.compilerPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 300)
            }
            Text(settings.t(.settingsCompilerDetected, compilerSummary))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.leading, 190)

            SettingsRow(label: settings.t(.settingsStandard)) {
                Picker("", selection: $settings.cStandard) {
                    ForEach(AppSettings.cStandards, id: \.self) { standard in
                        Text("-std=\(standard)").tag(standard)
                    }
                }
                .labelsHidden()
                .frame(width: 160)
            }

            SettingsRow(label: settings.t(.settingsFlags)) {
                TextField("-O2 -pthread", text: $settings.extraFlags)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 300)
            }
            Text(settings.t(.settingsFlagsHint))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .padding(.leading, 190)

            Toggle(settings.t(.settingsDebug), isOn: $settings.debugInfo)

            SettingsRow(label: settings.t(.settingsOutDir)) {
                Picker("", selection: $settings.outputToBuildFolder) {
                    Text(settings.t(.settingsOutSameDir)).tag(false)
                    Text(settings.t(.settingsOutBuildDir)).tag(true)
                }
                .labelsHidden()
                .frame(width: 300)
            }
            Spacer()
        }
        .padding(20)
    }

    private var compilerSummary: String {
        let path = settings.compilerPath
        guard FileManager.default.isExecutableFile(atPath: path) else {
            return settings.t(.msgCompilerMissing)
        }
        return "\(AppSettings.compilerVersion(path: path)) — \(path)"
    }
}

struct SettingsRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 11.5))
                .frame(width: 178, alignment: .leading)
            content
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Help window

struct HelpView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selection = 0

    private var sections: [(LKey, LKey, String)] {
        [
            (.helpSecEditing, .helpBodyEditing, "textformat"),
            (.helpSecBuild, .helpBodyBuild, "hammer"),
            (.helpSecProject, .helpBodyProject, "folder"),
            (.helpSecSettings, .helpBodySettings, "gearshape")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(settings.t(.helpTitle))
                    .font(.system(size: 15, weight: .semibold))
                Text(settings.t(.helpIntro))
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: section.2)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.accentColor)
                                Text(settings.t(section.0))
                                    .font(.system(size: 12.5, weight: .semibold))
                            }
                            Text(settings.t(section.1))
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.accentColor)
                            Text(settings.t(.helpShortcuts))
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        shortcutTable
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            HStack {
                Spacer()
                Button(settings.t(.settingsDone)) { AppWindows.closeHelp() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(14)
        }
        .frame(width: 600, height: 600)
    }

    private var shortcutTable: some View {
        let rows: [(String, String)] = [
            ("⌘N", settings.t(.fileNew)),
            ("⌘O", settings.t(.fileOpen)),
            ("⌘S", settings.t(.fileSave)),
            ("⇧⌘S", settings.t(.fileSaveAs)),
            ("⌘B", settings.t(.execCompile)),
            ("⇧⌘B", settings.t(.execRebuild)),
            ("⌘R", settings.t(.execRun)),
            ("⌘⏎", settings.t(.execCompileRun)),
            ("⌘.", settings.t(.execStop)),
            ("⌘F", settings.t(.searchFind)),
            ("⌥⌘F", settings.t(.searchReplace)),
            ("⌘G", settings.t(.searchGoToLine)),
            ("⌘/", settings.t(.editToggleComment)),
            ("⌘+ / ⌘-", "\(settings.t(.viewFontBigger)) / \(settings.t(.viewFontSmaller))"),
            ("⌘,", settings.t(.settingsTitle))
        ]
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(rows, id: \.0) { row in
                HStack(alignment: .top, spacing: 10) {
                    Text(row.0)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .frame(width: 70, alignment: .leading)
                    Text(row.1)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Window management

@MainActor
enum AppWindows {
    private static var aboutWindow: NSWindow?
    private static var settingsWindow: NSWindow?
    private static var helpWindow: NSWindow?

    private static func present(_ window: inout NSWindow?,
                                title: String,
                                size: NSSize,
                                resizable: Bool,
                                root: some View) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = NSHostingController(rootView: root)
        let newWindow = NSWindow(contentViewController: controller)
        newWindow.title = title
        newWindow.styleMask = resizable ? [.titled, .closable, .resizable] : [.titled, .closable]
        newWindow.isReleasedWhenClosed = false
        newWindow.setContentSize(size)
        newWindow.center()
        newWindow.isRestorable = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = newWindow
    }

    static func showAbout() {
        let settings = AppSettings.shared
        present(&aboutWindow,
                title: settings.t(.helpAbout),
                size: NSSize(width: 540, height: 620),
                resizable: false,
                root: AboutView().environmentObject(settings))
    }

    static func closeAbout() { aboutWindow?.close(); aboutWindow = nil }

    static func showSettings() {
        let settings = AppSettings.shared
        present(&settingsWindow,
                title: settings.t(.settingsTitle),
                size: NSSize(width: 560, height: 470),
                resizable: false,
                root: SettingsView().environmentObject(settings))
    }

    static func closeSettings() { settingsWindow?.close(); settingsWindow = nil }

    static func showHelp() {
        let settings = AppSettings.shared
        present(&helpWindow,
                title: settings.t(.helpTitle),
                size: NSSize(width: 600, height: 600),
                resizable: true,
                root: HelpView().environmentObject(settings))
    }

    static func closeHelp() { helpWindow?.close(); helpWindow = nil }
}
