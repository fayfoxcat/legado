import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }
        if value.count == 3 {
            value = value.reduce(into: "") { result, character in
                result.append(character)
                result.append(character)
            }
        }
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        let red = Double((number >> 16) & 0xFF) / 255.0
        let green = Double((number >> 8) & 0xFF) / 255.0
        let blue = Double(number & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
