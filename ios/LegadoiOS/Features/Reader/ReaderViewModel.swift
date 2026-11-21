import Foundation
import Combine

final class ReaderViewModel: ObservableObject {
    let book: Book
    @Published private(set) var chapters: [Chapter] = []
    @Published var currentIndex: Int
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let library: LibraryStore
    private var hasLoaded = false

    init(book: Book, library: LibraryStore) {
        self.book = book
        self.library = library
        self.currentIndex = max(0, min(book.progress.chapterIndex, max(0, book.chapterCount - 1)))
    }

    var currentChapter: Chapter? {
        guard chapters.indices.contains(currentIndex) else { return nil }
        return chapters[currentIndex]
    }

    var progressText: String {
        guard !chapters.isEmpty else { return "" }
        return "第 \(currentIndex + 1) / \(chapters.count) 章"
    }

    var progressFraction: Double {
        guard !chapters.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(chapters.count)
    }

    var canGoPrevious: Bool {
        currentIndex > 0
    }

    var canGoNext: Bool {
        currentIndex + 1 < chapters.count
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            chapters = try library.loadChapters(for: book)
            currentIndex = min(max(0, currentIndex), max(0, chapters.count - 1))
            isLoading = false
            if chapters.isEmpty {
                errorMessage = "没有可显示的章节。"
            }
        } catch {
            isLoading = false
            errorMessage = "读取章节失败：\(error.localizedDescription)"
        }
    }

    func goPrevious() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        saveProgress()
    }

    func goNext() {
        guard canGoNext else { return }
        currentIndex += 1
        saveProgress()
    }

    func saveProgress(characterOffset: Int = 0) {
        guard !chapters.isEmpty else { return }
        library.updateProgress(
            bookID: book.id,
            chapterIndex: currentIndex,
            characterOffset: characterOffset
        )
    }
}
