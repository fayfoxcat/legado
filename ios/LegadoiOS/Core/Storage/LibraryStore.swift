import Foundation
import Combine

final class LibraryStore: ObservableObject {
    @Published private(set) var books: [Book] = []
    @Published var lastError: String?

    private let store = BookFileStore()
    private var libraryURL: URL {
        store.root.appendingPathComponent("library.json")
    }

    init() {
        load()
    }

    func load() {
        if let data = try? Data(contentsOf: libraryURL) {
            if let decoded = try? JSONDecoder().decode([Book].self, from: data) {
                books = decoded.sorted { $0.addedAt > $1.addedAt }
            } else {
                lastError = "书架数据无法读取，已保留原文件。"
            }
            return
        }
        seedSampleBook()
    }

    @discardableResult
    func importTXT(from url: URL) throws -> Book {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        guard let text = TXTBookParser.decode(data: data) else {
            throw LibraryError.unreadableText
        }

        let rawTitle = url.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let title = rawTitle.isEmpty ? "未命名书籍" : rawTitle
        let chapters = TXTBookParser.parse(text: text, fallbackTitle: title)
        guard !chapters.isEmpty else {
            throw LibraryError.emptyBook
        }

        let id = UUID()
        let fileName = try store.writeChapters(chapters, bookID: id)
        let book = Book(
            id: id,
            title: title,
            author: "",
            kind: .local,
            chaptersFileName: fileName,
            chapterCount: chapters.count
        )
        books.insert(book, at: 0)
        save()
        return book
    }

    func loadChapters(for book: Book) throws -> [Chapter] {
        try store.readChapters(fileName: book.chaptersFileName)
    }

    func delete(_ book: Book) {
        books.removeAll { $0.id == book.id }
        store.deleteChapters(fileName: book.chaptersFileName)
        save()
    }

    func updateProgress(bookID: UUID, chapterIndex: Int, characterOffset: Int = 0) {
        guard let index = books.firstIndex(where: { $0.id == bookID }) else { return }
        books[index].progress = ReadingProgress(
            chapterIndex: max(0, chapterIndex),
            characterOffset: max(0, characterOffset),
            updatedAt: Date()
        )
        books[index].lastReadAt = Date()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(books)
            try data.write(to: libraryURL, options: .atomic)
        } catch {
            lastError = "保存书架失败：\(error.localizedDescription)"
        }
    }

    private func seedSampleBook() {
        let chapters = TXTBookParser.parse(text: SampleBook.text, fallbackTitle: "阅读样本")
        guard !chapters.isEmpty else { return }
        let id = UUID()
        guard let fileName = try? store.writeChapters(chapters, bookID: id) else { return }
        let book = Book(
            id: id,
            title: "阅读样本",
            author: "Legado iOS",
            kind: .sample,
            chaptersFileName: fileName,
            chapterCount: chapters.count
        )
        books = [book]
        save()
    }
}

enum LibraryError: LocalizedError {
    case unreadableText
    case emptyBook

    var errorDescription: String? {
        switch self {
        case .unreadableText:
            return "无法识别文件编码，请尝试 UTF-8 或 GB18030 文本。"
        case .emptyBook:
            return "这个文件没有可阅读的正文。"
        }
    }
}
