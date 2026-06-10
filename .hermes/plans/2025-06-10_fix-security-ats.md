# [P1] Fix Security — Remove NSAllowsArbitraryLoads

**Task ID:** t_5e0b0cfa  
**Branch:** `fix/security-ats`  
**Priority:** P1  
**Date:** 2025-06-10  

---

## Summary

Remove the blanket `NSAllowsArbitraryLoads: true` from `StressMonitor/Info.plist` and replace it with specific ATS domain exceptions for the exact HTTPS endpoints the app communicates with. This is required for App Store compliance (Apple rejects apps with `NSAllowsArbitraryLoads` without strong justification since iOS 9 / 2017).

---

## Current State

### Info.plist (`StressMonitor/Info.plist`, lines 45–51)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Network Endpoints Discovered in Code

All network calls use HTTPS only — no HTTP URLs found anywhere in the codebase.

| Domain | Source File | Purpose |
|--------|-----------|---------|
| `fqurrfnfczeozvaxjrcu.supabase.co` | `SupabaseConfig.swift` | Supabase Edge Functions (chat, health, sessions, preferences, credits, quick-actions) |
| `hyperpolysllabically-saronic-mee.ngrok-free.app` | `LLMAPITarget.swift`, `CloudLLMService.swift` | ngrok dev tunnel for cloud LLM |
| `stressmonitor-docs.vercel.app` | `DocsURL.swift` | Help/privacy/terms docs (via SafariView + Link) |

### Key Observations

1. **All endpoints already use HTTPS** — no `http://` URLs found in app code.
2. **`NSAllowsArbitraryLoads` is unnecessary** — it was likely added during early development as a convenience.
3. **Watch app (`StressMonitorWatch`)** has no Info.plist with ATS settings (inherits system defaults → HTTPS-only).
4. **Widget (`StressMonitorWidget`)** Info.plist has no ATS section (also inherits system defaults).
5. **`NSAllowsLocalNetworking: true`** can remain — it only applies to `.local` and loopback addresses, which is fine for development.

---

## Plan

### Task 1: Create feature branch

```bash
cd ~/Projects/ios-stress-app
git checkout main && git pull
git checkout -b fix/security-ats
```

**Verify:** `git branch --show-current` → `fix/security-ats`

---

### Task 2: Update Info.plist — Replace ATS config

**File:** `StressMonitor/Info.plist`

**Replace** lines 45–51 (the entire `NSAppTransportSecurity` dict):

```xml
<!-- BEFORE (lines 45-51) -->
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
```

**With:**

```xml
<!-- AFTER -->
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
		<key>NSExceptionDomains</key>
		<dict>
			<key>fqurrfnfczeozvaxjrcu.supabase.co</key>
			<dict>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<false/>
				<key>NSIncludesSubdomains</key>
				<false/>
			</dict>
			<key>hyperpolysyllabically-saronic-mee.ngrok-free.app</key>
			<dict>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<false/>
				<key>NSIncludesSubdomains</key>
				<false/>
			</dict>
			<key>stressmonitor-docs.vercel.app</key>
			<dict>
				<key>NSExceptionAllowsInsecureHTTPLoads</key>
				<false/>
				<key>NSIncludesSubdomains</key>
				<false/>
			</dict>
		</dict>
	</dict>
```

**Rationale:**
- `NSAllowsArbitraryLoads: true` → **removed entirely**
- `NSAllowsLocalNetworking: true` → **kept** (needed for local dev/testing only)
- Explicit domain entries with `NSExceptionAllowsInsecureHTTPLoads: false` → documents that we expect HTTPS for these domains, satisfying Apple's review requirements
- `NSIncludesSubdomains: false` → no subdomains used; tightens scope

> **Note:** Since all domains already use HTTPS with valid TLS certificates (Supabase, ngrok, Vercel all provide proper certs), the domain exceptions are actually *not strictly required* for the app to function. They serve as **documentation of allowed domains** for App Store review. However, if we wanted the *strictest* approach, we could omit `NSExceptionDomains` entirely and keep only `NSAllowsLocalNetworking`. See Task 7 for that alternative.

---

