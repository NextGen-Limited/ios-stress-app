import SwiftUI

struct IAPPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumViewModel
    @State private var hasLoadedPlans = false
    @State private var showPurchaseSuccess = false

    init(storeKit: StoreKitServiceProtocol, premiumState: PremiumState) {
        _viewModel = State(initialValue: PremiumViewModel(storeKit: storeKit, premiumState: premiumState))
    }

    private var isLoadingPlans: Bool { !hasLoadedPlans }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    IAPNavBar(onBack: { dismiss() }, onClose: { dismiss() })

                    // Section 1 — Transformation hero
                    RippleTransformationHero()
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Section 2 — Features (lead with Trends)
                    IAPBenefitsCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    // Section 3 — Plan grid (with loading skeleton)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHOOSE YOUR PLAN")
                            .font(Typography.iapSectionHeader)
                            .kerning(0.10 * 12)
                            .foregroundStyle(Color.iapHeaderTeal)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(Array(orderedPlans.enumerated()), id: \.offset) { _, plan in
                                PlanCard(
                                    plan: plan,
                                    isSelected: viewModel.selectedPlan == plan?.period,
                                    isLoading: isLoadingPlans,
                                    onSelect: {
                                        if let period = plan?.period {
                                            viewModel.selectedPlan = period
                                            HapticManager.shared.buttonPress()
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // Section 4 — 7-day trial prominence + CTA handled by sticky bar
                    trialBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 18)

                    // Section 5 — Trust indicators
                    TrustRow()
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    // Spacer for sticky bottom bar
                    Color.clear.frame(height: 150)
                }
                .padding(.bottom, 20)
            }
            .background(
                ZStack {
                    Color.iapWarmBackground
                    RadialGradient(
                        colors: [Color.iapGradientStart.opacity(0.12), .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 350
                    )
                }
            )

            // Sticky bottom CTA bar
            VStack(spacing: 0) {
                IAPCTAButton(isLoading: viewModel.isLoading) {
                    Task { await viewModel.purchaseSelectedPlan() }
                }

                VStack(spacing: 4) {
                    Text("Subscription auto-renews. Cancel anytime in App Store settings.")
                        .font(Typography.iapFinePrint)
                        .foregroundStyle(Color.iapTextSecondary)

                    HStack(spacing: 4) {
                        Link("Terms", destination: DocsURL.terms)
                            .foregroundStyle(Color.iapHeaderTeal)
                        Text("\u{00B7}")
                            .foregroundStyle(Color.iapTextSecondary)
                        Link("Privacy", destination: DocsURL.privacy)
                            .foregroundStyle(Color.iapHeaderTeal)
                    }
                    .font(Typography.iapFinePrint)
                }
                .padding(.top, 9)

                IAPFooterLinks {
                    Task { await viewModel.restorePurchases() }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 17)
            .padding(.top, 12)
            .padding(.bottom, 18)
            .background(
                Color.iapWarmBackground.opacity(0.88)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
            .overlay(alignment: .top) {
                Divider().background(Color.iapIconBorder.opacity(0.15))
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadInitialData()
            hasLoadedPlans = true
        }
        .onChange(of: viewModel.showSuccess) {
            if viewModel.showSuccess {
                showPurchaseSuccess = true
            }
        }
        .sheet(isPresented: $showPurchaseSuccess) {
            PurchaseSuccessView()
                .onDisappear {
                    viewModel.showSuccess = false
                    dismiss()
                }
        }
        .alert("Purchase Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }

    // MARK: - Trial banner

    private var trialBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.iapAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text("7-day free trial")
                    .font(Typography.iapPlanName)
                    .foregroundStyle(Color.iapTextPrimary)
                Text("Then \(selectedPlanPriceDisplay). Cancel anytime during the trial.")
                    .font(Typography.iapPlanFooter)
                    .foregroundStyle(Color.iapTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [Color.iapAmber.opacity(0.14), Color.iapCardBackground.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.iapAmber.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("7-day free trial, then \(selectedPlanPriceDisplay). Cancel anytime during the trial.")
    }

    // MARK: - Derived

    /// Plans ordered annual -> monthly -> weekly. While loading, returns three
    /// `nil` placeholders so the grid renders three skeleton cards.
    private var orderedPlans: [SubscriptionPlan?] {
        if isLoadingPlans || viewModel.plans.isEmpty {
            // Three skeleton slots matching the expected plan count
            return [nil, nil, nil]
        }
        let order: [SubscriptionPeriod] = [.annual, .monthly, .weekly]
        return order.compactMap { period in
            viewModel.plans.first(where: { $0.period == period })
        }
    }

    private var selectedPlanPriceDisplay: String {
        viewModel.selectedPlanDetails?.priceDisplay ?? "—"
    }
}
