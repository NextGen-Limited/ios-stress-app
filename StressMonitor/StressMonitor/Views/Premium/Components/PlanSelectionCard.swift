import SwiftUI

struct PlanSelectionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    private var title: String {
        switch plan.period {
        case .annual:  return "Annual"
        case .weekly:  return plan.displayName
        case .monthly: return plan.displayName
        }
    }

    private var subtitle: String {
        if plan.period == .annual { return plan.subtitle ?? "Best value option" }
        return plan.subtitle ?? "Flexible access"
    }

    private var priceText: String {
        switch plan.period {
        case .annual:
            return Self.currencyFormatter.string(from: plan.pricePerMonth as NSDecimalNumber) ?? "$14.99"
        case .monthly, .weekly:
            return plan.priceDisplay
        }
    }

    private var periodText: String {
        plan.periodUnitDisplay
    }

    private var rightFooterText: String {
        switch plan.period {
        case .annual:
            return "\(Self.currencyFormatter.string(from: plan.pricePerPeriod as NSDecimalNumber) ?? "$179.88") billed yearly"
        case .monthly:
            return plan.billingSummary ?? "Billed monthly"
        case .weekly:
            return plan.billingSummary ?? "Billed weekly"
        }
    }

    private var leftFooterText: String {
        switch plan.period {
        case .annual:
            return plan.savingsDisplay ?? "Save 25%"
        case .monthly:
            return "No commitment"
        case .weekly:
            return "Cancel anytime"
        }
    }

    private var footerColor: Color {
        plan.period == .annual ? Color.iapSavingsGreen : Color.iapTextSecondary
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                // Main row: radio + name + price
                HStack(alignment: .top) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.iapAmber : Color.iapTextSecondary.opacity(0.35),
                                lineWidth: 2
                            )
                            .frame(width: 22, height: 22)

                        if isSelected {
                            Circle()
                                .fill(Color.iapAmber)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.top, 2)

                    // Plan name
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(Typography.iapPlanName)
                            .tracking(-0.03 * 17)
                            .foregroundStyle(Color.iapTextPrimary)

                        Text(subtitle)
                            .font(Typography.iapPlanSubtitle)
                            .foregroundStyle(Color.iapTextSecondary)
                    }
                    .padding(.leading, 10)

                    Spacer()

                    // Price
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(priceText)
                                .font(Typography.iapPrice)
                                .tracking(-0.045 * 22)
                                .foregroundStyle(Color.iapTextPrimary)

                            Text(periodText)
                                .font(Typography.iapPerMonth)
                                .foregroundStyle(Color.iapTextSecondary)
                        }
                    }
                }

                // Footer: savings / commitment + billing summary
                HStack {
                    Text(leftFooterText)
                        .font(Typography.iapPlanFooter)
                        .foregroundStyle(footerColor)

                    Spacer()

                    Text(rightFooterText)
                        .font(Typography.iapPlanFooter)
                        .foregroundStyle(footerColor)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)
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
                // Best Value badge
                if plan.isBestValue && isSelected {
                    Text("Best Value")
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
    }
}

#Preview {
    VStack(spacing: 16) {
        PlanSelectionCard(
            plan: SubscriptionPlan.defaultPlans[0],
            isSelected: true,
            onSelect: {}
        )
        PlanSelectionCard(
            plan: SubscriptionPlan.defaultPlans[1],
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
    .background(Color(hex: "F5F2EC"))
}
