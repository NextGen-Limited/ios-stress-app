# Phase 3: SettingsView Redesign

## Overview
Replace existing Form-based SettingsView with card-based Figma design.

## Current State
- Uses SwiftUI `Form` with sections
- 4 sections: Profile, Notifications, Data Management, Version

## Target State
- Uses `ScrollView` with custom cards
- 3 main cards: Premium, Watch Complications, Data Sharing
- Background color `#F3F4F8`

## New Structure

```swift
// SettingsView.swift

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.settingsCardSpacing) {
                // Premium Card
                PremiumCard()
                    .padding(.top, 8)

                // Watch Face Card
                WatchFaceCard()

                // Data Sharing Card
                DataSharingCard()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.settingsBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load data
        }
    }
}
```

## WatchFaceCard Component

```swift
struct WatchFaceCard: View {
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                SettingsSectionHeader(
                    iconImage: "watch-icon",
                    title: "Watch face & Complications"
                )

                // Widgets Row
                HStack(spacing: 23) {
                    ComplicationWidget(title: "Circular")
                    ComplicationWidget(title: "Graphic")
                }
                .padding(.top, 23)

                // Button
                HStack {
                    Spacer()
                    AddComplicationButton {
                        // Action
                    }
                    Spacer()
                }
                .padding(.top, 24)
            }
        }
    }
}
```

## DataSharingCard Component

```swift
struct DataSharingCard: View {
    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                SettingsSectionHeader(
                    iconImage: "menu-icon",
                    title: "Data Sharing"
                )

                // Widgets Row
                HStack(spacing: 23) {
                    ComplicationWidget(title: "Export")
                    ComplicationWidget(title: "Sync")
                }
                .padding(.top, 23)

                // Button
                HStack {
                    Spacer()
                    ShareButton {
                        // Action
                    }
                    Spacer()
                }
                .padding(.top, 24)
            }
        }
    }
}
```

## Preserve Existing Functionality

Map existing features to new design:

| Current | New Location |
|---------|--------------|
| Profile Section | Keep in separate "Edit Profile" view (accessed from header) |
| Notifications Section | Move to system Settings via `openURL` |
| Data Management | DataSharingCard with navigation |
| Version Info | Add small footer text |

## Implementation Steps

- [x] 1. Backup existing SettingsView.swift
- [x] 2. Create `WatchFaceCard.swift` in Components
- [x] 3. Create `DataSharingCard.swift` in Components
- [x] 4. Rewrite SettingsView.swift with new structure
- [x] 5. Add NavigationLinks to existing DataExportView, DataDeleteView
- [x] 6. Add version footer
- [x] 7. Test all navigation flows
- [x] 8. Verify with VoiceOver

## Status: ✅ Complete

## Files to Modify

| File | Changes |
|------|---------|
| `Views/Settings/SettingsView.swift` | Complete rewrite |

## Files to Create

| File | Purpose |
|------|---------|
| `Views/Settings/Components/WatchFaceCard.swift` | Watch complications card |
| `Views/Settings/Components/DataSharingCard.swift` | Data sharing card |

## Validation
- [x] All existing NavigationLinks work
- [x] ViewModel bindings still function
- [x] Export/Delete views accessible
- [x] Build succeeds
