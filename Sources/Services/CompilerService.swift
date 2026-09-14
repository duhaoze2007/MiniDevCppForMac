import SwiftUI
import AppKit

struct Diagnostic: Identifiable, Hashable {
    enum Severity: String {
        case error, warning, note, fatal

        var label: String {
            switch self {
            case .error: return "error"
            case .warning: return "warning"
            case .note: return "note"
            case .fatal: return "fatal error"
            }
        }
    }

    let id = UUID()
    let filePath: String?
    let line: Int
    let column: Int
    let severity: Severity
    let message: String
    let raw: String

    var shortFileName: String? {
        filePath.map { ($0 as NSString).lastPathComponent }
    }
}

/// Drives clang and the compiled program, collecting everything the output
/// window displays. All blocking work happens off the main thread.
@MainActor
final class CompilerService: ObservableObject {

    static let shared = CompilerService()

    @Published var isBuilding = false
    @Published var isRunning = false
    @Published var log = ""
    @Published var diagnostics: [Diagnostic] = []
    @Published var programOutput = ""
    @Published var lastExitCode: Int32?
    @Published var buildSucceeded: Bool?
    @Published var statusMessage = ""
    @Published var builtExecutable: URL?
    @Published var lastBuildDate: Date?

    private var runProcess: Process?
    private var stdinHandle: FileHandle?
    private var pendingFlush = false

    private init() {}

    var errorCount: Int { diagnostics.filter { $0.severity == .error || $0.severity == .fatal }.count }
    var warningCount: Int { diagnostics.filter { $0.severity == .warning }.count }

    // MARK: - Compile

