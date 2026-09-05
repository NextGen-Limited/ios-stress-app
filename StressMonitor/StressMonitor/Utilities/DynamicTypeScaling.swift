import SwiftUI

// MARK: - Limited Dynamic Type Modifier

/// Modifier that limits Dynamic Type to accessibility level 3.
/// Escape hatch for dated exceptions only — never apply on a manifest
/// surface without an inline dated exception note at the call site.
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

/// Uncapped Dynamic Type contract: text scales through
/// `.accessibility5`, never shrinks, and wraps instead of truncating.
/// Layouts adapt (wrap, stack, or scroll) — the only escape is
/// `limitedDynamicType()` behind a dated exception note.
public struct AccessibleDynamicTypeModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .lineLimit(nil)
    }
}

extension View {
    /// Apply uncapped Dynamic Type scaling — no size cap, no shrink factor,
    /// no line limits. Text wraps; the container adapts.
    /// - Returns: View that scales through accessibility size 5
    public func accessibleDynamicType() -> some View {
        modifier(AccessibleDynamicTypeModifier())
    }
}
