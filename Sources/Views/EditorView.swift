import SwiftUI
import AppKit

/// Lets menu commands / diagnostics talk to the visible editor without passing
/// bindings around.
@MainActor
final class EditorBridge {
    static let shared = EditorBridge()
    weak var textView: CodeTextView?
    weak var activeFile: SourceFile?
    /// Set when a jump is requested for a file that is still being opened.
    var pendingLine: Int?

    func register(_ view: CodeTextView) {
        textView = view
    }

    func goTo(line: Int) {
        pendingLine = line
        textView?.goTo(line: line)
    }

    func focus() {
        guard let textView else { return }
        textView.window?.makeFirstResponder(textView)
    }

    func toggleComment() {
        textView?.toggleLineComment()
    }

    func currentLine() -> Int {
        guard let textView else { return 1 }
        return textView.lineNumber(atCharacterIndex: textView.selectedRange().location)
    }

    func lineCount() -> Int {
        guard let textView else { return 1 }
        return textView.lineNumber(atCharacterIndex: (textView.string as NSString).length)
    }
}

/// SwiftUI wrapper for the NSTextView based C editor.
struct EditorView: NSViewRepresentable {

    @ObservedObject var file: SourceFile
    @ObservedObject var settings: AppSettings
    let theme: EditorTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
        let container = NSTextContainer(containerSize: NSSize(width: 0,
                                                             height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)

        let textView = CodeTextView(frame: NSRect(x: 0, y: 0, width: 600, height: 400),
                                    textContainer: container)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                 height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.documentView = textView

        let ruler = LineNumberRulerView(textView: textView)
        ruler.theme = theme
        ruler.updateFont(size: CGFloat(settings.fontSize))
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = settings.showLineNumbers

        context.coordinator.textView = textView
        context.coordinator.appliedFontSize = CGFloat(settings.fontSize)
        context.coordinator.appliedHighlight = settings.highlight
        context.coordinator.appliedThemeID = theme.id
        context.coordinator.appliedWrap = settings.wrapLines
        context.coordinator.load(file: file, into: textView, force: true)

        EditorBridge.shared.register(textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CodeTextView else { return }
        let coordinator = context.coordinator
        coordinator.parent = self

        textView.theme = theme
        textView.backgroundColor = theme.background
        textView.insertionPointColor = theme.caret
        textView.selectedTextAttributes = [.backgroundColor: theme.selection]
        textView.tabWidth = settings.tabWidth
        textView.insertSpaces = settings.insertSpaces
        textView.smartIndent = settings.smartIndent
        textView.highlightCurrentLine = settings.highlightCurrentLine
        scrollView.backgroundColor = theme.background

        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.theme = theme
            ruler.updateFont(size: CGFloat(settings.fontSize))
        }
        scrollView.rulersVisible = settings.showLineNumbers
        scrollView.hasHorizontalScroller = !settings.wrapLines

        if coordinator.appliedWrap != settings.wrapLines {
            coordinator.appliedWrap = settings.wrapLines
            coordinator.applyWrap(settings.wrapLines, textView: textView, scrollView: scrollView)
        }

        if coordinator.fileID != file.id || coordinator.reloadToken != file.reloadToken {
            coordinator.load(file: file, into: textView, force: false)
        }

        if coordinator.appliedFontSize != CGFloat(settings.fontSize)
            || coordinator.appliedHighlight != settings.highlight
            || coordinator.appliedThemeID != theme.id {
            coordinator.appliedFontSize = CGFloat(settings.fontSize)
            coordinator.appliedHighlight = settings.highlight
            coordinator.appliedThemeID = theme.id
            coordinator.applyHighlight(textView)
        }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        weak var textView: CodeTextView?
        private(set) var fileID: UUID?
        private(set) var reloadToken: Int = -1
        private var loadedFile: SourceFile?
        private var highlightWork: DispatchWorkItem?
        var appliedFontSize: CGFloat = 0
        var appliedHighlight = true
        var appliedThemeID: String = ""
        var appliedWrap: Bool?

        init(parent: EditorView) {
            self.parent = parent
        }

        // MARK: document loading

        func load(file: SourceFile, into textView: CodeTextView, force: Bool) {
            if !force, fileID == file.id, reloadToken == file.reloadToken { return }
            if let old = loadedFile, old.id != file.id {
                old.savedSelection = textView.selectedRange()
            }
            textView.string = file.text
            textView.undoManager?.removeAllActions()
            let length = (file.text as NSString).length
            var selection = file.savedSelection
            if selection.location > length || selection.location < 0 {
                selection = NSRange(location: 0, length: 0)
            }
            textView.setSelectedRange(selection)
            textView.scrollRangeToVisible(selection)
            fileID = file.id
            reloadToken = file.reloadToken
            loadedFile = file
            EditorBridge.shared.activeFile = file
            applyHighlight(textView)
            updateCursor(file: file, textView: textView)
            if let pending = EditorBridge.shared.pendingLine {
                EditorBridge.shared.pendingLine = nil
                textView.goTo(line: pending)
            }
        }

        // MARK: appearance

        func applyHighlight(_ textView: CodeTextView) {
            SyntaxHighlighter.apply(to: textView,
                                    theme: parent.theme,
                                    fontSize: CGFloat(parent.settings.fontSize),
                                    enabled: parent.settings.highlight)
            textView.highlightCurrentLine = parent.settings.highlightCurrentLine
            textView.needsDisplay = true
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        func applyWrap(_ wrap: Bool, textView: CodeTextView, scrollView: NSScrollView) {
            guard let container = textView.textContainer else { return }
            if wrap {
                textView.isHorizontallyResizable = false
                textView.autoresizingMask = [.width]
                container.widthTracksTextView = true
                container.containerSize = NSSize(width: scrollView.contentSize.width,
                                                 height: CGFloat.greatestFiniteMagnitude)
                textView.setFrameSize(NSSize(width: scrollView.contentSize.width,
                                             height: max(textView.frame.height, scrollView.contentSize.height)))
            } else {
                container.widthTracksTextView = false
                container.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                 height: CGFloat.greatestFiniteMagnitude)
                textView.isHorizontallyResizable = true
                textView.autoresizingMask = []
            }
            textView.needsDisplay = true
        }

        // MARK: delegate

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            if let file = loadedFile, file.text != textView.string {
                file.text = textView.string
                file.isDirty = true
            }
            scheduleHighlight()
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView, let file = loadedFile else { return }
            updateCursor(file: file, textView: textView)
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        private func updateCursor(file: SourceFile, textView: CodeTextView) {
            let selection = textView.selectedRange()
            file.savedSelection = selection
            let line = textView.lineNumber(atCharacterIndex: selection.location)
            let column = textView.column(atCharacterIndex: selection.location)
            if file.cursorLine != line { file.cursorLine = line }
            if file.cursorColumn != column { file.cursorColumn = column }
            if file.selectionLength != selection.length { file.selectionLength = selection.length }
        }

        private func scheduleHighlight() {
            highlightWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self, let textView = self.textView else { return }
                self.applyHighlight(textView)
            }
            highlightWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
        }
    }
}
