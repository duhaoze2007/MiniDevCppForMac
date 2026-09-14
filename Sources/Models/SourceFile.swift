import Foundation
import AppKit

/// One open editor buffer. The text is mirrored from the NSTextView on every
/// keystroke so save/dirty tracking never needs to reach into AppKit.
@MainActor
final class SourceFile: ObservableObject, Identifiable {
    let id = UUID()
    @Published var url: URL?
    @Published var text: String
    @Published var isDirty: Bool = false
    /// Bumped when the buffer was replaced from disk (forces the editor to reload).
    @Published var reloadToken: Int = 0
    @Published var cursorLine: Int = 1
    @Published var cursorColumn: Int = 1
    @Published var selectionLength: Int = 0
    /// Caret/selection kept per document so switching tabs restores the position.
    var savedSelection: NSRange = NSRange(location: 0, length: 0)

    /// Name used before the buffer has been saved to disk ("Untitled1.c").
    var provisionalName: String?

    init(url: URL?, text: String) {
        self.url = url
        self.text = text
    }

    var displayName: String {
        url?.lastPathComponent ?? provisionalName ?? "untitled"
    }

    var plainName: String {
        guard let url else { return "untitled" }
        return url.deletingPathExtension().lastPathComponent
    }

    var directory: URL? {
        url?.deletingLastPathComponent()
    }

    var isCompilableSource: Bool {
        guard let ext = url?.pathExtension.lowercased() else { return false }
        return ["c", "m", "cpp", "cc", "cxx", "mm"].contains(ext)
    }

    var isCHeader: Bool {
        let ext = url?.pathExtension.lowercased() ?? ""
        return ["h", "hpp", "hh"].contains(ext)
    }

    func lineCount() -> Int {
        var count = 1
        for ch in text where ch == "\n" { count += 1 }
        return count
    }

    func lineText(_ line: Int) -> String {
        let lines = text.components(separatedBy: "\n")
        guard line >= 1, line <= lines.count else { return "" }
        return lines[line - 1]
    }
}
