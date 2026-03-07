import SwiftUI
import AnimatedTabBar

// MARK: - Tabbable Protocol (Local)

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

/// Custom tab bar view matching Figma design
/// Uses separate images for selected/unselected states.
/// Note: AnimatedTabBar library integrated but using custom implementation for reliability
struct StressTabBarView: View {
    @Binding var selectedTab: TabItem

    // Corner radius for tab bar top edges
    private let cornerRadius: CGFloat = 64

    var body: some View {
        HStack(spacing: 0) {
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
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(
            .rect(cornerRadius: cornerRadius)
        )
        .shadow(color: .black.opacity(0.11), radius: 14, y: -5)
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
    private let iconSize: CGFloat = 28

    var body: some View {
        Button(action: action) {
            iconView
                .frame(width: iconSize, height: iconSize)
                .frame(width: touchTargetSize, height: touchTargetSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityIdentifier(item.accessibilityIdentifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var iconView: some View {
        if item.useSymbol {
            Image(systemName: isSelected ? item.selectedIconName : item.unselectedIconName)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isSelected ? .primaryBlue : .secondary)
        } else {
            Image(isSelected ? item.selectedIconName : item.unselectedIconName)
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
        }
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
