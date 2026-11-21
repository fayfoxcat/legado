import Foundation

enum TXTBookParser {
    private static let headingRegex: NSRegularExpression? = {
        let pattern = #"^\s*(第[0-9零一二三四五六七八九十百千万两]+[章节回卷集部篇][^\n]{0,60}|(?:序章|楔子|前言|后记|尾声|番外)[^\n]{0,50})\s*$"#
        return try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
    }()

    static func decode(data: Data) -> String? {
        TextEncodingDetector.decode(data)
    }

    static func parse(text: String, fallbackTitle: String) -> [Chapter] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let byHeading = splitByHeadings(normalized)
        if !byHeading.isEmpty {
            return byHeading
        }
        return splitByLength(normalized, fallbackTitle: fallbackTitle)
    }

    private static func splitByHeadings(_ text: String) -> [Chapter] {
        guard let regex = headingRegex else { return [] }
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        guard !matches.isEmpty else { return [] }

        var chapters: [Chapter] = []
        var index = 0

        if matches[0].range.location > 0 {
            let prefaceRange = NSRange(location: 0, length: matches[0].range.location)
            let preface = nsText.substring(with: prefaceRange).trimmingCharacters(in: .whitespacesAndNewlines)
            if !preface.isEmpty {
                chapters.append(Chapter(index: index, title: "开始", content: preface))
                index += 1
            }
        }

        for (offset, match) in matches.enumerated() {
            let title = nsText.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            let start = match.range.location + match.range.length
            let end = offset + 1 < matches.count ? matches[offset + 1].range.location : nsText.length
            let length = max(0, end - start)
            let content = nsText.substring(with: NSRange(location: start, length: length))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                chapters.append(Chapter(index: index, title: title, content: content))
                index += 1
            }
        }
        return chapters
    }

    private static func splitByLength(_ text: String, fallbackTitle: String) -> [Chapter] {
        let chunkSize = 6000
        let characters = Array(text)
        guard !characters.isEmpty else { return [] }

        var chapters: [Chapter] = []
        var start = 0
        var index = 0
        while start < characters.count {
            let end = min(start + chunkSize, characters.count)
            let content = String(characters[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                let title = index == 0 ? fallbackTitle : "第 \(index + 1) 节"
                chapters.append(Chapter(index: index, title: title, content: content))
                index += 1
            }
            start = end
        }
        return chapters
    }
}
