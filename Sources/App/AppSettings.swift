import SwiftUI
import AppKit

// MARK: - Appearance

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }

    var lkey: LKey {
        switch self {
        case .system: return .viewThemeSystem
        case .light:  return .viewThemeLight
        case .dark:   return .viewThemeDark
        }
    }
}

// MARK: - Settings store

/// UserDefaults-backed application settings, readable from any code path.
@MainActor
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let d = UserDefaults.standard

    private enum K {
        static let language       = "MiniDevCpp.language"
        static let theme          = "MiniDevCpp.theme"
        static let fontSize       = "MiniDevCpp.fontSize"
        static let tabWidth       = "MiniDevCpp.tabWidth"
        static let insertSpaces   = "MiniDevCpp.insertSpaces"
        static let lineNumbers    = "MiniDevCpp.lineNumbers"
        static let highlight      = "MiniDevCpp.highlight"
        static let smartIndent    = "MiniDevCpp.smartIndent"
        static let wrapLines      = "MiniDevCpp.wrapLines"
        static let highlightLine  = "MiniDevCpp.highlightCurrentLine"
        static let showProject    = "MiniDevCpp.showProjectPane"
        static let showConsole    = "MiniDevCpp.showConsole"
        static let compilerPath   = "MiniDevCpp.compilerPath"
        static let cStandard      = "MiniDevCpp.cStandard"
        static let extraFlags     = "MiniDevCpp.extraFlags"
        static let debugInfo      = "MiniDevCpp.debugInfo"
        static let buildFolder    = "MiniDevCpp.outputToBuildFolder"
        static let runArguments   = "MiniDevCpp.runArguments"
        static let runStdin       = "MiniDevCpp.runStdin"
    }

    // MARK: published state

    @Published var language: AppLanguage {
        didSet { d.set(language.rawValue, forKey: K.language); applyLanguagePreference() }
    }
    @Published var theme: AppTheme {
        didSet { d.set(theme.rawValue, forKey: K.theme); applyTheme() }
    }
    @Published var fontSize: Double { didSet { d.set(fontSize, forKey: K.fontSize) } }
    @Published var tabWidth: Int { didSet { d.set(tabWidth, forKey: K.tabWidth) } }
    @Published var insertSpaces: Bool { didSet { d.set(insertSpaces, forKey: K.insertSpaces) } }
    @Published var showLineNumbers: Bool { didSet { d.set(showLineNumbers, forKey: K.lineNumbers) } }
    @Published var highlight: Bool { didSet { d.set(highlight, forKey: K.highlight) } }
    @Published var smartIndent: Bool { didSet { d.set(smartIndent, forKey: K.smartIndent) } }
    @Published var wrapLines: Bool { didSet { d.set(wrapLines, forKey: K.wrapLines) } }
    @Published var highlightCurrentLine: Bool { didSet { d.set(highlightCurrentLine, forKey: K.highlightLine) } }
    @Published var showProjectPane: Bool { didSet { d.set(showProjectPane, forKey: K.showProject) } }
    @Published var showConsole: Bool { didSet { d.set(showConsole, forKey: K.showConsole) } }
    @Published var compilerPath: String { didSet { d.set(compilerPath, forKey: K.compilerPath) } }
    @Published var cStandard: String { didSet { d.set(cStandard, forKey: K.cStandard) } }
    @Published var extraFlags: String { didSet { d.set(extraFlags, forKey: K.extraFlags) } }
    @Published var debugInfo: Bool { didSet { d.set(debugInfo, forKey: K.debugInfo) } }
    @Published var outputToBuildFolder: Bool { didSet { d.set(outputToBuildFolder, forKey: K.buildFolder) } }
    @Published var runArguments: String { didSet { d.set(runArguments, forKey: K.runArguments) } }
    @Published var runStdin: String { didSet { d.set(runStdin, forKey: K.runStdin) } }

    // MARK: init

    private init() {
        let d = UserDefaults.standard
        AppSettings.registerDefaults(in: d)

        self.language = AppLanguage(rawValue: d.string(forKey: K.language) ?? "system") ?? .system
        self.theme = AppTheme(rawValue: d.string(forKey: K.theme) ?? "system") ?? .system
        self.fontSize = d.double(forKey: K.fontSize)
        self.tabWidth = d.integer(forKey: K.tabWidth)
        self.insertSpaces = d.bool(forKey: K.insertSpaces)
        self.showLineNumbers = d.bool(forKey: K.lineNumbers)
        self.highlight = d.bool(forKey: K.highlight)
        self.smartIndent = d.bool(forKey: K.smartIndent)
        self.wrapLines = d.bool(forKey: K.wrapLines)
        self.highlightCurrentLine = d.bool(forKey: K.highlightLine)
        self.showProjectPane = d.bool(forKey: K.showProject)
        self.showConsole = d.bool(forKey: K.showConsole)
        self.compilerPath = d.string(forKey: K.compilerPath) ?? "/usr/bin/clang"
        self.cStandard = d.string(forKey: K.cStandard) ?? "gnu17"
        self.extraFlags = d.string(forKey: K.extraFlags) ?? ""
        self.debugInfo = d.bool(forKey: K.debugInfo)
        self.outputToBuildFolder = d.bool(forKey: K.buildFolder)
        self.runArguments = d.string(forKey: K.runArguments) ?? ""
        self.runStdin = d.string(forKey: K.runStdin) ?? ""

        // Resolve the AppleLanguages override *before* AppKit builds the menu bar,
        // otherwise the standard menu titles keep the system language.
        applyLanguagePreference()
    }

    private static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: [
            K.language: AppLanguage.system.rawValue,
            K.theme: AppTheme.system.rawValue,
            K.fontSize: 13.0,
            K.tabWidth: 4,
            K.insertSpaces: true,
            K.lineNumbers: true,
            K.highlight: true,
            K.smartIndent: true,
            K.wrapLines: false,
            K.highlightLine: false,
            K.showProject: true,
            K.showConsole: true,
            K.compilerPath: "/usr/bin/clang",
            K.cStandard: "gnu17",
            K.extraFlags: "",
            K.debugInfo: true,
            K.buildFolder: false,
            K.runArguments: "",
            K.runStdin: ""
        ])
    }

    // MARK: localization helper

    func t(_ key: LKey) -> String {
        L10n.string(key, language.resolved)
    }

    func t(_ key: LKey, _ arguments: CVarArg...) -> String {
        String(format: L10n.string(key, language.resolved), arguments: arguments)
            .replacingOccurrences(of: "%@", with: "%@")
    }

    // MARK: side effects

    /// AppKit's built-in menus follow `AppleLanguages`; keep it in sync so the
    /// standard menu items speak the same language as the app.
    func applyLanguagePreference() {
        if language == .system {
            d.removeObject(forKey: "AppleLanguages")
        } else {
            d.set([language.resolved.rawValue], forKey: "AppleLanguages")
        }
    }

    func applyTheme() {
        NSApp.appearance = theme.appearance
    }

    // MARK: derived helpers

    static let cStandards = ["gnu17", "c17", "gnu11", "c11", "gnu99", "c99", "gnu89", "c89"]

    /// Locate a usable clang if the configured one is missing.
    nonisolated static func detectCompiler() -> String? {
        let candidates = [
            "/usr/bin/clang",
            "/usr/local/bin/clang",
            "/opt/homebrew/opt/llvm/bin/clang"
        ]
        for c in candidates where FileManager.default.isExecutableFile(atPath: c) { return c }
        return nil
    }

    /// `clang --version` first line, used by the About window.
    nonisolated static func compilerVersion(path: String) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = ["--version"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return "—" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let text = String(data: data, encoding: .utf8) ?? ""
        let first = text.split(separator: "\n").first.map(String.init) ?? "—"
        // "Apple clang version 21.0.0 (clang-2100.0.123.1)" → "21.0.0"
        if let range = first.range(of: "version ") {
            let rest = first[range.upperBound...]
            return rest.split(separator: " ").first.map(String.init) ?? rest.description
        }
        return first
    }

    /// Toolchain target, e.g. "arm64-apple-darwin25.0.0"
    nonisolated static func compilerTarget(path: String) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = ["-dumpmachine"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return "—" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (String(data: data, encoding: .utf8) ?? "—").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func resetToDefaults() {
        fontSize = 13
        tabWidth = 4
        insertSpaces = true
        showLineNumbers = true
        highlight = true
        smartIndent = true
        wrapLines = false
        highlightCurrentLine = false
        showProjectPane = true
        showConsole = true
        compilerPath = "/usr/bin/clang"
        cStandard = "gnu17"
        extraFlags = ""
        debugInfo = true
        outputToBuildFolder = false
    }
}
