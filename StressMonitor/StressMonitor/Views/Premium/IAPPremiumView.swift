import SwiftUI

struct IAPPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumViewModel

    init(storeKit: StoreKitServiceProtocol, premiumState: PremiumState) {
        _viewModel = State(initialValue: PremiumViewModel(storeKit: storeKit, premiumState: premiumState))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    IAPNavBar(onBack: { dismiss() }, onClose: { dismiss() })

                    IAPHeroSection()
                        .padding(.top, 6)

                    // Benefits section
                    IAPBenefitsCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                    // Plan selection
                    VStack(spacing: 0) {
                        Text("CHOOSE YOUR PLAN")
                            .font(Typography.iapSectionHeader)
                            .kerning(0.10 * 12)
                            .foregroundStyle(Color.iapHeaderTeal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

                        VStack(spacing: 10) {
                            ForEach(viewModel.plans) { plan in
                                PlanSelectionCard(
                                    plan: plan,
                                    isSelected: viewModel.selectedPlan == plan.id,
                                    onSelect: { viewModel.selectedPlan = plan.id }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)

                    // Trust indicators
                    IAPTrustIndicators()
                        .padding(.horizontal, 16)
                        .padding(.top, 14)

                    // Spacer for sticky bottom bar
                    Color.clear
                        .frame(height: 140)
                }
                .padding(.bottom, 20)
            }
            .background(
                // Warm background with subtle cyan glow
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

                // Fine print
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
                Divider()
                    .background(Color.iapIconBorder.opacity(0.15))
            }
        }
        .navigationBarHidden(true)
        .task { await viewModel.loadInitialData() }
        .onChange(of: viewModel.showSuccess) {
            if viewModel.showSuccess {
                dismiss()
            }
        }
        .alert("Purchase Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
    }
}
