import SwiftUI

// MARK: - WatchDesignTokens

/// iOS Design System v1.4.2 token values, scoped for the watch canvas.
///
/// All values are lifted directly from `design/css/app.css` so the watch
/// reads as a sibling of the iPhone app: same light surfaces, ink ramp,
/// separators, radii, and motion curves.  The previous dark/scoreless
/// watch token set has been replaced entirely.
///
/// Sources:
/// - `design/css/app.css` (canonical CSS variables)
/// - `design/design-system.html` (DS v1.4.2 spec)
/// - watch design output `stressmonitor-watch-v2/index.html`
enum WatchDesignTokens {

    // MARK: - Surfaces (LIGHT theme — exact from app.css)

    /// `--bg` · system grouped background.
    static let canvas          = Color(hex: "#F2F2F7")
    /// `--surface` · cards, reading rows, picker items.
    static let surface         = Color(hex: "#FFFFFF")
    /// `--surface-2` · secondary elevated surface.
    static let surfaceSecondary = Color(hex: "#FBFBFD")
    /// `--settings-bg` · warm cream for Watch Face Settings (iOS Settings lineage).
    static let settingsCanvas  = Color(hex: "#FFFDF6")

    // MARK: - Ink

    /// `--fg` · primary text/ink.
    static let ink             = Color(hex: "#101223")
    /// `--fg-secondary` · secondary text.
    static let inkSecondary    = Color(hex: "#3C3C43")
    /// `--muted` · meta / caption text.
    static let muted           = Color(hex: "#777986")
    /// `--muted-2` · system gray.
    static let mutedSystem     = Color(hex: "#8E8E93")

    /// `--separator` at 0.5pt — hairline divider colour.
    static let separator       = Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.12)
    /// `--separator-strong` — used for inactive phase dots / control borders.
    static let separatorStrong = Color(red: 60/255, green: 60/255, blue: 67/255, opacity: 0.29)

    // MARK: - Ripple accent (budget: max 2 per screen)

    /// `--accent` · Ripple blue.
    static let accent          = Color(hex: "#4FC3F7")
    /// `--accent-strong` · deep Ripple blue for borders / selected states.
    static let accentStrong    = Color(hex: "#0288D1")
    /// `--accent-soft` · accent tint wash (callouts, selected theme well).
    static let accentSoft      = Color(red: 79/255, green: 195/255, blue: 247/255, opacity: 0.14)

    // MARK: - Radii (from app.css)

    static let radiusControl: CGFloat   = 12   // `--radius-control`
    static let radiusCard: CGFloat      = 14   // stat cards, reading rows
    static let radiusCardLarge: CGFloat = 18   // `--radius-card`
    static let radiusHero: CGFloat      = 22   // `--radius-card-lg`
    static let radiusPill: CGFloat      = 999  // `--radius-pill`

    // MARK: - Spacing scale (4/8/12/16/20/24/32)

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat  = 8
        static let sm: CGFloat  = 12
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 20
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Motion (iOS-aligned: ease, not spring-everything)

    enum Motion {
        /// Snappy state transitions (selection, tier swap).
        static let fast: Animation = .easeInOut(duration: 0.15)
        /// Default content transitions (score, ring fill).
        static let `default`: Animation = .easeInOut(duration: 0.20)
        /// Hero / breathing ring expansions.
        static let slow: Animation = .easeInOut(duration: 0.45)
        /// Ambient character halo (very slow, autoreverses).
        static let ambient: Animation = .easeInOut(duration: 2.4).repeatForever(autoreverses: true)
    }

    /// Resolve the motion to use, honoring `accessibilityReduceMotion`.
    /// Returns `nil` when motion should be disabled (callers pass `nil`
    /// to `.animation(_:value:)` to opt out of animation entirely).
    static func motion(_ baseline: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : baseline
    }

    // MARK: - Watch canvas metrics

    /// Apple Watch Series 10 45mm display — 216×264pt.
    static let screenCornerRadius: CGFloat = 52
    static let contentSidePadding: CGFloat = 14
    static let hairlineThickness: CGFloat = 0.5
}
