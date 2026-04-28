import SwiftUI

struct IAPPremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PremiumViewModel

    init(storeKit: StoreKitServiceProtocol, premiumState: PremiumState = .shared) {
        _viewModel = State(initialValue: PremiumViewModel(storeKit: storeKit, premiumState: premiumState))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                IAPNavBar(onBack: { dismiss() }, onClose: { dismiss() })

                IAPHeroSection()
                    .padding(.top, 8)

                VStack(spacing: 24) {
                    Text("CHOOSE YOUR PLAN")
                        .font(Typography.iapSectionHeader)
                        .kerning(-0.24)
                        .foregroundColor(Color.iapHeaderTeal)

                    VStack(spacing: 11) {
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
                .padding(.top, 54)

                VStack(spacing: 20) {
                    IAPCTAButton(isLoading: viewModel.isLoading) {
                        Task { await viewModel.purchaseSelectedPlan() }
                    }

                    VStack(spacing: 16) {
                        IAPUtilityRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: .iapRestoreBlue,
                            title: "Restore Purchases"
                        ) {
                            Task { await viewModel.restorePurchases() }
                        }

                        IAPUtilityRow(
                            icon: "gearshape",
                            iconColor: .iapManageDark,
                            title: "Manage Subscriptions"
                        ) {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }

                        IAPUtilityRow(
                            icon: "receipt",
                            iconColor: .iapManageDark,
                            title: "Purchase History"
                        ) {
                            // Future: show purchase history sheet
                        }
                    }

                    VStack(spacing: 4) {
                        Text("Subscription auto-renews. Cancel anytime.")
                            .font(Typography.iapSubtitle)
                            .foregroundColor(Color.iapTextSecondary)
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: DocsURL.terms)
                            Text("\u{00B7}")
                            Link("Privacy Policy", destination: DocsURL.privacy)
                        }
                        .font(Typography.iapSubtitle)
                        .foregroundColor(Color.iapHeaderTeal)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 17)
                .padding(.top, 40)
            }
            .padding(.bottom, 40)
        }
        .background(Color.white)
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
