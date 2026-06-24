import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel
    @State private var habitViewModel: HabitViewModel?
    @State private var navigateToExport = false
    @State private var navigateToDelete = false
    @State private var navigateToPremium = false
    @State private var navigateToCharacters = false
    @State private var docsURL: URL? = nil
    @State private var appearance = AppearanceManager.shared

    @Query(filter: #Predicate<CharacterUnlock> { $0.isActive })
    private var activeUnlocks: [CharacterUnlock]

    @Query(filter: #Predicate<CharacterUnlock> { $0.isUnlocked })
    private var unlockedCharacters: [CharacterUnlock]

    init() {
        _viewModel = State(initialValue: SettingsViewModel(
            modelContext: ModelContext((try? ModelContainer(for: StressMeasurement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))!)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.settingsCardSpacing) {
                meHeroSection
                companionBannerSection
                companionGroupSection
                syncDevicesSection
                habitsSection
                notificationsSection
                preferencesSection
                dataSupportSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Color.appBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = SettingsViewModel(modelContext: modelContext)
            if habitViewModel == nil {
                habitViewModel = HabitViewModel(modelContext: modelContext)
            } else {
                habitViewModel?.loadToday()
            }
            Task { await viewModel.loadUserProfile() }
        }
        .navigationDestination(isPresented: $navigateToExport) {
            DataExportView()
        }
        .navigationDestination(isPresented: $navigateToDelete) {
            DataDeleteView()
        }
        .navigationDestination(isPresented: $navigateToPremium) {
            IAPPremiumView(storeKit: Self.makeStoreKitService(), premiumState: PremiumState.shared)
        }
        .navigationDestination(isPresented: $navigateToCharacters) {
            CharacterCollectionView()
        }
        .sheet(item: $docsURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }

    // MARK: - 1. Me-hero

    private var meHeroSection: some View {
        MeHeroCard(
            bioAge: bioAgeValue,
            stressLevel: viewModel.latestStressLevel,
            streakDays: streakDayCount,
            displayName: "You",
            email: nil,
            onPlusTap: { navigateToPremium = true }
        )
    }

    // MARK: - 2. Active companion banner

    private var companionBannerSection: some View {
        CompanionBanner(
            companionName: activeCreature.displayName,
            companionSubtitle: activeCreature.element.rawValue.capitalized,
            mood: RippleMood.from(stressLevel: viewModel.latestStressLevel),
            onSwitch: { navigateToCharacters = true }
        )
    }

    // MARK: - 3. Companion group

    private var companionGroupSection: some View {
        SettingsCard {
            Button {
                navigateToCharacters = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "circle.grid.2x2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HomeCharacterDesignTokens.Ripple.deep)
                        .frame(width: 34, height: 34)
                        .background(HomeCharacterDesignTokens.Ripple.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Companion Collection")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                        Text("\(activeCreature.emoji) \(activeCreature.displayName) · \(unlockedCharacters.count) unlocked")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                    }

                    Spacer()
                    Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.6))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Companion collection. \(unlockedCharacters.count) unlocked.")
        }
    }

    // MARK: - 4. Sync & devices

    private var syncDevicesSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSectionHeader(icon: "heart.text.square.fill", title: "Sync & devices", color: .primaryGreen)
                    .padding(.bottom, 14)

                healthAccessRow
                hairlineDivider
                watchFaceRow
                hairlineDivider
                widgetRow

                if healthAuthStatus == .sharingAuthorized {
                    hairlineDivider
                    Button {
                        Task { await viewModel.loadUserProfile() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .bold))
                            Text("Sync now")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(Color.settingsRippleBlue)
                        .padding(.vertical, 10)
                    }
                    .accessibilityLabel("Sync health data now")
                }
            }
        }
        .onAppear { refreshHealthAuthStatus() }
        .alert("Health Access Needed", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Ripple needs Health access to read your stress data. Please enable it in Settings → Privacy → Health.")
        }
    }

    // MARK: - 5. Habits

    private var habitsSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 14) {
                SettingsSectionHeader(icon: "checklist", title: "Habits & tracking", color: .settingsIconPurple)

                if let habitVM = habitViewModel {
                    ForEach(HabitType.allCases) { type in
                        if let habit = habitVM.habit(for: type) {
                            HabitLogRow(habit: habit) {
                                habitVM.logManual(type)
                            }
                        }
                    }
                } else {
                    ForEach(HabitType.allCases) { type in
                        HabitLogRow(habit: Habit(type: type))
                    }
                }
            }
        }
    }

    // MARK: - 6. Notifications

    private var notificationsSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSectionHeader(icon: "bell.fill", title: "Notifications", color: .settingsIconYellow)
                    .padding(.bottom, 12)

                notificationToggle(
                    title: "New snapshot tips",
                    subtitle: "When Ripple notices stress changes",
                    isOn: $viewModel.notificationSettings.snapshotTipsEnabled
                )
                hairlineDivider
                notificationToggle(
                    title: "Morning preview",
                    subtitle: morningPreviewSubtitle,
                    isOn: $viewModel.notificationSettings.morningPreviewEnabled
                )
            }
        }
    }

    // MARK: - 7. Preferences (appearance + iCloud + premium)

    private var preferencesSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSectionHeader(icon: "slider.horizontal.3", title: "Preferences", color: .settingsRippleBlue)
                    .padding(.bottom, 12)

                appearanceRow
                hairlineDivider
                iCloudRow
                hairlineDivider
                premiumRow
            }
        }
    }

    // MARK: - 8. Data & support

    private var dataSupportSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSectionHeader(icon: "lock.shield.fill", title: "Data & support", color: .settingsIconPurple)
                    .padding(.bottom, 12)

                supportRow("Export CSV", icon: "arrow.down.doc") { navigateToExport = true }
                hairlineDivider
                supportRow("Delete all data", icon: "trash", role: .destructive) { navigateToDelete = true }
                hairlineDivider
                supportRow("Help & FAQ", icon: "questionmark.circle") { docsURL = DocsURL.help }
                hairlineDivider
                supportRow("Privacy Policy", icon: "hand.raised") { docsURL = DocsURL.privacy }
                hairlineDivider
                supportRow("Terms of Service", icon: "doc.text") { docsURL = DocsURL.terms }

                VStack(spacing: 4) {
                    Text("StressMonitor v1.0.0")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
            }
        }
    }

    // MARK: - Row builders

    private func notificationToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.primaryGreen)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private var appearanceRow: some View {
        HStack {
            Text("Appearance")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            Spacer()
            Picker("Appearance", selection: $appearance.preferredScheme) {
                ForEach(AppearanceManager.Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Appearance mode")
    }

    private var iCloudRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("iCloud Sync")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Sync settings across devices")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Toggle("", isOn: $viewModel.iCloudSyncEnabled)
                .labelsHidden()
                .tint(.primaryGreen)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("iCloud sync")
    }

    private var premiumRow: some View {
        Button {
            navigateToPremium = true
        } label: {
            HStack {
                Image(systemName: AppIconSystem.System.premium.sfSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.premiumGold)
                Text("Premium")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Spacer()
                PlusPill(onTap: { navigateToPremium = true })
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Premium. Unlock advanced features.")
    }

    private func supportRow(_ title: String, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) -> some View {
        Button(role: role, action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(role == .destructive ? Color.error : Color.settingsRippleBlue)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(role == .destructive ? Color.error : Color.Wellness.adaptivePrimaryText)
                Spacer()
                Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
            }
            .contentShape(Rectangle())
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Sync & devices rows

    private var healthAccessRow: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(healthStatusColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("Health Access")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text(healthStatusText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            if healthAuthStatus != .sharingAuthorized {
                Button(action: requestHealthPermission) {
                    HStack(spacing: 4) {
                        if isRequestingHealthPermission {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 12))
                        }
                        Text("Enable")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color.settingsRippleBlue)
                }
                .disabled(isRequestingHealthPermission)
                .accessibilityLabel("Request Health access")
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health access. \(healthStatusText)")
    }

    private var watchFaceRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.settingsRippleBlue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("Watch face & complications")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Add Ripple to your watch")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Watch face and complications")
    }

    private var widgetRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.primaryGreen)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text("Home screen widget")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
                Text("Stress score at a glance")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
            }
            Spacer()
            Image(systemName: AppIconSystem.Nav.forward.sfSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.5))
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Home screen widget")
    }

    private var hairlineDivider: some View {
        Rectangle()
            .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }

    // MARK: - Derived values

    private var activeCreature: CharacterCreature {
        activeUnlocks.first
            .flatMap { CharacterCreature.find(by: $0.characterId) }
            ?? CharacterCreature.allCharacters[0]
    }

    private var bioAgeValue: Int? {
        // Bio age requires a live BioAgeCalculator run not yet wired into SettingsViewModel.
        // Surface nil (rendered as "—") instead of fabricating a number.
        nil
    }

    private var streakDayCount: Int {
        // Streak requires historical measurement aggregation not yet exposed by the repository.
        // Surface 0 until a streak provider exists; avoids fabricating a number.
        0
    }

    private var morningPreviewSubtitle: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Daily outlook at \(formatter.string(from: viewModel.notificationSettings.quietHoursEnd))"
    }

    // MARK: - HealthKit state

    @State private var healthAuthStatus: HKAuthorizationStatus = .notDetermined
    @State private var isRequestingHealthPermission = false
    @State private var showPermissionDeniedAlert = false

    private var healthStatusColor: Color {
        switch healthAuthStatus {
        case .sharingAuthorized: return .green
        case .sharingDenied:     return .red
        case .notDetermined:     return .orange
        @unknown default:        return .gray
        }
    }

    private var healthStatusText: String {
        switch healthAuthStatus {
        case .sharingAuthorized: return "Access granted"
        case .sharingDenied:     return "Access denied — tap to enable"
        case .notDetermined:     return "Not requested yet"
        @unknown default:        return "Unknown"
        }
    }

    private func refreshHealthAuthStatus() {
        healthAuthStatus = HKHealthStore().authorizationStatus(for: .quantityType(forIdentifier: .heartRateVariabilitySDNN)!)
    }

    private func requestHealthPermission() {
        isRequestingHealthPermission = true
        guard HKHealthStore.isHealthDataAvailable() else {
            isRequestingHealthPermission = false
            return
        }

        let store = HKHealthStore()
        let types: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKCategoryType(.sleepAnalysis),
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]

        store.requestAuthorization(toShare: [], read: types) { _, _ in
            Task { @MainActor in
                isRequestingHealthPermission = false
                refreshHealthAuthStatus()
                if healthAuthStatus == .sharingDenied {
                    showPermissionDeniedAlert = true
                }
            }
        }
    }

    // MARK: - StoreKit factory (ported from previous SettingsView)

    #if DEBUG
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        MockStoreKitService(premiumState: PremiumState.shared)
    }
    #else
    private static func makeStoreKitService() -> StoreKitServiceProtocol {
        StoreKitService(premiumState: PremiumState.shared)
    }
    #endif
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsView()
        }
        .modelContainer(for: [StressMeasurement.self, CharacterUnlock.self], inMemory: true)
    }
}
