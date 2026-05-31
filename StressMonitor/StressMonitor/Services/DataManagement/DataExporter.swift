import Foundation
import UniformTypeIdentifiers

protocol DataExporter: Sendable {
    func exportToCSV(measurements: [StressMeasurement]) async throws -> URL
    func exportToJSON(measurements: [StressMeasurement], baseline: PersonalBaseline) async throws -> URL
    func generateReport(startDate: Date, endDate: Date) async throws -> URL
}
