import AppKit

/// Gutter showing line numbers, drawn in the Dev-C++ palette.
final class LineNumberRulerView: NSRulerView {

    var theme: EditorTheme = .classicLight {
        didSet { needsDisplay = true }
    }
    private var numberFont: NSFont = EditorTheme.monoFont(size: 11)

    weak var codeTextView: CodeTextView?

    init(textView: CodeTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.codeTextView = textView
        self.ruleThickness = 44
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFont(size: CGFloat) {
        numberFont = EditorTheme.monoFont(size: max(8, size - 2))
        needsDisplay = true
    }

    private func rectForLine(_ lineRange: NSRange,
                             layoutManager: NSLayoutManager,
                             textContainer: NSTextContainer,
                             content: NSString) -> NSRect {
        let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        if glyphRange.length > 0 {
            return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        }
        if lineRange.location >= content.length, layoutManager.extraLineFragmentTextContainer != nil {
            return layoutManager.extraLineFragmentRect
        }
        let characterIndex = min(lineRange.location, max(0, content.length - 1))
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        return layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = codeTextView ?? (clientView as? CodeTextView),
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let colors = theme
        colors.gutterBackground.setFill()
        bounds.fill()
        colors.gutterSeparator.setFill()
        NSRect(x: bounds.width - 1, y: 0, width: 1, height: bounds.height).fill()

        let content = textView.string as NSString
        let visibleRect = textView.visibleRect
        let inset = textView.textContainerInset

        // number of digits determines the gutter width
        let totalLines = max(1, lineCount(of: content))
        let digits = "\(totalLines)".count
        let charWidth = ("0" as NSString).size(withAttributes: [.font: numberFont]).width
        let desiredThickness = CGFloat(digits) * charWidth + 18
        if abs(desiredThickness - ruleThickness) > 0.5 {
            ruleThickness = desiredThickness
        }

        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // line number of the first visible line
        var lineNumber = 1
        var scan = 0
        while scan < charRange.location {
            let range = content.lineRange(for: NSRange(location: scan, length: 0))
            let next = NSMaxRange(range)
            if next <= scan { break }
            if next <= charRange.location { lineNumber += 1 }
            scan = next
        }

        let currentLine = textView.lineNumber(atCharacterIndex: textView.selectedRange().location)
        var index = charRange.location
        var guardCounter = 0

        while index < NSMaxRange(charRange), guardCounter < 5000 {
            guardCounter += 1
            let lineRange = content.lineRange(for: NSRange(location: index, length: 0))
            var fragment = rectForLine(lineRange, layoutManager: layoutManager,
                                       textContainer: textContainer, content: content)
            fragment.origin.y += inset.height
            let y = fragment.minY - visibleRect.minY
            let height = fragment.height > 0
                ? fragment.height
                : (numberFont.ascender - numberFont.descender + numberFont.leading)

            let isCurrent = lineNumber == currentLine && textView.highlightCurrentLine
            let attributes: [NSAttributedString.Key: Any] = [
                .font: numberFont,
                .foregroundColor: isCurrent ? colors.text : colors.gutterText
            ]
            let number = "\(lineNumber)" as NSString
            let size = number.size(withAttributes: attributes)
            let drawPoint = NSPoint(x: bounds.width - size.width - 8,
                                   y: y + (height - size.height) / 2)
            if drawPoint.y + size.height >= -2, drawPoint.y <= bounds.height + 2 {
                number.draw(at: drawPoint, withAttributes: attributes)
            }

            let next = NSMaxRange(lineRange)
            if next <= index { break }
            index = next
            lineNumber += 1
        }
    }

    private func lineCount(of content: NSString) -> Int {
        var count = 1
        var index = 0
        while index < content.length {
            let range = content.lineRange(for: NSRange(location: index, length: 0))
            let next = NSMaxRange(range)
            if next <= index { break }
            index = next
            if index <= content.length { count += 1 }
        }
        return count
    }
}
