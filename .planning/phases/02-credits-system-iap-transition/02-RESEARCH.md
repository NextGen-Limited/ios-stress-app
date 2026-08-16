# Phase 2: Credits System + IAP Transition - Research

**Researched:** 2026-08-16
**Domain:** StoreKit 2 consumable IAP + credits-gated chat (iOS 18.6+/SwiftUI) against Deno/Hono backend
**Confidence:** HIGH (in-repo contract verified by reading both repos this session; external StoreKit 2 claims cited)

> Dispatch note: this RESEARCH.md was produced under the **generic-agent workaround** (no typed gsd-phase-researcher dispatch available in this harness). The gsd-phase-researcher role file (`~/.codex/agents/gsd-phase-researcher.md`) was read and adopted: provenance tagging ([VERIFIED]/[CITED]/[ASSUMED]), in-repo value provenance with verbatim quotes + line ranges, section contract below.

<user_constraints>
## User Constraints

No `02-CONTEXT.md` exists (user chose to plan from research + requirements only). The dispatch supplies locked constraints in its place — copied verbatim from the dispatch:

### Locked Decisions (from dispatch "Known constraints — treat as locked")

- "iOS 17+/SwiftUI/@Observable MVVM, protocol-based DI, zero third-party deps except firebase-ios-sdk (SPM)"
- "All xcodebuild test runs MUST use `-parallel-testing-enabled NO` on this host (parallel clones fail)"
- "TDD mode is ON — planner will apply type:tdd tasks"
- "Commit author must be 'Phuong Doan'"

### The agent's Discretion (open product questions flagged for the planner)

From the dispatch (verbatim): "credit pack SKUs/pricing, what happens to existing subscribers (grandfathering?), paywall entry points, balance display placement, StoreKit 2 consumables vs current subscription flow, receipt/transaction verification for consumable credit grants (server-side redemption endpoint if backend has one — check `src/routes/` for an IAP/webhook/verify route)."

**Research answer to the last one: the backend has NO redemption/verify route** — see "Critical Backend Gap" under Summary and Open Questions Q1. This is the single biggest planning decision in the phase.

### Deferred Ideas (OUT OF SCOPE)

- Phase 3 scope per ROADMAP.md: `/sessions` server-side chat history, `/preferences` sync, `/quick-actions`, Supabase remnant removal, final integration testing. Do not pull these in even though they touch the same files.
- v1.0 carried items not gated by this phase: BUILD-01/02/03 (ASC/Info.plist consolidation), SHIP-01/02/03, A11Y-01..05, WIRE-01 (widget), DATA-01/04 (CloudKit delete), TEST-01 (CI runner).
</user_constraints>

<phase_requirements>
## Phase Requirements

ROADMAP.md maps no requirement IDs to Phase 2 (null). Per dispatch, coverage is derived from `.planning/PROJECT.md`'s Active requirements (IAP/AUTH items). PROJECT.md is the requirements authority this milestone — `.planning/REQUIREMENTS.md` does not exist (verified: directory listing of `.planning/` shows no such file).

| ID (derived) | Description (from PROJECT.md Active) | Research Support |
|----|-------------|------------------|
| IAP-01 | StoreKit product IDs resolve in Release configuration | `StoreKitProductCatalog` 3-tier resolution seam + `.storekit` config; consumable pack IDs follow the same mechanism |
| IAP-02 | `Transaction.updates` listener owned at app scope | Already shipped (`StoreKitService.listenForTransactions`, app-scope env key); must survive the subscription→consumable transition |
| IAP-03 | Stale-premium correction path reachable | `refreshEntitlements()` on foreground (StressMonitorApp scenePhase); semantics change when consumables enter the picture |
| IAP-04 | Character-unlock entitlement bypass (confirmed intentional per D-05) | PaywallController premium guard continues to gate characters; grandfathering decision affects it |
| IAP-05 | Pricing display accuracy (savings %, trial gating) | Paywall copy must change for packs; `savingsDisplay`/trial-banner code paths become dead or repurposed |
| IAP-06 | Purchase/restore/cancel/expiry verified against a `.storekit` file | `StressMonitorProducts.storekit` exists + is wired into scheme; needs consumable entries; `StoreKitServiceTests` suite is disabled (see Validation Architecture) |
| AUTH-02 (residual) | "keep open until Phase 2 credit-state surface lands" — stale-session masking | Credit balance fetch at launch doubles as a live auth-session probe (401 → re-auth surface) |
| BUILD-05 | `StoreKitServiceEnvironment.swift:12` Release compile blocker | **Appears already fixed at HEAD** — see Runtime State Inventory; Phase 2 should verify with an actual Release build since it touches these exact files |
</phase_requirements>

## Summary

Phase 2 wires the app to the backend's credit economy: a `GET /credits` balance API (already live, Bearer-authenticated), a 402 `INSUFFICIENT_CREDITS` paywall trigger on chat (already mapped to `LLMServiceError.insufficientCredits` in Phase 1 but currently rendered only as an error string), and a StoreKit transition from 3 auto-renewable subscriptions to consumable credit packs. The backend contract is fully implemented and verified this session: users are provisioned with **50 free credits** on first authenticated request, monthly reset via cron, 1 credit per chat message, and a terminal SSE `metadata` event carrying `credits_remaining` after every successful chat.

**Critical Backend Gap:** the backend can *deduct* and *report* credits but cannot *grant purchased* credits. `src/app.ts` mounts exactly six route groups (`/health`, docs, `/preferences`, `/credits`, `/sessions`, `/quick-actions`, `/chat`) — there is no IAP-verification/redemption endpoint and no App Store Server webhook. Yet the ledger anticipates purchases: `credit_type` enum includes `'purchase'` [VERIFIED: stress-app-be/migrations/20260812000001_enums_and_helpers.sql:2 — `CREATE TYPE credit_type AS ENUM ('chat', 'gift', 'purchase', 'reset');`]. This is a hard cross-repo dependency: either Phase 2 includes backend work (a `POST /credits/redeem`-style endpoint that verifies a StoreKit 2 JWS transaction and inserts a `'purchase'` ledger row), or iOS purchases credits with **no server-side destination**, which would be a fake implementation. The planner must resolve this before slicing tasks.

