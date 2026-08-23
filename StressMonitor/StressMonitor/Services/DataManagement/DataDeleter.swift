import Foundation
import SwiftData

@preconcurrency import SwiftData

@MainActor
protocol DataDeleter: Sendable {
    func deleteAllMeasurements(confirmation: (() async -> Bool)?) async throws
    func deleteMeasurements(before date: Date, confirmation: (() async -> Bool)?) async throws
    func deleteMeasurements(in range: ClosedRange<Date>, confirmation: (() async -> Bool)?) async throws
    func resetCloudKitData(confirmation: (() async -> Bool)?) async throws
    func performFactoryReset(confirmation: (() async -> Bool)?) async throws
}

// Default implementation for convenience
extension DataDeleter {
    func deleteAllMeasurements() async throws {
        try await deleteAllMeasurements(confirmation: nil)
    }

    func deleteMeasurements(before date: Date) async throws {
        try await deleteMeasurements(before: date, confirmation: nil)
    }

    func deleteMeasurements(in range: ClosedRange<Date>) async throws {
        try await deleteMeasurements(in: range, confirmation: nil)
    }

    func resetCloudKitData() async throws {
        try await resetCloudKitData(confirmation: nil)
    }

    func performFactoryReset() async throws {
        try await performFactoryReset(confirmation: nil)
    }
}

// MARK: - Server Session Wiping

/// Narrow seam over the sessions API so `DataDeleterService`'s factory-reset
/// wipe loop is unit-testable without a live network (derived-SES-03).
/// `StressAPIClient` conforms; tests substitute a fake.
protocol ServerSessionWiping: Sendable {
    func listSessions(limit: Int, offset: Int) async throws -> [ChatSession]
    func deleteSession(id: UUID) async throws
}

// MARK: - Delete Error
enum DeletionError: LocalizedError {
    case repositoryError(Error)
    case cloudKitError(Error)
    case serverSessionError(Error)
    case unauthorizedAccess
    case operationCancelled

    var errorDescription: String? {
        switch self {
        case .repositoryError(let error):
            return error.localizedDescription
        case .cloudKitError(let error):
            return error.localizedDescription
        case .serverSessionError(let error):
            return error.localizedDescription
        case .unauthorizedAccess:
            return "Unauthorized access to data"
        case .operationCancelled:
            return "Operation was cancelled"
        }
    }
}
