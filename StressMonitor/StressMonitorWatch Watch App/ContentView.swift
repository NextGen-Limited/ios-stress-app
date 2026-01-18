import SwiftUI

struct ContentView: View {
  @State private var viewModel = WatchStressViewModel()

  var body: some View {
    NavigationStack {
      VStack(spacing: WatchDesignTokens.standardSpacing) {
        if let stress = viewModel.currentStress {
          CompactStressView(stressLevel: stress.level, category: stress.category)
        } else {
          CompactStressView(stressLevel: 0, category: .relaxed)
            .opacity(0.5)
        }

        Button(action: {
          Task {
            await viewModel.measureStress()
          }
        }) {
          HStack {
            if viewModel.isLoading {
              ProgressView()
                .progressViewStyle(.circular)
            } else {
              Image(systemName: "heart.fill")
              Text("Measure")
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: WatchDesignTokens.buttonHeight)
          .background(Color.blue)
          .foregroundStyle(.white)
          .cornerRadius(WatchDesignTokens.buttonCornerRadius)
        }
        .disabled(viewModel.isLoading)

        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.system(size: WatchDesignTokens.captionSize))
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }
      }
      .padding()
      .navigationTitle("Stress")
      .task {
        await viewModel.requestAuthorization()
        await viewModel.loadLatestStress()
      }
    }
  }
}

#Preview {
  ContentView()
}
