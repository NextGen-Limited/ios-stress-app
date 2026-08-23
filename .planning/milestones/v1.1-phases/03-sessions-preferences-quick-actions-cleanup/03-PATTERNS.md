# Phase 3: Sessions, Preferences, Quick Actions + Cleanup - Pattern Map

**Mapped:** 2026-08-23
**Files analyzed:** 25 (14 new, 11 modified)
**Analogs found:** 22 / 25 (3 new patterns — no close analog, use RESEARCH.md guidance)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `Models/ChatSession.swift` | model | request-response | `Models/CreditBalance.swift` | exact |
| `Models/ChatSessionMessage.swift` | model | request-response | `Models/CreditBalance.swift` | exact |
| `Models/UserPreferences.swift` | model | request-response | `Models/CreditBalance.swift` | exact |
| `Models/ServerQuickAction.swift` | model | request-response | `Models/CreditBalance.swift` | exact |
| `Services/API/StressAPIClient+Sessions.swift` | service (API ext) | request-response | `Services/API/StressAPIClient+Credits.swift` | exact |
| `Services/API/StressAPIClient+Preferences.swift` | service (API ext) | request-response | `Services/API/StressAPIClient+Credits.swift` | exact |
| `Services/API/StressAPIClient+QuickActions.swift` | service (API ext) | request-response | `Services/API/StressAPIClient+Credits.swift` | exact |
| `Services/Preferences/PreferencesService.swift` | service | CRUD | `Services/Credits/CreditService.swift` | exact |
| `Services/LLM/StressLLMService.swift` (modify) | service | streaming | itself — existing `send` + `apply(metadata:)` | n/a (self-edit) |
| `Services/LLM/StressContextPayload.swift` (modify) | service | transform | itself — existing `build()` + CodingKeys | n/a (self-edit) |
| `ViewModels/ChatViewModel.swift` (modify) | component (VM) | request-response | itself — existing `send`/`clearConversation` | n/a (self-edit) |
| `Views/Chat/ChatBottomSheetView.swift` (modify) | component (view) | event-driven | itself — existing `onAppear`/`defaultQuickReplies` | n/a (self-edit) |
| `Views/Settings/SettingsView.swift` (modify) | component (view) | event-driven | itself — existing `preferencesSection` | n/a (self-edit) |
| `Services/DataManagement/DataDeleterService.swift` (modify) | service | batch | itself — existing `performFactoryReset` + injection seam | n/a (self-edit) |
| `StressMonitorApp.swift` (modify) | config | n/a | itself — existing `creditService` environment injection | n/a (self-edit) |
| `.gitignore` (modify) | config | n/a | n/a | trivial |
| `design/screens/25-about.html` (modify) | config | n/a | n/a | trivial |
| `Tests/StressAPIClientSessionsTests.swift` | test | request-response | `Tests/StressAPIClientCreditsTests.swift` | exact |
| `Tests/StressAPIClientPreferencesTests.swift` | test | request-response | `Tests/StressAPIClientCreditsTests.swift` | exact |
| `Tests/StressAPIClientQuickActionsTests.swift` | test | request-response | `Tests/StressAPIClientCreditsTests.swift` | exact |
| `Tests/PreferencesServiceTests.swift` | test | CRUD | `Tests/ChatLifecycleTests.swift` (FakeLLMService pattern) | role-match |
| `Tests/ChatHistoryRestoreTests.swift` | test | request-response | `Tests/ChatLifecycleTests.swift` (FakeLLMService + waitFor) | role-match |
| `Tests/DataDeleterServerWipeTests.swift` | test | batch | `Tests/DataDeletionConsolidationTests.swift` | role-match |
| `Tests/StressContextPayloadTests.swift` (modify) | test | transform | itself — existing XCTestCase suite | n/a (self-edit) |
| `project.pbxproj` (modify) | config | n/a | itself — existing 4-line registration pattern | n/a (self-edit) |

## Pattern Assignments

### `Models/ChatSession.swift` (model, request-response)

**Analog:** `Models/CreditBalance.swift`

**Imports pattern** (line 1):
```swift
import Foundation
```

**DTO struct pattern** (lines 9-28 — the full `CreditBalance` struct):
```swift
struct CreditBalance: Codable, Sendable, Equatable {
    let total: Int
    let used: Int
    var remaining: Int
    let planType: PlanType
    /// ISO-8601 timestamp string as delivered by the backend (may be null).
    let freeResetAt: String?

    enum PlanType: String, Codable, Sendable {
        case free
        case premium
    }

    enum CodingKeys: String, CodingKey {
        case total
        case used
        case remaining
        case planType = "plan_type"
        case freeResetAt = "free_reset_at"
    }

    var isUnlimited: Bool { planType == .premium }

    var displayDescription: String {
        isUnlimited ? "Unlimited" : "\(remaining) credits"
    }
}
```

