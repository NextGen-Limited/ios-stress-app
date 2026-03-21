import AnimatedTabBar
import SwiftUI

// MARK: - Tab Button Helpers for AnimatedTabBar

extension MainTabView {
    func tabButtons(selectedIndex: Int) -> [AnyView] {
        TabItem.allCases.map { tab in
            AnyView(
                TabBarImageButton(tab: tab, isSelected: selectedIndex == tab.rawValue)
            )
        }
    }
}

// MARK: - Custom Image-Based Tab Button

private struct TabBarImageButton: View {
    let tab: TabItem
    let isSelected: Bool

    var body: some View {
        Image(isSelected ? "\(tab.iconName)-selected" : tab.iconName)
            .renderingMode(.original)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .accessibilityLabel(Text(tab.title))
            .accessibilityHint(Text(tab.accessibilityHint))
            .accessibilityIdentifier(tab.accessibilityIdentifier)
    }
}
