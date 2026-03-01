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
/// Uses template rendering with foreground color styling.
/// Selected = teal (#85C9C9), Unselected = gray at 30% opacity
struct StressTabBarView: View {
    @Binding var selectedTab: TabItem
    @Namespace private var animation

    // Figma specs
    private let tabBarHeight: CGFloat = 100
    private let tabSpacing: CGFloat = 80
    private let topPadding: CGFloat = 21
    private let bottomSafeArea: CGFloat = 34
    private let indicatorWidth: CGFloat = 20
    private let indicatorHeight: CGFloat = 8

    // Colors
    private let selectedColor = Color(red: 133/255, green: 201/255, blue: 201/255) // #85C9C9
    private let unselectedColor = Color.gray

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab items HStack
            HStack(spacing: tabSpacing) {
                ForEach(TabItem.allCases) { item in
                TabBarItem(
                    item: item,
                    isSelected: selectedTab == item,
                    selectedColor: selectedColor,
                    unselectedColor: unselectedColor
                ) {
                    HapticManager.shared.buttonPress()
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = item
                    }
                }
            }
            .padding(.top, topPadding)
            .padding(.bottom, bottomSafeArea)

            // Sliding indicator at bottom of bar
            TabBarIndicator()
                .frame(width: indicatorWidth, height: indicatorHeight)
                .offset(x: indicatorOffset)
                .matchedGeometryEffect(id: "indicator", in: animation)
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

    /// Calculate horizontal offset for sliding indicator
    private var indicatorOffset: CGFloat {
        let tabIndex = TabItem.allCases.firstIndex(of: selectedTab) ?? 0
        let totalWidth = CGFloat(TabItem.allCases.count - 1) * tabSpacing
        let startX = -totalWidth / 2
        return startX + CGFloat(tabIndex) * tabSpacing
    }
}

/// Individual tab bar button using template rendering with foreground color
private struct TabBarItem: View {
    let item: TabItem
    let isSelected: Bool
    let selectedColor: Color
    let unselectedColor: Color
    let action: () -> Void

    private let touchTargetSize: CGFloat = 46
    private let iconSize: CGFloat = 40

    var body: some View {
        Button(action: action) {
            Image(item.iconName)
                .resizable()
                .renderingMode(.template)  // Template rendering for color tinting
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(isSelected ? selectedColor : unselectedColor)  // Teal or gray
                .opacity(isSelected ? 1.0 : 0.3)  // 30% opacity for unselected
                .frame(width: touchTargetSize, height: touchTargetSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - TabBarIndicator

/// Selection indicator for active tab (teal dot)
private struct TabBarIndicator: View {
    var body: some View {
        Image("TabIndicator")
            .resizable()
            .renderingMode(.original)
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
