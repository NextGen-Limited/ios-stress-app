import Foundation
import SwiftData

@MainActor
final class StressRepository: StressRepositoryProtocol {

    private let modelContext: ModelContext
    private nonisolated let baselineCalculator: BaselineCalculator

    private var cachedBaseline: PersonalBaseline?

    init(modelContext: ModelContext, baselineCalculator: BaselineCalculator? = nil) {
        self.modelContext = modelContext
        self.baselineCalculator = baselineCalculator ?? BaselineCalculator()
    }

    func save(_ measurement: StressMeasurement) async throws {
        modelContext.insert(measurement)
        try modelContext.save()
    }

    func fetchRecent(limit: Int) async throws -> [StressMeasurement] {
        var descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func fetchAll() async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func deleteOlderThan(_ date: Date) async throws {
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp < date }
        )

        do {
            let oldMeasurements = try modelContext.fetch(descriptor)
            for measurement in oldMeasurements {
                modelContext.delete(measurement)
            }
            try modelContext.save()
        }
    }

    func getBaseline() async throws -> PersonalBaseline {
        if let cached = cachedBaseline {
            return cached
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp >= thirtyDaysAgo }
        )

        let measurements = try modelContext.fetch(descriptor)

        let baseline: PersonalBaseline
        if measurements.isEmpty {
            baseline = PersonalBaseline()
        } else {
            let hrvMeasurements = measurements.map { HRVMeasurement(value: $0.hrv, timestamp: $0.timestamp) }
            baseline = try await baselineCalculator.calculateBaseline(from: hrvMeasurements)
        }

        cachedBaseline = baseline
        return baseline
    }

    func updateBaseline(_ baseline: PersonalBaseline) async throws {
        cachedBaseline = baseline
    }

    func fetchMeasurements(from: Date, to: Date) async throws -> [StressMeasurement] {
        let descriptor = FetchDescriptor<StressMeasurement>(
            predicate: #Predicate<StressMeasurement> { $0.timestamp >= from && $0.timestamp <= to },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    func delete(_ measurement: StressMeasurement) async throws {
        modelContext.delete(measurement)
        try modelContext.save()
    }

    func fetchAverageHRV(hours: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        let measurements = try await fetchMeasurements(from: startDate, to: Date())

        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
    }

    func fetchAverageHRV(days: Int) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let measurements = try await fetchMeasurements(from: startDate, to: Date())

        guard !measurements.isEmpty else { return 0 }
        return measurements.map { $0.hrv }.reduce(0, +) / Double(measurements.count)
    }

    func deleteAllMeasurements() async throws {
        let descriptor = FetchDescriptor<StressMeasurement>()
        let allMeasurements = try modelContext.fetch(descriptor)

        for measurement in allMeasurements {
            modelContext.delete(measurement)
        }
        try modelContext.save()
        cachedBaseline = nil
    }
}
