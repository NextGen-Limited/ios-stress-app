import SwiftUI

/// Decorative placeholder with pulsing opacity animation.
/// Used in permission-required state to hint at content behind the access gate.
struct SkeletonBlock: View {
    var height: CGFloat = 60

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: Spacing.settingsCardRadius)
            .fill(Color.oledCardSecondary)
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .opacity(isAnimating ? 0.4 : 0.8)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
            .accessibilityHidden(true)
    }
}
