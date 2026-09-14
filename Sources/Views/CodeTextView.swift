import AppKit

/// The editing surface: an NSTextView with Dev-C++-style behaviour — smart
/// indentation on `{`, tab handling, current line highlight and a handful of
/// editor commands used by the menus.
final class CodeTextView: NSTextView {

    var tabWidth: Int = 4
    var insertSpaces: Bool = true
    var smartIndent: Bool = true
    var highlightCurrentLine: Bool = false
    var theme: EditorTheme = .classicLight

    // MARK: - Indentation helpers

    var indentUnit: String {
        insertSpaces ? String(repeating: " ", count: max(1, tabWidth)) : "\t"
    }

    override func insertTab(_ sender: Any?) {
        insertText(indentUnit, replacementRange: selectedRange())
    }

    override func insertBacktab(_ sender: Any?) {
        unindentSelection()
    }

    override func insertNewline(_ sender: Any?) {
        guard smartIndent, let storage = textStorage else {
            super.insertNewline(sender)
            return
        }
        let ns = storage.string as NSString
        let selection = selectedRange()
        let safeLocation = min(selection.location, ns.length)
        let lineRange = ns.lineRange(for: NSRange(location: safeLocation, length: 0))
        let line = ns.substring(with: lineRange)
        let leading = line.prefix { $0 == " " || $0 == "\t" }
        let opensBlock = line.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("{")
        super.insertNewline(sender)
        let insertion = String(leading) + (opensBlock ? indentUnit : "")
        if !insertion.isEmpty {
            insertText(insertion, replacementRange: selectedRange())
        }
    }

    override func insertText(_ string: Any, replacementRange: NSRange) {
        // Typing '}' on a whitespace-only line lines it up with the block opener.
        if smartIndent, let text = string as? String, text == "}" {
            let ns = self.string as NSString
            let selection = selectedRange()
            let lineRange = ns.lineRange(for: NSRange(location: min(selection.location, ns.length), length: 0))
            let prefixLength = selection.location - lineRange.location
            if prefixLength > 0 {
                let prefix = ns.substring(with: NSRange(location: lineRange.location, length: prefixLength))
                if !prefix.isEmpty, prefix.allSatisfy({ $0 == " " || $0 == "\t" }) {
                    let unit = indentUnit
                    if prefix.hasSuffix(unit) {
                        let replacement = String(prefix.dropLast(unit.count)) + "}"
                        super.insertText(replacement,
                                         replacementRange: NSRange(location: lineRange.location, length: prefixLength))
                        return
                    }
                }
            }
        }
        super.insertText(string, replacementRange: replacementRange)
    }

    // MARK: - Line helpers

    func lineNumber(atCharacterIndex index: Int) -> Int {
        let ns = string as NSString
        var line = 1
        var scan = 0
        let target = max(0, min(index, ns.length))
        while scan < target {
            let range = ns.lineRange(for: NSRange(location: scan, length: 0))
            let next = NSMaxRange(range)
            if next <= scan { break }
            if next <= target { line += 1 }
            scan = next
        }
        return line
    }

    func characterIndex(forLine line: Int) -> Int {
        let ns = string as NSString
        guard line > 1 else { return 0 }
        var current = 1
        var scan = 0
        while current < line, scan < ns.length {
            let range = ns.lineRange(for: NSRange(location: scan, length: 0))
            let next = NSMaxRange(range)
            if next <= scan { break }
            scan = next
            current += 1
        }
        return min(scan, ns.length)
    }

    func column(atCharacterIndex index: Int) -> Int {
        let ns = string as NSString
        let location = max(0, min(index, ns.length))
        let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))
        return location - lineRange.location + 1
    }

    func goTo(line: Int) {
        let index = characterIndex(forLine: max(1, line))
        setSelectedRange(NSRange(location: index, length: 0))
        scrollRangeToVisible(NSRange(location: index, length: 0))
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    func currentLineRange() -> NSRange {
        let ns = string as NSString
        let location = max(0, min(selectedRange().location, ns.length))
        return ns.lineRange(for: NSRange(location: location, length: 0))
    }

    // MARK: - Comment toggling (⌘/)

    func toggleLineComment() {
        let ns = string as NSString
        let selection = selectedRange()
        let startLineRange = ns.lineRange(for: NSRange(location: max(0, min(selection.location, ns.length)), length: 0))
        let effectiveLength = max(0, NSMaxRange(selection) - startLineRange.location)
        let blockRange = ns.lineRange(for: NSRange(location: startLineRange.location,
                                                    length: min(effectiveLength, ns.length - startLineRange.location)))

        // Collect the individual lines of the block.
        var lines: [NSRange] = []
        var scan = blockRange.location
        while scan < NSMaxRange(blockRange) {
            let range = ns.lineRange(for: NSRange(location: scan, length: 0))
            lines.append(range)
            let next = NSMaxRange(range)
            if next <= scan { break }
            scan = next
        }

        let allCommented = lines.allSatisfy { line in
            let text = ns.substring(with: line)
            return text.trimmingCharacters(in: .whitespaces).hasPrefix("//") || text.trimmingCharacters(in: .whitespaces).isEmpty
        }

        let fullText = NSMutableString(string: string)
        if allCommented {
            for line in lines.reversed() {
                let text = ns.substring(with: line)
                guard let range = text.range(of: "//") else { continue }
                let offset = text.distance(from: text.startIndex, to: range.lowerBound)
                let length = text[range.upperBound...].hasPrefix(" ") ? 3 : 2
                fullText.deleteCharacters(in: NSRange(location: line.location + offset, length: length))
            }
        } else {
            for line in lines.reversed() {
                let text = ns.substring(with: line)
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                let indentLength = text.prefix { $0 == " " || $0 == "\t" }.count
                fullText.insert("// ", at: line.location + indentLength)
            }
        }

        let newText = fullText as String
        let fullRange = NSRange(location: 0, length: ns.length)
        if shouldChangeText(in: fullRange, replacementString: newText) {
            replaceCharacters(in: fullRange, with: newText)
            didChangeText()
        }
    }

    // MARK: - Current line highlight

    override func setSelectedRanges(_ ranges: [NSValue],
                                    affinity: NSSelectionAffinity,
                                    stillSelecting: Bool) {
        super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
        if highlightCurrentLine { needsDisplay = true }
    }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        guard highlightCurrentLine,
              let layoutManager, let textContainer, (string as NSString).length > 0 else { return }
        let lineRange = currentLineRange()
        let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        guard glyphRange.length > 0 else { return }
        var fragment = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        fragment.origin.y += textContainerInset.height
        guard fragment.height > 0 else { return }
        let highlight = NSRect(x: 0, y: fragment.minY, width: bounds.width, height: fragment.height)
        theme.currentLine.setFill()
        highlight.fill()
    }

    func unindentSelection() {
        let ns = string as NSString
        let lineRange = currentLineRange()
        let line = ns.substring(with: lineRange)
        let leading = line.prefix { $0 == " " || $0 == "\t" }
        guard !leading.isEmpty else { return }
        let unit = indentUnit
        let removeCount = min(unit.count, leading.count)
        let replacement = String(line.dropFirst(removeCount))
        if shouldChangeText(in: lineRange, replacementString: replacement) {
            replaceCharacters(in: lineRange, with: replacement)
            didChangeText()
        }
    }
}
