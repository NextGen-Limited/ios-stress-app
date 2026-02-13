import SwiftUI

// MARK: - Stress Pattern for Dual Coding

/// Visual patterns to supplement color for stress levels
/// Ensures accessibility for color-blind users (WCAG 2.1 compliance)
public enum StressPattern: String, CaseIterable {
    case solid       // No pattern (relaxed)
    case diagonal    // Diagonal lines (mild)
    case dots        // Dot pattern (moderate)
    case crosshatch  // Crosshatch lines (high)

    // MARK: - Pattern Mapping

    /// Get pattern for stress category
    /// - Parameter category: Stress category
    /// - Returns: Corresponding pattern
    public static func pattern(for category: StressCategory) -> StressPattern {
        switch category {
        case .relaxed: return .solid
        case .mild: return .diagonal
        case .moderate: return .dots
        case .high: return .crosshatch
        }
    }

    // MARK: - ShapeStyle

    /// ShapeStyle for pattern rendering
    public var shapeStyle: AnyShapeStyle {
        switch self {
        case .solid:
            return AnyShapeStyle(Color.clear)
        case .diagonal:
            return AnyShapeStyle(DiagonalPattern())
        case .dots:
            return AnyShapeStyle(DotPattern())
        case .crosshatch:
            return AnyShapeStyle(CrosshatchPattern())
        }
    }

    // MARK: - Overlay View

    /// Create pattern overlay view
    /// - Parameters:
    ///   - color: Base color for pattern
    ///   - opacity: Pattern opacity (default 0.3)
    /// - Returns: Pattern overlay view
    @ViewBuilder
    public func overlay(color: Color, opacity: Double = 0.3) -> some View {
        switch self {
        case .solid:
            // No pattern - just solid color
            EmptyView()
        case .diagonal:
            DiagonalLinesView(color: color, opacity: opacity)
        case .dots:
            DotsView(color: color, opacity: opacity)
        case .crosshatch:
            CrosshatchView(color: color, opacity: opacity)
        }
    }
}

// MARK: - Pattern Shapes

/// Diagonal lines pattern
private struct DiagonalPattern: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        Color.primary.opacity(0.2)
    }
}

/// Dot pattern
private struct DotPattern: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        Color.primary.opacity(0.2)
    }
}

/// Crosshatch pattern
private struct CrosshatchPattern: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        Color.primary.opacity(0.2)
    }
}

// MARK: - Pattern Views

/// Diagonal lines overlay
private struct DiagonalLinesView: View {
    let color: Color
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 8
                let width = geometry.size.width
                let height = geometry.size.height
                let diagonal = sqrt(width * width + height * height)

                var offset: CGFloat = -diagonal
                while offset < diagonal {
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset + height, y: height))
                    offset += spacing
                }
            }
            .stroke(color.opacity(opacity), lineWidth: 1)
        }
    }
}

/// Dots overlay
private struct DotsView: View {
    let color: Color
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 8
            let columns = Int(geometry.size.width / spacing)
            let rows = Int(geometry.size.height / spacing)

            Canvas { context, size in
                for row in 0...rows {
                    for col in 0...columns {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(color.opacity(opacity))
                        )
                    }
                }
            }
        }
    }
}

/// Crosshatch overlay
private struct CrosshatchView: View {
    let color: Color
    let opacity: Double

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 6
                let width = geometry.size.width
                let height = geometry.size.height

                // Horizontal lines
                var y: CGFloat = 0
                while y < height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                    y += spacing
                }

                // Vertical lines
                var x: CGFloat = 0
                while x < width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                    x += spacing
                }
            }
            .stroke(color.opacity(opacity), lineWidth: 1)
        }
    }
}

// MARK: - Pattern Overlay Modifier

/// View modifier to apply stress pattern overlay
public struct PatternOverlayModifier: ViewModifier {
    let pattern: StressPattern
    let color: Color

    public func body(content: Content) -> some View {
        content
            .overlay {
                pattern.overlay(color: color)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Apply stress pattern overlay for dual coding
    /// - Parameters:
    ///   - pattern: Pattern type
    ///   - color: Base color for pattern
    /// - Returns: View with pattern overlay
    public func stressPattern(_ pattern: StressPattern, color: Color) -> some View {
        modifier(PatternOverlayModifier(pattern: pattern, color: color))
    }

    /// Apply stress pattern based on category
    /// - Parameter category: Stress category
    /// - Returns: View with pattern overlay
    public func stressPattern(for category: StressCategory) -> some View {
        let pattern = StressPattern.pattern(for: category)
        return modifier(PatternOverlayModifier(pattern: pattern, color: category.color))
    }
}
