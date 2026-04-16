import SwiftUI

/// AI Chat settings card for configuring cloud LLM server connection
struct AIChatSettingsCard: View {
    @AppStorage("ai_server_url") private var serverURL: String = ""
    @AppStorage("ai_api_key") private var apiKey: String = ""

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                SettingsSectionHeader(icon: "bubble.left.and.bubble.right.fill", title: "AI Chat")

                // Server URL
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server URL")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("https://your-server.com", text: $serverURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                        .disableAutocorrection(true)
                }

                // API Key
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    SecureField("Enter API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 15))
                }

                // Info note
                Text("Changes take effect on next chat session.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}
