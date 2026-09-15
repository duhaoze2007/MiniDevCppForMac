import Foundation

// MARK: - Supported languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    /// Language actually used for lookups (resolves `.system`).
    var resolved: AppLanguage {
        self == .system ? AppLanguage.detectSystem() : self
    }

    static func detectSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW")
            || preferred.hasPrefix("zh-HK") || preferred.hasPrefix("zh-MO") {
            return .traditionalChinese
        }
        if preferred.hasPrefix("zh") { return .simplifiedChinese }
        return .english
    }

    /// Endonym shown in the language picker.
    var displayName: String {
        switch self {
        case .system: return ""            // filled by localized string
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }
}

// MARK: - Translation keys

enum LKey: String, CaseIterable {
    // menus
    case menuFile, menuEdit, menuSearch, menuView, menuProject, menuExecute, menuTools, menuHelp
    // app / about
    case appName, appTagline, aboutCreditsTitle, aboutCreditsIntro
    case aboutCreditDevCppTitle, aboutCreditDevCppText
    case aboutCreditOrwellTitle, aboutCreditOrwellText
    case aboutCreditClangTitle, aboutCreditClangText
    case aboutCreditSwiftTitle, aboutCreditSwiftText
    case aboutLicenseTitle, aboutLicenseText, aboutSystemTitle, aboutSystemRow
    case aboutCopyright
    // file menu
    case fileNew, fileOpen, fileOpenFolder, fileSave, fileSaveAs, fileSaveAll
    case fileClose, fileCloseAll, fileCloseProject, filePrint, fileExit
    // edit menu
    case editUndo, editRedo, editCut, editCopy, editPaste, editDelete, editSelectAll, editToggleComment
    // search menu
    case searchFind, searchFindNext, searchFindPrev, searchReplace, searchGoToLine
    case gotoTitle, gotoLabel, gotoOK, msgInvalidLine
    // view menu
    case viewProjectPane, viewOutputPane, viewAppearance, viewThemeSystem, viewThemeLight, viewThemeDark
    case viewFontBigger, viewFontSmaller, viewFontReset, viewFullScreen
    case viewLineNumbers, viewWrapLines, viewHighlight, viewHighlightLine, viewToolbarLabels
    // standard menu titles that AppKit would otherwise localize from the system
    case menuWindow
    // project menu
    case projectOpenFolder, projectReload, projectShowInFinder, projectNewFile
    // execute menu
    case execCompile, execRun, execCompileRun, execRebuild, execClean, execStop, execTerminal, execParameters
    // tools menu
    case toolsEditorOptions, toolsCompilerOptions, toolsClearConsole, toolsOpenBuildFolder
    // help menu
    case helpUsage, helpAbout
    // toolbar tooltips
    case tbNew, tbOpen, tbOpenFolder, tbSave, tbSaveAll, tbClose, tbCompile, tbRun, tbCompileRun
    case tbRebuild, tbStop, tbFind, tbOptions, tbParameters, tbTerminal
    // short captions shown under the toolbar icons
    case btNew, btOpen, btOpenFolder, btSave, btSaveAll, btClose, btCompile, btRun, btCompileRun
    case btRebuild, btStop, btFind, btParams, btTerminal, btProject, btOutput, btOptions
    // panels
    case paneProject, paneOpenFiles, paneNoProject
    case welcomeTitle, welcomeHint, welcomeNew, welcomeOpen
    case consoleTabCompiler, consoleTabProgram, consoleClear, consoleStdin, consoleSend, consoleEof
    case consoleExitCode, consoleNoOutput, consoleIdle, consoleStop
    // status bar
    case statusReady, statusCompiling, statusRunning, statusSavedMsg
    case statusLine, statusColumn, statusModified, statusSel, statusNoFile, statusProblems
    // messages
    case msgBuildOK, msgBuildOKWarn, msgBuildFail, msgProgramFinished, msgProgramStopped
    case msgNoSourceFiles, msgCompilerMissing, msgProgramNotBuilt
    case msgSaveFailed, msgLoadFailed, msgUnsavedTitle, msgUnsavedBody
    case btnSave, btnDiscard, btnCancel
    // run parameters
    case paramTitle, paramArgs, paramArgsHint, paramStdin, paramStdinHint, paramOK
    // settings
    case settingsTitle, settingsGeneral, settingsEditor, settingsCompiler
    case settingsLanguage, settingsLanguageHint, settingsAppearance
    case settingsFontSize, settingsTabWidth, settingsInsertSpaces, settingsLineNumbers
    case settingsHighlight, settingsSmartIndent, settingsWrap, settingsHighlightLine
    case settingsShowProject, settingsShowConsole
    case settingsCompilerPath, settingsCompilerDetected, settingsStandard, settingsFlags, settingsFlagsHint
    case settingsDebug, settingsOutDir, settingsOutSameDir, settingsOutBuildDir
    case settingsDefaults, settingsDone, settingsVersion, settingsOfflineNote
    // help window
    case helpTitle, helpIntro, helpSecEditing, helpSecBuild, helpSecProject, helpSecSettings
    case helpBodyEditing, helpBodyBuild, helpBodyProject, helpBodySettings, helpShortcuts
    // first launch
    case flTitle, flBody, flPrivacyTitle, flBody2, btnAgree, btnDisagree
}

