import SwiftUI

/// Dev-C++'s "Execute ▸ Parameters" dialog: command line arguments and stdin.
struct RunParametersView: View {
    @EnvironmentObject var settings: AppSettings
    @Binding var isPresented: Bool

    @State private var arguments = ""
    @State private var standardInput = ""
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(settings.t(.paramTitle))
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.paramArgs))
                    .font(.system(size: 11, weight: .medium))
                TextField("argv[1] argv[2] …", text: $arguments)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12, design: .monospaced))
                Text(settings.t(.paramArgsHint))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(settings.t(.paramStdin))
                    .font(.system(size: 11, weight: .medium))
                TextEditor(text: $standardInput)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                Text(settings.t(.paramStdinHint))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button(settings.t(.btnCancel)) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(settings.t(.paramOK)) {
                    settings.runArguments = arguments
                    settings.runStdin = standardInput
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 460)
        .onAppear {
            guard !loaded else { return }
            arguments = settings.runArguments
            standardInput = settings.runStdin
            loaded = true
        }
    }
}