**Key conventions to replicate:**
- `Codable, Sendable, Equatable` conformance
- `CodingKeys` enum mapping camelCase → snake_case
- Date fields as `String` (NOT `Date`) — see Pitfall 1: Postgres TIMESTAMPTZ with fractional seconds breaks `.iso8601` decoding. Follow the `freeResetAt: String?` precedent.
- `// MARK: -` section dividers
- Doc comments on the struct and on non-obvious stored properties

**ChatSession-specific notes:** Decode only `id`, `title`, `createdAt`, `updatedAt` from `select *`. Codable ignores extra keys by default. Dates as `String?`.

---

### `Models/ChatSessionMessage.swift` (model, request-response)

**Analog:** `Models/CreditBalance.swift` + `Models/ChatMessage.swift`

**DTO shape** (from backend `select id, session_id, role, content, tokens_used, created_at`):
- Map to a plain Codable struct (NOT `ChatMessage` — that's the in-memory display model with `UUID` ids, `Date` timestamps, and local metadata).
- `role` maps to existing `ChatRole` enum (same raw values: `user`/`assistant`/`system`).
- `created_at` as `String` (fractional-second safe). `tokens_used` as `Int?`.

**ChatRole reuse** (ChatMessage.swift lines 6-10):
```swift
enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
    case system
}
```

**Mapping to display model** (in `ChatViewModel.restoreHistory`):
```swift
// From ChatSessionMessage DTO → ChatMessage display model
ChatMessage(
    role: dto.role,
    content: dto.content,
    timestamp: Date(),  // cosmetic only — bubble shows time via formatter
    remoteId: dto.id,
    sessionId: dto.sessionId,
    isSynced: true,     // server-authoritative
    tokensUsed: dto.tokensUsed
)
```

---

### `Models/UserPreferences.swift` (model, request-response)

**Analog:** `Models/CreditBalance.swift`

**DTO shape** (from backend GET /preferences — full row, Codable ignores extra keys):
- `language: String` (default "en")
- `coachingStyle: String` (default "supportive")
- CodingKeys: `language`, `coachingStyle = "coaching_style"`
- All other backend fields (`display_name`, `theme`, `notification_enabled`, `stress_alert_threshold`, `custom_settings`) are silently ignored by Codable.

---

### `Models/ServerQuickAction.swift` (model, request-response)

**Analog:** `Models/CreditBalance.swift`

**DTO shape** (from backend `QuickAction { id, title, type }`):
```swift
struct ServerQuickAction: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let type: String  // "exercise" | "technique" | "tips" | "conversation"
}
```

---

### `Services/API/StressAPIClient+Sessions.swift` (service, request-response)

**Analog:** `Services/API/StressAPIClient+Credits.swift` (full file, 73 lines)

**Error enum pattern** (lines 3-18):
```swift
enum CreditsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case invalidTransaction
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Please sign in to view your credits."
        case .invalidResponse:
            return "Couldn't load credits (invalid server response)."
        case .invalidTransaction:
            return "The purchase couldn't be verified..."
        case .server(let statusCode):
            return "Couldn't load credits (server error \(statusCode))."
        }
    }
}
```

**Extension method pattern** (lines 22-46 — `getBalance`):
```swift
extension StressAPIClient {
    func getBalance() async throws -> CreditBalance {
        let request = try await authorizedRequest(path: "credits", method: "GET")
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CreditsAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(CreditBalance.self, from: data)
        case 401:
            throw CreditsAPIError.unauthorized
        default:
            throw CreditsAPIError.server(statusCode: httpResponse.statusCode)
        }
    }
}
```

**Sessions-specific notes:**
- `SessionsAPIError` needs a `.notFound` case (404 from `GET /sessions/{id}/messages` when session is gone).
- Query strings are embedded in `path` (e.g. `"sessions?limit=20&offset=0"`, `"sessions/\(id.uuidString)/messages"`, `"sessions?id=\(id.uuidString)"`). Verified: `authorizedRequest` calls `baseURL.appendingPathComponent(path)` (StressAPIClient.swift:39) — for query-string paths, the path must be manually appended or use `URLComponents` to avoid double-encoding. The Credits extension uses simple relative paths with no query strings; for paths with query params, construct the full URL and pass to `authorizedRequest` that accepts a full URL, OR verify that `appendingPathComponent("sessions?limit=20")` works correctly (it does — the `?` is treated as a literal path component suffix by Foundation when the base URL has no trailing path). **Recommendation:** test URL construction in the test suite.
- `DELETE /sessions?id=` uses query param (not path segment) — verified from backend route: `c.req.query("id")`.
- `listSessions(limit:offset:)` returns `[ChatSession]` from `{sessions: [...]}`.
- `createSession(title:stressContext:)` POSTs body and returns 201 → `ChatSession`.
- `fetchMessages(sessionId:)` GETs and returns `[ChatSessionMessage]` from `{messages: [...]}`. 404 → `.notFound`.
- `deleteSession(id:)` DELETEs with query param, returns `{success: true}`. 400 (missing id) → `.server(400)`.

---

### `Services/API/StressAPIClient+Preferences.swift` (service, request-response)

**Analog:** `Services/API/StressAPIClient+Credits.swift`

**Same template** as Sessions. `PreferencesAPIError` enum with `.unauthorized`, `.invalidResponse`, `.server(statusCode:)`, plus `.noValidFields` (400 — "No valid fields to update").

**Two methods:**
- `getPreferences() async throws -> UserPreferences` — GET, decodes full row.
- `updatePreferences(fields: [String: String]) async throws -> UserPreferences` — PUT with body `fields` (always exactly one key: `"language"` or `"coaching_style"`). 400 on empty payload maps to `.noValidFields`.

---

### `Services/API/StressAPIClient+QuickActions.swift` (service, request-response)

**Analog:** `Services/API/StressAPIClient+Credits.swift`

**Same template**. `QuickActionsAPIError` enum. One method:
- `getQuickActions(stressLevel: Int, language: String, coachingStyle: String) async throws -> [ServerQuickAction]` — GET with query params, decodes `{quick_actions: [...]}`.

---

### `Services/Preferences/PreferencesService.swift` (service, CRUD)

**Analog:** `Services/Credits/CreditService.swift` (full file, 37 lines)

**Service class pattern** (CreditService.swift lines 13-37):
```swift
@MainActor
@Observable
final class CreditService: CreditServiceProtocol {
    private(set) var balance: CreditBalance?
    private let apiClient: StressAPIClient

    init(
        apiClient: StressAPIClient? = nil,
        balance: CreditBalance? = nil
    ) {
        self.apiClient = apiClient ?? StressAPIClient()
        self.balance = balance
    }

    func refreshBalance() async throws {
        balance = try await apiClient.getBalance()
    }

    func apply(_ balance: CreditBalance) {
        self.balance = balance
    }

    func apply(creditsRemaining: Int) {
        guard var updated = balance else { return }
        updated.remaining = creditsRemaining
        balance = updated
    }
}
```

**Protocol pattern** (CreditServiceProtocol.swift lines 8-17):
```swift
@MainActor
protocol CreditServiceProtocol: AnyObject {
    var balance: CreditBalance? { get }
    func refreshBalance() async throws
    func apply(_ balance: CreditBalance)
    func apply(creditsRemaining: Int)
}
```

**PreferencesService-specific notes:**
- `@MainActor @Observable final class` — same shape.
- `private(set) var language: String = "en"`, `private(set) var coachingStyle: String = "supportive"`, `private(set) var hasSeeded = false`.
- `init(apiClient:)` with default `StressAPIClient()`.
- `seedIfNeeded()` — guarded by `hasSeeded`, calls `apiClient.getPreferences()`, maps to local state.
- `update(language:)` / `update(coachingStyle:)` — optimistic set + PUT single field; revert on throw.
- No protocol needed this phase (only consumed by `ChatViewModel` and `SettingsView`, both in the same module; follow CreditService's precedent of having a protocol only when test injection demands it — but CreditService has `CreditServiceProtocol` because `MainTabView`/`SettingsView` consume it). **Recommendation:** create `PreferencesServiceProtocol` if `ChatViewModel` needs test injection without a real API client, or inject `PreferencesService?` with defaults.
- App-root wiring follows CreditService pattern (see Shared Patterns below).

---

### `Services/LLM/StressLLMService.swift` (modify — session creation in send)

**Self-analog:** existing `send()` Task at lines 72-112 and `apply(metadata:)` at lines 116-130.

**Send Task capture-list pattern** (line 72):
```swift
let task = _Concurrency.Task { [stressAPIClient, currentSessionId, stressContext] in
    do {
        let (bytes, httpResponse) = try await stressAPIClient.sendChat(
            messages: messages,
            sessionId: currentSessionId,
            stressContext: stressContext
        )
```

**Session-id persistence pattern** (apply metadata, lines 117-120):
```swift
private func apply(metadata: SSEMetadata) {
    if let sessionId = metadata.sessionId {
        currentSessionId = sessionId
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
    }
```

**Insertion point for titled-session creation:** Before the `sendChat` call inside the Task, add:
```swift
var sessionId = currentSessionId
if sessionId == nil {
    // Create titled session before first chat (Pattern 5 from RESEARCH.md)
    let title = String(messages.last(where: { $0.role == .user })?.content.prefix(50) ?? "New Conversation")
    let created = try? await stressAPIClient.createSession(title: title, stressContext: stressContext)
    sessionId = created?.id
    if let sessionId {
        currentSessionId = sessionId
        UserDefaults.standard.set(sessionId.uuidString, forKey: Self.sessionIdDefaultsKey)
    }
    // Fail-soft: on error, sessionId stays nil → backend auto-creates untitled
}
```
Then pass `sessionId` (the local var) to `sendChat` instead of `currentSessionId`.

---

### `Services/LLM/StressContextPayload.swift` (modify — CR-02 fix + prefs feeding)

**Self-analog:** existing `build()` method at lines 78-113.

**CR-02 bug site** (lines 87-101):
```swift
let recent = recentHistory.suffix(min(5, max(2, recentHistory.count)))
if recent.count >= 2 {
    let levels = recent.map(\.stressLevel)
    let first = levels.first!
    let last = levels.last!
    let diff = last - first
    if abs(diff) < 5 { trend = "stable" } else if diff > 0 { trend = "increasing" } else { trend = "decreasing" }
```

**Fix:** Reverse to chronological before computing delta:
```swift
let recent = recentHistory.suffix(min(5, max(2, recentHistory.count)))
if recent.count >= 2 {
    let chronological = Array(recent.reversed())  // newest-first → chronological
    let levels = chronological.map(\.stressLevel)
    let first = levels.first!   // oldest
    let last = levels.last!     // newest
    let diff = last - first     // newest - oldest
    // ... same threshold logic
```

**Prefs feeding:** The `build()` method already has `language` and `coachingStyle` parameters with defaults (lines 81-82). The call site in `ChatViewModel.streamResponse()` (line 124) passes no args today. Phase 3 injects `PreferencesService` values through the VM's init or a set-on-appear property, then passes them at the call site.

---

### `ViewModels/ChatViewModel.swift` (modify — history restore + chips)

**Self-analog:** existing `send()` at lines 82-95, `clearConversation()` at lines 196-201, `setCreditsConvergenceSink()` at lines 206-209.

**Injection pattern for environment services** (set in `onAppear`, not `init`):
```swift
// ChatBottomSheetView.swift:49-54 — the established seam
.onAppear {
    viewModel.presentPaywall = { paywall.present(reason: $0) }
    viewModel.setCreditsConvergenceSink { [weak creditService] remaining in
        creditService?.apply(creditsRemaining: remaining)
    }
}
```

**History restore method to add:**
```swift
func restoreHistory() async {
    guard messages.isEmpty else { return }  // user may have typed before fetch lands
    guard let sessionId = (llmService as? StressLLMService)?.currentSessionId else { return }
    do {
        let dtos = try await stressAPIClient.fetchMessages(sessionId: sessionId)
        let restored = dtos.filter { $0.role != .system }.map { dto in
            ChatMessage(
                role: dto.role, content: dto.content,
                timestamp: Date(), remoteId: dto.id,
                sessionId: dto.sessionId, isSynced: true,
                tokensUsed: dto.tokensUsed
            )
        }
        guard messages.isEmpty else { return }  // re-check after async gap
        messages = restored
    } catch SessionsAPIError.notFound {
        (llmService as? StressLLMService)?.resetSession()
        // Empty chat — session was deleted server-side
    } catch {
        // Auth-unavailable or network error — silent skip, empty chat
    }
}
```

**Chips state to add:** A `var quickReplyPrompts: [String]` initialized to `defaultQuickReplies` and swappable from server response. The `ChatBottomSheetView` reads this instead of the hardcoded `defaultQuickReplies` computed property.

---

### `Views/Chat/ChatBottomSheetView.swift` (modify — onAppear restore + chips)

**Self-analog:** existing `onAppear` block at lines 45-54 and `defaultQuickReplies` at lines 355-357.

**OnAppear wiring pattern** (lines 45-54):
```swift
.onAppear {
    viewModel.presentPaywall = { paywall.present(reason: $0) }
    viewModel.setCreditsConvergenceSink { [weak creditService] remaining in
        creditService?.apply(creditsRemaining: remaining)
    }
}
```

**Add to onAppear:**
```swift
viewModel.restoreHistory()
viewModel.fetchQuickActions(stressLevel: stressResult?.level ?? 50)
```

**Chips section** (lines 326-357 — the actual rendered block):
```swift
ForEach(defaultQuickReplies, id: \.self) { reply in
    Button {
        inputText = reply
        sendMessage()
    } label: {
        Text(reply)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color(hex: "#0288D1"))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.15), lineWidth: 1)
            )
    }
    .buttonStyle(.plain)
}
```

**Swap approach:** Replace `defaultQuickReplies` computed property with a read of `viewModel.quickReplyPrompts` (or bind a `@State` that initializes to local defaults and gets updated from the fetch). Taps already ride `sendMessage()` → credit-metered `/chat`.

---

### `Views/Settings/SettingsView.swift` (modify — AI Coach section)

**Self-analog:** existing `preferencesSection` at lines 265-304.

**Section structure pattern** (the `SettingsCard` + `navRow`/`hairlineDivider` pattern):
```swift
private var preferencesSection: some View {
    SettingsCard {
        VStack(spacing: 0) {
            navRow(
                icon: AppIconSystem.Setting.stressMonitorPlus.sfSymbol,
                setting: .stressMonitorPlus,
                tint: .premiumGold,
                title: "StressMonitor Plus",
                value: CreditBalanceFormatter.plusRowValue(creditService.balance),
                valueTint: .premiumGold,
                action: { paywall.present(reason: .general) }
            )
            hairlineDivider
            navRow(
                icon: AppIconSystem.Setting.appearance.sfSymbol,
                setting: .appearance,
                tint: Color.Wellness.adaptiveSecondaryText,
                title: "Appearance",
                value: appearanceLabel,
                destination: .appearance
            )
            hairlineDivider
            toggleRow(
                icon: AppIconSystem.Setting.haptics.sfSymbol,
                setting: .haptics,
                tint: .orange,
                title: "Haptics",
                isOn: $hapticsEnabled
            )
            hairlineDivider
            navRow(
                icon: "rectangle.3.group.fill",
                tint: .settingsIconPurple,
                title: "Home screen widgets",
                value: "3 sizes",
                destination: .about
            )
        }
    }
}
```

**`sectionLabel` helper** (lines 91-98):
```swift
private func sectionLabel(_ title: String) -> some View {
    Text(title.uppercased())
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .tracking(0.8)
        .foregroundStyle(Color.Wellness.adaptiveSecondaryText.opacity(0.7))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, -8)
        .accessibilityAddTraits(.isHeader)
}
```

**`hairlineDivider`** (lines 460-463):
```swift
private var hairlineDivider: some View {
    Rectangle()
        .fill(Color.Wellness.adaptiveSecondaryText.opacity(0.14))
        .frame(height: 0.5)
}
```

**AI Coach section to add:** Insert `sectionLabel("AI Coach")` + `SettingsCard` block with:
- Language picker row (navRow or inline Picker — use a `Picker` inside the card matching the coaching-style UX)
- Coaching style picker (3 fixed cases: supportive/direct/educational)
- Rows separated by `hairlineDivider`
- Environment-read `PreferencesService` for current values and update calls

**Body section list** (lines 33-45) — insert `sectionLabel("AI Coach")` + the new section between `preferencesSection` and `dataSupportSection`:
```swift
VStack(spacing: 22) {
    meHeroSection
    companionBannerSection
    sectionLabel("Companion")
    companionGroupSection
    sectionLabel("Sync & devices")
    syncDevicesSection
    sectionLabel("Habits & tracking")
    habitsSection
    sectionLabel("Notifications")
    notificationsSection
    sectionLabel("Preferences")
    preferencesSection
    // ← INSERT: sectionLabel("AI Coach") + aiCoachSection here
    sectionLabel("Data & support")
    dataSupportSection
    versionFooter
}
```

---

### `Services/DataManagement/DataDeleterService.swift` (modify — server session wipe)

**Self-analog:** existing injection seam at lines 44-57 and `performFactoryReset` at lines 408-445.

**Injection seam pattern** (lines 44-57):
```swift
/// Injects a ``CloudKitResetServiceProtocol`` directly — the seam tests use to substitute
/// a failing/cancellable fake instead of a real CKContainer.
init(
    modelContext: ModelContext,
    cloudKitResetService: CloudKitResetServiceProtocol,
    repository: StressRepositoryProtocol,
    logger: DataManagementLogger
) { ... }
```

**performFactoryReset phase structure** (lines 408-445):
```swift
// Phase 1: Reset CloudKit (0% - 50%)
currentOperation = "Resetting CloudKit data"
deleteProgress = 0.05
try await cloudKitResetService.performDatabaseReset(confirmation: nil)

// Phase 2: Reset local storage (50% - 90%)
currentOperation = "Clearing local data"
deleteProgress = 0.55
try await localWipeService.deleteAllMeasurements()
try modelContext.delete(model: CharacterUnlock.self)
try modelContext.save()

// Phase 3: Reset baseline (90% - 100%)
currentOperation = "Resetting baseline"
deleteProgress = 0.9
try await repository.updateBaseline(PersonalBaseline())

Self.clearCredentialsAndSharedCaches()
```

**Server wipe insertion:** Add a new Phase 0 (before CloudKit, ~0.0-0.05) that runs while still authenticated:
1. Inject a `ServerSessionWiping` protocol (narrow, 2 methods: `listSessions` + `deleteSession`)
2. Loop: `listSessions(limit: 20, offset)` → `deleteSession(id:)` per row → advance offset until empty or safety cap
3. Clear `stressChatSessionId` from UserDefaults
4. Auth-unavailable → log + skip; server error → fail loudly (matches CloudKit precedent)

**Protocol seam to add:**
```swift
protocol ServerSessionWiping: Sendable {
    func listSessions(limit: Int, offset: Int) async throws -> [ChatSession]
    func deleteSession(id: UUID) async throws
}
```

---

### `StressMonitorApp.swift` (modify — PreferencesService environment injection)

**Self-analog:** existing CreditService wiring at lines 27-28, 180-181, 200.

**CreditService wiring pattern** (lines 180-181, 200):
```swift
// init()
let creditService = CreditService()
_creditService = State(initialValue: creditService)

// body
.environment(creditService)
```

**Add for PreferencesService:** Same pattern — `@State private var preferencesService: PreferencesService` initialized in `init()`, then `.environment(preferencesService)` on the `OnboardingContainerView()`.

---

### `Tests/StressAPIClientSessionsTests.swift` (test, request-response)

**Analog:** `Tests/StressAPIClientCreditsTests.swift` (full file, 150 lines)

**Test struct + makeClient pattern** (lines 14-28):
```swift
@MainActor
struct StressAPIClientCreditsTests {
    private static let balanceFixture = """
        {"total":50,"used":7,"remaining":43,"plan_type":"free","free_reset_at":"2026-09-01T00:00:00Z"}
        """

    private func makeClient(statusCode: Int, body: Data?) -> StressAPIClient {
        RequestCaptureURLProtocol.lastRequest = nil
        RequestCaptureURLProtocol.statusCode = statusCode
        RequestCaptureURLProtocol.responseBody = body
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [RequestCaptureURLProtocol.self]
        return StressAPIClient(
            authService: MockAuthService(token: "fake-token"),
            baseURL: URL(string: "https://api.test")!,
            session: URLSession(configuration: config)
        )
    }
```

**Test assertion pattern** (lines 31-46):
```swift
@Test("getBalance decodes the credit contract from GET credits with a Bearer header")
func getBalanceDecodesContractWithBearerHeader() async throws {
    let client = makeClient(statusCode: 200, body: Data(Self.balanceFixture.utf8))
    let balance = try await client.getBalance()
    #expect(balance.total == 50)
    #expect(balance.used == 7)
    // ...field assertions...
    let request = try #require(RequestCaptureURLProtocol.lastRequest)
    #expect(request.httpMethod == "GET")
    #expect(request.url?.absoluteString == "https://api.test/credits")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer fake-token")
}
```

**Error mapping pattern** (lines 47-53):
```swift
@Test("getBalance maps 401 to the unauthorized error case")
func getBalanceMaps401ToUnauthorized() async throws {
    let client = makeClient(statusCode: 401, body: Data("{}".utf8))
    await #expect(throws: CreditsAPIError.unauthorized) {
        try await client.getBalance()
    }
}
```

**Sessions-specific fixtures:** Must include **fractional-second timestamps** (Pitfall 1):
```json
{"messages":[{"id":"uuid-1","session_id":"uuid-sess","role":"user","content":"Hello","tokens_used":15,"created_at":"2026-08-23T07:39:53.953Z"}]}
```

**Test cases needed:** fetchMessages decodes contract + Bearer; 404 maps to `.notFound`; listSessions decodes pagination; createSession posts title + decodes 201; deleteSession sends query param.

---

### `Tests/StressAPIClientPreferencesTests.swift` (test, request-response)

**Analog:** `Tests/StressAPIClientCreditsTests.swift`

**Same makeClient + assertion pattern.** Test cases: getPreferences decodes language/coaching_style (extra keys ignored); updatePreferences PUTs single field; 400 maps to `.noValidFields`; 401 maps to `.unauthorized`.

---

### `Tests/StressAPIClientQuickActionsTests.swift` (test, request-response)

**Analog:** `Tests/StressAPIClientCreditsTests.swift`

**Same makeClient + assertion pattern.** Test cases: getQuickActions builds query string (stress_level, language, coaching_style) and decodes `{quick_actions: [{id, title, type}]}`; asserts request URL query params; 401 mapping.

---

### `Tests/PreferencesServiceTests.swift` (test, CRUD)

**Analog:** `Tests/ChatLifecycleTests.swift` (structure: `@MainActor struct` + `@Test` functions + injected fakes)

**Test structure pattern** (ChatLifecycleTests lines 12-16):
```swift
@MainActor
struct ChatLifecycleTests {
    private func waitFor(_ predicate: @MainActor () -> Bool, timeoutMS: Int = 2000) async throws { ... }

    @Test("cancelResponse preserves partial text, clears state, and ends streaming")
    func cancelResponsePreservesPartialText() async throws { ... }
}
```

**PreferencesService test approach:** Inject `StressAPIClient` with `RequestCaptureURLProtocol` (like `StressAPIClientCreditsTests`). Test: seed-once GET; optimistic set + PUT per field; revert on PUT failure; builder receives current values.

---

### `Tests/ChatHistoryRestoreTests.swift` (test, request-response)

**Analog:** `Tests/ChatLifecycleTests.swift` (FakeLLMService + waitFor pattern)

**FakeLLMService pattern** (ChatLifecycleTests lines 177-217):
```swift
@MainActor
final class FakeLLMService: LLMServiceProtocol {
    let tokens: [String]
    let shouldThrow: Bool
    private(set) var receivedStressContexts: [StressContextPayload?] = []

    init(tokens: [String], shouldThrow: Bool = false, streamError: LLMServiceError? = nil) { ... }

    func isAvailable() -> Bool { true }

    func send(messages: [ChatMessage], systemPrompt: String,
              stressContext: StressContextPayload?) async throws -> AsyncThrowingStream<String, Error> {
        receivedStressContexts.append(stressContext)
        // ... yields tokens, blocks or throws ...
    }
}
```

**waitFor helper** (ChatLifecycleTests lines 16-23):
```swift
private func waitFor(_ predicate: @MainActor () -> Bool, timeoutMS: Int = 2000) async throws {
    let ticks = timeoutMS / 10
    for _ in 0..<ticks {
        if predicate() { return }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("waitFor timed out waiting for condition")
}
```

**Test cases needed:** restore populates messages only when empty; 404 clears session id; send-then-restore does not clobber; chips state starts at local set and swaps from server; chip tap sends via `/chat` (record prompt on FakeLLMService).

---

### `Tests/DataDeleterServerWipeTests.swift` (test, batch)

**Analog:** `Tests/DataDeletionConsolidationTests.swift` (structure: `@Suite` + `@Test` + `@MainActor`)

**Test structure pattern** (DataDeletionConsolidationTests lines 9-10):
```swift
@Suite("Delete All Credential Clearance")
@MainActor
struct DeleteAllCredentialClearanceTests {
    @Test("clearCredentialsAndSharedCaches removes Supabase JWT from Keychain")
    func clearsSupabaseJWTFromKeychain() throws { ... }
}
```

**Server wipe test approach:** Create a fake `ServerSessionWiping` that records calls and returns controllable session lists. Test: wipe loop calls list→delete→list until empty; clears `stressChatSessionId` on completion; skips on auth error.

---

### `Tests/StressContextPayloadTests.swift` (modify — CR-02 regression)

**Self-analog:** existing XCTest suite (39 lines)

**Existing test pattern** (lines 11-17):
```swift
final class StressContextPayloadTests: XCTestCase {
    func testBuildDoesNotIncludeRawHealthReadings() {
        let result = StressResult(level: 65, category: .moderate, confidence: 0.9, hrv: 42.5, heartRate: 78)
        let baseline = PersonalBaseline(restingHeartRate: 60, baselineHRV: 50)
        let payload = StressContextPayload.build(stressResult: result, baseline: baseline)
        XCTAssertNil(payload.hrv, "Raw HRV must never leave the device.")
        // ...
    }
}
```

**CR-02 regression tests to add:**
- Newest-first input where stress rose → `stressTrend == "increasing"`
- Newest-first input where stress fell → `stressTrend == "decreasing"`
- Fluctuation within ±5 → `stressTrend == "stable"`
- Single measurement → `stressTrend == nil`

---

## Shared Patterns

### Authenticated HTTP Requests
**Source:** `Services/API/StressAPIClient.swift` lines 36-51
**Apply to:** All three new API extension files
```swift
func authorizedRequest(
    path: String,
    method: String,
    body: Data? = nil,
    accept: String? = nil
) async throws -> URLRequest {
    let token = try await authService.getIDToken()
    var request = URLRequest(url: baseURL.appendingPathComponent(path))
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let accept { request.setValue(accept, forHTTPHeaderField: "Accept") }
    request.timeoutInterval = 90
    if let body { request.httpBody = body }
    return request
}
```

### Per-Endpoint Error Enums
**Source:** `Services/API/StressAPIClient+Credits.swift` lines 3-18
**Apply to:** `SessionsAPIError`, `PreferencesAPIError`, `QuickActionsAPIError`
```swift
enum CreditsAPIError: Error, LocalizedError, Equatable, Sendable {
    case unauthorized
    case invalidResponse
    case invalidTransaction
    case server(statusCode: Int)
    var errorDescription: String? { /* switch */ }
}
```

### Status Code Switch
**Source:** `Services/API/StressAPIClient+Credits.swift` lines 30-40
**Apply to:** Every new endpoint method in all three API extensions
```swift
switch httpResponse.statusCode {
case 200...299: return try JSONDecoder().decode(...)
case 401: throw ...APIError.unauthorized
default: throw ...APIError.server(statusCode: httpResponse.statusCode)
}
```

### App-Scope Observable Service + Environment Injection
**Source:** `Services/Credits/CreditService.swift` + `StressMonitorApp.swift` lines 180-181, 200
**Apply to:** `PreferencesService`
```swift
// StressMonitorApp.swift init()
let creditService = CreditService()
_creditService = State(initialValue: creditService)

// StressMonitorApp.swift body
.environment(creditService)
```

### URLProtocol Test Infrastructure
**Source:** `Tests/StressAPIClientTests.swift` lines 60-82 (RequestCaptureURLProtocol) + 55-58 (MockAuthService)
**Apply to:** All three new `StressAPIClient*Tests.swift` files + `PreferencesServiceTests.swift`
```swift
// RequestCaptureURLProtocol — static stub configuration per test
final class RequestCaptureURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var statusCode: Int = 200
    nonisolated(unsafe) static var responseBody: Data?
    // ... canInit/canonicalRequest/startLoading/stopLoading ...
}

// MockAuthService — returns a fixed token string
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    let token: String
    func getIDToken() async throws -> String { token }
}
```

### Swift Testing Suite Structure
**Source:** `Tests/ChatLifecycleTests.swift` lines 12-16, `Tests/StressAPIClientCreditsTests.swift` line 14
**Apply to:** All new test files
```swift
@MainActor
struct StressAPIClientSessionsTests {  // or @Suite("...")
    private func makeClient(...) -> StressAPIClient { ... }
    @Test("...") func testMethod() async throws { ... }
}
```

### Settings Section UI
**Source:** `Views/Settings/SettingsView.swift` lines 91-98 (sectionLabel), 460-463 (hairlineDivider), 265-304 (full section)
**Apply to:** New AI Coach section
```swift
sectionLabel("AI Coach")
SettingsCard {
    VStack(spacing: 0) {
        // row 1
        hairlineDivider
        // row 2
    }
}
```

### Dependency Injection via Protocol Seam
**Source:** `Services/DataManagement/DataDeleterService.swift` lines 44-57
**Apply to:** DataDeleterService's new `ServerSessionWiping` injection
```swift
/// Injects a ``CloudKitResetServiceProtocol`` directly — the seam tests use to substitute
/// a failing/cancellable fake instead of a real CKContainer.
init(
    modelContext: ModelContext,
    cloudKitResetService: CloudKitResetServiceProtocol,
    repository: StressRepositoryProtocol,
    logger: DataManagementLogger
) { ... }
```

### pbxproj Test File Registration
**Source:** Existing 28 registered files (Pitfall 9 from RESEARCH.md)
**Apply to:** All 6 new test files
Each new file needs 4 entries in `project.pbxproj`:
1. `PBXBuildFile` entry (with `fileRef`)
2. `PBXFileReference` entry (lastKnownFileType = `sourcecode.swift`, path, name)
3. `PBXGroup` children membership (in the StressMonitorTests group)
4. `PBXSourcesBuildPhase` file list entry

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `Models/ChatSession.swift` | model | request-response | New DTO — follows CreditBalance pattern exactly (listed above), no separate pre-existing session model exists |
| `Models/ChatSessionMessage.swift` | model | request-response | New DTO — maps backend message row to display model; no prior server-message DTO exists |
| `Models/UserPreferences.swift` | model | request-response | New DTO — no prior preferences model exists; follow CreditBalance pattern |
| `Models/ServerQuickAction.swift` | model | request-response | New DTO — no prior server-quick-action model exists; follow CreditBalance pattern |

**Note:** All four DTOs have an exact structural analog in `CreditBalance.swift` — they are classified as "no analog found" only in the sense that no prior session/preference/quick-action model exists to copy field names from. The `CreditBalance` pattern (Codable struct with CodingKeys, Sendable, String dates) is the template.

## Metadata

**Analog search scope:** `StressMonitor/StressMonitor/Models/`, `Services/`, `ViewModels/`, `Views/Settings/`, `Views/Chat/`, `StressMonitor/StressMonitorTests/`
**Files scanned:** 18 source files + 8 test files
**Pattern extraction date:** 2026-08-23
