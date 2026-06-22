import SwiftUI

/// Decorative placeholder with pulsing opacity animation.
/// Used in permission-required state to hint at content behind the access gate.
struct SkeletonBlock: View {
    var height: CGFloat = 60

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: Spacing.settingsCardRadius)
            .fill(Color.oledCardSecondary)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .opacity(opacity)
            .animation(reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { guard !reduceMotion else { return }; isAnimating = true }
            .accessibilityHidden(true)
    }

    /// Static mid-opacity when Reduce Motion is on; otherwise the pulse target.
    private var opacity: Double {
        reduceMotion ? 0.6 : (isAnimating ? 0.4 : 0.8)
    }
}
