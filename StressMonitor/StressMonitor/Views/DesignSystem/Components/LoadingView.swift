import SwiftUI

struct LoadingView: View {
    var message: String?

    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(Typography.body)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundLight)
    }
}

struct LoadingOverlay: View {
    var isLoading: Bool
    var message: String?

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)

                    if let message = message {
                        Text(message)
                            .font(Typography.body)
                            .foregroundColor(.white)
                    }
                }
                .padding(Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                )
            }
        }
    }
}

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: 150)

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: 100)
            }

            Spacer()
        }
        .padding(Spacing.cellPadding)
        .shimmer()
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
