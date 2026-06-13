import SwiftUI

// MARK: - ProfileCard

/// Profile section card for Settings: appearance mode + delete all data.
struct ProfileCard: View {
    @State private var appearance = AppearanceManager.shared
    let onDeleteAllData: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(icon: "person.circle.fill", title: "Profile")

                // Appearance mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary)

                    Picker("Appearance", selection: $appearance.preferredScheme) {
                        ForEach(AppearanceManager.Mode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Appearance mode selector")
                }

                Divider()

                // Delete all data button
                Button(role: .destructive, action: onDeleteAllData) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 14))
                        Text("Delete All Data")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.red)
                }
                .accessibilityLabel("Delete all user data")
            }
        }
    }
}

#if DEBUG
#Preview {
    ProfileCard(onDeleteAllData: {})
        .padding()
        .background(Color.adaptiveSettingsBackground)
}
#endif
