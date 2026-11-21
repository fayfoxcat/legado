import Foundation
import CoreFoundation

enum TextEncodingDetector {
    static func decode(_ data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            if let text = String(data: Data(data.dropFirst(3)), encoding: .utf8), !text.isEmpty {
                return text
            }
        }
        if data.starts(with: [0xFF, 0xFE]) {
            if let text = String(data: data, encoding: .utf16LittleEndian), !text.isEmpty {
                return text
            }
        }
        if data.starts(with: [0xFE, 0xFF]) {
            if let text = String(data: data, encoding: .utf16BigEndian), !text.isEmpty {
                return text
            }
        }

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }

        let gbEncoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )
        if let text = String(data: data, encoding: String.Encoding(rawValue: gbEncoding)), !text.isEmpty {
            return text
        }

        let big5Encoding = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.big5.rawValue)
        )
        if let text = String(data: data, encoding: String.Encoding(rawValue: big5Encoding)), !text.isEmpty {
            return text
        }

        for encoding in [String.Encoding.utf16, .utf16LittleEndian, .utf16BigEndian, .isoLatin1] {
            if let text = String(data: data, encoding: encoding), !text.isEmpty {
                return text
            }
        }
        return nil
    }
}
