#if DEBUG
import SwiftUI

/// Pill-shaped banner overlay indicating demo mode is active
struct DemoModeBannerView: View {
    var body: some View {
        Text("DEMO MODE")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange.opacity(0.8), in: Capsule())
    }
}
#endif
