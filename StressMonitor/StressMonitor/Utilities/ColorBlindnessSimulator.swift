import SwiftUI

#if DEBUG

// MARK: - Color Blindness Simulator (DEBUG ONLY)

/// Simulates different types of color blindness for testing accessibility
/// Only available in DEBUG builds for design validation
public enum ColorBlindnessType: String, CaseIterable {
    case deuteranopia  // Red-green (most common, 5% of males)
    case protanopia    // Red-green (1% of males)
    case tritanopia    // Blue-yellow (rare, 0.01%)
    case normal        // No simulation

    // MARK: - Display Name

    public var displayName: String {
        switch self {
        case .deuteranopia: return "Deuteranopia (Red-Green)"
        case .protanopia: return "Protanopia (Red-Green)"
        case .tritanopia: return "Tritanopia (Blue-Yellow)"
        case .normal: return "Normal Vision"
        }
    }

    // MARK: - Color Simulation

    /// Simulate color-blind vision for a given color
    /// - Parameter color: Original color
    /// - Returns: Simulated color as seen by color-blind users
    public func simulate(_ color: Color) -> Color {
        guard self != .normal else { return color }

        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Apply color blindness transformation matrix
        let (r, g, b) = transformRGB(red: red, green: green, blue: blue)

        return Color(
            .sRGB,
            red: Double(r),
            green: Double(g),
            blue: Double(b),
            opacity: Double(alpha)
        )
    }

    // MARK: - RGB Transformation

    /// Transform RGB values based on color blindness type
    /// - Parameters:
    ///   - red: Red component (0-1)
    ///   - green: Green component (0-1)
    ///   - blue: Blue component (0-1)
    /// - Returns: Transformed RGB tuple
    private func transformRGB(red: CGFloat, green: CGFloat, blue: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        switch self {
        case .deuteranopia:
            // Deuteranopia transformation matrix
            let r = red * 0.625 + green * 0.375
            let g = red * 0.7 + green * 0.3
            let b = blue * 1.0
            return (r, g, b)

        case .protanopia:
            // Protanopia transformation matrix
            let r = red * 0.567 + green * 0.433
            let g = red * 0.558 + green * 0.442
            let b = blue * 1.0
            return (r, g, b)

        case .tritanopia:
            // Tritanopia transformation matrix
            let r = red * 0.95 + green * 0.05
            let g = green * 1.0
            let b = red * 0.433 + blue * 0.567
            return (r, g, b)

        case .normal:
            return (red, green, blue)
        }
    }
}

// MARK: - Color Blindness Simulator Modifier

/// View modifier that simulates color blindness
public struct ColorBlindnessSimulatorModifier: ViewModifier {
    let type: ColorBlindnessType

    public init(type: ColorBlindnessType) {
        self.type = type
    }

    public func body(content: Content) -> some View {
        if type == .normal {
            content
        } else {
            content
                .colorMultiply(simulationColor)
                .overlay {
                    // Add visual indicator that simulation is active
                    VStack {
                        Spacer()
                        Text("Color Blindness Simulation: \(type.displayName)")
                            .font(.caption2)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
        }
    }

    private var simulationColor: Color {
        // Approximation using color multiply
        switch type {
        case .deuteranopia:
            return Color(red: 0.8, green: 0.9, blue: 1.0)
        case .protanopia:
            return Color(red: 0.75, green: 0.85, blue: 1.0)
        case .tritanopia:
            return Color(red: 1.0, green: 0.95, blue: 0.8)
        case .normal:
            return .white
        }
    }
}

// MARK: - View Extension

extension View {
    /// Simulate color blindness for testing (DEBUG only)
    /// - Parameter type: Type of color blindness to simulate
    /// - Returns: View with color blindness simulation
    public func simulateColorBlindness(_ type: ColorBlindnessType) -> some View {
        modifier(ColorBlindnessSimulatorModifier(type: type))
    }
}

// MARK: - Preview Helper

/// Preview helper for testing accessibility with different color blindness types
public struct ColorBlindnessPreviewContainer<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(ColorBlindnessType.allCases, id: \.self) { type in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(type.displayName)
                            .font(.headline)
                            .padding(.horizontal)

                        content
                            .simulateColorBlindness(type)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Stress Color Validator

/// Validates stress colors for color blindness accessibility
public struct StressColorValidator {
    /// Test stress colors against all color blindness types
    /// - Returns: Validation results
    public static func validateStressColors() -> [String: [ColorBlindnessType: Color]] {
        let categories: [StressCategory] = [.relaxed, .mild, .moderate, .high]
        var results: [String: [ColorBlindnessType: Color]] = [:]

        for category in categories {
            let color = category.color
            var categoryResults: [ColorBlindnessType: Color] = [:]

            for type in ColorBlindnessType.allCases {
                categoryResults[type] = type.simulate(color)
            }

            results[category.rawValue] = categoryResults
        }

        return results
    }

    /// Print validation results to console
    public static func printValidationResults() {
        let results = validateStressColors()
        print("🎨 Stress Color Validation for Color Blindness:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        for (category, simulations) in results {
            print("\n\(category.uppercased()):")
            for (type, color) in simulations {
                print("  - \(type.displayName): \(color)")
            }
        }

        print("\n✓ Validation complete. Review visual differences in Preview.")
    }
}

#endif