// MARK: - Translation table  (en, zh-Hans, zh-Hant)

enum L10n {
    static func string(_ key: LKey, _ language: AppLanguage) -> String {
        guard let row = table[key], row.count == 3 else { return key.rawValue }
        switch language {
        case .simplifiedChinese: return row[1]
        case .traditionalChinese: return row[2]
        default: return row[0]
        }
    }

    private static let table: [LKey: [String]] = [
        // ── menus ──────────────────────────────────────────────────────────
        .menuFile: ["File", "文件", "檔案"],
        .menuEdit: ["Edit", "编辑", "編輯"],
        .menuSearch: ["Search", "搜索", "搜尋"],
        .menuView: ["View", "显示", "顯示方式"],
        .menuProject: ["Project", "项目", "專案"],
        .menuExecute: ["Execute", "执行", "執行"],
        .menuTools: ["Tools", "工具", "工具"],
        .menuHelp: ["Help", "帮助", "說明"],

        // ── app / about ────────────────────────────────────────────────────
        .appName: ["Mini Dev-C++", "Mini Dev-C++", "Mini Dev-C++"],
        .appTagline: [
            "A lightweight C IDE for macOS, modelled on Dev-C++ 4.9.9.2",
            "复刻 Dev-C++ 4.9.9.2 的 macOS 轻量级 C 语言 IDE",
            "復刻 Dev-C++ 4.9.9.2 的 macOS 輕量級 C 語言 IDE"
        ],
        .aboutCreditsTitle: ["Credits", "致谢", "致謝"],
        .aboutCreditsIntro: [
            "Mini Dev-C++ is an independent re-implementation for macOS. It would not exist without the free and open source projects below — thanks to their authors and maintainers.",
            "Mini Dev-C++ 是为 macOS 独立重新实现的版本。没有以下自由与开源项目，就没有这个程序 —— 感谢它们的作者与维护者。",
            "Mini Dev-C++ 是為 macOS 獨立重新實作的版本。沒有以下自由與開源專案，就沒有這個程式 —— 感謝它們的作者與維護者。"
        ],
        .aboutCreditDevCppTitle: [
            "Dev-C++ 4.9.9.2 — Bloodshed Software",
            "Dev-C++ 4.9.9.2 — Bloodshed Software",
            "Dev-C++ 4.9.9.2 — Bloodshed Software"
        ],
        .aboutCreditDevCppText: [
            "The original IDE by Colin Laplace and the Bloodshed Software team (1998–2005). Its layout, menus and workflow are what this app recreates. Released under the GNU GPL.",
            "由 Colin Laplace 与 Bloodshed Software 团队开发的原版 IDE（1998–2005）。本程序的界面布局、菜单结构和工作流程均以其为蓝本复刻。原项目以 GNU GPL 发布。",
            "由 Colin Laplace 與 Bloodshed Software 團隊開發的原版 IDE（1998–2005）。本程式的介面佈局、選單結構與工作流程均以其為藍本復刻。原專案以 GNU GPL 發佈。"
        ],
        .aboutCreditOrwellTitle: [
            "Orwell Dev-C++ — Orwelldevcpp Team",
            "Orwell Dev-C++ — Orwelldevcpp 团队",
            "Orwell Dev-C++ — Orwelldevcpp 團隊"
        ],
        .aboutCreditOrwellText: [
            "The community fork that kept Dev-C++ alive after 2005; several defaults in this app follow it. GNU GPL.",
            "2005 年之后延续 Dev-C++ 生命的社区分支，本程序的部分默认设置参考了它。GNU GPL。",
            "2005 年之後延續 Dev-C++ 生命的社群分支，本程式的部分預設設定參考了它。GNU GPL。"
        ],
        .aboutCreditClangTitle: [
            "LLVM / Clang — LLVM Project",
            "LLVM / Clang — LLVM 项目",
            "LLVM / Clang — LLVM 專案"
        ],
        .aboutCreditClangText: [
            "The compiler this IDE drives (Apple clang from the Xcode Command Line Tools). Licensed under Apache 2.0 with LLVM Exceptions.",
            "本 IDE 所调用的编译器（Xcode 命令行工具中的 Apple clang）。以 Apache 2.0 with LLVM Exceptions 授权。",
            "本 IDE 所呼叫的編譯器（Xcode 命令列工具中的 Apple clang）。以 Apache 2.0 with LLVM Exceptions 授權。"
        ],
        .aboutCreditSwiftTitle: [
            "SwiftUI, AppKit & SF Symbols — Apple Inc.",
            "SwiftUI、AppKit 与 SF Symbols — Apple Inc.",
            "SwiftUI、AppKit 與 SF Symbols — Apple Inc."
        ],
        .aboutCreditSwiftText: [
            "The interface is built entirely on Apple's frameworks; menus, panels and toolbars use system-provided components.",
            "界面完全基于 Apple 框架构建，菜单、对话框与工具栏使用系统提供的组件。",
            "介面完全基於 Apple 框架構建，選單、對話框與工具列使用系統提供的元件。"
        ],
        .aboutLicenseTitle: ["License", "许可", "授權"],
        .aboutLicenseText: [
            "Mini Dev-C++ is released under the MIT License. It contains no code from Dev-C++; the original project is credited as the design reference only.",
            "Mini Dev-C++ 以 MIT 许可证发布。程序不包含任何 Dev-C++ 的代码，原项目仅作为设计参考予以致谢。",
            "Mini Dev-C++ 以 MIT 授權條款發佈。程式不包含任何 Dev-C++ 的程式碼，原專案僅作為設計參考予以致謝。"
        ],
        .aboutSystemTitle: ["Compiler in use", "当前编译器", "目前編譯器"],
        .aboutSystemRow: [
            "Apple clang %@ — %@",
            "Apple clang %@ — %@",
            "Apple clang %@ — %@"
        ],
        .aboutCopyright: [
            "Copyright © 2026 Du Haoze. All rights reserved.",
            "Copyright © 2026 Du Haoze. 保留所有权利。",
            "Copyright © 2026 Du Haoze. 保留所有權利。"
        ],

        // ── file menu ──────────────────────────────────────────────────────
        .fileNew: ["New", "新建", "新增"],
        .fileOpen: ["Open…", "打开…", "開啟…"],
        .fileOpenFolder: ["Open Folder as Project…", "打开文件夹作为项目…", "開啟資料夾為專案…"],
        .fileSave: ["Save", "保存", "儲存"],
        .fileSaveAs: ["Save As…", "另存为…", "另存新檔…"],
        .fileSaveAll: ["Save All", "全部保存", "全部儲存"],
        .fileClose: ["Close", "关闭", "關閉"],
        .fileCloseAll: ["Close All", "关闭全部", "關閉全部"],
        .fileCloseProject: ["Close Project", "关闭项目", "關閉專案"],
        .filePrint: ["Print…", "打印…", "列印…"],
        .fileExit: ["Quit Mini Dev-C++", "退出 Mini Dev-C++", "結束 Mini Dev-C++"],

        // ── edit menu ──────────────────────────────────────────────────────
        .editUndo: ["Undo", "撤销", "還原"],
        .editRedo: ["Redo", "重做", "重做"],
        .editCut: ["Cut", "剪切", "剪下"],
        .editCopy: ["Copy", "复制", "拷貝"],
        .editPaste: ["Paste", "粘贴", "貼上"],
        .editDelete: ["Delete", "删除", "刪除"],
        .editSelectAll: ["Select All", "全选", "全選"],
        .editToggleComment: ["Toggle Comment", "注释/取消注释", "註解/取消註解"],

        // ── search menu ────────────────────────────────────────────────────
        .searchFind: ["Find…", "查找…", "尋找…"],
        .searchFindNext: ["Find Next", "查找下一个", "尋找下一個"],
        .searchFindPrev: ["Find Previous", "查找上一个", "尋找上一個"],
        .searchReplace: ["Replace…", "替换…", "取代…"],
        .searchGoToLine: ["Go to Line…", "转到行…", "跳到行…"],
        .gotoTitle: ["Go to Line", "转到行", "跳到行"],
        .gotoLabel: ["Line number", "行号", "行號"],
        .gotoOK: ["Go", "跳转", "跳轉"],
        .msgInvalidLine: ["Please enter a valid line number.", "请输入有效的行号。", "請輸入有效的行號。"],

        // ── view menu ──────────────────────────────────────────────────────
        .viewProjectPane: ["Project Explorer", "项目浏览器", "專案瀏覽器"],
        .viewOutputPane: ["Output Window", "输出窗口", "輸出視窗"],
        .viewAppearance: ["Appearance", "外观", "外觀"],
        .viewThemeSystem: ["Follow System", "跟随系统", "跟隨系統"],
        .viewThemeLight: ["Light", "浅色", "淺色"],
        .viewThemeDark: ["Dark", "深色", "深色"],
        .viewFontBigger: ["Bigger Editor Font", "增大编辑器字号", "增大編輯器字級"],
        .viewFontSmaller: ["Smaller Editor Font", "减小编辑器字号", "減小編輯器字級"],
        .viewFontReset: ["Reset Editor Font", "重置编辑器字号", "重設編輯器字級"],
        .viewFullScreen: ["Enter Full Screen", "进入全屏", "進入全螢幕"],
        .viewLineNumbers: ["Show Line Numbers", "显示行号", "顯示行號"],
        .viewWrapLines: ["Word Wrap", "自动换行", "自動換行"],
        .viewHighlight: ["Syntax Highlighting", "语法高亮", "語法高亮"],
        .viewHighlightLine: ["Highlight Current Line", "高亮当前行", "標示目前行"],
        .viewToolbarLabels: ["Button Labels", "显示按钮文字", "顯示按鈕文字"],
        .menuWindow: ["Window", "窗口", "視窗"],

        // ── project menu ───────────────────────────────────────────────────
        .projectOpenFolder: ["Open Folder as Project…", "打开文件夹作为项目…", "開啟資料夾為專案…"],
        .projectReload: ["Reload Project", "重新载入项目", "重新載入專案"],
        .projectShowInFinder: ["Reveal in Finder", "在访达中显示", "在 Finder 中顯示"],
        .projectNewFile: ["New File", "新建文件", "新增檔案"],

        // ── execute menu ───────────────────────────────────────────────────
        .execCompile: ["Compile", "编译", "編譯"],
        .execRun: ["Run", "运行", "執行"],
        .execCompileRun: ["Compile & Run", "编译并运行", "編譯並執行"],
        .execRebuild: ["Rebuild All", "全部重新编译", "全部重新編譯"],
        .execClean: ["Clean", "清理", "清除"],
        .execStop: ["Stop", "停止", "停止"],
        .execTerminal: ["Run in Terminal", "在终端中运行", "在終端機中執行"],
        .execParameters: ["Run Parameters…", "运行参数…", "執行參數…"],

        // ── tools menu ─────────────────────────────────────────────────────
        .toolsEditorOptions: ["Editor Options…", "编辑器选项…", "編輯器選項…"],
        .toolsCompilerOptions: ["Compiler Options…", "编译器选项…", "編譯器選項…"],
        .toolsClearConsole: ["Clear Output", "清空输出", "清空輸出"],
        .toolsOpenBuildFolder: ["Open Output Folder", "打开输出文件夹", "開啟輸出資料夾"],

        // ── help menu ──────────────────────────────────────────────────────
        .helpUsage: ["Mini Dev-C++ Help", "Mini Dev-C++ 使用帮助", "Mini Dev-C++ 使用說明"],
        .helpAbout: ["About Mini Dev-C++", "关于 Mini Dev-C++", "關於 Mini Dev-C++"],

        // ── toolbar ────────────────────────────────────────────────────────
        .tbNew: ["New file", "新建文件", "新增檔案"],
        .tbOpen: ["Open file", "打开文件", "開啟檔案"],
        .tbOpenFolder: ["Open folder as project", "打开文件夹作为项目", "開啟資料夾為專案"],
        .tbSave: ["Save", "保存", "儲存"],
        .tbSaveAll: ["Save all", "全部保存", "全部儲存"],
        .tbClose: ["Close file", "关闭文件", "關閉檔案"],
        .tbCompile: ["Compile (⌘B)", "编译（⌘B）", "編譯（⌘B）"],
        .tbRun: ["Run (⌘R)", "运行（⌘R）", "執行（⌘R）"],
        .tbCompileRun: ["Compile & Run (⌘⏎)", "编译并运行（⌘⏎）", "編譯並執行（⌘⏎）"],
        .tbRebuild: ["Rebuild all (⇧⌘B)", "全部重新编译（⇧⌘B）", "全部重新編譯（⇧⌘B）"],
        .tbStop: ["Stop the running program", "停止正在运行的程序", "停止正在執行的程式"],
        .tbFind: ["Find (⌘F)", "查找（⌘F）", "尋找（⌘F）"],
        .tbOptions: ["Options", "选项", "選項"],
        .tbParameters: ["Run parameters", "运行参数", "執行參數"],
        .tbTerminal: ["Run in Terminal", "在终端中运行", "在終端機中執行"],

        // ── toolbar captions ───────────────────────────────────────────────
        .btNew: ["New", "新建", "新增"],
        .btOpen: ["Open", "打开", "開啟"],
        .btOpenFolder: ["Open Folder", "打开目录", "開啟目錄"],
        .btSave: ["Save", "保存", "儲存"],
        .btSaveAll: ["Save All", "全部保存", "全部儲存"],
        .btClose: ["Close", "关闭", "關閉"],
        .btCompile: ["Compile", "编译", "編譯"],
        .btRun: ["Run", "运行", "執行"],
        .btCompileRun: ["Build & Run", "编译并运行", "編譯並執行"],
        .btRebuild: ["Rebuild", "重新编译", "重新編譯"],
        .btStop: ["Stop", "停止", "停止"],
        .btFind: ["Find", "查找", "尋找"],
        .btParams: ["Params", "运行参数", "執行參數"],
        .btTerminal: ["Terminal", "终端", "終端"],
        .btProject: ["Project", "项目栏", "專案欄"],
        .btOutput: ["Output", "输出栏", "輸出欄"],
        .btOptions: ["Options", "选项", "選項"],

        // ── panels ─────────────────────────────────────────────────────────
        .paneProject: ["Project", "项目", "專案"],
        .paneOpenFiles: ["Open Files", "打开的文件", "開啟的檔案"],
        .paneNoProject: ["No project opened", "未打开项目", "未開啟專案"],
        .welcomeTitle: ["No file is open", "没有打开的文件", "沒有開啟的檔案"],
        .welcomeHint: [
            "Press ⌘N for a new C source file, or ⌘O to open an existing one.",
            "按 ⌘N 新建 C 源文件，或按 ⌘O 打开已有文件。",
            "按 ⌘N 新增 C 原始檔，或按 ⌘O 開啟既有檔案。"
        ],
        .welcomeNew: ["New File", "新建文件", "新增檔案"],
        .welcomeOpen: ["Open File", "打开文件", "開啟檔案"],
        .consoleTabCompiler: ["Compiler", "编译器", "編譯器"],
        .consoleTabProgram: ["Program Output", "程序输出", "程式輸出"],
        .consoleClear: ["Clear", "清除", "清除"],
        .consoleStdin: ["Program input (stdin)", "程序输入（stdin）", "程式輸入（stdin）"],
        .consoleSend: ["Send", "发送", "送出"],
        .consoleEof: ["Send EOF", "结束输入", "結束輸入"],
        .consoleExitCode: ["Exit code", "退出码", "結束碼"],
        .consoleNoOutput: ["(no output yet)", "（暂无输出）", "（尚無輸出）"],
        .consoleIdle: ["Ready. No build has been run yet.", "就绪。尚未进行编译。", "就緒。尚未進行編譯。"],
        .consoleStop: ["Stop the program", "停止程序", "停止程式"],

        // ── status bar ─────────────────────────────────────────────────────
        .statusReady: ["Ready", "就绪", "就緒"],
        .statusCompiling: ["Compiling…", "正在编译…", "正在編譯…"],
        .statusRunning: ["Running…", "正在运行…", "正在執行…"],
        .statusSavedMsg: ["Saved", "已保存", "已儲存"],
        .statusLine: ["Line", "行", "行"],
        .statusColumn: ["Col", "列", "欄"],
        .statusModified: ["Modified", "已修改", "已修改"],
        .statusSel: ["Sel", "选中", "選取"],
        .statusNoFile: ["No file", "无文件", "無檔案"],
        .statusProblems: ["%d error(s), %d warning(s)", "%d 个错误，%d 个警告", "%d 個錯誤，%d 個警告"],

        // ── messages ───────────────────────────────────────────────────────
        .msgBuildOK: ["Build succeeded.", "编译成功。", "編譯成功。"],
        .msgBuildOKWarn: ["Build succeeded with %d warning(s).", "编译成功，%d 个警告。", "編譯成功，%d 個警告。"],
        .msgBuildFail: ["Build failed: %d error(s), %d warning(s).", "编译失败：%d 个错误，%d 个警告。", "編譯失敗：%d 個錯誤，%d 個警告。"],
        .msgProgramFinished: ["Program finished with exit code %d.", "程序结束，退出码 %d。", "程式結束，結束碼 %d。"],
        .msgProgramStopped: ["Program stopped.", "程序已停止。", "程式已停止。"],
        .msgNoSourceFiles: ["No C source file (*.c) found to compile.", "没有找到可编译的 C 源文件（*.c）。", "找不到可編譯的 C 來源檔（*.c）。"],
        .msgCompilerMissing: [
            "clang was not found at the configured path. Install the Xcode Command Line Tools with:  xcode-select --install",
            "未在指定路径找到 clang。请安装 Xcode 命令行工具：xcode-select --install",
            "未在指定路徑找到 clang。請安裝 Xcode 命令列工具：xcode-select --install"
        ],
        .msgProgramNotBuilt: ["Compile the program first.", "请先编译程序。", "請先編譯程式。"],
        .msgSaveFailed: ["Could not save the file: %@", "无法保存文件：%@", "無法儲存檔案：%@"],
        .msgLoadFailed: ["Could not open the file: %@", "无法打开文件：%@", "無法開啟檔案：%@"],
        .msgUnsavedTitle: ["Unsaved changes", "未保存的更改", "未儲存的變更"],
        .msgUnsavedBody: [
            "“%@” has unsaved changes. Save before closing?",
            "“%@” 有未保存的更改，关闭前是否保存？",
            "「%@」有未儲存的變更，關閉前是否儲存？"
        ],
        .btnSave: ["Save", "保存", "儲存"],
        .btnDiscard: ["Don't Save", "不保存", "不儲存"],
        .btnCancel: ["Cancel", "取消", "取消"],

        // ── run parameters ─────────────────────────────────────────────────
        .paramTitle: ["Run Parameters", "运行参数", "執行參數"],
        .paramArgs: ["Command line arguments", "命令行参数", "命令列參數"],
        .paramArgsHint: ["Passed to your program as argv[1…].", "作为 argv[1…] 传给程序。", "作為 argv[1…] 傳給程式。"],
        .paramStdin: ["Standard input", "标准输入", "標準輸入"],
        .paramStdinHint: [
            "Written to stdin when the program starts.",
            "程序启动时写入到标准输入。",
            "程式啟動時寫入至標準輸入。"
        ],
        .paramOK: ["OK", "确定", "確定"],

        // ── settings ───────────────────────────────────────────────────────
        .settingsTitle: ["Options", "选项", "選項"],
        .settingsGeneral: ["General", "常规", "一般"],
        .settingsEditor: ["Editor", "编辑器", "編輯器"],
        .settingsCompiler: ["Compiler", "编译器", "編譯器"],
        .settingsLanguage: ["Language / 语言", "语言 / Language", "語言 / Language"],
        .settingsLanguageHint: [
            "App menus update immediately; the system menu bar follows after a restart.",
            "程序内菜单立即切换，系统菜单栏在重启后完全生效。",
            "程式內選單立即切換，系統選單列在重新啟動後完全生效。"
        ],
        .settingsAppearance: ["Appearance", "外观", "外觀"],
        .settingsFontSize: ["Font size", "字号", "字級"],
        .settingsTabWidth: ["Tab width", "Tab 宽度", "Tab 寬度"],
        .settingsInsertSpaces: ["Insert spaces instead of tabs", "用空格代替 Tab", "用空格取代 Tab"],
        .settingsLineNumbers: ["Show line numbers", "显示行号", "顯示行號"],
        .settingsHighlight: ["Syntax highlighting", "语法高亮", "語法高亮"],
        .settingsSmartIndent: ["Smart indentation", "智能缩进", "智慧縮排"],
        .settingsWrap: ["Word wrap", "自动换行", "自動換行"],
        .settingsHighlightLine: ["Highlight the current line", "高亮当前行", "標示目前行"],
        .settingsShowProject: ["Show the project explorer", "显示项目浏览器", "顯示專案瀏覽器"],
        .settingsShowConsole: ["Show the output window", "显示输出窗口", "顯示輸出視窗"],
        .settingsCompilerPath: ["Compiler", "编译器", "編譯器"],
        .settingsCompilerDetected: ["Detected: %@", "已检测：%@", "已偵測：%@"],
        .settingsStandard: ["C standard", "C 标准", "C 標準"],
        .settingsFlags: ["Extra compiler flags", "附加编译参数", "附加編譯參數"],
        .settingsFlagsHint: ["Separated by spaces, e.g. -O2 -pthread", "以空格分隔，例如 -O2 -pthread", "以空格分隔，例如 -O2 -pthread"],
        .settingsDebug: ["Generate debug information (-g)", "生成调试信息（-g）", "產生除錯資訊（-g）"],
        .settingsOutDir: ["Output location", "输出位置", "輸出位置"],
        .settingsOutSameDir: ["Same folder as the source (Dev-C++ style)", "与源文件同目录（Dev-C++ 风格）", "與來源檔同目錄（Dev-C++ 風格）"],
        .settingsOutBuildDir: ["“build” subfolder", "“build” 子目录", "“build” 子目錄"],
        .settingsDefaults: ["Reset to Defaults", "恢复默认设置", "回復預設設定"],
        .settingsDone: ["Done", "完成", "完成"],
        .settingsVersion: ["Version %@", "版本 %@", "版本 %@"],
        .settingsOfflineNote: [
            "Mini Dev-C++ is completely offline — it never connects to the network. Compilation runs locally through clang and your files never leave this Mac.",
            "Mini Dev-C++ 完全离线运行，不进行任何网络连接。编译通过本机的 clang 完成，文件不会离开这台 Mac。",
            "Mini Dev-C++ 完全離線執行，不進行任何網路連線。編譯透過本機的 clang 完成，檔案不會離開這台 Mac。"
        ],

        // ── help window ────────────────────────────────────────────────────
        .helpTitle: ["Mini Dev-C++ Help", "Mini Dev-C++ 使用帮助", "Mini Dev-C++ 使用說明"],
        .helpIntro: [
            "A lightweight C IDE for macOS. Write C code, press ⌘B to compile and ⌘R to run — exactly the Dev-C++ 4.9.9.2 workflow, rebuilt for macOS.",
            "macOS 上的轻量级 C 语言 IDE。编写代码后按 ⌘B 编译、⌘R 运行 —— 与 Dev-C++ 4.9.9.2 相同的工作流程，为 macOS 重新构建。",
            "macOS 上的輕量級 C 語言 IDE。撰寫程式碼後按 ⌘B 編譯、⌘R 執行 —— 與 Dev-C++ 4.9.9.2 相同的工作流程，為 macOS 重新構建。"
        ],
        .helpSecEditing: ["Editing", "编辑", "編輯"],
        .helpSecBuild: ["Building and running", "编译与运行", "編譯與執行"],
        .helpSecProject: ["Projects and files", "项目与文件", "專案與檔案"],
        .helpSecSettings: ["Options", "设置", "設定"],
        .helpBodyEditing: [
            "Type your C code in the editor. Keywords, comments, strings and preprocessor directives are highlighted with the Dev-C++ colour scheme. Braces indent automatically, ⌘/ toggles a line comment, and the built-in find bar (⌘F) supports replace (⌥⌘F). The status bar shows the caret position and whether the file has been modified.",
            "在编辑器中编写 C 代码。关键字、注释、字符串与预处理指令按 Dev-C++ 配色高亮。大括号自动缩进，⌘/ 可注释或取消注释，内置查找栏（⌘F）支持替换（⌥⌘F）。底部状态栏显示光标位置与文件修改状态。",
            "在編輯器中撰寫 C 程式碼。關鍵字、註解、字串與前置處理指令依 Dev-C++ 配色標示。大括號自動縮排，⌘/ 可註解或取消註解，內建尋找列（⌘F）支援取代（⌥⌘F）。底部狀態列顯示游標位置與檔案修改狀態。"
        ],
        .helpBodyBuild: [
            "⌘B compiles the current file (or every .c file of the open project) with clang, ⇧⌘B rebuilds everything, ⌘R runs the last built program and ⌘⏎ compiles and runs in one step. The Compiler tab shows errors and warnings — double-click a diagnostic to jump to that line. The Program Output tab shows what your program prints and lets you feed stdin. Programs that need a real terminal can be launched with Execute ▸ Run in Terminal.",
            "⌘B 用 clang 编译当前文件（或项目的全部 .c 文件），⇧⌘B 全部重新编译，⌘R 运行上次编译的程序，⌘⏎ 一步完成编译并运行。“编译器”标签显示错误与警告，双击可跳转到对应行；“程序输出”标签显示程序输出并可输入 stdin。需要完整终端交互的程序可用“运行 ▸ 在终端中运行”启动。",
            "⌘B 用 clang 編譯目前檔案（或專案中全部 .c 檔案），⇧⌘B 全部重新編譯，⌘R 執行上次編譯的程式，⌘⏎ 一步完成編譯並執行。「編譯器」分頁顯示錯誤與警告，連按兩下可跳至對應行；「程式輸出」分頁顯示程式輸出並可輸入 stdin。需要完整終端機互動的程式可用「執行 ▸ 在終端機中執行」啟動。"
        ],
        .helpBodyProject: [
            "Use File ▸ Open Folder as Project… to load a folder: its .c and .h files appear in the project explorer on the left, and Compile builds every .c file in it, linking them into a single executable just like a Dev-C++ project. Without a project, the IDE compiles the file you are editing. The executable is written next to the source (or into a build subfolder if you prefer).",
            "用“文件 ▸ 打开文件夹作为项目…”载入文件夹：其中的 .c 与 .h 文件会显示在左侧项目浏览器中，“编译”会编译其中的所有 .c 文件并链接为一个可执行文件，与 Dev-C++ 项目一致。未打开项目时，只编译当前编辑的文件。可执行文件默认生成在源文件旁边（也可改为 build 子目录）。",
            "用「檔案 ▸ 開啟資料夾為專案…」載入資料夾：其中的 .c 與 .h 檔案會顯示在左側專案瀏覽器中，「編譯」會編譯其中所有 .c 檔案並連結為一個執行檔，與 Dev-C++ 專案一致。未開啟專案時，只編譯目前編輯的檔案。執行檔預設產生在來源檔旁（也可改為 build 子目錄）。"
        ],
        .helpBodySettings: [
            "Options (⌘,) holds the light/dark/system appearance switch, the language picker, editor font size, tab width, compiler path, C standard, extra flags and the output location. The whole interface follows the macOS appearance automatically unless you pin it to Light or Dark.",
            "“选项”（⌘,）中包含 浅色/深色/跟随系统 的外观切换、语言选择、编辑器字号、Tab 宽度、编译器路径、C 标准、附加参数与输出位置。界面默认自动跟随 macOS 外观，也可固定为浅色或深色。",
            "「選項」（⌘,）中包含 淺色/深色/跟隨系統 的外觀切換、語言選擇、編輯器字級、Tab 寬度、編譯器路徑、C 標準、附加參數與輸出位置。介面預設自動跟隨 macOS 外觀，也可固定為淺色或深色。"
        ],
        .helpShortcuts: ["Shortcuts", "快捷键", "快速鍵"],

        // ── first launch ───────────────────────────────────────────────────
        .flTitle: ["Copyright & License", "版权与许可", "版權與授權"],
        .flBody: [
            "Copyright © 2026 Du Haoze. All rights reserved.\n\nMini Dev-C++ is free software released under the MIT License. You may use, modify and redistribute it, keeping the copyright notice and licence text.\n\nThis app is an independent re-implementation for macOS, inspired by Dev-C++ 4.9.9.2 by Bloodshed Software (GNU GPL). It contains no source code from the original project; Dev-C++ is credited as the design reference, and the compiler used is Apple clang from the Xcode Command Line Tools.",
            "Copyright © 2026 Du Haoze. 保留所有权利。\n\nMini Dev-C++ 是以 MIT 许可证发布的自由软件。您可以使用、修改和再分发，但需保留版权声明与许可证文本。\n\n本程序是为 macOS 独立重新实现的版本，设计参考了 Bloodshed Software 的 Dev-C++ 4.9.9.2（GNU GPL）。程序不包含原项目的任何源代码；原项目仅作为设计蓝本予以致谢，所使用的编译器为 Xcode 命令行工具中的 Apple clang。",
            "Copyright © 2026 Du Haoze. 保留所有權利。\n\nMini Dev-C++ 是以 MIT 授權條款發佈的自由軟體。您可以使用、修改與再發佈，但需保留版權聲明與授權條款文字。\n\n本程式是為 macOS 獨立重新實作的版本，設計參考了 Bloodshed Software 的 Dev-C++ 4.9.9.2（GNU GPL）。程式不包含原專案的任何原始碼；原專案僅作為設計藍本予以致謝，所使用的編譯器為 Xcode 命令列工具中的 Apple clang。"
        ],
        .flPrivacyTitle: ["Privacy", "隐私说明", "隱私說明"],
        .flBody2: [
            "Mini Dev-C++ works entirely offline. It has no networking code at all: no telemetry, no analytics, no update checks, no accounts. Your source files stay on this Mac and are only read by the local clang compiler you invoke. Nothing about your code, your usage or your system is ever transmitted anywhere.",
            "Mini Dev-C++ 完全离线运行。程序不含任何网络代码：没有遥测、没有统计分析、没有更新检查、没有账号。您的源代码只保存在本机，并仅由您调用的本机 clang 编译器读取。程序不会以任何方式发送您的代码、使用情况或系统信息。",
            "Mini Dev-C++ 完全離線執行。程式不含任何網路程式碼：沒有遙測、沒有統計分析、沒有更新檢查、沒有帳號。您的原始碼只保存在本機，並僅由您呼叫的本機 clang 編譯器讀取。程式不會以任何方式傳送您的程式碼、使用情況或系統資訊。"
        ],
        .btnAgree: ["Agree", "同意", "同意"],
        .btnDisagree: ["Disagree", "不同意", "不同意"]
    ]
}
