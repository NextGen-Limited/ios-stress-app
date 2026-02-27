import SwiftUI

// MARK: - Decorative Triangle View

/// Decorative triangle element from Figma design
/// Size: 37x34.5px, Color: #363636 at 80% opacity
/// Positioned in top-right area of stress character card
struct DecorativeTriangleView: View {
    /// Size of the triangle (default: Figma spec 37x34.5)
    let size: CGSize

    /// Whether to show shadow effects
    let showShadow: Bool

    init(
        width: CGFloat = 37,
        height: CGFloat = 34.5,
        showShadow: Bool = true
    ) {
        self.size = CGSize(width: width, height: height)
        self.showShadow = showShadow
    }

    var body: some View {
        TriangleShape()
            .fill(Color(hex: "#363636"))
            .opacity(0.8)
            .frame(width: size.width, height: size.height)
            .modifier(DecorativeShadowModifier(showShadow: showShadow))
    }
}

// MARK: - Triangle Shape

/// Custom triangle shape pointing right
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Triangle pointing right
        // Top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Bottom-left corner
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        // Right point (center-right)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        // Back to start
        path.closeSubpath()

        return path
    }
}

// MARK: - Shadow Modifier

/// Multi-layered shadow matching card shadow from Figma
struct DecorativeShadowModifier: ViewModifier {
    let showShadow: Bool

    func body(content: Content) -> some View {
        if showShadow {
            content
                .shadow(color: .black.opacity(0.04), radius: 2.2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.03), radius: 4.4, x: 0, y: 2.2)
                .shadow(color: .black.opacity(0.02), radius: 8.8, x: 0, y: 4.4)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview("Decorative Triangle") {
    ZStack {
        Color.Wellness.adaptiveBackground

        VStack(spacing: 40) {
            DecorativeTriangleView()

            DecorativeTriangleView(showShadow: false)
                .opacity(0.5)

            HStack(spacing: 20) {
                ForEach([20, 30, 40], id: \.self) { width in
                    DecorativeTriangleView(width: CGFloat(width), height: CGFloat(width) * 0.93)
                }
            }
        }
    }
}

#Preview("On Card") {
    ZStack(alignment: .topTrailing) {
        // Simulated card background
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.Wellness.adaptiveCardBackground)
            .frame(width: 390, height: 408)

        // Decorative triangle in top-right area
        DecorativeTriangleView()
            .padding(.top, 60)
            .padding(.trailing, 30)
    }
    .background(Color.Wellness.adaptiveBackground)
}
