import SwiftUI

extension Color {
    // MARK: - Brand

    static let spotEmerald = Color(hex: "047857")
    static let spotEmeraldLight = Color(hex: "059669")
    static let spotEmeraldDark = Color(hex: "065F46")

    // MARK: - Adaptive Text (auto dark mode)

    static let spotTextPrimary = Color(.label)               // black in light, white in dark
    static let spotTextSecondary = Color(.secondaryLabel)     // gray that adapts

    // MARK: - Adaptive Backgrounds (auto dark mode)

    static let spotBackground = Color(.systemBackground)             // white / near-black
    static let spotCardBackground = Color(.secondarySystemBackground) // slight contrast
    static let spotDivider = Color(.separator)                       // adapts automatically

    // MARK: - Semantic

    static let spotDanger = Color(hex: "DC2626")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
