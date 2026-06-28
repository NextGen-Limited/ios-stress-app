# Dependencies

StressMonitor is primarily built on Apple system frameworks. A small set of Swift Package Manager dependencies handle UI concerns (charts, chat components, image loading, tab bar animation). The README and AGENTS.md note 13 SPM packages, though the project is in the process of pruning unused ones as the codebase moves to pure SwiftUI equivalents.

## System frameworks

| Framework | Use |
| --- | --- |
| SwiftUI | All UI |
| SwiftData | Local persistence (`@Model`, `ModelContainer`) |
| HealthKit | Biometric reads (HRV, HR, sleep, activity, recovery) |
| CloudKit | Encrypted sync (private database) |
| WidgetKit | Home screen widgets, watch complications, Live Activities |
| StoreKit | IAP subscriptions (StoreKit 2) |
| BackgroundTasks | `BGAppRefreshTask` scheduling |
| UserNotifications | Local notifications |
| WatchConnectivity | Phone-watch messaging |
| Security | Keychain storage (`KeychainService`) |
| Observation | `@Observable` macro |
| Charts | Used partially; most charts are custom `Path`/`Canvas` |

## Swift Package Manager dependencies

The project declares SPM dependencies in `StressMonitor/StressMonitor.xcodeproj`. The README lists the following packages, though not all are actively used and the list is being pruned:

| Package | Stated purpose | Status |
| --- | --- | --- |
| SwiftUICharts | Custom chart views | Being replaced by custom `Path`/`Canvas` charts |
| Alamofire | HTTP networking | Used transitively by Moya |
| Moya | Network abstraction | Used for LLM API calls (historically) |
| Kingfisher | Image loading and caching | Used for character asset loading |
| ReactiveSwift | Reactive primitives | Legacy, candidate for removal |
| RxSwift | Reactive extensions | Legacy, candidate for removal |
| Chat | Chat UI components | Used in `ChatBottomSheetView` |
| Giphy iOS SDK | GIF support | Used in chat |
| MediaPicker | Media selection | Used in chat |
| ActivityIndicatorView | Loading indicators | Used in various views |
| AnchoredPopup | Popup overlays | Used in onboarding and tooltips |
| AnimatedTabBar | Animated tab bar | The app now uses native `TabView` with `Tab` |
| LibWebP | WebP image support | Used for character assets |

The actively-used dependencies are Kingfisher (image loading), Chat (chat UI), and the media-related packages. The reactive and networking packages are candidates for removal as the LLM layer now uses `URLSession` directly through `SupabaseLLMService`.

## No analytics or tracking

No third-party analytics, crash reporting, or advertising SDKs are present. The privacy manifest at `StressMonitor/StressMonitor/PrivacyInfo.xcprivacy` declares `NSPrivacyTracking: false` and an empty tracking domains list.

## Build-time only

- `swiftlint` via `.swiftlint.yml` (run from Xcode build phase or CLI).
- `fastlane` via `fastlane/Gemfile` and `fastlane/Gemfile.lock`.

These are development dependencies and do not ship in the app binary.
