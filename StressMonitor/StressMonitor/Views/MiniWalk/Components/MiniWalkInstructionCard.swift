import SwiftUI

/// Ripple companion speech-bubble for the Mini Walk screen.
///
/// Replaces the old static italic text card with a 40 pt bouncing
/// StressBuddyIllustration avatar and a glass-card speech bubble that updates
/// its message based on walk progress.
struct MiniWalkInstructionCard: View {
    let progress: Double

    @State private var bobOffset: CGFloat = 0

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 40 pt Ripple avatar with walk-bob animation
            StressBuddyIllustration(mood: rippleMood, size: 40)
                .offset(y: bobOffset)
                .accessibilityHidden(true)

            // Speech bubble — glass card with asymmetric corner
            Text(message)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#E0E0E8"))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    // Glass card #1A1A2E, accent border
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(HomeCharacterDesignTokens.darkCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(
                                    Color(hex: "#4FC3F7").opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                )
                // Asymmetric corner: tail pointing toward the avatar (bottom-left)
                .clipShape(BubbleTailShape(cornerRadius: 14, tailPosition: .bottomLeft))
        }
        .padding(.horizontal, 16)
        .onAppear { startBobAnimation() }
        .onDisappear { bobOffset = 0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Ripple says: \(message)")
    }

    // MARK: - Ripple Mood (synced with progress)

    private var rippleMood: RippleMood {
        if progress < 0.30 { return .focused }
        if progress < 0.70 { return .happy }
        if progress < 0.95 { return .determined }
        return .celebrating
    }

    // MARK: - Dynamic Messages

    private var message: String {
        switch progress {
        case ..<0.30:
            return "Let's go! Walk at a brisk pace. Focus on breathing."
        case ..<0.70:
            return "Keep going! You're doing great."
        case ..<0.95:
            return "Almost there! Just a few more minutes!"
        default:
            return "Last few seconds! Finish strong!"
        }
    }

    // MARK: - Walk-Bob Animation

    private func startBobAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            bobOffset = -3
        }
    }
}

// MARK: - Speech Bubble Shape

/// A rounded rectangle with a small triangular tail on one corner.
private struct BubbleTailShape: Shape {
    enum TailPosition { case bottomLeft, bottomRight }

    var cornerRadius: CGFloat = 14
    var tailPosition: TailPosition = .bottomLeft

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let r = cornerRadius
        let tailWidth: CGFloat = 8
        let tailHeight: CGFloat = 6

        // Top-left
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        // Top-right corner
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
                     radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        // Bottom-right corner
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                     radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // Bottom edge → tail
        if tailPosition == .bottomLeft {
            path.addLine(to: CGPoint(x: rect.minX + r + tailWidth + 4, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r + 2, y: rect.maxY + tailHeight))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        } else {
            path.addLine(to: CGPoint(x: rect.minX + r + tailWidth + 4, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r + 2, y: rect.maxY + tailHeight))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        }
        // Bottom-left corner
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                     radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        // Top-left corner
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r),
                     radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)

        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        MiniWalkInstructionCard(progress: 0.0)
        MiniWalkInstructionCard(progress: 0.5)
        MiniWalkInstructionCard(progress: 0.85)
        MiniWalkInstructionCard(progress: 0.99)
    }
    .padding(40)
    .background(HomeCharacterDesignTokens.darkCanvas)
}
