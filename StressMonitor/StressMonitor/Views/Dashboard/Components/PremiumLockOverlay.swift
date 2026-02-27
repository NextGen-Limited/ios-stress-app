import SwiftUI

// MARK: - Premium Lock Overlay

/// Semi-transparent overlay that indicates premium-only features
/// Displays lock icon and upgrade button when user is not premium
struct PremiumLockOverlay: View {
    @AppStorage("isPremiumUser") private var isPremiumUser = false
    @State private var showPremiumSheet = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.white.opacity(0.63)
                .ignoresSafeArea()

            // Lock button
            Button {
                showPremiumSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Unlock with Premium")
                        .font(Typography.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color(hex: "#1A1A1A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#FFD380"))
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPremiumSheet) {
            PremiumPlaceholderView()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Premium feature locked. Tap to unlock with Premium subscription.")
    }
}

// MARK: - Premium Placeholder View

/// Placeholder view for premium upgrade screen
struct PremiumPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: "#FFD380"))
                    .padding(.top, 40)

                Text("Upgrade to Premium")
                    .font(Typography.title1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)

                VStack(spacing: 16) {
                    premiumFeatureRow(icon: "chart.bar.fill", text: "Advanced stress analytics")
                    premiumFeatureRow(icon: "calendar.badge.clock", text: "Unlimited history access")
                    premiumFeatureRow(icon: "bell.fill", text: "Custom stress alerts")
                    premiumFeatureRow(icon: "person.fill.checkmark", text: "Personalized insights")
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    // Premium purchase action placeholder
                    dismiss()
                } label: {
                    Text("Subscribe Now")
                        .font(Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.primaryBlue)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.Wellness.adaptiveBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color.primaryBlue)
                .frame(width: 24)

            Text(text)
                .font(Typography.body)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Premium Lock Overlay") {
    ZStack {
        Color.gray.opacity(0.3)
            .frame(width: 358, height: 376)

        PremiumLockOverlay()
    }
    .padding()
}

#Preview("Premium Placeholder View") {
    PremiumPlaceholderView()
}
