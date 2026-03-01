import SwiftUI

/// Quick actions and stress relief exercises
/// Placeholder for future implementation
struct ActionView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image("TabFlash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .opacity(0.3)

                Text("Quick Actions")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Breathing exercises and stress relief tools coming soon.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Action")
        }
    }
}

#Preview {
    ActionView()
}
