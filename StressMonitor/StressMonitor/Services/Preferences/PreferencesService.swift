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
        await enqueueUpdate {
            await self.updateField(
                "language",
                newValue: newValue,
                read: { self.language },
                set: { self.language = $0 }
            )
        }
    }

    func update(coachingStyle newValue: String) async {
        await enqueueUpdate {
            await self.updateField(
                "coaching_style",
                newValue: newValue,
                read: { self.coachingStyle },
                set: { self.coachingStyle = $0 }
            )
        }
    }

    /// Serializes optimistic updates: each runs only after the previous one
    /// fully settled (PUT resolved, revert applied, error surfaced).
    /// `@MainActor` serializes the synchronous parts but not the awaits —
    /// without this chain, two rapid picker taps interleave and a stale
    /// revert can clobber the newer optimistic value (WR-04).
    private var updateChain: Task<Void, Never>?

    private func enqueueUpdate(_ operation: @escaping @MainActor () async -> Void) async {
        let predecessor = updateChain
        let task = Task {
            await predecessor?.value
            await operation()
        }
        updateChain = task
        await task.value
    }

    /// Shared optimistic-update skeleton: set, PUT the single field, keep the
    /// optimistic value on success (the server persisted exactly it), revert
    /// and surface the error on failure. Runs serialized (see
    /// `updateChain`) and reads its revert value inside the serialized
    /// section — after every earlier update settled — so a failure always
    /// reverts to the value the user actually saw.
    private func updateField(
        _ field: String,
        newValue: String,
        read: () -> String,
        set: (String) -> Void
    ) async {
        let revertValue = read()
        set(newValue)
        do {
            _ = try await apiClient.updatePreferences(fields: [field: newValue])
            errorMessage = nil
        } catch {
            set(revertValue)
            errorMessage = error.localizedDescription
        }
    }
}
