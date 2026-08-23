import Foundation
import Observation

// MARK: - Preferences Service

/// Owns the chat-relevant preference pair (language + coaching style) with
/// seed-once hydration and optimistic, revert-on-failure updates.
///
/// The backend row is the authority; this cache exists so the Settings
/// pickers and the stress-context payload read one on-device source of truth
/// (derived-PREF-02). Seeding is best-effort background hydration — a failed
/// GET never surfaces an error; only a failed user-initiated PUT does
/// (reverted state + `errorMessage`, T-3-08).
@MainActor
@Observable
final class PreferencesService {

    /// Defaults mirror the backend migration so a fresh install reads
    /// identically before the first seed lands.
    private(set) var language: String = "en"
    private(set) var coachingStyle: String = "supportive"

    /// True once a GET has mapped the server row into state. Repeated
    /// surfaces (Settings onAppear, chat open) call `seedIfNeeded()` for free.
    private(set) var hasSeeded = false

    /// Non-nil only after a failed user-initiated update; the optimistic
    /// value has already been reverted when this is set. Settings surfaces it.
    private(set) var errorMessage: String?

    private let apiClient: StressAPIClient

    init(apiClient: StressAPIClient? = nil) {
        self.apiClient = apiClient ?? StressAPIClient()
    }

    /// Hydrates the pair from the server once per process. Silent on failure
    /// by design: defaults stay, `hasSeeded` stays false so a later surface
    /// retries. Never writes — a fresh install must not overwrite the server
    /// row with device defaults (T-3-06).
    func seedIfNeeded() async {
        guard !hasSeeded else { return }
        do {
            let preferences = try await apiClient.getPreferences()
            language = preferences.language
            coachingStyle = preferences.coachingStyle
            hasSeeded = true
        } catch {
            // Best-effort hydration — leave defaults, allow a retry.
        }
    }

    func update(language newValue: String) async {
        await updateField("language", newValue: newValue, revertValue: language) { self.language = $0 }
    }

    func update(coachingStyle newValue: String) async {
        await updateField("coaching_style", newValue: newValue, revertValue: coachingStyle) { self.coachingStyle = $0 }
    }

    /// Shared optimistic-update skeleton: set, PUT the single field, keep the
    /// optimistic value on success (the server persisted exactly it), revert
    /// and surface the error on failure.
    private func updateField(
        _ field: String,
        newValue: String,
        revertValue: String,
        apply: (String) -> Void
    ) async {
        apply(newValue)
        do {
            _ = try await apiClient.updatePreferences(fields: [field: newValue])
            errorMessage = nil
        } catch {
            apply(revertValue)
            errorMessage = error.localizedDescription
        }
    }
}
