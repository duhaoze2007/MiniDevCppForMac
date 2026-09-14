import AppKit

/// C syntax highlighting, written from scratch (no external highlighter), using
/// the Dev-C++ 4.9.9.2 palette: bold blue reserved words, navy preprocessor
/// directives and string literals, grey comments.
enum SyntaxHighlighter {

    enum Kind {
        case keyword, preprocessor, comment, string, number
    }

    struct Token {
        let range: NSRange
        let kind: Kind
    }

    // C17 + common C23 reserved words, plus the identifiers students write in
    // the first weeks (true/false/bool/NULL-ish macros are deliberately not
    // treated as keywords — Dev-C++ colours reserved words only).
    static let keywords: Set<String> = [
        "auto", "break", "case", "char", "const", "continue", "default", "do",
        "double", "else", "enum", "extern", "float", "for", "goto", "if",
        "inline", "int", "long", "register", "restrict", "return", "short",
        "signed", "sizeof", "static", "struct", "switch", "typedef", "union",
        "unsigned", "void", "volatile", "while",
        "_Bool", "_Complex", "_Imaginary", "_Alignas", "_Alignof", "_Atomic",
        "_Generic", "_Noreturn", "_Static_assert", "_Thread_local", "_BitInt",
        "alignas", "alignof", "bool", "constexpr", "false", "nullptr",
        "static_assert", "thread_local", "true", "typeof", "typeof_unqual",
        "asm", "__asm__", "__attribute__", "__restrict", "__inline", "__volatile__"
    ]

    // MARK: - Public API

    static func apply(to textView: NSTextView, theme: EditorTheme, fontSize: CGFloat, enabled: Bool) {
        guard let storage = textView.textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        let font = EditorTheme.monoFont(size: fontSize)
        let bold = EditorTheme.monoBoldFont(size: fontSize)
        let base: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.text,
            .font: font
        ]

        // Attribute edits must not enter the undo stack.
        let undo = textView.undoManager
        let undoWasEnabled = undo?.isUndoRegistrationEnabled ?? false
        if undoWasEnabled { undo?.disableUndoRegistration() }

        storage.beginEditing()
        storage.setAttributes(base, range: full)
        if enabled {
            for token in tokens(in: storage.string) {
                var attrs: [NSAttributedString.Key: Any] = [:]
                switch token.kind {
                case .keyword:      attrs[.foregroundColor] = theme.keyword;      attrs[.font] = bold
                case .preprocessor: attrs[.foregroundColor] = theme.preprocessor; attrs[.font] = bold
                case .comment:      attrs[.foregroundColor] = theme.comment
                case .string:       attrs[.foregroundColor] = theme.string
                case .number:       attrs[.foregroundColor] = theme.number
                }
                storage.addAttributes(attrs, range: token.range)
            }
        }
        storage.endEditing()

        if undoWasEnabled { undo?.enableUndoRegistration() }
        textView.typingAttributes = base
    }

    // MARK: - Scanner

    static func tokens(in text: String) -> [Token] {
        let ns = text as NSString
        let length = ns.length
        guard length > 0 else { return [] }

        var chars = [unichar](repeating: 0, count: length)
        ns.getCharacters(&chars, range: NSRange(location: 0, length: length))

        var result: [Token] = []
        var i = 0
        var lineHasCode = false      // becomes false after a newline, so '#…' is recognised

        func isIdentStart(_ c: unichar) -> Bool {
            (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c > 127
        }
        func isIdentBody(_ c: unichar) -> Bool {
            isIdentStart(c) || (c >= 48 && c <= 57)
        }
        func isDigit(_ c: unichar) -> Bool { c >= 48 && c <= 57 }

        while i < length {
            let c = chars[i]

            switch c {
            case 10, 13:                                   // newline
                lineHasCode = false
                i += 1

            case 32, 9:                                    // space / tab
                i += 1

            case 47 where i + 1 < length && chars[i + 1] == 47:      // //
                var j = i
                while j < length && chars[j] != 10 && chars[j] != 13 { j += 1 }
                result.append(Token(range: NSRange(location: i, length: j - i), kind: .comment))
                i = j

            case 47 where i + 1 < length && chars[i + 1] == 42:      // /*
                var j = i + 2
                while j + 1 < length && !(chars[j] == 42 && chars[j + 1] == 47) { j += 1 }
                let end = min(length, j + 2)
                result.append(Token(range: NSRange(location: i, length: end - i), kind: .comment))
                i = end

            case 34:                                                  // "string"
                var j = i + 1
                while j < length {
                    if chars[j] == 92 { j += 2; continue }
                    if chars[j] == 34 { j += 1; break }
                    if chars[j] == 10 { break }
                    j += 1
                }
                let end = min(j, length)
                result.append(Token(range: NSRange(location: i, length: end - i), kind: .string))
                i = end

            case 39:                                                  // 'c'
                var j = i + 1
                while j < length {
                    if chars[j] == 92 { j += 2; continue }
                    if chars[j] == 39 { j += 1; break }
                    if chars[j] == 10 { break }
                    j += 1
                }
                let end = min(j, length)
                result.append(Token(range: NSRange(location: i, length: end - i), kind: .string))
                i = end

            case 35:                                                  // #directive
                if !lineHasCode {
                    var j = i
                    while j < length {
                        if chars[j] == 92 {                       // line continuation
                            j += 2
                            // skip the newline following a backslash
                            while j < length && (chars[j] == 10 || chars[j] == 13) { j += 1 }
                            continue
                        }
                        if chars[j] == 10 || chars[j] == 13 { break }
                        j += 1
                    }
                    let end = min(j, length)
                    result.append(Token(range: NSRange(location: i, length: end - i), kind: .preprocessor))
                    i = end
                    lineHasCode = true
                } else {
                    i += 1
                    lineHasCode = true
                }

            default:
                if isDigit(c) {
                    var j = i
                    while j < length {
                        let d = chars[j]
                        let isNumberChar = isDigit(d) || d == 46 /* . */ || d == 120 || d == 88
                            || (d >= 97 && d <= 102) || (d >= 65 && d <= 70)
                            || d == 95 || d == 117 || d == 85 || d == 108 || d == 76 || d == 102 || d == 70
                        if !isNumberChar { break }
                        // stop before a plain identifier (e.g. `123abc` handled loosely)
                        j += 1
                    }
                    result.append(Token(range: NSRange(location: i, length: j - i), kind: .number))
                    i = j
                    lineHasCode = true
                } else if isIdentStart(c) {
                    var j = i
                    while j < length && isIdentBody(chars[j]) { j += 1 }
                    let word = ns.substring(with: NSRange(location: i, length: j - i))
                    if keywords.contains(word) {
                        result.append(Token(range: NSRange(location: i, length: j - i), kind: .keyword))
                    }
                    i = j
                    lineHasCode = true
                } else {
                    if c > 32 { lineHasCode = true }
                    i += 1
                }
            }
        }
        return result
    }
}
