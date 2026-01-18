import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("StressMonitor")
                .font(.title3)
                .fontWeight(.bold)

            Text("Phase 1")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
