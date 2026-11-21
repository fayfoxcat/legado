import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BookshelfView: View {
    @EnvironmentObject private var library: LibraryStore

    @State private var showImporter = false
    @State private var errorMessage: String?
    @State private var bookToDelete: Book?

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if library.books.isEmpty {
                    ContentUnavailableView {
                        Label("书架还是空的", systemImage: "books.vertical")
                    } description: {
                        Text("导入一本本地 TXT，或从示例书开始。")
                    } actions: {
                        Button("导入 TXT") {
                            showImporter = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: columns, spacing: 22) {
                        ForEach(library.books) { book in
                            NavigationLink(value: book) {
                                BookCardView(book: book)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    bookToDelete = book
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Label("导入", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Book.self) { book in
                ReaderView(book: book, library: library)
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .alert("提示", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .confirmationDialog(
                "删除这本书？",
                isPresented: Binding(
                    get: { bookToDelete != nil },
                    set: { if !$0 { bookToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("删除", role: .destructive) {
                    if let book = bookToDelete {
                        library.delete(book)
                    }
                    bookToDelete = nil
                }
                Button("取消", role: .cancel) {
                    bookToDelete = nil
                }
            } message: {
                Text("只会删除章节缓存，不会影响原文件。")
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            _ = try library.importTXT(from: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
