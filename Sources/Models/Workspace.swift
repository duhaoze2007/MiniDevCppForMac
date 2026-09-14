import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// A node of the project explorer tree.
struct FileNode: Identifiable, Hashable {
    let id: String
    let url: URL
    let name: String
    let isDirectory: Bool
    var children: [FileNode]

    var isSource: Bool {
        ["c", "h", "cpp", "cc", "cxx", "hpp", "hh", "m", "mm", "txt", "md", "makefile"].contains(
            url.pathExtension.lowercased()
        ) || name.lowercased().hasPrefix("makefile")
    }
}

/// Everything the IDE has open: files, the active buffer and the project folder.
@MainActor
final class Workspace: ObservableObject {

    static let shared = Workspace()

    @Published var files: [SourceFile] = []
    @Published var activeID: UUID?
    @Published var projectRoot: URL?
    @Published var tree: [FileNode] = []
    @Published var statusMessage: String = ""
    @Published var projectFileCount: Int = 0

    private var untitledCounter = 1

    private init() {}

    var activeFile: SourceFile? {
        guard let activeID else { return nil }
        return files.first { $0.id == activeID }
    }

    var windowTitle: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let app = AppSettings.shared.t(.appName)
        if let file = activeFile {
            return "\(app) \(version) - [\(file.displayName)]"
        }
        return "\(app) \(version)"
    }

    // MARK: - Documents

    func newFile() {
        let file = SourceFile(url: nil, text: "")
        file.provisionalName = "Untitled\(untitledCounter).c"
        untitledCounter += 1
        files.append(file)
        activeID = file.id
        statusMessage = AppSettings.shared.t(.welcomeTitle)
    }

    func openFromPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.message = AppSettings.shared.t(.fileOpen)
        if panel.runModal() == .OK {
            open(urls: panel.urls)
        }
    }

    func open(urls: [URL]) {
        var lastOpened: SourceFile?
        for url in urls where !url.hasDirectoryPath {
            if let existing = files.first(where: { $0.url?.standardizedFileURL == url.standardizedFileURL }) {
                lastOpened = existing
                continue
            }
            do {
                let text = try Self.readText(url)
                let file = SourceFile(url: url, text: text)
                files.append(file)
                lastOpened = file
            } catch {
                Dialogs.error(title: AppSettings.shared.t(.msgLoadFailed, url.lastPathComponent),
                              body: error.localizedDescription)
            }
        }
        if let lastOpened { activeID = lastOpened.id }
    }

    private static func readText(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let latin = String(data: data, encoding: .isoLatin1) { return latin }
        if let utf16 = String(data: data, encoding: .utf16) { return utf16 }
        throw NSError(domain: "MiniDevCpp", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Unsupported text encoding"
        ])
    }

    func select(_ file: SourceFile) {
        activeID = file.id
    }

    // MARK: - Saving

    @discardableResult
    func save(_ file: SourceFile) -> Bool {
        if let url = file.url {
            do {
                try file.text.write(to: url, atomically: true, encoding: .utf8)
                file.isDirty = false
                statusMessage = "\(AppSettings.shared.t(.statusSavedMsg))  \(file.displayName)"
                refreshTreeAfterSave(url)
                return true
            } catch {
                Dialogs.error(title: AppSettings.shared.t(.msgSaveFailed, file.displayName),
                              body: error.localizedDescription)
                return false
            }
        }
        return saveAs(file)
    }

    @discardableResult
    func saveAs(_ file: SourceFile) -> Bool {
        let panel = NSSavePanel()
        panel.message = AppSettings.shared.t(.fileSaveAs)
        panel.nameFieldStringValue = file.url?.lastPathComponent ?? file.provisionalName ?? "Untitled.c"
        if let dir = file.url?.deletingLastPathComponent() ?? projectRoot {
            panel.directoryURL = dir
        }
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        do {
            try file.text.write(to: url, atomically: true, encoding: .utf8)
            file.url = url
            file.isDirty = false
            statusMessage = "\(AppSettings.shared.t(.statusSavedMsg))  \(file.displayName)"
            refreshTreeAfterSave(url)
            return true
        } catch {
            Dialogs.error(title: AppSettings.shared.t(.msgSaveFailed, url.lastPathComponent),
                          body: error.localizedDescription)
            return false
        }
    }

    func saveActive() {
        guard let file = activeFile else { return }
        save(file)
    }

    func saveAll() {
        for file in files where file.isDirty { _ = save(file) }
    }

    /// Saves every dirty buffer before a build; missing names are resolved with
    /// a Save panel like Dev-C++ does.
    @discardableResult
    func saveAllForBuild() -> Bool {
        for file in files where file.isDirty {
            if !save(file) { return false }
        }
        return true
    }

    private func refreshTreeAfterSave(_ url: URL) {
        guard let root = projectRoot else { return }
        guard url.path.hasPrefix(root.path) else { return }
        reloadProject()
    }

    // MARK: - Closing

    @discardableResult
    func close(_ file: SourceFile) -> Bool {
        if file.isDirty {
            switch Dialogs.confirmUnsaved(name: file.displayName, settings: AppSettings.shared) {
            case .cancel:  return false
            case .save:    if !save(file) { return false }
            case .discard: break
            }
        }
        let wasActive = activeID == file.id
        files.removeAll { $0.id == file.id }
        if wasActive { activeID = files.last?.id }
        return true
    }

    func closeActive() {
        guard let file = activeFile else { return }
        _ = close(file)
    }

    func closeAll() {
        for file in files {
            if !close(file) { return }
        }
    }

    func closeProject() {
        projectRoot = nil
        tree = []
        projectFileCount = 0
    }

    // MARK: - Project folder

    func openFolderFromPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = AppSettings.shared.t(.fileOpenFolder)
        if panel.runModal() == .OK, let url = panel.url {
            loadProject(url)
        }
    }

    func loadProject(_ url: URL) {
        projectRoot = url
        untitledCounter = 1
        reloadProject()
        let sources = buildSources()
        if let first = sources.first { open(urls: [first]) }
        statusMessage = "\(AppSettings.shared.t(.paneProject)): \(url.lastPathComponent) · \(sources.count) *.c"
    }

    func reloadProject() {
        guard let root = projectRoot else { tree = []; return }
        tree = Self.scan(url: root, depth: 0)
        projectFileCount = buildSources().count
    }

    private static func scan(url: URL, depth: Int) -> [FileNode] {
        guard depth < 6 else { return [] }
        let fm = FileManager.default
        let skip: Set<String> = [".git", ".build", "build", "node_modules", ".DS_Store", "__pycache__", "dist"]
        let keys: [URLResourceKey] = [.isDirectoryKey, .nameKey]
        guard let entries = try? fm.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: keys,
                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants])
        else { return [] }

        var nodes: [FileNode] = []
        for entry in entries.sorted(by: { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }) {
            let name = entry.lastPathComponent
            if skip.contains(name) { continue }
            let isDir = (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                let children = scan(url: entry, depth: depth + 1)
                if !children.isEmpty {
                    nodes.append(FileNode(id: entry.path, url: entry, name: name,
                                          isDirectory: true, children: children))
                }
            } else {
                let node = FileNode(id: entry.path, url: entry, name: name,
                                    isDirectory: false, children: [])
                if node.isSource {
                    nodes.append(node)
                }
            }
        }
        // folders first, then files
        return nodes.sorted { a, b in
            if a.isDirectory != b.isDirectory { return a.isDirectory }
            return a.name.lowercased() < b.name.lowercased()
        }
    }

    // MARK: - Build inputs / outputs

    /// Files handed to clang: the whole project, or just the edited file.
    func buildSources() -> [URL] {
        let extensions: Set<String> = ["c", "cpp", "cc", "cxx", "m", "mm"]
        if let root = projectRoot {
            var result: [URL] = []
            let fm = FileManager.default
            if let enumerator = fm.enumerator(at: root,
                                              includingPropertiesForKeys: [.isDirectoryKey],
                                              options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let url as URL in enumerator {
                    if url.pathComponents.contains("build") || url.pathComponents.contains(".build") { continue }
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    if isDir { continue }
                    if extensions.contains(url.pathExtension.lowercased()) { result.append(url) }
                }
            }
            return result.sorted { $0.path < $1.path }
        }
        guard let file = activeFile, let url = file.url, file.isCompilableSource else { return [] }
        return [url]
    }

    /// Dev-C++ writes the executable next to the source; a `build` subfolder is
    /// available as an option.
    func outputURL(settings: AppSettings) -> URL? {
        let fm = FileManager.default
        let baseDirectory: URL
        let name: String
        if let root = projectRoot {
            baseDirectory = root
            name = root.lastPathComponent
        } else if let url = activeFile?.url, activeFile?.isCompilableSource == true {
            baseDirectory = url.deletingLastPathComponent()
            name = url.deletingPathExtension().lastPathComponent
        } else {
            return nil
        }
        var directory = baseDirectory
        if settings.outputToBuildFolder {
            directory = baseDirectory.appendingPathComponent("build", isDirectory: true)
            if !fm.fileExists(atPath: directory.path) {
                try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
        return directory.appendingPathComponent(name)
    }

    func cleanOutputs() -> Int {
        let settings = AppSettings.shared
        guard let out = outputURL(settings: settings) else { return 0 }
        var removed = 0
        let candidates = [out,
                          out.appendingPathExtension("dSYM"),
                          out.deletingLastPathComponent().appendingPathComponent(out.lastPathComponent + ".exe")]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            if (try? FileManager.default.removeItem(at: url)) != nil { removed += 1 }
        }
        return removed
    }

    // MARK: - Editor navigation

    func revealInFinder() {
        let target = activeFile?.url ?? projectRoot
        guard let target else { return }
        NSWorkspace.shared.activateFileViewerSelecting([target])
    }
}
