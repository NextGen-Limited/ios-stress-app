import Foundation
import Testing
@testable import StressMonitor

/// Pins D-03: StressAPIConfig resolves STRESS_API_BASE_URL via the 3-tier
/// chain (Info.plist → environment → UserDefaults → fallback) with documented
/// precedence, and exposes endpoint URLs derived from the resolved base.
/// The `resolveBaseURL` helper is the testable seam — the static `baseURL`
/// captures the resolved value at type-load time and cannot be re-resolved,
/// so the precedence table is asserted against the helper directly.
struct StressAPIConfigTests {

    // MARK: - 3-tier resolution precedence (D-03)

    @Test("Info.plist value wins over environment, UserDefaults, and fallback")
    func infoPlistValueWins() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: "https://info.test",
            environmentValue: "https://env.test",
            userDefaultsValue: "https://defaults.test",
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://info.test")
    }

    @Test("environment wins when Info.plist value is nil")
    func environmentWinsWhenNoInfoPlist() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: nil,
            environmentValue: "https://env.test",
            userDefaultsValue: "https://defaults.test",
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://env.test")
    }

    @Test("UserDefaults wins when Info.plist and environment are nil")
    func userDefaultsWinsWhenNoInfoPlistOrEnv() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: nil,
            environmentValue: nil,
            userDefaultsValue: "https://defaults.test",
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://defaults.test")
    }

    @Test("fallback wins when no other tier provides a value")
    func fallbackWinsWhenAllHigherTiersNil() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: nil,
            environmentValue: nil,
            userDefaultsValue: nil,
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://fallback.test")
    }

    @Test("empty Info.plist value falls through to environment")
    func emptyInfoPlistFallsThrough() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: "",
            environmentValue: "https://env.test",
            userDefaultsValue: nil,
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://env.test")
    }

    @Test("Xcode build placeholder $(...) in Info.plist falls through to environment")
    func placeholderInfoPlistFallsThrough() {
        let url = StressAPIConfig.resolveBaseURL(
            infoPlistValue: "$(STRESS_API_BASE_URL)",
            environmentValue: "https://env.test",
            userDefaultsValue: nil,
            fallback: "https://fallback.test"
        )
        #expect(url.absoluteString == "https://env.test")
    }

    // MARK: - Resolved endpoints

    @Test("baseURL resolves to a URL with a scheme and host")
    func baseURLResolves() {
        #expect(StressAPIConfig.baseURL.scheme != nil)
        #expect(StressAPIConfig.baseURL.host?.isEmpty == false)
    }

    @Test("healthURL appends /health to baseURL")
    func healthURLIsBasePlusHealth() {
        let base = StressAPIConfig.baseURL.absoluteString
        #expect(StressAPIConfig.healthURL.absoluteString == base + "/health")
    }

    @Test("chatURL appends /chat to baseURL")
    func chatURLIsBasePlusChat() {
        let base = StressAPIConfig.baseURL.absoluteString
        #expect(StressAPIConfig.chatURL.absoluteString == base + "/chat")
    }

    @Test("isConfigured is always true because the fallback URL is valid")
    func isConfiguredAlwaysTrue() {
        #expect(StressAPIConfig.isConfigured == true)
    }
}
