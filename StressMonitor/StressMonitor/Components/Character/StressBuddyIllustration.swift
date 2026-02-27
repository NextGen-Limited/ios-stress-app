import SwiftUI

// MARK: - Eye Side Enum

/// Represents left or right eye for character illustration
private enum EyeSide {
    case left
    case right
}

// MARK: - Stress Buddy Character Illustration

/// Custom SwiftUI illustration of the Stress Buddy character matching Figma design
/// Displays a cute rounded character with mood-based expressions
struct StressBuddyIllustration: View {
    let mood: StressBuddyMood
    let size: CGFloat

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body Parts

    private var bodySize: CGSize {
        CGSize(width: size * 0.7, height: size * 0.85)
    }

    // MARK: - Colors (from Figma)

    private var bodyColor: Color {
        colorScheme == .dark ? Color(hex: "#4A4A4A") : Color(hex: "#D9D9D9")
    }

    private var featureColor: Color {
        colorScheme == .dark ? Color(hex: "#C4C4C4") : Color(hex: "#363636")
    }

    private var cheekColor: Color {
        colorScheme == .dark ? Color(hex: "#CC7474") : Color(hex: "#FF9191")
    }

    var body: some View {
        ZStack {
            // Body (main ellipse)
            bodyShape

            // Arms
            leftArm
            rightArm

            // Legs
            leftLeg
            rightLeg

            // Face (overlay on body)
            faceView
                .offset(y: -size * 0.1)

            // Cheeks
            cheeksView

            // Mood-specific accessories
            accessoriesView
        }
        .frame(width: size, height: size)
        .characterAnimation(for: mood)
    }

    // MARK: - Body Shape

    @ViewBuilder
    private var bodyShape: some View {
        Ellipse()
            .fill(bodyColor)
            .frame(width: bodySize.width, height: bodySize.height)
            .overlay(
                // Belly highlight
                Ellipse()
                    .fill(bodyColor.opacity(0.5))
                    .frame(width: bodySize.width * 0.6, height: bodySize.height * 0.7)
                    .offset(y: size * 0.05)
            )
    }

    // MARK: - Arms

    @ViewBuilder
    private var leftArm: some View {
        Ellipse()
            .fill(bodyColor)
            .frame(width: size * 0.15, height: size * 0.25)
            .offset(x: -size * 0.4, y: size * 0.1)
            .rotationEffect(.degrees(-20))
    }

    @ViewBuilder
    private var rightArm: some View {
        Ellipse()
            .fill(bodyColor)
            .frame(width: size * 0.15, height: size * 0.25)
            .offset(x: size * 0.4, y: size * 0.1)
            .rotationEffect(.degrees(20))
    }

    // MARK: - Legs

    @ViewBuilder
    private var leftLeg: some View {
        Ellipse()
            .fill(bodyColor)
            .frame(width: size * 0.18, height: size * 0.2)
            .offset(x: -size * 0.15, y: size * 0.38)
    }

    @ViewBuilder
    private var rightLeg: some View {
        Ellipse()
            .fill(bodyColor)
            .frame(width: size * 0.18, height: size * 0.2)
            .offset(x: size * 0.15, y: size * 0.38)
    }

    // MARK: - Face

    @ViewBuilder
    private var faceView: some View {
        VStack(spacing: size * 0.05) {
            eyesView
            noseView
            mouthView
        }
        .frame(height: size * 0.4)
    }

    // MARK: - Eyes

    @ViewBuilder
    private var eyesView: some View {
        HStack(spacing: size * 0.15) {
            eye(for: .left)
            eye(for: .right)
        }
    }

    @ViewBuilder
    private func eye(for side: EyeSide) -> some View {
        let isLeft = side == .left
        let offsetX = isLeft ? -size * 0.12 : size * 0.12

        Group {
            switch mood {
            case .sleeping:
                // Closed eyes (curved lines)
                sleepingEye
            case .calm:
                // Relaxed eyes (slightly curved)
                calmEye
            case .concerned:
                // Worried eyes (raised eyebrow)
                concernedEye(isLeft: isLeft)
            case .worried:
                // Wide eyes
                worriedEye
            case .overwhelmed:
                // Distressed eyes
                overwhelmedEye
            }
        }
        .frame(width: size * 0.12, height: size * 0.08)
        .offset(x: offsetX)
    }

    @ViewBuilder
    private var sleepingEye: some View {
        // Curved closed eye - draw as a shape
        SleepingEyeShape()
            .fill(featureColor)
            .frame(width: size * 0.1, height: size * 0.04)
    }

