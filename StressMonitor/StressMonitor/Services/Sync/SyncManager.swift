import CloudKit
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class SyncManager {
    // MARK: - Properties

    public private(set) var syncStatus: SyncStatus = .idle
    public private(set) var lastSyncDate: Date?
    public private(set) var syncError: Error?

    private let cloudKitManager: CloudKitManager
    private let syncEngine: CloudKitSyncEngine
    private let conflictResolver: ConflictResolver

    private var syncTask: Task<Void, Never>?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Initialization

    public init(
        cloudKitManager: CloudKitManager,
        conflictResolver: ConflictResolver = ConflictResolver()
    ) {
        self.cloudKitManager = cloudKitManager
        self.conflictResolver = conflictResolver
        self.syncEngine = CloudKitSyncEngine(cloudKitManager: cloudKitManager)

        // Initialize from cloud kit manager state
        self.syncStatus = .idle
        self.lastSyncDate = nil
    }

    public static func create() -> SyncManager {
        return SyncManager(
            cloudKitManager: CloudKitManager(),
            conflictResolver: ConflictResolver()
        )
    }

    // MARK: - Public Sync Methods

    public func sync(localMeasurements: [StressMeasurement]) async throws {
        guard syncTask == nil else {
            throw SyncError.syncInProgress
        }

        syncStatus = .syncing(progress: 0.0)
        syncError = nil

        syncTask = Task {
            do {
                // Check account status first
                let accountStatus = try await cloudKitManager.checkAccountStatus()
                guard accountStatus == .available else {
                    self.syncStatus = .unavailable(.iCloudNotSignedIn)
                    self.syncError = SyncError.accountNotAvailable
                    self.syncTask = nil
                    return
                }

                // Perform bidirectional sync
                let remoteMeasurements = try await syncEngine.sync(localMeasurements: localMeasurements)

                // Resolve any conflicts
                let resolutions = conflictResolver.resolveBatch(
                    localMeasurements: localMeasurements,
                    remoteMeasurements: remoteMeasurements
                )

                // Apply resolutions
                var syncedMeasurements: [StressMeasurement] = []
                for resolution in resolutions {
                    switch resolution.decision {
                    case .keepLocal:
                        syncedMeasurements.append(resolution.local)
                    case .keepRemote:
                        if let remote = resolution.remote {
                            syncedMeasurements.append(remote)
                        }
                    case .merge:
                        syncedMeasurements.append(resolution.winningMeasurement)
                    }
                }

                // Upload merged results if needed
                let needsUpload = resolutions.contains { $0.decision == .merge || $0.decision == .keepLocal }
                if needsUpload {
                    try await cloudKitManager.saveMeasurement(localMeasurements.first!)
                }

                lastSyncDate = Date()
                syncStatus = .success
            } catch {
                syncError = error
                syncStatus = .error(error)
            }

            syncTask = nil
        }

        await syncTask?.value
    }

    public func quickSync() async throws {
        syncStatus = .syncing(progress: 0.0)
        syncError = nil

        do {
            try await cloudKitManager.sync()
            lastSyncDate = Date()
            syncStatus = .success
        } catch {
            syncError = error
            syncStatus = .error(error)
            throw error
        }
    }

    // MARK: - Lifecycle Event Handlers

    public func handleAppWillEnterForeground() async {
        // Trigger sync when app comes to foreground
        try? await quickSync()
    }

    public func handleAppWillResignActive() async {
        // Perform quick sync before going to background
        await beginBackgroundSync()
    }

    public func handleAppDidBecomeActive() async {
        // Cancel background sync and do a fresh sync
        endBackgroundSync()
        try? await quickSync()
    }

    // MARK: - Background Sync

    private func beginBackgroundSync() async {
        guard backgroundTask == .invalid else { return }

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundSync()
        }

        // Perform background sync
        do {
            try await syncEngine.performBackgroundSync()
            lastSyncDate = Date()
        } catch {
            syncError = error
        }

        endBackgroundSync()
    }

    private func endBackgroundSync() {
        guard backgroundTask != .invalid else { return }

        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    // MARK: - Remote Change Handling

    public func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo) != nil else {
            return
        }

        do {
            try await quickSync()
        } catch {
            syncError = error
        }
    }

    // MARK: - Manual Sync Trigger

    public func manualSync() async throws {
        try await sync(localMeasurements: [])
    }

    // MARK: - Status Checks

    public var isSyncing: Bool {
        if case .syncing = syncStatus {
            return true
        }
        return false
    }

    public var syncProgress: Double {
        if case .syncing(let progress) = syncStatus {
            return progress
        }
        return 0.0
    }

    public var canSync: Bool {
        if case .unavailable = syncStatus {
            return false
        }
        return true
    }

    // MARK: - Setup

    public func setup() async throws {
        // Setup push subscription for remote changes
        try await cloudKitManager.setupPushSubscription()

        // Check initial account status
        let accountStatus = try await cloudKitManager.checkAccountStatus()

        if accountStatus != .available {
            syncStatus = .unavailable(.iCloudNotSignedIn)
        }
    }

    // MARK: - Reset

    public func reset() {
        syncTask?.cancel()
        syncTask = nil
        syncStatus = .idle
        syncError = nil
        syncEngine.reset()
    }
}

// MARK: - Sync Errors

public enum SyncError: Error, Sendable {
    case syncInProgress
    case accountNotAvailable
    case networkUnavailable
    case quotaExceeded
    case unknown(Error)

    public var localizedDescription: String {
        switch self {
        case .syncInProgress:
            return "A sync operation is already in progress"
        case .accountNotAvailable:
            return "iCloud account is not available"
        case .networkUnavailable:
            return "Network is not available"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - SyncManager Environment Key

struct SyncManagerKey: EnvironmentKey {
    static let defaultValue: SyncManager? = nil
}

extension EnvironmentValues {
    public var syncManager: SyncManager? {
        get { self[SyncManagerKey.self] }
        set { self[SyncManagerKey.self] = newValue }
    }
}

extension View {
    public func syncManager(_ manager: SyncManager) -> some View {
        environment(\.syncManager, manager)
    }
}
