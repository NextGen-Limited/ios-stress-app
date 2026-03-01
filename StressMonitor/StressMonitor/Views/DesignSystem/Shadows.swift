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
