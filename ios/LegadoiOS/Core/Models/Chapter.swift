import Foundation

struct Chapter: Identifiable, Codable, Hashable {
    var id: UUID
    var index: Int
    var title: String
    var content: String

    init(id: UUID = UUID(), index: Int, title: String, content: String) {
        self.id = id
        self.index = index
        self.title = title
        self.content = content
    }
}

struct BookContent: Codable {
    var chapters: [Chapter]
}
