import Foundation
import SwiftUI

// MARK: - Tab Bar Scroll State

@Observable
final class TabBarScrollState {
    var isVisible: Bool = true
    var tabBarHeight: CGFloat = 83
    private var lastScrollOffset: CGFloat = 0

    private let threshold: CGFloat = 5

    func handleScrollOffset(_ newOffset: CGFloat) {
        let delta = newOffset - lastScrollOffset

        guard abs(delta) >= threshold else { return }

        if delta > 0 {
            // Scrolling down - hide tab bar
            if isVisible && newOffset > threshold {
                isVisible = false
            }
        } else {
            // Scrolling up - show tab bar
            if !isVisible {
                isVisible = true
            }
        }

        lastScrollOffset = newOffset
    }

    func resetToVisible() {
        isVisible = true
        lastScrollOffset = 0
    }
}

// MARK: - View Extension for iOS 17 Scroll Tracking

extension ScrollView {
    /// Apply this to the ScrollView (not inner content). No coordinateSpace needed.
    func trackScrollOffsetForTabBar(state: TabBarScrollState) -> some View {
        self.onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, newOffset in
            state.handleScrollOffset(newOffset)
        }
    }
}
