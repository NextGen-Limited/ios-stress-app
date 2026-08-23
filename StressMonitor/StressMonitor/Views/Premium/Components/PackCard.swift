import SwiftUI

/// Single consumable credit-pack tier in the paywall's pack section.
///
/// Shares `PlanCard`'s token structure (radio selection, iap* typography,
/// skeleton while unresolved) with pack-specific content: one-time price,
/// per-credit unit price, and a "Best Value" pill on the selected large pack.
struct PackCard: View {
    let pack: CreditPack?
    let isSelected: Bool
    let isLoading: Bool
    let savingsPercent: Int?
    let isBestValue: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                if isLoading || pack == nil {
                    skeletonContent
                } else {
                    packContent
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(Color.iapCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 23))
            .overlay(
                RoundedRectangle(cornerRadius: 23)
                    .stroke(isSelected ? Color.iapAmber : Color.iapIconBorder.opacity(0.15), lineWidth: 1.4)
            )
            .shadow(
                color: isSelected
                    ? Color(hex: "FFAE3B").opacity(0.16)
                    : Color.black.opacity(0.04),
                radius: isSelected ? 12 : 8,
                y: isSelected ? 6 : 3
            )
            .overlay(alignment: .top) {
                if let pack, isBestValue, isSelected {
                    Text(bestValueBadge)
                        .font(Typography.iapBadge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.iapAmber))
                        .shadow(color: Color(hex: "FFAE3B").opacity(0.26), radius: 6, y: 3)
                        .offset(y: -13)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading || pack == nil)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Content

    @ViewBuilder
    private var packContent: some View {
        if let pack {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.iapAmber : Color.iapTextSecondary.opacity(0.35),
                            lineWidth: 2
                        )
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle().fill(Color.iapAmber).frame(width: 10, height: 10)
                    }
                }
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.displayName)
                        .font(Typography.iapPlanName)
                        .tracking(-0.03 * 17)
                        .foregroundStyle(Color.iapTextPrimary)

                    Text("One-time purchase")
                        .font(Typography.iapPlanSubtitle)
                        .foregroundStyle(Color.iapTextSecondary)
                }
                .padding(.leading, 10)

                Spacer()

                Text(pack.displayPrice ?? "—")
                    .font(Typography.iapPrice)
                    .tracking(-0.045 * 22)
                    .foregroundStyle(Color.iapTextPrimary)
            }

            HStack {
                Text(unitPriceText(for: pack))
                    .font(Typography.iapPlanFooter)
                    .foregroundStyle(Color.iapTextSecondary)
                Spacer()
                if let savingsPercent {
                    Text("Save \(savingsPercent)%")
                        .font(Typography.iapPlanFooter)
                        .foregroundStyle(Color.iapSavingsGreen)
                }
            }
        }
    }

    private var skeletonContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(Color.iapIconBorder.opacity(0.15)).frame(width: 22, height: 22)
                SkeletonBlock(height: 14).frame(width: 90)
                Spacer()
                SkeletonBlock(height: 22).frame(width: 60)
            }
            SkeletonBlock(height: 10).frame(width: 120)
        }
    }

    // MARK: - Derived

    private var bestValueBadge: String {
        if let savingsPercent {
            return "Best Value · Save \(savingsPercent)%"
        }
        return "Best Value"
    }

    private func unitPriceText(for pack: CreditPack) -> String {
        guard let price = pack.pricePerPack, pack.credits > 0 else {
            return "\(pack.credits) credits"
        }
        let unit = price / Decimal(pack.credits)
        let formatted = Self.unitPriceFormatter.string(from: unit as NSDecimalNumber) ?? ""
        return "\(formatted) per credit"
    }

    private var accessibilityLabel: String {
        if isLoading || pack == nil {
            return "Loading credit pack"
        }
        guard let pack else { return "Credit pack" }
        let selected = isSelected ? ", selected" : ""
        return "\(pack.displayName), \(pack.displayPrice ?? ""), one-time purchase\(selected)"
    }

    private static let unitPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

#Preview {
    VStack(spacing: 16) {
        PackCard(
            pack: CreditPack.defaultPacks[1],
            isSelected: true,
            isLoading: false,
            savingsPercent: 33,
            isBestValue: true,
            onSelect: {}
        )
        PackCard(
            pack: CreditPack.defaultPacks[0],
            isSelected: false,
            isLoading: false,
            savingsPercent: nil,
            isBestValue: false,
            onSelect: {}
        )
        PackCard(pack: nil, isSelected: false, isLoading: true, savingsPercent: nil, isBestValue: false, onSelect: {})
    }
    .padding()
    .background(Color(hex: "F5F2EC"))
}
