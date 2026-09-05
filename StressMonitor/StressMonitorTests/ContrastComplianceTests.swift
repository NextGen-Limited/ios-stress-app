import Foundation
import SwiftUI
import Testing
import UIKit
@testable import StressMonitor

/// Permanent WCAG AA contrast gate (A11Y-02, decision D-06): ratios are
/// computed from the semantic token definitions via
/// `UIColor.resolvedColor(with:)` in BOTH appearances — never sampled from
/// screenshots. Thresholds follow the usage class of the pair: >= 4.5:1 for
/// body-text pairs, >= 3:1 for large-text / UI-component pairs (W3C
/// techniques G18 and G145).
@Suite("Contrast Compliance")
struct ContrastComplianceTests {

    // MARK: - WCAG Relative Luminance

    private func linearize(_ channel: CGFloat) -> CGFloat {
        channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private func relativeLuminance(_ color: UIColor) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    /// WCAG contrast ratio, lighter luminance first — per W3C G18/G145.
    private func contrastRatio(_ foreground: UIColor, on background: UIColor) -> CGFloat {
        let foregroundLuminance = relativeLuminance(foreground)
        let backgroundLuminance = relativeLuminance(background)
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // MARK: - Appearance Resolution

    /// Resolves an app `Color` per appearance so the `Color(light:dark:)`
    /// dynamic provider is honored inside the hosted test target.
    private func resolved(_ color: Color, _ style: UIUserInterfaceStyle) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    // MARK: - Formula Sanity

    @Test("WCAG formula sanity: pure black on pure white computes 21.00")
    func formulaPinsBlackOnWhiteAt21() {
        let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        #expect(abs(contrastRatio(black, on: white) - 21.0) < 0.01)
    }

    // MARK: - Text Pairs (>= 4.5:1)

    @Test(
        "Adaptive secondary text passes AA (4.5:1) on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func adaptiveSecondaryTextOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.Wellness.adaptiveSecondaryText, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 4.5)
    }

    @Test(
        "Adaptive secondary text passes AA (4.5:1) on cards in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func adaptiveSecondaryTextOnCard(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.Wellness.adaptiveSecondaryText, style),
            on: resolved(Color.Wellness.adaptiveCardBackground, style)
        )
        #expect(ratio >= 4.5)
    }
}
