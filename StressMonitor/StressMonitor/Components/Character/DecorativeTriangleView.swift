import SwiftUI

// MARK: - Decorative Triangle View

/// Decorative triangle shape for visual enhancement
/// Used in StressCharacterCard for Figma-aligned design
struct DecorativeTriangleView: View {
    private let size: CGFloat = 40
    private let color: Color = Color.Wellness.boxBreathingPurple.opacity(0.3)

    var body: some View {
        TriangleShape()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(15))
    }
}

// MARK: - Triangle Shape

private struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    DecorativeTriangleView()
        .padding()
}
