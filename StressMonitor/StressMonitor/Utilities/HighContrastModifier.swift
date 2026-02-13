import SwiftUI

// MARK: - High Contrast Border for Accessibility

/// View modifier that adds high contrast border when "Differentiate Without Color" is enabled
/// Ensures interactive elements are visible for users who cannot distinguish colors
public struct HighContrastBorderModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    let isInteractive: Bool
    let cornerRadius: CGFloat

    public init(isInteractive: Bool = true, cornerRadius: CGFloat = 8) {
        self.isInteractive = isInteractive
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if differentiateWithoutColor && isInteractive {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.primary, lineWidth: 2)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Add high contrast border for interactive elements
    /// - Parameters:
    ///   - interactive: Whether the element is interactive (default: true)
    ///   - cornerRadius: Corner radius for border (default: 8)
    /// - Returns: View with conditional high contrast border
    public func highContrastBorder(interactive: Bool = true, cornerRadius: CGFloat = 8) -> some View {
        modifier(HighContrastBorderModifier(isInteractive: interactive, cornerRadius: cornerRadius))
    }
}

// MARK: - High Contrast Card Modifier

/// Enhanced card modifier with high contrast support
public struct HighContrastCardModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.colorScheme) var colorScheme

    let backgroundColor: Color?
    let cornerRadius: CGFloat

    public init(backgroundColor: Color? = nil, cornerRadius: CGFloat = 12) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if differentiateWithoutColor {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.primary.opacity(0.3), lineWidth: 2)
                }
            }
    }

    private var cardBackground: Color {
        if let backgroundColor = backgroundColor {
            return backgroundColor
        }
        return colorScheme == .dark ? Color(hex: "#1C1C1E") : .white
    }
}

extension View {
    /// Apply high contrast card styling
    /// - Parameters:
    ///   - backgroundColor: Custom background color (optional)
    ///   - cornerRadius: Corner radius (default: 12)
    /// - Returns: View with high contrast card styling
    public func highContrastCard(backgroundColor: Color? = nil, cornerRadius: CGFloat = 12) -> some View {
        modifier(HighContrastCardModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
}

// MARK: - High Contrast Button Modifier

/// Button modifier with enhanced high contrast styling
public struct HighContrastButtonModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    let style: ButtonStyle

    public enum ButtonStyle {
        case primary
        case secondary
        case tertiary
    }

    public init(style: ButtonStyle = .primary) {
        self.style = style
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if differentiateWithoutColor {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(borderColor, lineWidth: 2)
                }
            }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .tertiary:
            return Color.primary.opacity(0.5)
        }
    }
}

extension View {
    /// Apply high contrast button styling
    /// - Parameter style: Button style (default: .primary)
    /// - Returns: View with high contrast button styling
    public func highContrastButton(style: HighContrastButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(HighContrastButtonModifier(style: style))
    }
}
