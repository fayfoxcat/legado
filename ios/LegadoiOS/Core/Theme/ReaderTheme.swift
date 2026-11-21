import SwiftUI

enum ReaderTheme: String, CaseIterable, Identifiable, Codable {
    case paper
    case sepia
    case night

    var id: String { rawValue }

    var name: String {
        switch self {
        case .paper: return "纸白"
        case .sepia: return "护眼"
        case .night: return "夜间"
        }
    }

    var background: Color {
        switch self {
        case .paper: return Color(red: 0.98, green: 0.97, blue: 0.94)
        case .sepia: return Color(red: 0.93, green: 0.87, blue: 0.75)
        case .night: return Color(red: 0.07, green: 0.07, blue: 0.08)
        }
    }

    var foreground: Color {
        switch self {
        case .paper: return Color(red: 0.16, green: 0.15, blue: 0.13)
        case .sepia: return Color(red: 0.24, green: 0.18, blue: 0.10)
        case .night: return Color(red: 0.78, green: 0.78, blue: 0.76)
        }
    }

    var secondary: Color {
        foreground.opacity(0.55)
    }

    var divider: Color {
        foreground.opacity(0.12)
    }
}
