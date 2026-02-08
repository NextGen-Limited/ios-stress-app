import Foundation
import UIKit

public final class ConflictResolver {
    // MARK: - Properties

    public let strategy: ResolutionStrategy
    private let deviceType: DeviceType

    // MARK: - Initialization

    public init(strategy: ResolutionStrategy = .devicePriority) {
        self.strategy = strategy
        self.deviceType = Self.determineDeviceType()
    }

    // MARK: - Device Type Detection

    private static func determineDeviceType() -> DeviceType {
        #if os(watchOS)
        return .watch
        #elseif os(iOS)
        #if targetEnvironment(macCatalyst)
        return .iPad
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
        #endif
        #else
        return .iPhone
        #endif
    }

    // MARK: - Public Resolution Methods

    public func resolve(
        local: StressMeasurement,
        remote: StressMeasurement,
        remoteDeviceID: String? = nil
    ) -> MergeDecision {
        switch strategy {
        case .timestamp:
            return resolveByTimestamp(local: local, remote: remote)
        case .server:
            return .keepRemote
        case .client:
            return .keepLocal
        case .devicePriority:
            return resolveByDevicePriority(
                local: local,
                remote: remote,
                remoteDeviceID: remoteDeviceID
            )
        }
    }

    // MARK: - Timestamp-Based Resolution

    private func resolveByTimestamp(local: StressMeasurement, remote: StressMeasurement) -> MergeDecision {
        let timeDifference = abs(local.timestamp.timeIntervalSince(remote.timestamp))

        // Same timestamp - use merge logic
        if timeDifference < 1.0 {
            return mergeMeasurements(local: local, remote: remote)
        }

        return local.timestamp > remote.timestamp ? .keepLocal : .keepRemote
    }

    // MARK: - Device Priority Resolution

    private func resolveByDevicePriority(
        local: StressMeasurement,
        remote: StressMeasurement,
        remoteDeviceID: String?
    ) -> MergeDecision {
        guard let remoteDeviceID = remoteDeviceID else {
            return resolveByTimestamp(local: local, remote: remote)
        }

        let remoteDeviceType = DeviceType.from(deviceID: remoteDeviceID)
        let comparison = deviceType.compareTo(remoteDeviceType)

        switch comparison {
        case .higher:
            return .keepLocal
        case .lower:
            return .keepRemote
        case .equal:
            return resolveByTimestamp(local: local, remote: remote)
        }
    }

    // MARK: - Merge Logic

    private func mergeMeasurements(local: StressMeasurement, remote: StressMeasurement) -> MergeDecision {
        // If same timestamp and similar values, keep either
        let timeDifference = abs(local.timestamp.timeIntervalSince(remote.timestamp))
        guard timeDifference < 1.0 else {
            return resolveByTimestamp(local: local, remote: remote)
        }

        // Merge by taking max values for each field
        let merged = StressMeasurement(
            timestamp: max(local.timestamp, remote.timestamp),
            stressLevel: max(local.stressLevel, remote.stressLevel),
            hrv: max(local.hrv, remote.hrv),
            restingHeartRate: max(local.restingHeartRate, remote.restingHeartRate),
            confidences: mergeConfidences(local: local.confidences, remote: remote.confidences)
        )

        // Use the category from the measurement with higher stress
        merged.categoryRawValue = local.stressLevel >= remote.stressLevel
            ? local.categoryRawValue
            : remote.categoryRawValue

        // Store merged result
        _ = merged

        return .merge
    }

    private func mergeConfidences(local: [Double]?, remote: [Double]?) -> [Double]? {
        guard let local = local, let remote = remote else {
            return local ?? remote
        }

        let maxLength = max(local.count, remote.count)
        var merged: [Double] = []

        for i in 0..<maxLength {
            let localValue = i < local.count ? local[i] : 0
            let remoteValue = i < remote.count ? remote[i] : 0
            merged.append(max(localValue, remoteValue))
        }

        return merged
    }

    // MARK: - Deleted Record Handling

    public func resolveDeleted(local: StressMeasurement?, remote: StressMeasurement?) -> MergeDecision {
        switch (local, remote) {
        case (nil, nil):
            return .keepLocal
        case (nil, _?):
            return .keepRemote
        case (_?, nil):
            return .keepLocal
        case let (local?, remote?):
            return resolve(local: local, remote: remote, remoteDeviceID: nil)
        }
    }

    // MARK: - Batch Conflict Resolution

    public func resolveBatch(
        localMeasurements: [StressMeasurement],
        remoteMeasurements: [StressMeasurement]
    ) -> [ConflictResolution] {
        var resolutions: [ConflictResolution] = []

        // Create lookup by timestamp for O(n) matching
        let remoteDict = Dictionary(grouping: remoteMeasurements) { measurement in
            Int(measurement.timestamp.timeIntervalSince1970)
        }.compactMapValues { $0.first }

        for local in localMeasurements {
            let timestampKey = Int(local.timestamp.timeIntervalSince1970)
            if let remote = remoteDict[timestampKey] {
                let decision = resolve(local: local, remote: remote)
                resolutions.append(ConflictResolution(
                    local: local,
                    remote: remote,
                    decision: decision
                ))
            } else {
                // No conflict - local only
                resolutions.append(ConflictResolution(
                    local: local,
                    remote: nil,
                    decision: .keepLocal
                ))
            }
        }

        return resolutions
    }
}

// MARK: - Device Type

public enum DeviceType: Int, Sendable {
    case iPhone = 3
    case iPad = 2
    case watch = 1

    func compareTo(_ other: DeviceType) -> DeviceComparisonResult {
        if rawValue > other.rawValue {
            return .higher
        } else if rawValue < other.rawValue {
            return .lower
        } else {
            return .equal
        }
    }

    static func from(deviceID: String) -> DeviceType {
        // Extract device type from device ID prefix
        if deviceID.hasPrefix("watch-") {
            return .watch
        } else if deviceID.hasPrefix("ipad-") {
            return .iPad
        } else {
            return .iPhone
        }
    }
}

public enum DeviceComparisonResult {
    case higher
    case lower
    case equal
}

// MARK: - Conflict Resolution Result

public struct ConflictResolution: Sendable {
    public let local: StressMeasurement
    public let remote: StressMeasurement?
    public let decision: MergeDecision

    public init(local: StressMeasurement, remote: StressMeasurement?, decision: MergeDecision) {
        self.local = local
        self.remote = remote
        self.decision = decision
    }

    public var hasConflict: Bool {
        return remote != nil
    }

    public var winningMeasurement: StressMeasurement {
        switch decision {
        case .keepLocal:
            return local
        case .keepRemote:
            return remote ?? local
        case .merge:
            return local
        }
    }
}

// MARK: - Merge Decision Extension

extension MergeDecision {
    public var shouldKeepLocal: Bool {
        if case .keepLocal = self { return true }
        return false
    }

    public var shouldKeepRemote: Bool {
        if case .keepRemote = self { return true }
        return false
    }

    public var shouldMerge: Bool {
        if case .merge = self { return true }
        return false
    }
}
