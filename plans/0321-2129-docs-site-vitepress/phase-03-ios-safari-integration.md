# Phase 03: iOS SFSafariViewController Integration

**Status:** complete
**Priority:** High
**Effort:** ~1h
**Depends on:** phase-02 (need deployed URL)

## Overview

Add `SFSafariViewController` sheet support to Settings. Update `AboutCard` to expose Help & FAQ link. Privacy Policy and Terms of Service links switch from `openURL` (external browser) to SFSafariViewController sheet.

## Files to Create

### `StressMonitor/StressMonitor/Utilities/DocsURL.swift`

```swift
import Foundation

/// Centralized docs URL constants. Update `base` after Vercel deploy.
enum DocsURL {
    static let base = URL(string: "https://stressmonitor-docs.vercel.app")!

    static let help       = base.appending(path: "user-guide/")
    static let principle  = base.appending(path: "principle/")
    static let stressLevels = base.appending(path: "principle/stress-levels")
    static let privacy    = base.appending(path: "legal/privacy")
    static let terms      = base.appending(path: "legal/terms")
}
```

### `StressMonitor/StressMonitor/Views/Shared/SafariView.swift`

```swift
import SafariServices
import SwiftUI

/// Thin UIViewControllerRepresentable wrapper for SFSafariViewController.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ viewController: SFSafariViewController, context: Context) {}
}
```

## Files to Modify

### `StressMonitor/StressMonitor/Views/Settings/Components/AboutCard.swift`

Add `onHelp` callback alongside existing `onPrivacyPolicy` and `onTermsOfService`:

```swift
struct AboutCard: View {
    let onHelp: () -> Void           // NEW
    let onContactSupport: () -> Void
    let onPrivacyPolicy: () -> Void
    let onTermsOfService: () -> Void

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSectionHeader(icon: "info.circle.fill", title: "About and Support")
                VStack(alignment: .leading, spacing: 12) {
                    supportLink("Help & FAQ", action: onHelp)        // NEW
                    supportLink("Contact Support", action: onContactSupport)
                    supportLink("Privacy Policy", action: onPrivacyPolicy)
                    supportLink("Terms of Service", action: onTermsOfService)
                }
                // ... cat illustration + version unchanged
            }
        }
    }
}
```

### `StressMonitor/StressMonitor/Views/Settings/SettingsView.swift`

Replace `openURL` calls for privacy/terms with sheet state, and wire the new Help link:

```swift
struct SettingsView: View {
    // ... existing state ...
    @State private var docsURL: URL? = nil   // NEW — drives sheet

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.settingsCardSpacing) {
                // ... existing cards ...

                AboutCard(
                    onHelp: { docsURL = DocsURL.help },                    // NEW
                    onContactSupport: { openURLString("mailto:support@stressmonitor.app") },
                    onPrivacyPolicy: { docsURL = DocsURL.privacy },        // CHANGED
                    onTermsOfService: { docsURL = DocsURL.terms }          // CHANGED
                )
            }
        }
        // ... existing modifiers ...
        .sheet(item: $docsURL) { url in       // NEW
            SafariView(url: url)
                .ignoresSafeArea()
        }
    }
}
```

> **Note:** `URL` needs `Identifiable` conformance for `.sheet(item:)`. Add via extension:
>
> ```swift
> // In DocsURL.swift or a URL+Extensions file
> extension URL: @retroactive Identifiable {
>     public var id: String { absoluteString }
> }
> ```

## Offline Fallback

SFSafariViewController handles network errors natively (shows "Cannot Open Page" error page). No custom fallback needed — this is acceptable iOS behavior.

## Todo

- [ ] Create `Utilities/DocsURL.swift` with correct Vercel URL
- [ ] Create `Views/Shared/SafariView.swift`
- [ ] Add `URL: Identifiable` extension (check if already exists)
- [ ] Update `AboutCard.swift` — add `onHelp` param + "Help & FAQ" link
- [ ] Update `SettingsView.swift` — add `@State private var docsURL`, wire sheet
- [ ] Build project — verify no compile errors
- [ ] Manually test: tap Help → SFSafariViewController opens docs
- [ ] Manually test: tap Privacy Policy → opens `/legal/privacy`
- [ ] Manually test: tap Terms → opens `/legal/terms`

## Success Criteria

- All 3 links (Help, Privacy, Terms) open SFSafariViewController sheet
- Sheet dismisses correctly with swipe-down
- No external Safari app opens for these links
- `SettingsView` compiles without warnings

## Risks

- `URL: Identifiable` retroactive conformance — Swift may warn about this in future. Alternative: wrap in a simple `struct DocLink: Identifiable { let url: URL; var id: String { url.absoluteString } }`.
