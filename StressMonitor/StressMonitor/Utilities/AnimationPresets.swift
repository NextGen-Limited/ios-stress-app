import SwiftUI

/// Animation presets for consistent timing across the app
/// All durations follow 150-300ms guidelines for micro-interactions
extension Animation {
    /// Quick micro-interaction (100ms)
    static let micro = Animation.easeOut(duration: 0.1)

    /// Standard micro-interaction (150ms)
    static let quick = Animation.easeOut(duration: 0.15)

    /// Standard interaction (250ms)
    static let standard = Animation.easeOut(duration: 0.25)

    /// Emphasis animation (350ms)
    static let emphasis = Animation.easeOut(duration: 0.35)

    /// Spring animation for bouncy feel
    static let springy = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Stiff spring for quick feedback
    static let stiffSpring = Animation.spring(response: 0.2, dampingFraction: 0.8)

    /// Slow spring for dramatic effect
    static let slowSpring = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Smooth ease for state transitions
    static let smooth = Animation.easeInOut(duration: 0.3)
}

// MARK: - Staggered Animation Modifier

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    let totalItems: Int
    let baseDelay: Double

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var delay: Double {
        baseDelay * Double(index)
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    /// Applies staggered appear animation for list items
    func staggeredAppear(index: Int, total: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearModifier(index: index, totalItems: total, baseDelay: delay))
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerLoadingModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content.redacted(reason: .placeholder)
        } else {
            content
                .overlay(
                    ShimmerEffectView(phase: $phase)
                )
                .redacted(reason: .placeholder)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        }
    }
}

struct ShimmerEffectView: View {
    @Binding var phase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color.white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
        }
        .mask(Rectangle())
    }
}

extension View {
    /// Applies shimmer loading effect
    func shimmerLoading() -> some View {
        modifier(ShimmerLoadingModifier())
    }
}

// MARK: - Preview

#Preview("Animation Presets Demo") {
    VStack(spacing: 20) {
        Text("Animation Presets")
            .font(.headline)

        Text("Micro, Quick, Standard, Emphasis")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.oledBackground)
}
