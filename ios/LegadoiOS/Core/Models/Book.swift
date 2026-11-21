import Foundation

struct ReadingProgress: Codable, Hashable {
    var chapterIndex: Int
    var characterOffset: Int
    var updatedAt: Date

    static let zero = ReadingProgress(chapterIndex: 0, characterOffset: 0, updatedAt: .distantPast)

    var isStarted: Bool {
        chapterIndex > 0 || characterOffset > 0
    }
}

struct Book: Identifiable, Codable, Hashable {
    enum Kind: String, Codable, Hashable {
        case local
        case sample
    }

    var id: UUID
    var title: String
    var author: String
    var kind: Kind
    var chaptersFileName: String
    var chapterCount: Int
    var coverColorHex: String
    var addedAt: Date
    var lastReadAt: Date?
    var progress: ReadingProgress

    init(
        id: UUID = UUID(),
        title: String,
        author: String = "",
        kind: Kind = .local,
        chaptersFileName: String,
        chapterCount: Int,
        coverColorHex: String? = nil,
        addedAt: Date = Date(),
        lastReadAt: Date? = nil,
        progress: ReadingProgress = .zero
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.kind = kind
        self.chaptersFileName = chaptersFileName
        self.chapterCount = chapterCount
        self.coverColorHex = coverColorHex ?? Book.coverColor(for: title)
        self.addedAt = addedAt
        self.lastReadAt = lastReadAt
        self.progress = progress
    }

    var displayAuthor: String {
        let trimmed = author.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未知作者" : trimmed
    }

    var progressDescription: String {
        guard chapterCount > 0 else { return "未开始" }
        let index = min(max(progress.chapterIndex, 0), chapterCount - 1)
        return "第 \(index + 1) / \(chapterCount) 章"
    }

    var progressFraction: Double {
        guard chapterCount > 0, lastReadAt != nil || progress.isStarted else { return 0 }
        return min(1, max(0, Double(progress.chapterIndex + 1) / Double(chapterCount)))
    }

    static let coverPalette = [
        "#B45F3C",
        "#3E6B5A",
        "#4A5C8A",
        "#8A5A7A",
        "#7A6A3E",
        "#5E4A3E",
        "#496A7A",
        "#8A4A3C"
    ]

    static func coverColor(for title: String) -> String {
        var hash = 0
        for scalar in title.unicodeScalars {
            hash = (hash &* 31 &+ Int(scalar.value)) & 0x7FFFFFFF
        }
        return coverPalette[hash % coverPalette.count]
    }
}
