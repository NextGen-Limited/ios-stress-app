import SwiftUI

/// Notifications settings card with toggles, gradient intensity, and quiet hours.
struct NotificationsCard: View {
    @Binding var snapshotTipsEnabled: Bool
    @Binding var morningPreviewEnabled: Bool
    @Binding var notificationIntensity: Double
    @Binding var quietHoursStart: Date
    @Binding var quietHoursEnd: Date

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(
                    icon: "bell.fill",
                    title: "Notifications",
                    color: .settingsIconYellow
                )

                notificationToggle(
                    title: "New snapshot tips",
                    subtitle: "When Ripple notices stress changes",
                    isOn: $snapshotTipsEnabled,
                    accessibilityLabel: "New snapshot tips notification"
                )

                Divider().opacity(0.55)

                notificationToggle(
                    title: "Morning preview",
                    subtitle: morningPreviewSubtitle,
                    isOn: $morningPreviewEnabled,
                    accessibilityLabel: "Morning preview notification"
                )

                Divider().opacity(0.55)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Notification intensity")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(intensityLabel)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.settingsRippleBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.settingsRippleBlue.opacity(0.13), in: Capsule())
                    }

                    GradientIntensitySlider(value: $notificationIntensity)

                    HStack {
                        Text("Soft")
                        Spacer()
                        Text("Balanced")
                        Spacer()
                        Text("Strong")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                }

                Divider().opacity(0.55)

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
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
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
        return "Daily outlook at \(formatter.string(from: quietHoursEnd))"
    }

    private var intensityLabel: String {
        switch notificationIntensity {
        case 0..<0.34: return "Soft"
        case 0.34..<0.67: return "Balanced"
        default: return "Strong"
        }
    }

    private var quietHoursRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Quiet Hours")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text("Ripple stays quiet during your reset window")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(quietHoursRangeText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.settingsAmberInfo, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.settingsIconYellow.opacity(0.45), lineWidth: 1)
                )
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

private struct GradientIntensitySlider: View {
    @Binding var value: Double

    private let sliderHeight: CGFloat = 30
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let progress = min(max(value, 0), 1)
            let thumbOffset = max(thumbSize / 2, min(width - thumbSize / 2, width * progress))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.14))
                    .frame(height: 8)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "4FC3F7"), Color.settingsRippleBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbSize, width * progress), height: 8)

                Circle()
                    .fill(Color.Wellness.adaptiveCardBackground)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.16), radius: 5, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.settingsRippleBlue, lineWidth: 2)
                    )
                    .offset(x: thumbOffset - thumbSize / 2)
            }
            .frame(height: sliderHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let rawValue = min(max(gesture.location.x / width, 0), 1)
                        value = (rawValue / 0.25).rounded() * 0.25
                    }
            )
        }
        .frame(height: sliderHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Notification intensity")
        .accessibilityValue("\(Int(value * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(1, value + 0.25)
            case .decrement:
                value = max(0, value - 0.25)
            @unknown default:
                break
            }
        }
    }
}

struct NotificationsCard_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsCard(
            snapshotTipsEnabled: .constant(true),
            morningPreviewEnabled: .constant(true),
            notificationIntensity: .constant(0.5),
            quietHoursStart: .constant(Calendar.current.date(from: DateComponents(hour: 0, minute: 0)) ?? Date()),
            quietHoursEnd: .constant(Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date())
        )
        .padding()
        .background(Color.adaptiveSettingsBackground)
    }
}
