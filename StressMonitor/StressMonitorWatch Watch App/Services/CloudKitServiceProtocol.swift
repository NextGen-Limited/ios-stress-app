import CloudKit
import Foundation

protocol CloudKitServiceProtocol: Sendable {
    var syncStatus: SyncStatus { get }
    var lastSyncDate: Date? { get }

    func saveMeasurement(_ measurement: WatchStressMeasurement) async throws
    func fetchMeasurements(since date: Date?) async throws -> [WatchStressMeasurement]
    func deleteMeasurement(_ measurement: WatchStressMeasurement) async throws
    func sync() async throws

    func setupPushSubscription() async throws
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
enum ResolutionStrategy: Sendable {
    case timestamp
    case server
    case client
    case devicePriority
}

enum MergeDecision: Sendable {
    case keepLocal
    case keepRemote
    case merge
}
