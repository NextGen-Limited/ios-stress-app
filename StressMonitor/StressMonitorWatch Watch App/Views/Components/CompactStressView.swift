import SwiftUI

/// Compact circular stress indicator used by complications and inline
/// previews. Light-theme aware: tier-coloured ring + numeric score +
/// tier glyph label.
struct CompactStressView: View {
    let stressLevel: Double
    var category: StressCategory { StressCategory.category(for: stressLevel) }
    var size: CGFloat = 120
    var showsScore: Bool = true
    var showsLabel: Bool = true

    private var ringWidth: CGFloat { max(4, size * 0.08) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WatchDesignTokens.separator, lineWidth: ringWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    category.color,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.2), value: fraction)

            VStack(spacing: 2) {
                if showsScore {
                    Text("\(Int(stressLevel))")
                        .font(.system(size: size * 0.30, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(category.inkColor)
                }
                if showsLabel {
                    Text(category.displayName)
                        .font(.system(size: size * 0.11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(WatchDesignTokens.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(width: size, height: size)
    }

    private var fraction: CGFloat {
        CGFloat(min(max(stressLevel, 0), 100) / 100.0)
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 12) {
        CompactStressView(stressLevel: 18, size: 80)
        CompactStressView(stressLevel: 42, size: 80)
        CompactStressView(stressLevel: 78, size: 80)
    }
    .padding()
    .background(WatchDesignTokens.canvas)
}
#endif
