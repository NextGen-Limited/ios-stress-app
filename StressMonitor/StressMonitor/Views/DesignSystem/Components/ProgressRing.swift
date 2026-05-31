import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var color: Color = .primaryBlue
    var lineWidth: CGFloat = 8
    var size: CGFloat = 60

    @State private var animateProgress = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth)
                )
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: animateProgress)
        }
        .onAppear {
            animateProgress = true
        }
    }
}

struct StressProgressRing: View {
    let stressLevel: Double

    var body: some View {
        ProgressRing(
            progress: stressLevel / 100,
            color: Color.stressColor(for: stressLevel),
            lineWidth: 12,
            size: 80
        )
    }
}
