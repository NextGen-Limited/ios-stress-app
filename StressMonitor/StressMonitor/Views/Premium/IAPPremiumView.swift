import SwiftUI

struct IAPPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumViewModel
    @State private var creditsViewModel: CreditsViewModel
    @State private var hasLoadedPlans = false
    @State private var showPurchaseSuccess = false
    @State private var showPackSuccess = false

    init(
        storeKit: StoreKitServiceProtocol,
        premiumState: PremiumState,
        credits: CreditsViewModel
    ) {
        _viewModel = State(initialValue: PremiumViewModel(storeKit: storeKit, premiumState: premiumState))
        _creditsViewModel = State(initialValue: credits)
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

                    if viewModel.selectedPlanDetails?.hasIntroductoryOffer == true && viewModel.isEligibleForIntroOffer {
                        trialBanner
                            .padding(.horizontal, 16)
                            .padding(.top, 18)
                    }

                    // Section 4b — Credit packs (DEC-1: secondary one-time
                    // top-ups; the subscription above stays the leading path)
                    packSection
                        .padding(.horizontal, 16)
                        .padding(.top, 26)

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
            .accessibleDynamicType()

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
            await creditsViewModel.loadPacks()
            hasLoadedPlans = true
        }
        .onChange(of: viewModel.showSuccess) {
            if viewModel.showSuccess {
                showPurchaseSuccess = true
            }
        }
        .onChange(of: creditsViewModel.showSuccess) {
            if creditsViewModel.showSuccess {
                showPackSuccess = true
            }
        }
        .sheet(isPresented: $showPurchaseSuccess) {
            PurchaseSuccessView()
                .onDisappear {
                    viewModel.showSuccess = false
                    dismiss()
                }
        }
        .sheet(isPresented: $showPackSuccess) {
            PurchaseSuccessView(
                purchasedPack: creditsViewModel.purchasedPack,
                newBalanceText: creditsViewModel.currentBalanceText
            )
            .onDisappear {
                creditsViewModel.showSuccess = false
                dismiss()
            }
        }
        .alert("Purchase Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
        .alert("Purchase Error", isPresented: $creditsViewModel.showError) {
            Button("OK") { creditsViewModel.dismissError() }
        } message: {
            Text(creditsViewModel.errorMessage ?? "An error occurred.")
        }
    }

    // MARK: - Pack section

    private var packSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OR TOP UP ONCE")
                .font(Typography.iapSectionHeader)
                .kerning(0.10 * 12)
                .foregroundStyle(Color.iapHeaderTeal)
                .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(Array(orderedPacks.enumerated()), id: \.offset) { _, pack in
                    PackCard(
                        pack: pack,
                        isSelected: creditsViewModel.selectedPack == pack?.id,
                        isLoading: isLoadingPlans,
                        savingsPercent: savingsPercent(for: pack),
                        isBestValue: pack?.id == .large,
                        onSelect: {
                            if let id = pack?.id {
                                creditsViewModel.selectedPack = id
                                HapticManager.shared.buttonPress()
                            }
                        }
                    )
                }
            }

            packPurchaseButton

            Text("Credit packs are one-time purchases — they don't renew automatically.")
                .font(Typography.iapFinePrint)
                .foregroundStyle(Color.iapTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var packPurchaseButton: some View {
        Button {
            guard creditsViewModel.selectedPackDetails != nil else { return }
            HapticManager.shared.buttonPress()
            Task { await creditsViewModel.purchaseSelectedPack() }
        } label: {
            HStack(spacing: 8) {
                if creditsViewModel.isLoading {
                    ProgressView()
                        .tint(Color.iapHeaderTeal)
                } else {
                    Text(packCTATitle)
                        .font(Typography.iapCTA)
                        .tracking(-0.02 * 16)
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(Color.iapHeaderTeal)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                Capsule().fill(Color.iapPillBackground)
            )
            .overlay(
                Capsule().stroke(Color.iapHeaderTeal.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(creditsViewModel.isLoading || creditsViewModel.selectedPackDetails == nil)
        .accessibilityLabel(packCTATitle)
    }

    /// Packs ordered small -> large. While loading, returns two `nil`
    /// placeholders so the section renders two skeleton cards.
    private var orderedPacks: [CreditPack?] {
        if isLoadingPlans || creditsViewModel.packs.isEmpty {
            return [nil, nil]
        }
        let order: [CreditPackID] = [.small, .large]
        return order.compactMap { id in
            creditsViewModel.packs.first(where: { $0.id == id })
        }
    }

    private var packCTATitle: String {
        guard let pack = creditsViewModel.selectedPackDetails else {
            return "Select a pack to buy"
        }
        guard let price = pack.displayPrice, !price.isEmpty else {
            return "Buy \(pack.displayName)"
        }
        return "Buy \(pack.displayName) · \(price)"
    }

    /// Per-unit savings of one pack versus the most expensive per-credit
    /// pack in the resolved set (typically large vs small).
    private func savingsPercent(for pack: CreditPack?) -> Int? {
        guard let pack, let price = pack.pricePerPack, pack.credits > 0 else { return nil }
        let referenceUnit = creditsViewModel.packs
            .compactMap { candidate -> Decimal? in
                guard candidate.credits > 0, let candidatePrice = candidate.pricePerPack else { return nil }
                return candidatePrice / Decimal(candidate.credits)
            }
            .max()
        guard let referenceUnit, referenceUnit > 0 else { return nil }
        let unit = price / Decimal(pack.credits)
        guard unit < referenceUnit else { return nil }
        let percent = Int(((referenceUnit - unit) / referenceUnit * 100) as NSDecimalNumber)
        return percent > 0 ? percent : nil
    }

    // MARK: - Trial banner

    private var trialBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.iapAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text(trialHeadline)
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
        .accessibilityLabel("\(trialHeadline), then \(selectedPlanPriceDisplay). Cancel anytime during the trial.")
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

    private var trialHeadline: String {
        if let unit = viewModel.selectedPlanDetails?.introOfferPeriodUnit {
            return "\(unit) free trial"
        }
        return "Free trial"
    }
}
