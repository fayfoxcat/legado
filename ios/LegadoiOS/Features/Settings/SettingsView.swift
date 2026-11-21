import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var library: LibraryStore
    @AppStorage("reader.theme") private var themeRaw = ReaderTheme.paper.rawValue
    @AppStorage("reader.fontSize") private var fontSize = 19.0

    var body: some View {
        NavigationStack {
            Form {
                Section("阅读") {
                    Picker("主题", selection: $themeRaw) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.name).tag(theme.rawValue)
                        }
                    }
                    HStack {
                        Text("默认字号")
                        Spacer()
                        Text("\(Int(fontSize)) pt")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("书架") {
                    LabeledContent("书籍数量", value: "\(library.books.count)")
                    LabeledContent("存储位置", value: "应用沙盒")
                }

                Section("关于") {
                    LabeledContent("版本", value: "0.1.0 (MVP)")
                    LabeledContent("代码基线", value: "Legado da17bb2")
                    Text("Legado iOS 是社区重写项目，不内置书源或正文内容。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}
