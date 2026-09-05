import SwiftUI
import Testing
import UIKit
@testable import StressMonitor

/// Pins the text-style anchoring of `Font.WellnessType` (and `Font.SystemFallback`)
/// to the platform ramp at the Large (default) content size category: every anchored
/// token must render at byte-identical point size to the fixed-size font it replaced.
/// A failure here means an SDK ramp change silently retyped a token — compensate the
/// drifting token with `Font.system(size:weight:design:relativeTo:)` at the designed
/// point size instead of accepting the drift.
@Suite("Font WellnessType Parity")
struct FontWellnessTypeParityTests {
    private let large = UITraitCollection(preferredContentSizeCategory: .large)

    private func pointSize(_ style: UIFont.TextStyle) -> CGFloat {
        UIFont.preferredFont(forTextStyle: style, compatibleWith: large).pointSize
    }

    @Test(
        "Anchored text styles render at the designed point size at the Large default",
        arguments: zip(
            [UIFont.TextStyle.largeTitle, .title1, .title2, .body, .headline, .footnote, .caption2],
            [34, 28, 22, 17, 17, 13, 11]
        )
    )
    func anchoredStyleMatchesDesignedSize(style: UIFont.TextStyle, expected: Int) {
        let rendered = pointSize(style)
        #expect(rendered == CGFloat(expected), "\(style.rawValue) renders \(rendered), designed \(expected)")
    }

    @Test("Headline style carries the semibold trait so bodyEmphasized preserves its weight")
    func headlineCarriesSemiboldTrait() {
        let font = UIFont.preferredFont(forTextStyle: .headline, compatibleWith: large)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
    }
}
