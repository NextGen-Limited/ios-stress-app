import SwiftUI

struct PlanSelectionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Plan name + subtitle (left), price (right)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.displayName)
                            .font(Typography.iapPlanName)
                            .foregroundStyle(Color.iapTextPrimary)

                        if let subtitle = plan.subtitle {
                            Text(subtitle)
                                .font(Typography.iapSubtitle)
                                .foregroundStyle(Color.iapTextSecondary)
                        }
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(plan.priceDisplay)
                            .font(Typography.iapPrice)
                            .foregroundStyle(Color.iapTextPrimary)

                        Text("/month")
                            .font(Typography.iapPerMonth)
                            .foregroundStyle(Color.iapTextSecondary)
                    }
                }

                // Savings row (annual only)
                if let savings = plan.savingsDisplay {
                    HStack {
                        Spacer()
                        Text(savings)
                            .font(Typography.iapSavings)
                            .foregroundStyle(Color.iapSavingsGreen)
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 82)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.iapAmber : Color.clear, lineWidth: 2)
            )
            .shadow(AppShadow.iapPlanCard)
            .overlay(alignment: .top) {
                // Best Value badge
                if plan.isBestValue && isSelected {
                    Text("Best Value")
                        .font(Typography.iapBadge)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.iapAmber))
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
    .background(Color(UIColor.systemGroupedBackground))
}