    func compile(runAfter: Bool = false) {
        guard !isBuilding else { return }
        let settings = AppSettings.shared
        let workspace = Workspace.shared

        guard workspace.saveAllForBuild() else { return }
        let sources = workspace.buildSources()
        guard !sources.isEmpty else {
            log = settings.t(.msgNoSourceFiles)
            diagnostics = []
            buildSucceeded = false
            statusMessage = settings.t(.msgNoSourceFiles)
            return
        }
        let compiler = settings.compilerPath
        guard FileManager.default.isExecutableFile(atPath: compiler) else {
            log = settings.t(.msgCompilerMissing)
            diagnostics = []
            buildSucceeded = false
            statusMessage = settings.t(.msgCompilerMissing)
            return
        }
        guard let output = workspace.outputURL(settings: settings) else { return }

        var args: [String] = ["-std=\(settings.cStandard)", "-Wall"]
        if settings.debugInfo { args.append("-g") }
        args += settings.extraFlags
            .split(whereSeparator: { $0 == " " || $0 == "\n" })
            .map(String.init)
        args += sources.map(\.path)
        args += ["-o", output.path]
        // Dev-C++ links the maths library by default; keep that convenience.
        args.append("-lm")

        let workingDirectory = workspace.projectRoot ?? sources[0].deletingLastPathComponent()

        isBuilding = true
        buildSucceeded = nil
        log = ""
        diagnostics = []
        statusMessage = settings.t(.statusCompiling)
        lastBuildDate = Date()

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.runSynchronously(executable: compiler,
                                               arguments: args,
                                               workingDirectory: workingDirectory)
            DispatchQueue.main.async {
                let settings = AppSettings.shared
                self.log = result.output.isEmpty
                    ? "\(compiler) \(args.joined(separator: " "))\n\n\(settings.t(.msgBuildOK))"
                    : result.output
                self.diagnostics = Self.parse(result.output, workingDirectory: workingDirectory)
                self.isBuilding = false
                let ok = result.exitCode == 0
                self.buildSucceeded = ok
                self.builtExecutable = ok ? output : nil
                if ok {
                    let warnings = self.warningCount
                    self.statusMessage = warnings == 0
                        ? settings.t(.msgBuildOK)
                        : settings.t(.msgBuildOKWarn, warnings)
                    if runAfter { self.run() }
                } else {
                    self.statusMessage = settings.t(.msgBuildFail, self.errorCount, self.warningCount)
                }
            }
        }
    }

    // MARK: - Run

    func run() {
        let settings = AppSettings.shared
        guard let exe = builtExecutable, FileManager.default.fileExists(atPath: exe.path) else {
            programOutput = settings.t(.msgProgramNotBuilt)
            statusMessage = settings.t(.msgProgramNotBuilt)
            return
        }
        stop()

        let process = Process()
        process.executableURL = exe
        process.arguments = Self.splitArguments(settings.runArguments)
        process.currentDirectoryURL = exe.deletingLastPathComponent()

        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = outPipe
        let inPipe = Pipe()
        process.standardInput = inPipe

        programOutput = ""
        lastExitCode = nil

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            guard let chunk = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                CompilerService.shared.appendOutput(chunk)
            }
        }

        process.terminationHandler = { proc in
            DispatchQueue.main.async {
                CompilerService.shared.finishRun(exitCode: proc.terminationStatus)
            }
        }

        do {
            try process.run()
        } catch {
            programOutput = error.localizedDescription
            statusMessage = error.localizedDescription
            return
        }

        runProcess = process
        stdinHandle = inPipe.fileHandleForWriting
        isRunning = true
        statusMessage = settings.t(.statusRunning)

        // Pre-fill stdin from the Run Parameters sheet, exactly like Dev-C++
        // redirecting a file into the console program.
        if !settings.runStdin.isEmpty {
            sendStdin(settings.runStdin, appendNewline: true)
        }
    }

    func sendStdin(_ text: String, appendNewline: Bool = true) {
        guard let handle = stdinHandle else { return }
        let payload = appendNewline ? text + "\n" : text
        if let data = payload.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }

    func closeStdin() {
        guard let handle = stdinHandle else { return }
        try? handle.close()
        stdinHandle = nil
    }

    func stop() {
        guard let process = runProcess, process.isRunning else {
            runProcess = nil
            isRunning = false
            return
        }
        closeStdin()
        process.interrupt()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if process.isRunning { process.terminate() }
        }
        statusMessage = AppSettings.shared.t(.msgProgramStopped)
    }

    private func appendOutput(_ chunk: String) {
        programOutput += chunk
        if programOutput.count > 400_000 {
            programOutput = "…\n" + String(programOutput.suffix(300_000))
        }
    }

    private func finishRun(exitCode: Int32) {
        isRunning = false
        lastExitCode = exitCode
        runProcess = nil
        stdinHandle = nil
        statusMessage = AppSettings.shared.t(.msgProgramFinished, Int(exitCode))
    }

    // MARK: - Terminal

    func runInTerminal() {
        guard let exe = builtExecutable, FileManager.default.fileExists(atPath: exe.path) else {
            programOutput = AppSettings.shared.t(.msgProgramNotBuilt)
            return
        }
        let script = """
        #!/bin/bash
        cd \(Self.shellQuote(exe.deletingLastPathComponent().path))
        \(Self.shellQuote(exe.path)) \(AppSettings.shared.runArguments)
        code=$?
        echo
        echo "-- \(AppSettings.shared.t(.consoleExitCode)): $code --"
        """
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("minidevcpp_run.command")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            NSWorkspace.shared.open(url)
        } catch {
            Dialogs.error(title: "Terminal", body: error.localizedDescription)
        }
    }

    // MARK: - Housekeeping

    func clean() {
        let removed = Workspace.shared.cleanOutputs()
        builtExecutable = nil
        buildSucceeded = nil
        lastExitCode = nil
        diagnostics = []
        let note = removed > 0 ? "\(removed) file(s) removed" : "nothing to remove"
        log = note
        programOutput = ""
        statusMessage = note
    }

    func clearOutput() {
        log = ""
        programOutput = ""
        diagnostics = []
        lastExitCode = nil
        buildSucceeded = nil
    }

    func revealOutputFolder() {
        guard let out = builtExecutable ?? Workspace.shared.outputURL(settings: AppSettings.shared) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([out])
    }

    // MARK: - Process helpers

    nonisolated static func runSynchronously(executable: String,
                                             arguments: [String],
                                             workingDirectory: URL?) -> (exitCode: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let workingDirectory { process.currentDirectoryURL = workingDirectory }
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.standardInput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return (-1, "Failed to launch \(executable): \(error.localizedDescription)")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(data: data, encoding: .utf8) ?? ""
        return (process.terminationStatus, text)
    }

    /// clang diagnostics: "/path/main.c:12:5: error: expected ';' after expression"
    nonisolated static func parse(_ output: String, workingDirectory: URL?) -> [Diagnostic] {
        let pattern = #"^(.*?):(\d+):(\d+):\s*(fatal error|error|warning|note):\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { return [] }
        var result: [Diagnostic] = []
        for rawLine in output.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let ns = line as NSString
            guard let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: ns.length)),
                  match.numberOfRanges == 6 else { continue }
            let path = ns.substring(with: match.range(at: 1))
            guard let lineNumber = Int(ns.substring(with: match.range(at: 2))),
                  let column = Int(ns.substring(with: match.range(at: 3))) else { continue }
            let severityText = ns.substring(with: match.range(at: 4))
            let message = ns.substring(with: match.range(at: 5))
            let severity: Diagnostic.Severity
            switch severityText {
            case "fatal error": severity = .fatal
            case "error":       severity = .error
            case "warning":     severity = .warning
            default:            severity = .note
            }
            var resolved = path
            if !path.hasPrefix("/"), let cwd = workingDirectory {
                resolved = cwd.appendingPathComponent(path).standardizedFileURL.path
            }
            result.append(Diagnostic(filePath: urlExists(resolved) ? resolved : nil,
                                     line: lineNumber,
                                     column: column,
                                     severity: severity,
                                     message: message,
                                     raw: line))
        }
        return result
    }

    nonisolated private static func urlExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Splits a command line honouring double quotes.
    nonisolated static func splitArguments(_ text: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for ch in text {
            if ch == "\"" {
                inQuotes.toggle()
            } else if ch == " " && !inQuotes {
                if !current.isEmpty { result.append(current); current = "" }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    nonisolated static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