### Task 3: Verify no HTTP URLs exist in codebase

**Scan for any `http://` (non-HTTPS) URLs:**

```bash
cd ~/Projects/ios-stress-app
grep -rn "http://" --include="*.swift" --include="*.plist" StressMonitor/ | grep -v "apple.com/DTDs" | grep -v "http://www.w3.org" | grep -v "localhost"
```

**Expected:** No results (all network URLs are HTTPS).

If any `http://` URLs are found (excluding DTD references and comments), they must either:
- Be upgraded to `https://`, or
- Have a specific domain exception added to Info.plist

---

### Task 4: Add ATS configuration unit test

**File:** `StressMonitor/StressMonitorTests/ATSSecurityTests.swift` (new file)

```swift
import XCTest
@testable import StressMonitor

final class ATSSecurityTests: XCTestCase {

    // MARK: - Info.plist ATS Configuration Tests

    /// Verify that NSAllowsArbitraryLoads is NOT set to true.
    /// This is a regression test — App Store will reject apps with this flag.
    func testInfoPlistDoesNotAllowArbitraryLoads() {
        guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(
                  from: plistData, options: [], format: nil
              ) as? [String: Any] else {
            XCTFail("Could not read Info.plist")
            return
        }

        guard let ats = plist["NSAppTransportSecurity"] as? [String: Any] else {
            // No ATS dict at all — that's fine, system default is HTTPS-only
            return
        }

        if let allowsArbitraryLoads = ats["NSAllowsArbitraryLoads"] as? Bool {
            XCTAssertFalse(
                allowsArbitraryLoads,
                "NSAllowsArbitraryLoads must NOT be true — it causes App Store rejection. "
                + "Use NSExceptionDomains for specific domain exceptions instead."
            )
        }
        // If the key is absent, that's also acceptable (defaults to false)
    }

    /// Verify that all ATS exception domains require HTTPS.
    func testExceptionDomainsRequireHTTPS() {
        guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(
                  from: plistData, options: [], format: nil
              ) as? [String: Any],
              let ats = plist["NSAppTransportSecurity"] as? [String: Any],
              let domains = ats["NSExceptionDomains"] as? [String: [String: Any]] else {
            // No exception domains — nothing to check
            return
        }

        for (domain, config) in domains {
            if let allowsInsecure = config["NSExceptionAllowsInsecureHTTPLoads"] as? Bool {
                XCTAssertFalse(
                    allowsInsecure,
                    "Domain '\(domain)' must not allow insecure HTTP loads. "
                    + "All domains should use HTTPS."
                )
            }
            // If NSExceptionAllowsInsecureHTTPLoads is absent, it defaults to false — acceptable
        }
    }

    /// Verify that the known required domains are listed in ATS config.
    func testRequiredDomainsAreListed() {
        let requiredDomains = [
            "fqurrfnfczeozvaxjrcu.supabase.co",
            "hyperpolysllabically-saronic-mee.ngrok-free.app",
            "stressmonitor-docs.vercel.app",
        ]

        guard let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plist = try? PropertyListSerialization.propertyList(
                  from: plistData, options: [], format: nil
              ) as? [String: Any],
              let ats = plist["NSAppTransportSecurity"] as? [String: Any],
              let domains = ats["NSExceptionDomains"] as? [String: Any] else {
            // If there's no exception domains section, skip this test
            // (the minimal approach with no exceptions is also valid)
            return
        }

        for domain in requiredDomains {
            XCTAssertNotNil(
                domains[domain],
                "Required domain '\(domain)' should be listed in NSExceptionDomains. "
                + "If it was intentionally removed, update this test."
            )
        }
    }
}
```

---

### Task 5: Build and run tests

```bash
# Build the project first
xcodebuild build \
    -project StressMonitor/StressMonitor.xcodeproj \
    -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -quiet

# Run all tests (including the new ATSSecurityTests)
xcodebuild test \
    -project StressMonitor/StressMonitor.xcodeproj \
    -scheme StressMonitor \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    -only-testing:StressMonitorTests/ATSSecurityTests \
    -quiet
```

**Expected:** All tests pass.

---

### Task 6: Manual verification — app functionality check

