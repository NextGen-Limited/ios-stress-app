import SwiftUI

enum PlusPillMode {
    case labelOnly
    case tryFree
}

struct PlusPill: View {
    var mode: PlusPillMode = .labelOnly
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            HapticManager.shared.buttonPress()
            onTap?()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }

    @ViewBuilder
    private var content: some View {
        switch mode {
        case .labelOnly:
            Text("PLUS")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(Color.premiumGold)
                .textCase(.uppercase)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.premiumGold.opacity(0.14))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.premiumGold.opacity(0.32), lineWidth: 1))

        case .tryFree:
            HStack(spacing: 6) {
                Image(AppIconSystem.Setting.plusPillSparkleAsset)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text("Plus")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Text("Try free ›")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.premiumGold.opacity(0.85))
            }
            .foregroundStyle(Color.premiumGold)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.premiumGold.opacity(0.14))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.premiumGold.opacity(0.32), lineWidth: 1))
        }
    }

    private var accessibility: String {
        switch mode {
        case .labelOnly:    return "Plus member"
        case .tryFree:      return "Plus. Try free."
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        PlusPill(mode: .labelOnly)
        PlusPill(mode: .tryFree)
    }
    .padding()
    .background(Color.appBackground)
}
