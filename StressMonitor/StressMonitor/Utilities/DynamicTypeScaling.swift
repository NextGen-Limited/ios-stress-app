import SwiftUI

// MARK: - Dynamic Type Scaling for Accessibility

/// View modifier that enables dynamic type scaling with minimum scale factor
/// Ensures text remains readable while preventing truncation
public struct DynamicTypeScalingModifier: ViewModifier {
    let minimumScale: CGFloat

    public init(minimumScale: CGFloat = 0.75) {
        self.minimumScale = minimumScale
    }

    public func body(content: Content) -> some View {
        content
            .minimumScaleFactor(minimumScale)
            .lineLimit(nil) // Allow wrapping
    }
}

// MARK: - View Extension

extension View {
    /// Apply scalable text with dynamic type support
    /// - Parameter minimumScale: Minimum scale factor (default: 0.75)
    /// - Returns: View with scalable text
    public func scalableText(minimumScale: CGFloat = 0.75) -> some View {
        modifier(DynamicTypeScalingModifier(minimumScale: minimumScale))
    }
}

// MARK: - Adaptive Text Size Modifier

/// Modifier that adjusts text size based on Dynamic Type setting
public struct AdaptiveTextSizeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    public init(baseSize: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) {
        self.baseSize = baseSize
        self.weight = weight
        self.design = design
    }

    public func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: weight, design: design))
            .minimumScaleFactor(0.7)
            .lineLimit(nil)
    }

    private var scaledSize: CGFloat {
        // Scale based on Dynamic Type setting
        switch dynamicTypeSize {
        case .xSmall:
            return baseSize * 0.8
        case .small:
            return baseSize * 0.9
        case .medium:
            return baseSize
        case .large:
            return baseSize * 1.1
        case .xLarge:
            return baseSize * 1.2
        case .xxLarge:
            return baseSize * 1.3
        case .xxxLarge:
            return baseSize * 1.4
        case .accessibility1:
            return baseSize * 1.6
        case .accessibility2:
            return baseSize * 1.8
        case .accessibility3:
            return baseSize * 2.0
        case .accessibility4:
            return baseSize * 2.3
        case .accessibility5:
            return baseSize * 2.6
        @unknown default:
            return baseSize
        }
    }
}

extension View {
    /// Apply adaptive text sizing with Dynamic Type support
    /// - Parameters:
    ///   - baseSize: Base font size
    ///   - weight: Font weight (default: .regular)
    ///   - design: Font design (default: .default)
    /// - Returns: View with adaptive text size
    public func adaptiveTextSize(_ baseSize: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(AdaptiveTextSizeModifier(baseSize: baseSize, weight: weight, design: design))
    }
}

// MARK: - Limited Dynamic Type Modifier

/// Modifier that limits Dynamic Type to accessibility level 3
/// Prevents extreme scaling that could break layout
public struct LimitedDynamicTypeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

extension View {
    /// Limit Dynamic Type to accessibility level 3
    /// - Returns: View with limited Dynamic Type scaling
    public func limitedDynamicType() -> some View {
        modifier(LimitedDynamicTypeModifier())
    }
}

// MARK: - Accessible Dynamic Type Modifier

/// Comprehensive Dynamic Type modifier with best practices
public struct AccessibleDynamicTypeModifier: ViewModifier {
    let minimumScale: CGFloat
    let maxDynamicTypeSize: DynamicTypeSize

    public init(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3) {
        self.minimumScale = minimumScale
        self.maxDynamicTypeSize = maxDynamicTypeSize
    }

    public func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...maxDynamicTypeSize)
            .minimumScaleFactor(minimumScale)
            .lineLimit(nil)
    }
}

extension View {
    /// Apply accessible Dynamic Type with scaling limits
    /// - Parameters:
    ///   - minimumScale: Minimum scale factor (default: 0.75)
    ///   - maxDynamicTypeSize: Maximum Dynamic Type size (default: .accessibility3)
    /// - Returns: View with accessible Dynamic Type
    public func accessibleDynamicType(minimumScale: CGFloat = 0.75, maxDynamicTypeSize: DynamicTypeSize = .accessibility3) -> some View {
        modifier(AccessibleDynamicTypeModifier(minimumScale: minimumScale, maxDynamicTypeSize: maxDynamicTypeSize))
    }
}