After building, launch the app in the simulator and verify:

1. **Dashboard loads** — stress data displays correctly (no network needed, all HealthKit)
2. **Settings → About → Help** — SafariView opens `https://stressmonitor-docs.vercel.app/user-guide/` successfully
3. **AI Chat** (if enabled) — attempt to send a message to verify Supabase endpoint works
4. **No console ATS errors** — check Xcode console for `NSURLErrorDomain` / ATS violation messages

---

### Task 7 (Alternative): Minimal ATS config — no exception domains

If during App Store review Apple questions the domain exceptions (they sometimes do), consider this even stricter approach:

**Replace the entire `NSAppTransportSecurity` dict with just:**

```xml
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsLocalNetworking</key>
		<true/>
	</dict>
```

This is valid because:
- All domains use HTTPS with valid TLS certificates
- No domain needs any ATS exception (no self-signed certs, no ancient TLS)
- `NSAllowsLocalNetworking` is only for `.local` mDNS addresses and `127.0.0.1`/`localhost`

If adopting this alternative, update the test in Task 4 to skip/remove `testRequiredDomainsAreListed`.

---

## Files Modified

| File | Action | Description |
|------|--------|-------------|
| `StressMonitor/Info.plist` | Modify | Remove `NSAllowsArbitraryLoads`, add `NSExceptionDomains` |
| `StressMonitor/StressMonitorTests/ATSSecurityTests.swift` | Create | Regression tests for ATS config |

## Files NOT Modified (and why)

| File | Reason |
|------|--------|
| `StressMonitor/StressMonitorWidget/Info.plist` | No ATS section — inherits system HTTPS-only defaults |
| `StressMonitor/Services/LLM/CloudLLMService.swift` | Already uses HTTPS URL — no changes needed |
| `StressMonitor/Services/LLM/SupabaseLLMService.swift` | Already uses HTTPS via SupabaseConfig — no changes needed |
| `StressMonitor/Services/LLM/SupabaseConfig.swift` | Already uses HTTPS — no changes needed |
| `StressMonitor/Services/LLM/LLMAPITarget.swift` | Already uses HTTPS — no changes needed |
| `StressMonitor/Utilities/DocsURL.swift` | Already uses HTTPS — no changes needed |

---

## Verification Checklist

- [ ] `NSAllowsArbitraryLoads` is absent or `false` in Info.plist
- [ ] No `http://` URLs in any Swift source files (excluding DTDs and comments)
- [ ] All ATS exception domains have `NSExceptionAllowsInsecureHTTPLoads: false`
- [ ] `ATSSecurityTests` all pass
- [ ] App builds without ATS-related warnings
- [ ] Dashboard, settings docs links, and AI Chat still function correctly
- [ ] No `NSURLErrorDomain` ATS violation errors in console

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| ngrok tunnel cert issues | AI Chat unavailable in dev | ngrok-free.app uses valid certs; if issues arise, keep `NSAllowsLocalNetworking` for local proxy |
| Missing domain in exceptions | Feature silently fails | Test in Task 6 covers all known features; grep in Task 3 catches new URLs |
| App Store still flags ATS | Review delay | Use Task 7 alternative (minimal config) if reviewer pushes back |

---

## Implementation Order

1. Create branch → **Task 1**
2. Edit Info.plist → **Task 2**
3. Scan for HTTP URLs → **Task 3**
4. Create test file → **Task 4**
5. Build + run tests → **Task 5**
6. Manual app verification → **Task 6**
7. Commit and push

```bash
git add StressMonitor/Info.plist StressMonitor/StressMonitorTests/ATSSecurityTests.swift
git commit -m "fix(security): remove NSAllowsArbitraryLoads, add specific ATS domain exceptions

- Remove blanket NSAllowsArbitraryLoads=true from Info.plist
- Add NSExceptionDomains for: supabase.co, ngrok-free.app, vercel.app
- All domains configured with HTTPS-only (NSExceptionAllowsInsecureHTTPLoads=false)
- Add ATSSecurityTests regression test suite
- Keep NSAllowsLocalNetworking for local development

Fixes: t_5e0b0cfa"
```
