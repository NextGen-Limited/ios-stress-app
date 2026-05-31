import SwiftUI

/// Notifications settings card with toggles, slider, and quiet hours
struct NotificationsCard: View {
    @Binding var snapshotTipsEnabled: Bool
    @Binding var morningPreviewEnabled: Bool
    @Binding var notificationIntensity: Double
    @Binding var quietHoursStart: Date
    @Binding var quietHoursEnd: Date

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(icon: "bell.fill", title: "Notifications")

                // New snapshot tips toggle
                notificationToggle(
                    title: "New snapshot tips",
                    subtitle: "When stress levels change",
                    isOn: $snapshotTipsEnabled,
                    accessibilityLabel: "New snapshot tips notification"
                )

                Divider()

                // Morning preview toggle
                notificationToggle(
                    title: "Morning preview",
                    subtitle: morningPreviewSubtitle,
                    isOn: $morningPreviewEnabled,
                    accessibilityLabel: "Morning preview notification"
                )

                Divider()

                // Intensity slider
                Slider(value: $notificationIntensity, in: 0...1, step: 0.25)
                    .tint(.accentTeal)
                    .accessibilityLabel("Notification intensity")
                    .accessibilityValue("\(Int(notificationIntensity * 100))%")

                Divider()

                // Quiet hours row
                quietHoursRow
            }
        }
    }

    // MARK: - Subviews

    private func notificationToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        accessibilityLabel: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.primaryGreen)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var morningPreviewSubtitle: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Daily Outlook at \(formatter.string(from: quietHoursEnd))"
    }

    private var quietHoursRow: some View {
        HStack {
            Text("Quiet Hours")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
            Spacer()
            Text(quietHoursRangeText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quiet hours from \(quietHoursRangeText)")
    }

    private var quietHoursRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: quietHoursStart)) - \(formatter.string(from: quietHoursEnd))"
    }
}

#Preview {
    @Previewable @State var snapshots = true
    @Previewable @State var morning = true
    @Previewable @State var intensity = 0.5
    @Previewable @State var start = Calendar.current.date(from: DateComponents(hour: 0, minute: 0)) ?? Date()
    @Previewable @State var end = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    NotificationsCard(
        snapshotTipsEnabled: $snapshots,
        morningPreviewEnabled: $morning,
        notificationIntensity: $intensity,
        quietHoursStart: $start,
        quietHoursEnd: $end
    )
    .padding()
    .background(Color.adaptiveSettingsBackground)
}
