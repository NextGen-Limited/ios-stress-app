shell-init: error retrieving current directory: getcwd: cannot access parent directories: No such file or directory
chdir: error retrieving current directory: getcwd: cannot access parent directories: No such file or directory
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

    // MARK: - Custom Fonts (Roboto)

    /// Custom Roboto-Bold font. Use for special branding elements.
    /// Font file: Roboto-Bold.ttf (loaded via FontBlaster)
    static func roboto(size: CGFloat) -> Font {
        .custom("Roboto-Bold", size: size)
    }

    static let robotoTitle = Font.custom("Roboto-Bold", size: 24)
    static let robotoHeadline = Font.custom("Roboto-Bold", size: 17)
    static let robotoBody = Font.custom("Roboto-Bold", size: 16)
    static let robotoCaption = Font.custom("Roboto-Bold", size: 12)

    // MARK: - Custom Fonts (Lato - IAP Screen)

    /// Custom Lato font. Use for IAP/Premium screen elements.
    static func lato(_ weight: LatoWeight, size: CGFloat) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum LatoWeight: String {
        case regular = "Lato-Regular"
        case medium = "Lato-Medium"
        case bold = "Lato-Bold"
        case black = "Lato-Black"

        var fontName: String { rawValue }
    }

    // MARK: - IAP Typography (Figma — Redesigned Paywall)

    static let iapNavTitle = Font.system(size: 13, weight: .bold)
    static let iapTagline = Font.system(size: 21, weight: .black)
    static let iapSectionHeader = Font.system(size: 12, weight: .heavy)
    static let iapPlanName = Font.system(size: 17, weight: .bold)
    static let iapPlanSubtitle = Font.system(size: 12, weight: .medium)
    static let iapPrice = Font.system(size: 22, weight: .bold)
    static let iapPerMonth = Font.system(size: 11, weight: .semibold)
    static let iapSavings = Font.system(size: 12, weight: .heavy)
    static let iapSubtitle = Font.system(size: 11, weight: .medium)
    static let iapCTA = Font.system(size: 16, weight: .heavy)
    static let iapUtilityLabel = Font.system(size: 11, weight: .bold)
    static let iapBadge = Font.system(size: 11, weight: .heavy)

    // New paywall redesign tokens
    static let iapHeroHeadline = Font.system(size: 32, weight: .bold)
    static let iapHeroSubtitle = Font.system(size: 15, weight: .semibold)
    static let iapBenefitTitle = Font.system(size: 15, weight: .bold)
    static let iapBenefitDescription = Font.system(size: 12, weight: .medium)
    static let iapPillLabel = Font.system(size: 12, weight: .heavy)
    static let iapTrustLabel = Font.system(size: 10.5, weight: .semibold)
    static let iapTrustIcon = Font.system(size: 16, weight: .bold)
    static let iapFinePrint = Font.system(size: 10.8, weight: .medium)
    static let iapPlanFooter = Font.system(size: 12, weight: .heavy)
}
