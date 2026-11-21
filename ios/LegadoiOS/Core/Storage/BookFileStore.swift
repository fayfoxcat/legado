import Foundation

struct BookFileStore {
    let root: URL
    let booksDirectory: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        root = base.appendingPathComponent("Legado", isDirectory: true)
        booksDirectory = root.appendingPathComponent("Books", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
    }

    func writeChapters(_ chapters: [Chapter], bookID: UUID) throws -> String {
        let fileName = bookID.uuidString + ".chapters.json"
        let data = try JSONEncoder().encode(BookContent(chapters: chapters))
        try data.write(to: booksDirectory.appendingPathComponent(fileName), options: .atomic)
        return fileName
    }

    func readChapters(fileName: String) throws -> [Chapter] {
        let url = booksDirectory.appendingPathComponent(fileName)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BookContent.self, from: data).chapters
    }

    func deleteChapters(fileName: String) {
        try? FileManager.default.removeItem(at: booksDirectory.appendingPathComponent(fileName))
    }
}
