import SwiftUI

struct AppShadow {
    // MARK: - Shadow Presets

    static let card = ShadowDefinition(
        color: Color.black.opacity(0.05),
        radius: 8,
        x: 0,
        y: 2
    )

    static let elevated = ShadowDefinition(
        color: Color.black.opacity(0.1),
        radius: 16,
        x: 0,
        y: 4
    )

    static let button = ShadowDefinition(
        color: Color.black.opacity(0.15),
        radius: 4,
        x: 0,
        y: 2
    )

    static let subtle = ShadowDefinition(
        color: Color.black.opacity(0.03),
        radius: 4,
        x: 0,
        y: 1
    )

    // MARK: - Settings Card Shadow

    /// Settings card shadow per Figma spec
    static let settingsCard = ShadowDefinition(
        color: Color.settingsCardShadowColor.opacity(0.08),
        radius: 5.71,
        x: 0,
        y: 2.85
    )

    // MARK: - IAP Shadows (Figma)

    /// IAP plan card shadow (Figma multi-layer)
    static let iapPlanCard = ShadowDefinition(
        color: Color(hex: "5C5C5C").opacity(0.1),
        radius: 8,
        x: 0,
        y: 2
    )

    /// IAP utility row shadow
    static let iapUtilityRow = ShadowDefinition(
        color: Color(hex: "18274B").opacity(0.06),
        radius: 6,
        x: 0,
        y: 3
    )
}

struct ShadowDefinition {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers

extension View {
    func shadow(_ shadow: ShadowDefinition) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }

    func cardShadow() -> some View {
        self.shadow(AppShadow.card)
    }

    func elevatedShadow() -> some View {
        self.shadow(AppShadow.elevated)
    }

    func buttonShadow() -> some View {
        self.shadow(AppShadow.button)
    }
}
