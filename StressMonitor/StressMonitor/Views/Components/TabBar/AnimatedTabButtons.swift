import AnimatedTabBar
import SwiftUI

// MARK: - Tab Button Helpers for AnimatedTabBar
// These helpers create DropletButton instances with proper selection state

/// Creates tab buttons for AnimatedTabBar with proper selection binding
/// Usage: AnimatedTabBar(selectedIndex: $selectedIndex, views: tabButtons(selectedIndex: selectedIndex))

extension MainTabView {
    /// Creates array of tab buttons for AnimatedTabBar
    func tabButtons(selectedIndex: Int) -> [AnyView] {
        [
            AnyView(dropletButton(
                imageName: "home",
                isSelected: selectedIndex == 0,
                label: "Home",
                hint: "Double tap to view current stress measurement"
            )),
            AnyView(dropletButton(
                imageName: "action",
                isSelected: selectedIndex == 1,
                label: "Action",
                hint: "Double tap to access quick actions and exercises"
            )),
            AnyView(dropletButton(
                imageName: "trend",
                isSelected: selectedIndex == 2,
                label: "Trend",
                hint: "Double tap to view stress trends and history"
            ))
        ]
    }

    /// Creates a single droplet button with accessibility
    private func dropletButton(
        imageName: String,
        isSelected: Bool,
        label: String,
        hint: String
    ) -> some View {
        DropletButton(
            imageName: imageName,
            dropletColor: .primaryBlue,
            isSelected: isSelected
        )
        .accessibilityLabel(Text("\(label) tab"))
        .accessibilityHint(Text(hint))
        .accessibilityIdentifier("\(label)Tab")
    }
}
