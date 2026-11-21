import SwiftUI

struct ReaderSettingsView: View {
    @AppStorage("reader.fontSize") private var fontSize = 19.0
    @AppStorage("reader.lineSpacing") private var lineSpacing = 8.0
    @AppStorage("reader.theme") private var themeRaw = ReaderTheme.paper.rawValue

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("主题") {
                    Picker("配色", selection: $themeRaw) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.name).tag(theme.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("排版") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("字号")
                            Spacer()
                            Text("\(Int(fontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $fontSize, in: 14...30, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("行距")
                            Spacer()
                            Text("\(Int(lineSpacing)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $lineSpacing, in: 2...18, step: 1)
                    }
                }

                Section {
                    Text("阅读设置会即时生效，并在下次打开时保留。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