    @ViewBuilder
    private var calmEye: some View {
        // Normal eye with slight curve (happy)
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.1, height: size * 0.06)
            Circle()
                .fill(featureColor)
                .frame(width: size * 0.05, height: size * 0.05)
                .offset(x: size * 0.01)
        }
    }

    @ViewBuilder
    private func concernedEye(isLeft: Bool) -> some View {
        // Worried eye with raised eyebrow
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.1, height: size * 0.07)
            Circle()
                .fill(featureColor)
                .frame(width: size * 0.04, height: size * 0.04)
            // Raised eyebrow
            Capsule()
                .fill(featureColor)
                .frame(width: size * 0.1, height: size * 0.015)
                .offset(y: -size * 0.05)
                .rotationEffect(.degrees(isLeft ? 15 : -15))
        }
    }

    @ViewBuilder
    private var worriedEye: some View {
        // Wide eye
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.11, height: size * 0.08)
            Circle()
                .fill(featureColor)
                .frame(width: size * 0.05, height: size * 0.05)
        }
    }

    @ViewBuilder
    private var overwhelmedEye: some View {
        // Very wide, distressed eye
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.09)
            Circle()
                .fill(featureColor)
                .frame(width: size * 0.06, height: size * 0.06)
            // Stress lines
            stressLines
        }
    }

    @ViewBuilder
    private var stressLines: some View {
        // Small lines above eye indicating stress
        ForEach(0..<3, id: \.self) { i in
            Rectangle()
                .fill(featureColor)
                .frame(width: size * 0.06, height: 1.5)
                .offset(x: CGFloat(i - 1) * size * 0.05, y: -size * 0.06)
                .rotationEffect(.degrees(45.0 + CGFloat(i) * 15.0))
        }
    }

    // MARK: - Nose

    @ViewBuilder
    private var noseView: some View {
        // Small rounded nose
        Ellipse()
            .fill(featureColor.opacity(0.6))
            .frame(width: size * 0.04, height: size * 0.03)
    }

    // MARK: - Mouth

    @ViewBuilder
    private var mouthView: some View {
        Group {
            switch mood {
            case .sleeping:
                // Slight smile (peaceful)
                SleepingMouthShape()
                    .fill(featureColor)
                    .frame(width: size * 0.08, height: size * 0.03)

            case .calm:
                // Gentle smile
                CalmMouthShape()
                    .fill(featureColor)
                    .frame(width: size * 0.1, height: size * 0.04)

            case .concerned:
                // Slight frown
                ConcernedMouthShape()
                    .fill(featureColor)
                    .frame(width: size * 0.08, height: size * 0.03)

            case .worried:
                // O-shaped mouth
                Ellipse()
                    .stroke(featureColor, lineWidth: 2)
                    .frame(width: size * 0.06, height: size * 0.08)

            case .overwhelmed:
                // Open mouth (distressed)
                Ellipse()
                    .fill(featureColor)
                    .frame(width: size * 0.08, height: size * 0.1)
            }
        }
        .frame(height: size * 0.1)
    }

    // MARK: - Cheeks

    @ViewBuilder
    private var cheeksView: some View {
        HStack {
            // Left cheek
            Circle()
                .fill(cheekColor.opacity(0.5))
                .frame(width: size * 0.06, height: size * 0.04)
                .offset(x: -size * 0.2, y: size * 0.05)

            Spacer()

            // Right cheek
            Circle()
                .fill(cheekColor.opacity(0.5))
                .frame(width: size * 0.06, height: size * 0.04)
                .offset(x: size * 0.2, y: size * 0.05)
        }
    }

    // MARK: - Accessories

    @ViewBuilder
    private var accessoriesView: some View {
        switch mood {
        case .sleeping:
            // Zzz bubbles
            sleepingBubbles
        case .concerned:
            // Sweat drop
            sweatDrop
        case .worried:
            // Multiple sweat drops
            multipleSweatDrops
        case .overwhelmed:
            // Flames and sweat
            flamesAndSweat
        case .calm:
            EmptyView()
        }
    }

    @ViewBuilder
    private var sleepingBubbles: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let letters = ["Z", "z", "z"]
                Text(letters[index])
                    .font(.system(size: size * 0.1, weight: .bold))
                    .foregroundStyle(featureColor.opacity(0.7))
                    .offset(
                        x: size * 0.35,
                        y: -size * 0.2 + CGFloat(index) * size * 0.1
                    )
                    .accessoryAnimation(index: index)
            }
        }
    }

    @ViewBuilder
    private var sweatDrop: some View {
        // Single sweat drop
        TeardropShape()
            .fill(Color(hex: "#87CEEB"))
            .frame(width: size * 0.05, height: size * 0.08)
            .offset(x: size * 0.3, y: -size * 0.15)
            .rotationEffect(.degrees(30))
            .accessoryAnimation(index: 0)
    }

    @ViewBuilder
    private var multipleSweatDrops: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                TeardropShape()
                    .fill(Color(hex: "#87CEEB"))
                    .frame(width: size * 0.04, height: size * 0.06)
                    .offset(
                        x: size * 0.25 + CGFloat(i) * size * 0.1,
                        y: -size * 0.12 - CGFloat(i) * size * 0.05
                    )
                    .rotationEffect(.degrees(30))
                    .accessoryAnimation(index: i)
            }
        }
    }

    @ViewBuilder
    private var flamesAndSweat: some View {
        ZStack {
            // Flame on head
            FlameShape()
                .fill(Color(hex: "#FF9500"))
                .frame(width: size * 0.1, height: size * 0.12)
                .offset(y: -size * 0.35)
                .accessoryAnimation(index: 0)

            // Sweat drops
            multipleSweatDrops
        }
    }
}

