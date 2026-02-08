import CloudKit
import Foundation

protocol CloudKitServiceProtocol: Sendable {
    // Sync Status
    var syncStatus: SyncStatus { get }
    var lastSyncDate: Date? { get }

    // Operations
    func saveMeasurement(_ measurement: StressMeasurement) async throws
    func fetchMeasurements(since date: Date?) async throws -> [StressMeasurement]
    func deleteMeasurement(_ measurement: StressMeasurement) async throws
    func sync() async throws

    // Subscriptions
    func setupPushSubscription() async throws

    // Account Status
    func checkAccountStatus() async throws -> CloudKitAccountStatus
}

// MARK: - Sync Status
public enum SyncStatus: Sendable {
    case idle
    case syncing(progress: Double)
    case success
    case error(Error)
    case unavailable(NetworkReason)
}

public enum NetworkReason: Sendable {
    case noInternet
    case iCloudNotSignedIn
    case cloudKitDisabled
    case quotaExceeded
}

public enum CloudKitAccountStatus: Sendable {
    case available
    case noAccount
    case restricted
    case unknown
}

// MARK: - Conflict Resolution
public enum ResolutionStrategy: Sendable {
    case timestamp
    case server
    case client
    case devicePriority
}

public enum MergeDecision: Sendable {
    case keepLocal
    case keepRemote
    case merge
}
