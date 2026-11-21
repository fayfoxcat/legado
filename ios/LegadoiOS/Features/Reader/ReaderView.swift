import SwiftUI

struct ReaderView: View {
    let book: Book
    @StateObject private var model: ReaderViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("reader.fontSize") private var fontSize = 19.0
    @AppStorage("reader.lineSpacing") private var lineSpacing = 8.0
    @AppStorage("reader.theme") private var themeRaw = ReaderTheme.paper.rawValue

    @State private var showSettings = false

    init(book: Book, library: LibraryStore) {
        self.book = book
        _model = StateObject(wrappedValue: ReaderViewModel(book: book, library: library))
    }

    private var theme: ReaderTheme {
        ReaderTheme(rawValue: themeRaw) ?? .paper
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider().overlay(theme.divider)
                content
                Divider().overlay(theme.divider)
                footer
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            model.load()
        }
        .onDisappear {
            model.saveProgress()
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsView()
        }
        .alert("提示", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(model.progressText)
                    .font(.caption)
                    .opacity(0.6)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 17, weight: .medium))
            }
        }
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: lineSpacing) {
                if model.isLoading {
                    ProgressView()
                        .tint(theme.foreground)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                } else if let chapter = model.currentChapter {
                    Text(chapter.title)
                        .font(.system(size: fontSize + 4, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.foreground)
                        .padding(.bottom, 10)

                    Text(chapter.content)
                        .font(.system(size: fontSize, design: .serif))
                        .lineSpacing(lineSpacing)
                        .foregroundStyle(theme.foreground)
                        .textSelection(.enabled)
                } else {
                    Text("没有可显示的章节。")
                        .font(.system(size: fontSize, design: .serif))
                        .foregroundStyle(theme.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .id(model.currentIndex)
    }

    private var footer: some View {
        HStack {
            Button {
                model.goPrevious()
            } label: {
                Label("上一章", systemImage: "chevron.left")
            }
            .disabled(!model.canGoPrevious)

            Spacer()

            Text(model.progressText)
                .font(.caption2)
                .opacity(0.6)

            Spacer()

            Button {
                model.goNext()
            } label: {
                Label("下一章", systemImage: "chevron.right")
            }
            .disabled(!model.canGoNext)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}
