import Foundation

@preconcurrency import SwiftData

protocol StressRepositoryProtocol: Sendable {
    func save(_ measurement: StressMeasurement) async throws
    func fetchRecent(limit: Int) async throws -> [StressMeasurement]
    func fetchAll() async throws -> [StressMeasurement]
    func deleteOlderThan(_ date: Date) async throws
    func getBaseline() async throws -> PersonalBaseline
    func updateBaseline(_ baseline: PersonalBaseline) async throws
    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement]
    func delete(_ measurement: StressMeasurement) async throws
    func fetchAverageHRV(hours: Int) async throws -> Double
    func fetchAverageHRV(days: Int) async throws -> Double
    func deleteAllMeasurements() async throws
}
