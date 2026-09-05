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
/// techniques G18 and G145). Stress hues are asserted through
/// `Color.stressColor(for:)` delegating to `StressCategory.color`, pinning
/// the single source of truth for the stress palette.
///
/// Widget contrast scope (decision D-07, platform-bounded): widget gallery
/// and lock-screen surfaces join the contrast/Dynamic Type sweep per D-02 —
/// the Dynamic Type half executes in plan 03-02 Task 4. Widget foregrounds
/// are system `.primary` / `.secondary` on system materials (Apple-guaranteed
/// pairs, verified as token pairs only); the tier accent is always dual-coded
/// next to a text label and never carries meaning alone; wallpaper-dependent
/// contrast is out of scope by construction.
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
        "Adaptive primary text passes AA (4.5:1) on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func adaptivePrimaryTextOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.Wellness.adaptivePrimaryText, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 4.5)
    }

    @Test(
        "Adaptive primary text passes AA (4.5:1) on cards in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func adaptivePrimaryTextOnCard(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.Wellness.adaptivePrimaryText, style),
            on: resolved(Color.Wellness.adaptiveCardBackground, style)
        )
        #expect(ratio >= 4.5)
    }

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

    @Test(
        "Tertiary text (aliased to the adaptive secondary token) passes AA on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func textTertiaryOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.textTertiary, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 4.5)
    }

    @Test(
        "Descriptive text (aliased to the adaptive secondary token) passes AA on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func textDescriptiveOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.textDescriptive, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 4.5)
    }

    // MARK: - UI / Large-Text Accent Pairs (>= 3:1)

    @Test(
        "Primary blue passes AA-UI (3:1) on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func primaryBlueOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.primaryBlue, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 3.0)
    }

    @Test(
        "White text on the primary blue fill passes 3:1 in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func whiteOnPrimaryBlueFill(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            UIColor.white,
            on: resolved(Color.primaryBlue, style)
        )
        #expect(ratio >= 3.0)
    }

    @Test(
        "Ripple accent passes AA-UI (3:1) on the canvas in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func rippleAccentOnCanvas(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            resolved(Color.settingsRippleBlue, style),
            on: resolved(Color.Wellness.adaptiveBackground, style)
        )
        #expect(ratio >= 3.0)
    }

    @Test(
        "White text on the ripple fill passes 3:1 in both appearances",
        arguments: [UIUserInterfaceStyle.light, .dark]
    )
    func whiteOnRippleFill(style: UIUserInterfaceStyle) {
        let ratio = contrastRatio(
            UIColor.white,
            on: resolved(Color.settingsRippleBlue, style)
        )
        #expect(ratio >= 3.0)
    }

    @Test("White label text on the moderate distribution-bar segment passes 3:1 in light mode")
    func whiteOnModerateDistributionSegmentLight() {
        let ratio = contrastRatio(
            UIColor.white,
            on: resolved(StressCategory.moderate.color, .light)
        )
        #expect(ratio >= 3.0)
    }

    @Test("Black label text on the moderate distribution-bar segment passes 3:1 in dark mode")
    func blackOnModerateDistributionSegmentDark() {
        let ratio = contrastRatio(
            UIColor.black,
            on: resolved(StressCategory.moderate.color, .dark)
        )
        #expect(ratio >= 3.0)
    }

    // MARK: - Stress Indicator Pairs (>= 3:1)

    @Test(
        "Every stress category hue passes 3:1 on the light canvas via Color.stressColor(for:)",
        arguments: StressCategory.allCases
    )
    func stressHuesOnLightCanvas(category: StressCategory) {
        let ratio = contrastRatio(
            resolved(Color.stressColor(for: category), .light),
            on: resolved(Color.Wellness.adaptiveBackground, .light)
        )
        #expect(ratio >= 3.0)
    }

    @Test(
        "Every stress category hue passes 3:1 on the dark canvas via Color.stressColor(for:)",
        arguments: StressCategory.allCases
    )
    func stressHuesOnDarkCanvas(category: StressCategory) {
        let ratio = contrastRatio(
            resolved(Color.stressColor(for: category), .dark),
            on: resolved(Color.Wellness.adaptiveBackground, .dark)
        )
        #expect(ratio >= 3.0)
    }

    @Test(
        "High-contrast stress variants pass 3:1 on the light canvas for every category",
        arguments: StressCategory.allCases
    )
    func highContrastStressVariantsOnLightCanvas(category: StressCategory) {
        let ratio = contrastRatio(
            resolved(Color.accessibleStressColor(for: category, highContrast: true), .light),
            on: resolved(Color.Wellness.adaptiveBackground, .light)
        )
        #expect(ratio >= 3.0)
    }

    // MARK: - Watch Token Pins
    //
    // `StressMonitorWatch Watch App` is a separate module and cannot be
    // imported from this iOS test target, so the retuned watch values are
    // pinned here by literal hex against their fixed watch-canvas
    // background (`#F2F2F7`, non-adaptive on the watch).

    @Test("Watch moderate ink (mirrors StressCategory.color, #8A5A00) passes 3:1 on the watch canvas")
    func watchModerateInkOnCanvas() {
        let ratio = contrastRatio(
            UIColor(Color(hex: "#8A5A00")),
            on: UIColor(Color(hex: "#F2F2F7"))
        )
        #expect(ratio >= 3.0)
    }
}
