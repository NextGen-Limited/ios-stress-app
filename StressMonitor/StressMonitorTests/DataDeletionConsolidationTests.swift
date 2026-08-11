import Foundation
import Security
import Testing
@testable import StressMonitor

@Suite("Delete All Credential Clearance")
struct DeleteAllCredentialClearanceTests {

    @Test("clearCredentialsAndSharedCaches removes Supabase JWT from Keychain")
    func clearsSupabaseJWTFromKeychain() throws {
        let service = "com.stressmonitor.app"
        let account = "supabaseAccessToken"

        try KeychainService.save("test-jwt", service: service, account: account)

        DataDeleterService.clearCredentialsAndSharedCaches()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        #expect(status == errSecItemNotFound)
    }

    @Test("clearCredentialsAndSharedCaches removes App Group widget cache")
    func clearsAppGroupWidgetCache() throws {
        let suiteID = WidgetConstants.appGroupID
        let testKey = "latest_stress_level"

        guard let defaults = UserDefaults(suiteName: suiteID) else {
            Issue.record("Could not create UserDefaults for suite \(suiteID)")
            return
        }
        defaults.set(72.5, forKey: testKey)

        DataDeleterService.clearCredentialsAndSharedCaches()

        let snapshot = UserDefaults(suiteName: suiteID)?.dictionaryRepresentation()
        #expect(snapshot?[testKey] == nil)
    }
}
