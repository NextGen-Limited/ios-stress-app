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

// MARK: - Delete Error
enum DeletionError: Error {
    case repositoryError(Error)
    case cloudKitError(Error)
    case unauthorizedAccess
    case operationCancelled
}
