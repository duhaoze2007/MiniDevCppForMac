import SwiftUI

/// Left dock: the project explorer (folder tree) on top and the open buffers
/// underneath, mirroring Dev-C++'s project pane.
struct ProjectPane: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var workspace: Workspace

    var body: some View {
        VStack(spacing: 0) {
            paneHeader(symbol: "folder", title: settings.t(.paneProject))
            Group {
                if workspace.projectRoot == nil {
                    VStack(spacing: 6) {
                        Text(settings.t(.paneNoProject))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Button(settings.t(.projectOpenFolder)) { workspace.openFolderFromPanel() }
                            .buttonStyle(.link)
                            .font(.system(size: 11))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(workspace.tree) { node in
                                FileNodeRow(node: node, depth: 0)
                            }
                        }
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(minHeight: 60, maxHeight: .infinity)

            Divider()

            paneHeader(symbol: "doc.on.doc", title: settings.t(.paneOpenFiles))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(workspace.files) { file in
                        OpenFileRow(file: file)
                    }
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 50, maxHeight: 160)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func paneHeader(symbol: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color.primary.opacity(0.04))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
        }
    }
}

struct FileNodeRow: View {
    let node: FileNode
    let depth: Int
    @EnvironmentObject var workspace: Workspace
    @State private var expanded = true
    @State private var hovering = false

    private var icon: String {
        let ext = node.url.pathExtension.lowercased()
        switch ext {
        case "c", "cpp", "cc", "cxx": return "doc.text"
        case "h", "hpp", "hh":       return "h.square"
        case "txt", "md":            return "doc.plaintext"
        default:                     return "doc"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                if node.isDirectory {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)
                } else {
                    Spacer().frame(width: 10)
                }
                Image(systemName: node.isDirectory ? "folder" : icon)
                    .font(.system(size: 11))
                    .foregroundStyle(node.isDirectory ? Color.accentColor : .secondary)
                Text(node.name)
                    .font(.system(size: 11.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.leading, CGFloat(depth) * 12 + 6)
            .padding(.trailing, 6)
            .frame(height: 19)
            .background(hovering ? Color.primary.opacity(0.06) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    expanded.toggle()
                } else {
                    workspace.open(urls: [node.url])
                }
            }
            .onHover { hovering = $0 }
            .help(node.url.path)

            if node.isDirectory && expanded {
                ForEach(node.children) { child in
                    FileNodeRow(node: child, depth: depth + 1)
                }
            }
        }
    }
}

struct OpenFileRow: View {
    @ObservedObject var file: SourceFile
    @EnvironmentObject var workspace: Workspace

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: file.isCHeader ? "h.square" : "doc.text")
                .font(.system(size: 10))
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
            Text(file.displayName)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .truncationMode(.middle)
            if file.isDirty {
                Circle().fill(Color.accentColor).frame(width: 5, height: 5)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: 19)
        .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { workspace.select(file) }
    }

    private var isActive: Bool { workspace.activeID == file.id }
}
