import SwiftUI

struct EvolutionCelebrationView: View {
    let creature: CharacterCreature
    let newStage: EvolutionStage

    @Environment(\.dismiss) private var dismiss
    @State private var showGlow = false
    @State private var showCharacter = false
    @State private var showText = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                if showText {
                    VStack(spacing: Spacing.sm) {
                        Text("Evolution!")
                            .font(Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("\(creature.displayName) evolved to \(newStage.displayName)!")
                            .font(Typography.body)
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                ZStack {
                    if showGlow {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [creature.element.primaryColor.opacity(0.65), .clear],
                                    center: .center,
                                    startRadius: 50,
                                    endRadius: 150
                                )
                            )
                            .frame(width: 300, height: 300)
                            .transition(.opacity)
                    }

                    if showCharacter {
                        StressBuddyIllustration(
                            characterId: creature.id,
                            evolution: newStage,
                            mood: .calm,
                            size: 165
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer()

                if showText {
                    Button("Awesome!") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .tint(creature.element.primaryColor)
                        .controlSize(.large)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(Spacing.xl)
        }
        .onAppear { runAnimationSequence() }
    }

    private func runAnimationSequence() {
        withAnimation(.easeOut(duration: 0.6)) {
            showGlow = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showCharacter = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            showText = true
        }
    }
}
