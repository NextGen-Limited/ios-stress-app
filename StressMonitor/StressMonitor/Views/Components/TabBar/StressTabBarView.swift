import SwiftUI

// MARK: - Tabbable Protocol

/// Protocol defining tab bar item properties
/// Based on https://github.com/onl1ner/TabBar
public protocol Tabbable {
    var icon: String { get }
    var title: String { get }
}

// MARK: - TabBarVisibility

/// Visibility state for tab bar
public enum TabBarVisibility {
    case visible
    case hidden
}

// MARK: - StressTabBarView

/// Custom tab bar view matching Figma design (Node 4:5990)
/// Uses separate images for selected/unselected states.
struct StressTabBarView: View {
    @Binding var selectedTab: TabItem
    @Namespace private var animation

    // Figma specs
    private let tabBarHeight: CGFloat = 100
    private let tabSpacing: CGFloat = 80
    private let topPadding: CGFloat = 21
    private let bottomSafeArea: CGFloat = 34

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab items HStack
            HStack(spacing: tabSpacing) {
                ForEach(TabItem.allCases) { item in
                    TabBarItem(
                        item: item,
                        isSelected: selectedTab == item
                    ) {
                        HapticManager.shared.buttonPress()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = item
                        }
                    }
                }
            }
            .padding(.top, topPadding)
            .padding(.bottom, bottomSafeArea)
        }
        .frame(height: tabBarHeight)
        .frame(maxWidth: .infinity)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.11), radius: 14, y: -5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("StressTabBar")
    }
}

// MARK: - TabBarItem

/// Individual tab bar button using separate images for selected/unselected states
private struct TabBarItem: View {
    let item: TabItem
    let isSelected: Bool
    let action: () -> Void

    private let touchTargetSize: CGFloat = 46
    private let iconSize: CGFloat = 40

    var body: some View {
        Button(action: action) {
            Image(isSelected ? item.selectedIconName : item.unselectedIconName)
                .resizable()
                .renderingMode(.original)  // Use original image colors
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .frame(width: touchTargetSize, height: touchTargetSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview("StressTabBarView - All States") {
    struct PreviewContainer: View {
        @State private var selectedTab: TabItem = .home

        var body: some View {
            VStack {
                Spacer()
                StressTabBarView(selectedTab: $selectedTab)
            }
        }
    }
    return PreviewContainer()
}

#Preview("StressTabBarView - Dark Mode") {
    struct PreviewContainer: View {
        @State private var selectedTab: TabItem = .action

        var body: some View {
            VStack {
                Spacer()
                StressTabBarView(selectedTab: $selectedTab)
            }
            .background(Color(.systemGroupedBackground))
            .preferredColorScheme(.dark)
        }
    }
    return PreviewContainer()
}
