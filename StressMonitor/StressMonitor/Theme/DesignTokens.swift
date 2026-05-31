import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let minTouchTarget: CGFloat = 44
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
    }

    enum Typography {
        static let heroSize: CGFloat = 72
        static let largeTitle: CGFloat = 48
        static let title: CGFloat = 34
        static let headline: CGFloat = 22
        static let body: CGFloat = 17
        static let caption: CGFloat = 13
    }

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let slowDuration: Double = 1.0
    }
}