// MARK: - Custom Shapes

/// Sleeping eye shape (curved closed line)
private struct SleepingEyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let curveHeight = height * 0.8

        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control: CGPoint(x: width * 0.5, y: height * 0.5 - curveHeight)
        )

        return path.strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

/// Calm/sleeping mouth shape (slight smile)
private struct SleepingMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control: CGPoint(x: width * 0.5, y: height)
        )

        return path.strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

/// Calm mouth shape (gentle smile)
private struct CalmMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.3),
            control: CGPoint(x: width * 0.5, y: height)
        )

        return path.strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

/// Concerned mouth shape (slight frown)
private struct ConcernedMouthShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control: CGPoint(x: width * 0.5, y: 0)
        )

        return path.strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

/// Teardrop/sweat drop shape
struct TeardropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let minY = rect.minY
        let maxY = rect.maxY
        let midY = rect.midY
        let width = rect.width

        // Start at top point
        path.move(to: CGPoint(x: midX, y: minY))

        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: midX + width / 2, y: midY + rect.height * 0.3),
            control: CGPoint(x: midX + width / 2, y: minY)
        )

        // Bottom curve
        path.addQuadCurve(
            to: CGPoint(x: midX, y: maxY),
            control: CGPoint(x: midX + width / 2, y: maxY)
        )

        // Left curve
        path.addQuadCurve(
            to: CGPoint(x: midX - width / 2, y: midY + rect.height * 0.3),
            control: CGPoint(x: midX - width / 2, y: maxY)
        )

        // Back to top
        path.addQuadCurve(
            to: CGPoint(x: midX, y: minY),
            control: CGPoint(x: midX - width / 2, y: minY)
        )

        return path
    }
}

/// Flame shape
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let minY = rect.minY
        let maxY = rect.maxY
        let midY = rect.midY
        let width = rect.width

        // Start at bottom left
        path.move(to: CGPoint(x: midX - width / 2, y: maxY))

        // Left flame edge
        path.addQuadCurve(
            to: CGPoint(x: midX, y: minY),
            control: CGPoint(x: midX - width * 0.3, y: midY)
        )

        // Right flame edge
        path.addQuadCurve(
            to: CGPoint(x: midX + width / 2, y: maxY),
            control: CGPoint(x: midX + width * 0.3, y: midY)
        )

        // Bottom curve
        path.addQuadCurve(
            to: CGPoint(x: midX - width / 2, y: maxY),
            control: CGPoint(x: midX, y: maxY + rect.height * 0.1)
        )

        return path
    }
}

// MARK: - Preview

#Preview("All Moods") {
    HStack(spacing: 20) {
        ForEach(StressBuddyMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
                Text(mood.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
}

#Preview("Dark Mode") {
    HStack(spacing: 20) {
        ForEach(StressBuddyMood.allCases, id: \.self) { mood in
            VStack {
                StressBuddyIllustration(mood: mood, size: 120)
                Text(mood.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
    .background(Color.Wellness.adaptiveBackground)
    .preferredColorScheme(.dark)
}
