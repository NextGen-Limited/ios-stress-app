import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)

                Text("StressMonitor")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Phase 1: Foundation")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("StressMonitor")
        }
    }
}

#Preview {
    ContentView()
}
