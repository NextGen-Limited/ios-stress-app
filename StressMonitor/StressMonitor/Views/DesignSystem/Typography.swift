import SwiftUI

struct Typography {
    // MARK: - Large Titles

    static let largeTitle = Font.system(size: 34, weight: .bold)

    // MARK: - Titles

    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)

    // MARK: - Headline

    static let headline = Font.system(size: 17, weight: .semibold)

    // MARK: - Body

    static let body = Font.system(size: 17, weight: .regular)
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)

    // MARK: - Callout

    static let callout = Font.system(size: 16, weight: .regular)

    // MARK: - Subheadline

    static let subheadline = Font.system(size: 15, weight: .regular)

    // MARK: - Footnote

    static let footnote = Font.system(size: 13, weight: .regular)

    // MARK: - Captions

    static let caption1 = Font.system(size: 12, weight: .regular)
    static let caption2 = Font.system(size: 11, weight: .regular)

    // MARK: - Data Display (SF Pro Display Rounded)

    static let dataHero = Font.system(size: 72, weight: .bold, design: .rounded)
    static let dataLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let dataMedium = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let dataSmall = Font.system(size: 28, weight: .bold, design: .rounded)
}
