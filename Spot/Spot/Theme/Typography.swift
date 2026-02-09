import SwiftUI

/// Uses system text styles that automatically scale with Dynamic Type.
/// SF Pro is the default system font — no custom font loading needed.
struct SpotTypography {
    static let largeTitle = Font.largeTitle.bold()
    static let title = Font.title.bold()
    static let title2 = Font.title2.bold()
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
}