**Primary recommendation:** Plan iOS-first in three layers — (1) `CreditService` + `CreditBalance` model against `GET /credits` with TDD via a `MockAuthService`-style protocol seam (Phase 1's proven pattern), (2) 402 → paywall presentation + balance display wired through `ChatViewModel`/`PaywallController`/`SettingsView`, (3) StoreKit consumable packs in `StoreKitService` with a **deferred-grant design**: verify transaction, POST the signed transaction to the backend redemption endpoint (new, cross-repo), only `finish()` after the server acks — and treat "backend endpoint not built yet" as an explicit blocker/checkpoint rather than shipping client-only credit grants.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Credit balance (source of truth) | Backend (Postgres `user_credits`) | iOS cache (display only) | Backend deducts atomically per chat; client balance is always advisory and must converge via `credits_remaining` metadata + `GET /credits` |
| 402 detection | Backend (chat route pre-check) | iOS `StressLLMService.mapHTTPError` | Backend already returns 402 pre-stream; iOS maps it (StressLLMService.swift:131) — paywall *presentation* is iOS-only |
| Paywall presentation decision | iOS (PaywallController) | — | `present(reason:)` guard + fullScreenCover at root are established app-side patterns |
| Purchase flow (StoreKit) | iOS (StoreKitService) | — | StoreKit 2 client API; only iOS can run `Product.purchase` |
| Credit *grant* on purchase | Backend (new endpoint) | iOS (sends JWS) | Server-authoritative ledger; client must never write its own balance |
| Transaction verification | iOS `VerificationResult` + backend JWS verify | — | On-device verification gates the UI; server verification gates the money |
| Entitlement state (premium/characters) | iOS (PremiumState) | Backend (`plan_type='premium'`) | Two notions of "premium" now exist — see Pitfall 1 |
| Free-tier reset scheduling | Backend (Deno cron) | — | Monthly reset is server-side; iOS only displays `free_reset_at` |

## Standard Stack

No new packages. This phase is system-framework-only by locked constraint ("zero third-party deps except firebase-ios-sdk").

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| StoreKit 2 | iOS 18.6 SDK (Xcode 26.3) | Consumable pack purchases, `Transaction.updates`, `AppStore.sync()` | Apple-native; already imported in `StoreKitService.swift:2` |
| SwiftUI / Observation | iOS 18.6 SDK | Paywall UX, balance display, `@Observable` VMs | Project convention (@Observable MVVM) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Firebase Auth (via firebase-ios-sdk 11.x, already linked) | resolved in Package.resolved | Bearer token for `GET /credits` + redemption calls | Every authenticated request — reuse `StressAPIClient.authorizedRequest` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom paywall (current `IAPPremiumView`) | StoreKit `SubscriptionStoreView`/`ProductView` | Apple's StoreKit views handle consumables (`ProductView` works for any product type [CITED: createwithswift.com consumables tutorial]) but the project has a heavily customized paywall design system (Typography, iap* colors, PlanCard) — keep custom UI, keep StoreKit 2 purchase calls |
| Server-side JWS verification | Client-trusted grants (`finish()` immediately, backend trusts client POST of amount) | Client-trusted = a jailbroken client can mint free credits; JWS verification needs App Store root certs or an App Store Server API call on the backend. Minimum viable: verify JWS signature chain server-side; gold: also cross-check via `App Store Server API` `Get Transaction Info` [CITED: developer.apple.com/videos/play/wwdc2024/10062] |

**Installation:** none (`swift package resolve` unchanged; firebase-ios-sdk + GoogleSignIn already in pbxproj from Phase 1).

**Version verification:** no packages added; nothing to verify on a registry.

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages (verified: no new SPM references required; constraint locks deps to system frameworks + already-integrated firebase-ios-sdk/GoogleSignIn).

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 [Chat entry: SettingsView chat row / ActionView card]
        │  user sends message
        ▼
 ChatViewModel.send ──► StressLLMService.send ──► StressAPIClient.sendChat (Bearer ID token)
        │                                            │
        │                                     POST /chat (backend)
        │                                            │
        │                     ┌──────────────────────┴───────────────────────┐
        │                     ▼                                                ▼
        │          remaining <= 0 && plan_type != 'premium'          streams content chunks
        │                     │                                       then deductCredit(uid, 1)
        │                HTTP 402                                            │
        │          {error:"No credits remaining",                          ▼
        │           code:"INSUFFICIENT_CREDITS"}              SSE terminal metadata event:
        │                     │                                 {type:"metadata", session_id,
        │                     ▼                                  credits_remaining, model_used,
        │       StressLLMService.mapHTTPError(402)                 quick_actions} + [DONE]
        │              → .insufficientCredits                              │
        │                     │                                            ▼
        │                     ▼                            StressLLMService.apply(metadata:)
        │       ChatViewModel catches                              creditsRemaining updated
        │       LLMServiceError ────────► NEW: paywall trigger          │
        │                     │ (instead of error string only)          ▼
        │                     ▼                              balance UI update
        │       PaywallController.present(reason: .outOfCredits)
        │                     │
        ▼                     ▼
 [Paywall: credit pack cards + balance display + free reset date]
        │  user taps pack
        ▼
 StoreKitService.purchase(pack) ──► Product.purchase ──► .success(verification)
        │                                                       │
        │                                              checkVerified (on-device JWS)
        │                                                       │
        │                                     POST signed transaction → BACKEND /credits/redeem (NEW — does not exist yet)
        │                                                       │
        │                                        backend verifies JWS → inserts 'purchase' ledger row
        │                                        → increments total_credits → returns new balance
        │                                                       │
        └────────────────────────── after server ack: transaction.finish()
                                                                │
                              GET /credits (on paywall open, after purchase, app foreground)
                                  → {total, used, remaining, plan_type, free_reset_at}
```

### Recommended Project Structure

```
StressMonitor/StressMonitor/
├── Models/
│   └── CreditBalance.swift                 # Codable mirror of GET /credits response
├── Services/
│   ├── API/
│   │   └── StressAPIClient+Credits.swift   # extension: getBalance(), redeemPurchase(jws:)
│   ├── Credits/
│   │   ├── CreditService.swift             # @MainActor @Observable, owns balance state
│   │   └── CreditServiceProtocol.swift     # seam for MockCreditService (Phase 1 pattern)
│   └── StoreKit/
│       ├── StoreKitProductCatalog.swift    # + consumable pack IDs (3-tier resolution)
│       ├── CreditPack.swift                # pack model (id, credits, productID)
│       └── StoreKitService.swift           # + purchase(pack:), deferred-grant flow
├── ViewModels/
│   └── CreditsViewModel.swift              # balance + purchase state machine (AccountViewModel pattern)
└── Views/
    └── Premium/                             # reworked paywall: pack cards + balance header
StressMonitor/StressMonitorTests/
├── CreditServiceTests.swift                # NEW (add via 4-line pbxproj pattern — see Pitfall 7)
├── StressAPIClientCreditsTests.swift       # NEW
└── CreditsViewModelTests.swift             # NEW
stress-app-be/src/routes/                    # (if cross-repo scope approved)
└── credits.ts                               # + POST redeem endpoint + JWS verification
```

### Pattern 1: Service-wraps-protocol with @Observable ViewModel (Phase 1's AccountViewModel pattern)
**What:** `@MainActor @Observable` ViewModel, constructor-injected service protocol, VM owns UI state (`isX`, `errorMessage`), rethrows errors so views decide presentation, silent classification of user-cancellation.
**When to use:** `CreditService`/`CreditsViewModel` exactly. [VERIFIED: 01-04-SUMMARY.md — "AccountViewModel rethrows sign-in errors (view decides alert presentation) while owning errorMessage state"]
**Example:** see `.planning/phases/01-firebase-auth-api-client-chat-migration/01-04-SUMMARY.md` patterns-established block; `AccountViewModel.swift` + `AccountViewModelTests.swift` (4 Swift Testing cases with `MockAuthService`) are the templates.

### Pattern 2: Deferred-grant consumable purchase (verify → server redeem → finish)
**What:** On `.success(verification)` with `.verified(transaction)`, do NOT `finish()` immediately. Send the signed transaction (`verification.jwsRepresentation` — the JWS string — or `transaction.jsonRepresentation`) to the backend redemption endpoint; call `transaction.finish()` only after the server acknowledges. If the app dies mid-flow, the unfinished transaction reappears in `Transaction.updates` at next launch and the flow retries.
**When to use:** every consumable credit-pack purchase.
**Why:** consumables disappear from `Transaction.currentEntitlements` once finished [ASSUMED — standard StoreKit 2 semantics, consistent with Apple's "currentEntitlements = products the user is entitled to" doc framing at developer.apple.com/documentation/storekit/transaction/currententitlements and with the createwithswift tutorial's finish-to-prevent-redelivery loop]; server-side dedup on `transaction.id` makes retries idempotent. This is the standard pattern for consumables + server balance [CITED: stackoverflow.com/questions/79402090 — "The product is consumable. After the purchase is successful, I need to call API and backend will…" pattern; CITED: developer.apple.com/videos/play/wwdc2024/10062].
**Example:**
```swift
// Source: synthesized from createwithswift.com consumables tutorial (finish after granting)
// + WWDC24 "Explore App Store server APIs for In-App Purchase" (server ack before finish)
case .success(let verification):
    let transaction = try checkVerified(verification)
    guard let pack = catalog.pack(for: transaction.productID) else { break }
    // 1. Server-authoritative grant (idempotent on transaction.id)
    let balance = try await apiClient.redeemPurchase(jws: verification.jwsRepresentation)
    // 2. Only now consume the transaction — retry-safe via Transaction.updates
    await transaction.finish()
    creditService.apply(balance)
```
Note: `jwsRepresentation` on `VerificationResult` is the verified-JSON variant (`VerificationResult<jws>`); the exact spelling must be confirmed against the iOS 18.6 SDK headers during implementation — treat the property name as [ASSUMED] until compile-verified, mirroring Phase 1's "Firebase 11.x API differs from plan pseudocode" lesson.

### Pattern 3: Balance convergence from three sources
**What:** Client balance is display-only and converges from (a) `GET /credits` on foreground/paywall-open, (b) `credits_remaining` in every chat terminal metadata event, (c) redemption response. Never decrement locally on send — the backend is authoritative (it deducts only after streaming completes, and premium users report `999999`).
**When to use:** `CreditService.apply(...)` call sites.

### Anti-Patterns to Avoid
- **Client-side balance arithmetic:** decrementing `remaining` optimistically on send breaks for premium (`remaining: 999999`) and for concurrent chats (backend `deductCredit` uses `for update` row locks precisely because concurrent sends race) [VERIFIED: stress-app-be/src/lib/credits.ts:26-33 — `select ... for update`, then `if (available < amount) return { success: false, remaining: available }`].
- **`finish()` before server ack:** loses the transaction forever (consumables are not restorable — Apple: "You can't restore consumable purchases" [CITED: support.apple.com/en-us/108096]).
- **Duplicating `insufficientCredits` UI in the chat sheet AND paywall:** keep the chat error message short, route to `PaywallController`.
- **Gating chat locally on cached balance:** a stale local balance would block sends the server would allow (e.g. after monthly reset). Let the server's 402 be the only gate.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| On-device receipt validation crypto | Manual cert-chain checking of App Store root CA | StoreKit 2 `VerificationResult` (already in `StoreKitService.checkVerified`) | Apple-signed JWS verification is built in; the app already throws on `.unverified` |
| Server-side purchase verification | Parsing the JWS by hand on the backend | App Store Server Library (Apple, open source) or `jsonwebtoken` + Apple root certs | X.509 chain, OCSP, cert rotation edge cases [CITED: developer.apple.com/videos/play/wwdc2024/10062 — Apple ships a server library for exactly this] |
| Balance persistence | SwiftData/local DB of credits | Server + in-memory `@Observable` cache | Two sources of truth diverge instantly; balance is already server-side |
| Paywall presentation plumbing | New sheet/sheet-fullScreen plumbing per entry point | `PaywallController.present(reason:)` (exists, root-mounted) | Established pattern; add a `.outOfCredits` reason case |
| HTTP auth/JSON for /credits | New request builder | `StressAPIClient.authorizedRequest(path:method:...)` | Already injects Bearer token, Content-Type, 90s timeout |

**Key insight:** everything money-adjacent already has a mechanism in this codebase or in StoreKit 2 — the only genuinely new server-side surface is the redemption endpoint, and Apple publishes a server library for its verification half.

## Runtime State Inventory

> This IS a migration phase (subscription → consumable transition + paywall semantics change). All five categories answered.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data (client) | `UserDefaults` key `"isPremiumUser"` (PremiumState.swift:23 — `init(defaults: UserDefaults = .standard, key: String = "isPremiumUser")`); `UserDefaults` key `"stressChatSessionId"` (StressLLMService.swift:26); StoreKit product-ID keys `storeKitPremiumWeeklyProductID`/`Monthly`/`Annual`/`SubscriptionGroupID` (StoreKitProductCatalog.swift:47-68 resolution keys) | Grandfathering decision decides whether `isPremiumUser` stays authoritative for characters; pack IDs are *additive* keys — no migration needed. `stressChatSessionId` untouched |
| Stored data (server) | `user_credits` rows (`total_credits/used_credits/plan_type/free_reset_at`), `credit_transactions` ledger. Existing subscribers have NO server-side record of their App Store subscription — backend only knows `plan_type ∈ {'free','premium'}` with no mechanism ever setting 'premium' | **Data migration decision:** how does an active App Store subscription map to server `plan_type='premium'` (or to granted credits)? Nothing server-side can answer this today — see Open Questions Q2 |
| Live service config | App Store Connect: zero IAP products exist there (v1.0 audit: "Currently zero product IDs resolve in any build configuration" — PROJECT.md Business Context). Local `.storekit` file has 3 subscriptions, zero consumables (`"products" : []` — StressMonitorProducts.storekit). Scheme Test+Launch actions already reference the file [VERIFIED: StressMonitor.xcscheme:45-47, 75-77] | Add consumable products to `.storekit` (local testing) AND file ASC products (lead-time item — same-day filing per PROJECT.md constraint). If subscriptions are being retired, ASC product retirement is a manual ASC action |
| OS-registered state | StoreKit transaction queue: active subscribers (sandbox/production) have live auto-renewable transactions that `Transaction.currentEntitlements` will keep returning even after code changes | `refreshEntitlements()` must keep honoring them (grandfather) or deliberately stop; `Transaction.updates` listener must stay app-scoped (IAP-02) |
| Secrets/env vars | None new. `STRESS_API_BASE_URL` (fallback `https://stress-api.dropitx.site` — StressAPIConfig.swift:11-14) already exists; no StoreKit secrets client-side | None |
| Build artifacts | Release-build blocker BUILD-05: STATE.md/PROJECT.md claim `StoreKitServiceEnvironment.swift:12` references `MockStoreKitService` unconditionally — **file at HEAD shows the guard present** [VERIFIED: StoreKitServiceEnvironment.swift:11-17 — `#if DEBUG` / `static let defaultValue: StoreKitServiceProtocol = MockStoreKitService(premiumState: .shared)` / `#else` ... `#endif`; also StressMonitorApp.swift:211-219 `#if DEBUG makeStoreKitService()`]. Either fixed since the note, or the note misdiagnosed | Phase 2 touches exactly these files: include one Release-configuration build (`xcodebuild -configuration Release`) as a task checkpoint to empirically close BUILD-05 |

## Common Pitfalls

### Pitfall 1: Two divergent "premium" notions
**What goes wrong:** iOS `PremiumState.isPremiumUser` (gates characters, trends, paywall suppression) vs backend `plan_type` (gates chat via 999999-unlimited + maxTokens 2048). If the app keeps selling subscriptions while the backend sells credits, a premium subscriber gets `plan_type='free'` + 50 credits on the server → chat 402s for a paying user.
**Why it happens:** Phase 1 never synced entitlements to the backend (nothing sets `plan_type='premium'`).
**How to avoid:** Decide at plan time: (a) grandfather = map an active subscription to server premium (needs a backend endpoint too — subscription JWS → set plan_type), or (b) retire subscriptions and credit-grant equivalent value once, or (c) keep both and sync. The dispatch explicitly lists this as open.
**Warning signs:** UAT test where a "premium" local state still receives 402.

### Pitfall 2: Consumables vanish after `finish()`
**What goes wrong:** grant-then-finish-in-wrong-order, or finish-then-server-write, loses purchases permanently — consumables cannot be restored [CITED: support.apple.com/en-us/108096 — "You can't restore consumable purchases"], so `AppStore.sync()`/`restorePurchases()` recovers nothing.
**How to avoid:** Pattern 2 (server ack → finish); server-side idempotency keyed on `transaction.id`.
**Warning signs:** `restorePurchases()` in a pack world can only restore *subscriptions* — the existing `StoreKitError.noActiveSubscription` copy becomes wrong/misleading.

### Pitfall 3: The metadata event arrives AFTER the stream, and the 402 arrives BEFORE it
**What goes wrong:** UI that expects `creditsRemaining` at stream-open shows nil; UI that assumes error JSON comes as a body reads an SSE `data: {"error": ...}` event instead for mid-stream failures.
**Why it happens:** backend contract: 402 is an HTTP status pre-stream [VERIFIED: stress-app-be/src/routes/chat.ts:33-38]; mid-stream errors are SSE `data: {"error": errorMsg}` events inside a 200 [VERIFIED: stress-app-be/src/routes/chat.ts:117-122 catch block enqueues `data: ${JSON.stringify({ error: errorMsg })}`]; success metadata is the second-to-last SSE event [VERIFIED: stress-app-be/src/routes/chat.ts:101-113].
**How to avoid:** iOS already handles all three correctly (SSEParser `.error`/`.metadata` cases + `mapHTTPError`) — don't re-implement; extend.

### Pitfall 4: Premium `credits_remaining` is a sentinel, not a count
**What goes wrong:** displaying `999999` credits to premium users, or `remaining <= 0` logic.
**Why:** `PREMIUM_UNLIMITED = 999999` [VERIFIED: stress-app-be/src/lib/credits.ts:3]; `deductCredit` returns it for plan_type 'premium' [VERIFIED: credits.ts:18-23].
**How to avoid:** iOS renders `plan_type == "premium"` as "Unlimited" and never formats raw remaining for premium. `CreditBalance.plan_type` union is `"free" | "premium"` [VERIFIED: stress-app-be/src/lib/types.ts:49-53 — `export interface CreditBalance { total: number; used: number; remaining: number; plan_type: "free" | "premium"; free_reset_at: string | null; }`].

### Pitfall 5: maxTokens shrinks near zero credits — UX reads as "AI got dumber"
**What goes wrong:** answers get terser below 20/5 remaining credits and users blame the model.
**Why:** backend tiers: premium 2048, >20 1024, >5 768, else 512 [VERIFIED: stress-app-be/src/lib/openrouter.ts:36-44].
**How to avoid:** not an iOS bug; paywall copy near depletion ("low credits — responses get shorter") manages expectation. Planner: copy decision, not code.

### Pitfall 6: Backend race — `deductCredit` can fail after streaming
**What goes wrong:** pre-check passes (remaining=1), two sends race, one stream completes but `deductCredit` returns `success:false`; chat.ts does not branch on it — it still emits `credits_remaining: available` (the un-deducted value) in metadata.
**Why:** [VERIFIED: stress-app-be/src/lib/credits.ts:26-33 returns `{ success: false, remaining: available }` without writing; chat.ts:100-101 ignores `deduction.success`].
**How to avoid:** iOS treats metadata `credits_remaining` as advisory (Pattern 3); not fixable client-side. Flag to backend owner as a follow-up, out of iOS scope.

### Pitfall 7: New test files silently don't compile
**What goes wrong:** dropping `*.swift` into `StressMonitorTests/` does nothing — the target uses an explicit PBXSourcesBuildPhase, not the synchronized folder [VERIFIED: 01-03-SUMMARY.md — "New test files dropped into the folder are NOT auto-compiled", fix = 4-line pbxproj pattern]. Seven test files are currently orphaned this way: `ChatAvailabilityTests`, `ChatLifecycleTests` (contains `FakeLLMService`, line 96), `DataDeletionConsolidationTests`, `EntitlementForegroundCorrectionTests`, `LLMServiceErrorTests`, `SSEParserTests`, `StoreKitProductCatalogLiveTests` (verified absent from the Sources phase via pbxproj awk this session).
**How to avoid:** every new test task includes the 4-line pbxproj edit (PBXBuildFile + PBXFileReference + group + Sources entry, `F1A1B2C3D4E5...A00x/B00x` ID scheme). Optionally bundle the orphan-repair as a Phase 2 hygiene task since `ChatLifecycleTests`/`SSEParserTests` pin exactly the chat-error contract this phase extends.

### Pitfall 8: 501 parallel-testing clones
**What goes wrong:** default `xcodebuild test` fails on this host (XCTestDevices/Mach -308) [VERIFIED: STATE.md decision — "xcodebuild test works with `-parallel-testing-enabled NO`"].
**How to avoid:** every verify command in every task plan carries `-parallel-testing-enabled NO`.

## Code Examples

### GET /credits — exact response contract (backend source of truth)
```typescript
// Source: read this session — stress-app-be/src/routes/credits.ts:9-21
app.get("/", async (c) => {
  const uid = c.get("uid");
  if (c.req.query("history") === undefined) {
    const balance = await getBalance(uid);
    if (!balance) return c.json({ error: "Failed to fetch credits" }, 500);
    return c.json({
      total: balance.total_credits,
      used: balance.used_credits,
      remaining: balance.total_credits - balance.used_credits,
      plan_type: balance.plan_type,
      free_reset_at: balance.free_reset_at,
    });
  }
```
History branch: `?history` (any value) + `limit` (default 20) + `offset` (default 0) → `{ transactions, limit, offset }` where rows are `credit_transactions.*` (`id UUID, user_id, amount, type, description, created_at`) [VERIFIED: stress-app-be/src/routes/credits.ts:12,21-35; migrations/20260812000005_credit_system.sql:12-20].

### 402 + provisioning + reset (backend, verbatim)
```typescript
// Source: stress-app-be/src/routes/chat.ts:33-38 — the 402 contract
const remaining = credits.total_credits - credits.used_credits;
if (remaining <= 0 && credits.plan_type !== "premium") {
  return c.json(
    { error: "No credits remaining", code: "INSUFFICIENT_CREDITS" },
    402,
  );
}
// Source: stress-app-be/src/middleware/auth.ts:40-41 — first authenticated request provisions
insert into user_credits (user_id, total_credits, used_credits, plan_type, free_reset_at)
values (${claims.uid}, 50, 0, 'free', now() + interval '1 month')
// Source: stress-app-be/src/lib/cron.ts:5-9 — monthly reset (Deno.cron "0 0 1 * *")
update user_credits
set total_credits = 50,
    used_credits = 0,
    free_reset_at = now() + interval '1 month'
where plan_type = 'free'
```

### iOS 402 mapping + metadata state that already exists (extend, don't rebuild)
```swift
// Source: read this session — StressMonitor/StressMonitor/Services/LLM/StressLLMService.swift:127-140
static func mapHTTPError(_ statusCode: Int) -> LLMServiceError? {
    switch statusCode {
    case 200...299: return nil
    case 401: return .unavailable(reason: "Please sign in to use AI Chat.")
    case 402: return .insufficientCredits
    // ...
// StressLLMService.swift:24 — already tracks per-message balance
private(set) var creditsRemaining: Int?
// StressLLMService.swift:107-115 — apply(metadata:) already stores creditsRemaining
// SSEParser.swift:53-60 — already parses {"type":"metadata", "credits_remaining": ...}
```
Current dead end (the gap Phase 2 closes): ChatViewModel.swift:157-169 renders `error.localizedDescription` only; `LLMServiceError.insufficientCredits` copy is "Out of credits. Monthly credits reset automatically." [VERIFIED: LLMServiceProtocol.swift:29-33] — accurate for free tier, wrong once packs exist; no paywall is triggered anywhere on 402 today.

### Paywall presentation seam (exists)
```swift
// Source: StressMonitor/StressMonitor/Services/Premium/PaywallController.swift:57-59
func present(reason: PaywallReason) {
    guard !premiumState.isPremiumUser else { return }
    presentation = PaywallPresentation(reason: reason)
}
```
Add `.outOfCredits` to `PaywallReason` (its cases are `general, trendsLongRange, bioAgeDetail, characters, breathingAdvanced, feature(named:)` [VERIFIED: PaywallController.swift:8-16]); note the premium-guard semantics: once a user is "premium" the credit paywall would ALSO be suppressed — reconcile with Pitfall 1's plan.

### Consumable pack in the local .storekit config
Current file: subscription group `SMPREMIUM01` with `com.stressmonitor.app.premium.weekly` (2.99) / `.monthly` (7.99) / `.annual` (59.88, 1-week free trial); `"products" : []` is empty [VERIFIED: StressMonitorTests/StressMonitorProducts.storekit — read this session]. Add entries:
```json
{
  "displayPrice" : "1.99",
  "internalID" : "SMCP0010",
  "localizations" : [ { "description" : "10 AI chat credits", "displayName" : "10 Credits", "locale" : "en_US" } ],
  "productID" : "com.stressmonitor.app.credits.small",
  "referenceName" : "CreditPack10",
  "type" : "Consumable"
}
```
SKU IDs/prices are the dispatch's open product question — above is shape-only; every concrete ID/price in final code must come from the user's decision. Scheme already loads this file for Test+Launch [VERIFIED: xcshareddata/xcschemes/StressMonitor.xcscheme:45-47, 75-77].

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StoreKit 1 receipt validation (send opaque receipt blob to Apple `/verifyReceipt`) | StoreKit 2 signed JWS transactions (`VerificationResult`, `jwsRepresentation`) + App Store Server API v2 | iOS 15 (2021); `/verifyReceipt` deprecated | No receipt blob handling anywhere; the new redemption endpoint should consume JWS [CITED: developer.apple.com/videos/play/wwdc2024/10062] |
| Local-only entitlement (PremiumState UserDefaults) | Server-authoritative balances for metered features | This phase | Characters/premium UX can stay local; credits cannot |
| `Transaction.currentEntitlements` for all products | Consumables appear only while unfinished; balance must be tracked server-side | StoreKit 2 semantics | Restores (`AppStore.sync`) cannot recover packs [CITED: support.apple.com/en-us/108096] |

**Deprecated/outdated:**
- Backend docs `plan-ios-integration.md` / `ios-integration-analysis.md` are pre-Firebase (they describe Supabase auth); their IAP sections still correctly describe the iOS files but reference "credits as IAP consumable ... alongside existing subscriptions" as a future option [CITED: stress-app-be/docs/ios-integration-analysis.md §10] — now becoming the actual design.
- `StoreKitError.noActiveSubscription` message "No active subscription was found for this Apple ID." (StoreKitServiceProtocol.swift:26) — wrong copy for pack restore; needs a packs-era rewrite or removal.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `VerificationResult.jwsRepresentation` is the correct API spelling for extracting the signed transaction to send server-side | Pattern 2 | Compile-time fix only; Phase 1 hit the same class of issue with Firebase labels — executor must verify against SDK headers |
| A2 | Finished consumables drop out of `Transaction.currentEntitlements` (hence deferred finish) | Pattern 2 / Pitfall 2 | If wrong, restore semantics change slightly; deferred-finish remains best practice regardless |
| A3 | Backend team/owner can accept cross-repo work in this phase (redemption endpoint) | Summary / Open Q1 | If not, Phase 2 must descope server-verified grants to a mock + checkpoint, or block |
| A4 | App Store Server Library (node) is the right backend verification tool for a Deno/Hono service | Don't Hand-Roll | Deno can run it via npm compat; if not, `jsonwebtoken` + Apple root certs path |
| A5 | 50 free credits/month continues to be the free tier during/after transition | Pitfall 4, paywall copy | Copy and UX change; backend behavior unchanged regardless |
| A6 | `.storekit` schema `"type": "Consumable"` entries work with Xcode 26.3's editor (format v3, current file) | Code Examples | Manual JSON edit fallback; the file is plain JSON |
| A7 | BUILD-05 (Release compile) is already fixed — based on HEAD showing `#if DEBUG` guards where STATE.md says none | Runtime State Inventory | If the Release build still fails elsewhere, AUTH-01's `strings` gate stays blocked; a Release build checkpoint resolves this empirically either way |

## Open Questions

1. **Backend redemption endpoint (blocks monetization-correctness)**
   - What we know: no route grants credits; `credit_type='purchase'` exists in the enum only. Backend repo is Deno 2.7.5/Hono with `postgres` (sql template) access and Firebase Admin token verification already in place.
   - What's unclear: is backend work in-scope for this phase (dispatch scopes "iOS app" repos, but the phase cannot ship real purchases without it)?
   - Recommendation: planner adds a `checkpoint:human-verify` decision task at phase start: (a) include a backend `POST /credits/redeem` plan (verify JWS → idempotent ledger insert → return new balance), or (b) ship iOS against a contract test with the live endpoint as an end-of-phase human-verify gate. Do NOT ship client-authoritative credit grants.
   - → RESOLVED-BY: DEC-1 checkpoint (02-01 Task 1) — option scope decides backend inclusion; backend half is planned as 02-02. Dependency safety additionally gated by the 02-02 Task 1 package-legitimacy checkpoint (blocking-human) before any Apple-verification dependency is added.
2. **Existing subscribers / grandfathering**
   - What we know: zero ASC products exist (nothing sold yet), so production subscribers = zero; sandbox/test transactions exist locally. `plan_type='premium'` is settable only by direct DB write today.
   - What's unclear: does the transition retire subscriptions entirely, keep both, or keep subscriptions for characters + credits for chat?
   - Recommendation: since no real subscribers exist, the cheapest correct path is retire-subscriptions-for-chat + keep the character/premium gating on existing subscription products until decided; ask the user.
   - → RESOLVED-BY: DEC-1 checkpoint (02-01 Task 1) — option-a/b/c covers coexistence vs retirement vs synced-premium; guard semantics recorded verbatim in 02-01-SUMMARY before Wave 2.
3. **Pack SKUs/pricing**
   - What we know: nothing decided. Backend docs once sketched "10 AI credits", "50 AI credits" [CITED: stress-app-be/docs/ios-integration-analysis.md §future-table].
   - Recommendation: 2–3 packs (small/medium/large) with per-unit discount on larger packs; concrete IDs/prices need user confirmation before ASC filing (which itself has lead time — file same-day as phase start per PROJECT.md).
   - → RESOLVED-BY: DEC-2 checkpoint (02-01 Task 2) — pack count/IDs/prices/amounts fixed there; mirrored into .storekit (02-03 Task 1), PACK_CREDITS (02-02 Task 3), and the 02-03 ASC user_setup.
4. **Where the balance surfaces**
   - What we know: chat sheet + Settings are natural hosts; `StressLLMService.creditsRemaining` already updates per message; Settings has a chat row ("Active") and a "StressMonitor Plus" row ("Try free").
   - Recommendation: chat sheet header (compact "12 credits" pill) + Settings value text; paywall shows balance + `free_reset_at`. Final placement is a UI decision for the planner/user (ui_phase: true, ui_review: true).
   - → RESOLVED-BY: DEC-2 checkpoint (02-01 Task 2) — placement-a/b decided there; tracer display target (02-01 Task 5) and surface expansion (02-04 Tasks 1–2) consume the recorded option.
5. **Does `PaywallController`'s premium guard suppress the credit paywall?**
   - What we know: `present()` no-ops when `isPremiumUser` — for a premium subscriber who somehow lacks server credits this hides the only path to buy more (or is exactly right if premium = unlimited chat). Tied to Q2.
   - Recommendation: resolve with Q2 in one decision; if premium ⇒ unlimited server-side, guard is correct as-is.
   - → RESOLVED-BY: DEC-1 checkpoint (02-01 Task 1) — option-a/b make the out-of-credits reason bypass premium suppression; option-c keeps the guard as-is. Behavior pinned by ChatLifecycleTests (02-01 Task 5) whichever branch is chosen.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Backend (stress-api.dropitx.site) | /credits contract, 402, metadata | ✓ (verified live this session: `GET /health` → 200) | deployed 2026-08-16 state | local `deno task` run (deno 2.7.5 present) |
| Xcode | builds, StoreKit tests | ✓ | 26.3 | — |
| iPhone 17 simulator | test destination | ✓ (iPhone 17e, iPhone Air available) | iOS 26.x runtime | any booted iPhone-family device |
| Deno (backend dev) | contract tests, redemption endpoint dev | ✓ | 2.7.5 | — |
| Node 22 | tooling | ✓ | v22.23.2 | — |
| App Store Connect products | Release-config pack resolution (IAP-01) | ✗ (none exist) | — | local `.storekit` covers Debug/test; Release-resolution verification becomes a checkpoint:human-verify until ASC products are filed |
| Firebase project (GoogleService-Info.plist) | auth for /credits calls | ✓ (Phase 1, gitignored, placed) | Firebase 11.x SDK | — |

**Missing dependencies with no fallback:** none that block coding/testing — ASC product creation blocks only the Release/production verification gate (lead-time item, file early).
**Missing dependencies with fallback:** ASC products → local `.storekit`.

## Validation Architecture

> `workflow.nyquist_validation: true` in `.planning/config.json` — section required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (`import Testing`) + XCTest host, via xcodebuild |
| Config file | none — target membership IS the config (explicit PBXSourcesBuildPhase; see Pitfall 7) |
| Quick run command | `xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:StressMonitorTests/<Suite> -parallel-testing-enabled NO` |
| Full suite command | `xcodebuild test -scheme StressMonitor -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO` (baseline: 87 tests / 14 suites green, 2026-08-16 per 01-04-SUMMARY) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| derived-CR-01 | `StressAPIClient.getBalance()` decodes `{total,used,remaining,plan_type,free_reset_at}`; Bearer injected; 401/500 mapping | unit (URLProtocol stub — Phase 1's `RequestCaptureURLProtocol` pattern) | `... -only-testing:StressMonitorTests/StressAPIClientCreditsTests` | ❌ Wave 0 |
| derived-CR-02 | `402 → LLMServiceError.insufficientCredits` regression pin | unit (exists: `StressAPIClientTests` 402 case — keep green; orphaned `LLMServiceErrorTests` repair adds coverage) | `... -only-testing:StressMonitorTests/StressAPIClientTests` | ✅ (compiled) / ❌ (orphaned suite) |
| derived-CR-03 | 402 in ChatViewModel routes to paywall presentation (not just error text) | unit with mock LLMService throwing `.insufficientCredits` (`FakeLLMService` exists but is ORPHANED — `ChatLifecycleTests.swift:96`) | `... -only-testing:StressMonitorTests/ChatLifecycleTests` | ❌ Wave 0 (file exists, not in Sources phase) |
| derived-CR-04 | `CreditService` state machine: load → balance; apply(metadata) → convergence; premium sentinel display rule | unit (MockAuthService-style seam) | `... -only-testing:StressMonitorTests/CreditServiceTests` | ❌ Wave 0 |
| derived-CR-05 | Pack purchase: deferred-grant order (server redeem before `finish()`), retry via Transaction.updates | unit with fake API client + StoreKitTest session | `... -only-testing:StressMonitorTests/CreditPurchaseFlowTests` | ❌ Wave 0 — CAUTION: `StoreKitServiceTests` is `@Suite(.serialized, .disabled("StoreKitTest session-isolation bug on CI"))` [VERIFIED: StoreKitServiceTests.swift:17]; new StoreKitTest-based suites inherit that risk — prefer protocol-mock tests for logic, keep StoreKitTest coverage to one serialized suite |
| derived-CR-06 | Paywall shows balance + reset date; pack cards render from catalog | unit on ViewModel + manual UI review (ui_review: true) | `... -only-testing:StressMonitorTests/CreditsViewModelTests` | ❌ Wave 0 |
| derived-CR-07 | Backend redemption correctness: idempotent grant keyed on the Apple transaction id (replay ≠ double-credit), amounts from server-side PACK_CREDITS only (client-asserted amounts ignored), unverified JWS → 400 INVALID_TRANSACTION | unit (Deno, injected fake verifier seam — `credits.test.ts` + `iap.test.ts`) | `cd /Users/ddphuong/Projects/next-labs/stress-ai/stress-app-be && deno task test src/routes/credits.test.ts src/lib/iap.test.ts` | ❌ Wave 0 (created by plan 02-02) |
| IAP-06 | purchase/restore against `.storekit` | integration (StoreKitTest) | blocked by the disabled-suite issue; checkpoint:human-verify manual run via scheme LaunchAction (already wired to `.storekit`) | ⚠️ exists-but-disabled |

### Sampling Rate
- **Per task commit:** targeted `-only-testing` suite(s) touched by the task, always with `-parallel-testing-enabled NO`
- **Per wave merge:** full suite command above, exit 0 required
- **Phase gate:** full suite green + live-backend smoke (balance fetch + one 402-triggered chat) before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `StressMonitorTests/CreditServiceTests.swift` — derived-CR-04 (+ 4-line pbxproj registration)
- [ ] `StressMonitorTests/StressAPIClientCreditsTests.swift` — derived-CR-01
- [ ] `StressMonitorTests/CreditsViewModelTests.swift` — derived-CR-06
- [ ] Repair orphaned `ChatLifecycleTests.swift` + `SSEParserTests.swift` + `LLMServiceErrorTests.swift` into the Sources phase (derived-CR-02/03 substrate; delete/rewrite broken `ChatAvailabilityTests.swift` which references deleted Supabase symbols)
- [ ] Add consumable products to `StressMonitorProducts.storekit` (no framework install needed)

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1`, `security_block_on: high` (`.planning/config.json`). Phase 2 introduces a payment-adjacent surface — highest-stakes phase so far.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Firebase ID token via existing `AuthServiceProtocol`/`StressAPIClient.authorizedRequest`; 401 → re-auth message already mapped |
| V3 Session Management | yes | Token refresh margin (60s) already in `FirebaseAuthService.getIDToken`; balance calls inherit it |
| V4 Access Control | yes — NEW server surface | Redemption endpoint must bind grants to the *verified transaction's app account*, not to a client-asserted uid+amount; idempotency on `transaction.id` prevents replay |
| V5 Input Validation | yes | Backend: JWS parse + signature chain before any ledger write; iOS: decode-only of typed `CreditBalance` (Codable); never trust client-sent credit amounts |
| V6 Cryptography | yes | JWS verification with Apple's root CA chain (App Store Server Library) — never hand-roll; on-device `checkVerified` already throws on `.unverified` |
| V14 Config | yes | No secrets client-side; `STRESS_API_BASE_URL` 3-tier resolution unchanged; `GoogleService-Info.plist` embedding is by-design (Phase 1 review) |

### Known Threat Patterns for iOS + consumable credits

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged redemption (client POSTs fake JWS / replays old one) | Tampering, Repudiation | Server-side JWS signature verification + unique constraint / idempotency on transaction id; log every grant row (`credit_transactions.type='purchase'`) |
| Client-authoritative balance tampering (UserDefaults edits) | Tampering | Balance is display-only; server is sole authority for deduction/gating |
| Race: parallel chats draining credits inconsistently | Repudiation | Backend `for update` row lock already handles it (credits.ts:26-33); iOS never parallel-decrements |
| Entitlement spoofing for characters (local PremiumState) | Elevation | Pre-existing design (local premium gates local content only — no server value at risk); unchanged by this phase |
| 402-response spoofing to force paywall confusion | none material | Paywall is not a security boundary; no state mutation on present |

## Project Constraints (from AGENTS.md)

Extracted from repo-root `AGENTS.md` (read this session) — directives the planner must honor:

- **MUST read `/docs/INDEX.md` first before implementing any feature** — `/docs/` is authoritative project documentation.
- Build/test via the `xc-all` MCP tools when available (`xcode_build`, `xcode_test` with scheme `StressMonitor`; simulator management, idb UI automation, screenshots). In this harness, plain `xcodebuild` equivalents apply.
- **MVVM with SwiftUI, @Observable (iOS 17+ macro), protocol-based constructor DI** — all new credit services follow.
- **Async/await everywhere**; `.task {}` for view-attached async work; no callback APIs.
- **Imports grouped alphabetically** (`Foundation`, `StoreKit`, `SwiftUI`...).
- **Tests:** floating-point with `accuracy`; naming `test[Condition]` / `test[Method]_[Condition]`.
- **UI must follow `documentation/references/ui-ux-design-system.md`**: dual coding (color + icon/text), `.accessibleDynamicType()`, ≥44pt targets, `HapticManager` for feedback.
- **NEVER create git commits unless required**; **commit author must be "Phuong Doan"**; never include Codex credentials/attribution or Co-Authored-By trailers.
- GitNexus: run impact analysis before editing symbols; `detect_changes()` before committing (root AGENTS.md).
- HealthKit read-only; no third-party analytics; no external API calls beyond the app's own backend (Privacy & Security section).
- Known-issues guidance: HealthKit denial → Settings path; CloudKit errors → graceful handling; background tasks need Background Modes (not directly touched this phase).

Additional locked operational constraints (dispatch + STATE.md):
- All test invocations use `-parallel-testing-enabled NO`.
- TDD mode on: RED → GREEN per task for new logic (type:tdd tasks).
- Branch decision pending: repo is on `main`, 31 commits ahead of `origin/main` (verified this session); STATE.md says "Decide branch strategy + push before starting Phase 2" — planner should surface as a pre-flight checkpoint, not silently continue.

## Sources

### Primary (HIGH confidence — read in-repo this session)
- `stress-app-be/src/routes/credits.ts` — GET /credits balance + history contract
- `stress-app-be/src/routes/chat.ts` — 402 semantics, SSE metadata event, deduction ordering
- `stress-app-be/src/lib/credits.ts` — deductCredit locking, premium sentinel
- `stress-app-be/src/middleware/auth.ts` — provisioning (50 credits), Bearer verification
- `stress-app-be/src/lib/cron.ts`, `src/lib/openrouter.ts` (getMaxTokens), `src/lib/types.ts` (CreditBalance), `src/app.ts` (route inventory — no IAP route)
- `stress-app-be/migrations/20260812000005_credit_system.sql`, `20260812000001_enums_and_helpers.sql` — ledger schema + enums
- iOS: `StoreKitService(.Protocol/.Environment)`, `MockStoreKitService`, `StoreKitProductCatalog`, `PremiumState`, `PaywallController`, `PremiumViewModel`, `PaywallView`, `IAPPremiumView`, `PurchaseSuccessView`, `StressLLMService`, `SSEParser`, `LLMServiceProtocol`, `ChatViewModel`, `ChatAvailability`, `StressAPIClient`, `StressAPIConfig`, `StressMonitorApp`, `SettingsView`, `StressMonitorProducts.storekit`, `StressMonitor.xcscheme`, `project.pbxproj` (Sources-phase audit)
- `.planning/`: STATE.md, ROADMAP.md, PROJECT.md, config.json, Phase 01 summaries 01-01..01-04, 01-REVIEW.md

### Secondary (MEDIUM confidence)
- createwithswift.com/implementing-consumable-in-app-purchases-with-storekit-2 — consumable purchase/finish flow, `.storekit` config steps, Xcode 26.2/iOS 26
- developer.apple.com/videos/play/wwdc2024/10062 — App Store Server API / server library for IAP verification
- developer.apple.com/videos/play/tech-talks/10887 — StoreKit 2 + App Store Server API customer support patterns
- support.apple.com/en-us/108096 — "You can't restore consumable purchases"
- stackoverflow.com/questions/79402090 — server-side validation pattern for consumables (community corroboration)
- stress-app-be/docs/ios-integration-analysis.md §10, docs/plans/plan-ios-integration.md — pre-Firebase design intent for credits-as-consumables (stale on auth, correct on integration points)

### Tertiary (LOW confidence)
- None — no claim in this document rests on an unverified web source alone.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; StoreKit 2 usage already in-repo
- Architecture: HIGH — both repos read directly; contract quoted verbatim with line ranges
- Pitfalls: HIGH — each verified against source or cited to Apple/official material
- Backend redemption gap: HIGH — negative claim verified by enumerating `src/app.ts` route mounts this session

**Research date:** 2026-08-16
**Valid until:** 2026-09-16 (stable domain; backend contract pinned by deployed code — re-verify if backend deploy changes)
