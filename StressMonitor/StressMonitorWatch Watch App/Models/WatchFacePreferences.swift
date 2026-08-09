import Foundation
import WidgetKit

// MARK: - WatchFacePreferences

/// Centralised read/write access to the user's watch-face personalisation
/// choices.
///
/// All values are persisted in the App-Groups `UserDefaults` so they are
/// visible to both the watch app process **and** the WidgetKit complication
/// extension (which runs in a separate process).
enum WatchFacePreferences {

    /// Must match `ComplicationDataProvider.suiteName`.
    static let suiteName = "group.stress.ai.com"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // MARK: - Keys

    enum Keys {
        static let backgroundStyle = "watchFaceBackgroundStyle"
        static let theme           = "watchFaceTheme"
    }

    // MARK: - Defaults

    static let defaultStyle: WatchFaceBackgroundStyle = .gradient
    static let defaultTheme: WatchFaceTheme = .ripple

    // MARK: - Getters

    static var backgroundStyle: WatchFaceBackgroundStyle {
        let raw = defaults.string(forKey: Keys.backgroundStyle)
        return raw.flatMap { WatchFaceBackgroundStyle(rawValue: $0) } ?? defaultStyle
    }

    static var theme: WatchFaceTheme {
        let raw = defaults.string(forKey: Keys.theme)
        return raw.flatMap { WatchFaceTheme(rawValue: $0) } ?? defaultTheme
    }

    // MARK: - Setters

    /// Persist and broadcast the selection so complications refresh immediately.
    static func setBackgroundStyle(_ style: WatchFaceBackgroundStyle) {
        defaults.set(style.rawValue, forKey: Keys.backgroundStyle)
        reloadComplications()
    }

    static func setTheme(_ theme: WatchFaceTheme) {
        defaults.set(theme.rawValue, forKey: Keys.theme)
        reloadComplications()
    }

    /// Dictionary payload for WatchConnectivity sync (iPhone → Watch push).
    static func connectivityPayload() -> [String: Any] {
        [
            Keys.backgroundStyle: backgroundStyle.rawValue,
            Keys.theme: theme.rawValue
        ]
    }

    /// Apply a WatchConnectivity payload received from the iPhone.
    static func apply(payload: [String: Any]) {
        if let styleRaw = payload[Keys.backgroundStyle] as? String,
           let style = WatchFaceBackgroundStyle(rawValue: styleRaw) {
            defaults.set(style.rawValue, forKey: Keys.backgroundStyle)
        }
        if let themeRaw = payload[Keys.theme] as? String,
           let theme = WatchFaceTheme(rawValue: themeRaw) {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
        reloadComplications()
    }

    // MARK: - Private

    private static func reloadComplications() {
        WidgetCenter.shared.reloadTimelines(ofKind: "CircularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "RectangularComplication")
        WidgetCenter.shared.reloadTimelines(ofKind: "InlineComplication")
    }
}
