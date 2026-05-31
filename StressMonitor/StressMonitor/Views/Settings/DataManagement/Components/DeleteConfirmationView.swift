import SwiftUI

/// Confirmation view for data deletion operations
/// Requires user to type "DELETE" to confirm, shows affected data and consequences
struct DeleteConfirmationView: View {
    let deleteScope: DataDeleteScope
    let dateRange: DateRange?
    let affectedDataCounts: AffectedDataCounts
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var confirmationText = ""
    @FocusState private var isTextFieldFocused: Bool

    private let requiredConfirmationText = "DELETE"

    var isConfirmationValid: Bool {
        confirmationText.uppercased() == requiredConfirmationText
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.warning)
                        .padding(.top, 20)

                    // Title
                    Text(deleteScope.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.horizontal)

                    // Warning message
                    Text(deleteScope.warningMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // What will be deleted section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What will be deleted")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 12) {
                            DeleteConfirmationItem(
                                icon: "heart.slash.fill",
                                title: "Stress Measurements",
                                count: affectedDataCounts.stressMeasurements,
                                color: .error
                            )

                            if deleteScope.includesBaseline {
                                DeleteConfirmationItem(
                                    icon: "chart.line.flattrend.xyaxis",
                                    title: "Personal Baseline",
                                    count: affectedDataCounts.baseline ? 1 : 0,
                                    color: .warning
                                )
                            }

                            if let range = dateRange {
                                DeleteConfirmationItem(
                                    icon: "calendar.badge.exclamationmark",
                                    title: "Date Range",
                                    subtitle: range.displayText,
                                    count: nil,
                                    color: .secondary
                                )
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                    // Consequences section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important")
                            .font(.headline)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 8) {
                            ConsequenceRow(
                                icon: "xmark.circle.fill",
                                text: "This action cannot be undone"
                            )

                            ConsequenceRow(
                                icon: "xmark.circle.fill",
                                text: deleteScope.includesCloud ? "Data will be removed from all devices" : "Only local data will be affected"
                            )

                            ConsequenceRow(
                                icon: "info.circle.fill",
                                text: "HealthKit data will not be affected"
                            )
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                    // Confirmation requirement
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type DELETE to confirm")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter DELETE", text: $confirmationText)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.characters)
                            .focused($isTextFieldFocused)
                            .accessibilityLabel("Confirmation text field")
                            .accessibilityHint("Type \(requiredConfirmationText) to enable the delete button")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: onConfirm) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Everything")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isConfirmationValid ? Color.error : Color.secondary)
                            .cornerRadius(26)
                        }
                        .disabled(!isConfirmationValid)
                        .accessibilityLabel("Delete all data")
                        .accessibilityHint(isConfirmationValid ? "Double tap to permanently delete data" : "Type DELETE to enable")

                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.primaryBlue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.primaryBlue.opacity(0.1))
                                .cornerRadius(26)
                        }
                        .accessibilityLabel("Cancel and return")
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Confirm Deletion")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

/// Individual item showing what will be deleted
struct DeleteConfirmationItem: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let count: Int?
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let count = count {
                Text("\(count)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        if let count = count {
            Text(count == 1 ? "1 item" : "\(count) items")
                .accessibilityHidden(true)
        }
    }
}

/// Row displaying a consequence
struct ConsequenceRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(icon.contains("xmark") ? .error : .warning)

            Text(text)
                .font(.callout)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Data deletion scope
enum DataDeleteScope {
    case localOnly
    case cloudOnly
    case everything

    var title: String {
        switch self {
        case .localOnly: return "Delete Local Data"
        case .cloudOnly: return "Delete Cloud Data"
        case .everything: return "Delete All Data"
        }
    }

    var warningMessage: String {
        switch self {
        case .localOnly:
            return "This will permanently delete all stress measurements stored on this device. Your cloud data will not be affected."
        case .cloudOnly:
            return "This will permanently delete all data from iCloud. Your local data will remain on this device."
        case .everything:
            return "This will permanently delete all your stress measurements from both this device and iCloud. This action cannot be undone."
        }
    }

    var includesBaseline: Bool {
        switch self {
        case .localOnly, .everything: return true
        case .cloudOnly: return false
        }
    }

    var includesCloud: Bool {
        switch self {
        case .localOnly: return false
        case .cloudOnly, .everything: return true
        }
    }
}

/// Date range for deletion
struct DateRange {
    let startDate: Date
    let endDate: Date

    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

/// Counts of affected data
struct AffectedDataCounts {
    let stressMeasurements: Int
    let baseline: Bool
}

#Preview {
    DeleteConfirmationView(
        deleteScope: .everything,
        dateRange: DateRange(
            startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            endDate: Date()
        ),
        affectedDataCounts: AffectedDataCounts(
            stressMeasurements: 1247,
            baseline: true
        ),
        onConfirm: {},
        onCancel: {}
    )
}
