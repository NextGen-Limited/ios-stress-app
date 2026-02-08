import SwiftUI

/// Progress view for data export operations
/// Displays progress bar, current operation, records processed, and estimated time remaining
struct ExportProgressView: View {
    let progress: Double // 0.0 to 1.0
    let currentOperation: String
    let recordsProcessed: Int
    let totalRecords: Int
    let estimatedTimeRemaining: TimeInterval?
    let isCancellable: Bool
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress indicator with animation
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.primaryBlue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityLabel("Export progress: \(Int(progress * 100)) percent complete")
            .accessibilityValue("\(recordsProcessed) of \(totalRecords) records processed")

            VStack(spacing: 12) {
                // Current operation
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(currentOperation)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)

                // Records processed
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                    Text("\(recordsProcessed) of \(totalRecords) records")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Estimated time remaining
                if let timeRemaining = estimatedTimeRemaining {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(estimatedTimeText(timeRemaining))
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            // Cancel button (if cancellable)
            if isCancellable {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.primaryBlue.opacity(0.1))
                        .cornerRadius(26)
                }
                .padding(.horizontal, 32)
                .accessibilityHint("Cancel the export operation")
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private func estimatedTimeText(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 60 {
            return "About \(Int(timeInterval)) seconds remaining"
        } else {
            let minutes = Int(timeInterval / 60)
            return "About \(minutes) minute\(minutes == 1 ? "" : "s") remaining"
        }
    }
}

/// Linear progress bar variant for use in cards
struct ExportProgressBarView: View {
    let progress: Double // 0.0 to 1.0
    let currentOperation: String
    let recordsProcessed: Int
    let totalRecords: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(currentOperation)
                    .font(.callout)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(recordsProcessed)/\(totalRecords)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.primaryBlue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentOperation), \(recordsProcessed) of \(totalRecords) records, \(Int(progress * 100)) percent complete")
    }
}

#Preview {
    VStack(spacing: 40) {
        ExportProgressView(
            progress: 0.65,
            currentOperation: "Preparing data...",
            recordsProcessed: 650,
            totalRecords: 1000,
            estimatedTimeRemaining: 45,
            isCancellable: true,
            onCancel: {}
        )

        ExportProgressBarView(
            progress: 0.45,
            currentOperation: "Generating CSV...",
            recordsProcessed: 450,
            totalRecords: 1000
        )
        .padding()
    }
}
