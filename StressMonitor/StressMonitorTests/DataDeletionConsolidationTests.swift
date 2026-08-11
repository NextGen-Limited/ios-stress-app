import Foundation
import CloudKit
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

@Suite("Data Deleter Consolidation")
struct DataDeleterConsolidationTests {

    @Test("clearCredentialsAndSharedCaches removes Supabase refresh token from Keychain")
    func factoryResetClearsRefreshToken() throws {
        let service = "com.stressmonitor.app"
        let account = "supabaseRefreshToken"

        try KeychainService.save("test-refresh-token", service: service, account: account)

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
}

@Suite("Export Protection")
struct ExportProtectionTests {

    @Test("validateExportSize rejects record count exceeding cap")
    func rejectsRecordCountOverCap() throws {
        let overageRecords = Array(
            repeating: StressMeasurement(timestamp: Date(), stressLevel: 50, hrv: 40),
            count: DataExportViewModel.maxExportRecords + 1
        )

        #expect(throws: ExportError.self) {
            try DataExportViewModel.validateExportSize(recordCount: overageRecords.count, format: .csv)
        }
    }

    @Test("validateExportSize accepts record count within cap")
    func acceptsRecordCountWithinCap() throws {
        #expect(throws: Never.self) {
            try DataExportViewModel.validateExportSize(recordCount: 100, format: .csv)
        }
    }

    @Test("cleanupExportTempFile removes stress_export file from caches")
    func removesTempFileOnShareDismiss() throws {
        let cachesDir = try FileManager.default.url(
            for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        )
        let tempFile = cachesDir.appendingPathComponent("stress_export_test_cleanup.json")
        try "{\"test\":1}".write(to: tempFile, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: tempFile.path))

        DataExportViewModel.cleanupExportTempFile(at: tempFile)

        #expect(!FileManager.default.fileExists(atPath: tempFile.path))
    }
}

@Suite("CloudKit Encryption")
struct CloudKitEncryptionTests {

    @Test("health fields round-trip through encryptedValues and are absent from plaintext keys")
    func healthFieldsRoundTripThroughEncryptedValues() throws {
        let record = CKRecord(recordType: "CD_StressMeasurement")
        let stressLevel: Double = 62.5
        let hrv: Double = 48.0
        let restingHeartRate: Double = 72.0

        record.encryptedValues["stressLevel"] = stressLevel
        record.encryptedValues["hrv"] = hrv
        record.encryptedValues["restingHeartRate"] = restingHeartRate

        let readStressLevel = try #require(record.encryptedValues["stressLevel"] as? Double)
        let readHRV = try #require(record.encryptedValues["hrv"] as? Double)
        let readHR = try #require(record.encryptedValues["restingHeartRate"] as? Double)

        #expect(readStressLevel == stressLevel)
        #expect(readHRV == hrv)
        #expect(readHR == restingHeartRate)

        #expect(record["stressLevel"] == nil)
        #expect(record["hrv"] == nil)
        #expect(record["restingHeartRate"] == nil)
    }
}
