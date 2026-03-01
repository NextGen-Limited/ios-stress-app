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
/// 100px height, white background with shadow, 80px gap between items
/// Sliding indicator at BOTTOM of bar per Figma specs
/// Unselected icons at 30% opacity
///
/// Follows TabBar library patterns from https://github.com/onl1ner/TabBar
struct StressTabBarView: View {
    @Binding var selectedTab: TabItem
    @Namespace private var animation

    // Figma specs from design context
    private let tabBarHeight: CGFloat = 100
    private let tabSpacing: CGFloat = 80
    private let topPadding: CGFloat = 21  // Updated from 16 to match Figma
    private let bottomSafeArea: CGFloat = 34
    private let indicatorWidth: CGFloat = 20
    private let indicatorHeight: CGFloat = 8

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
        // Calculate center position of each tab
        let totalWidth = CGFloat(TabItem.allCases.count - 1) * tabSpacing
        let startX = -totalWidth / 2
        return startX + CGFloat(tabIndex) * tabSpacing
    }
}

// MARK: - TabBarItem

/// Individual tab bar button matching Figma design
/// Unselected icons at 30% opacity for visual hierarchy
private struct TabBarItem: View {
    let item: TabItem
    let isSelected: Bool
    let action: () -> Void

    // Figma specs: 46x46px touch target, 40x40px icon container
    private let touchTargetSize: CGFloat = 46
    private let iconSize: CGFloat = 40

    var body: some View {
        Button(action: action) {
            Image(item.iconName(isSelected: isSelected))
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
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
