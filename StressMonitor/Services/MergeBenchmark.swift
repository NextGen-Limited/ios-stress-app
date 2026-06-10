import Foundation
import SwiftData
import CloudKit
import os.log

/// Benchmark utility for measuring merge performance.
///
/// Compares the optimized O(1) merge (compound predicate + fetchLimit)
/// against the naive O(n) scan (no predicate, fetchAll).
///
/// Usage:
///   let results = try await MergeBenchmark.run(context: modelContext, recordCount: 1000)
///   print(results.report)
struct MergeBenchmark {
    
    private static let logger = Logger(subsystem: "com.stressmonitor", category: "Benchmark")
    
    /// Result of a single benchmark run
    struct Result {
        let method: String
        let recordCount: Int
        let duration: TimeInterval
        let fetchCount: Int  // Number of DB fetches performed
        
        var recordsPerSecond: Double {
            guard duration > 0 else { return 0 }
            return Double(recordCount) / duration
        }
        
        var avgDurationPerRecord: TimeInterval {
            guard recordCount > 0 else { return 0 }
            return duration / Double(recordCount)
        }
    }
    
    /// Full benchmark comparing both approaches
    struct BenchmarkResult {
        let optimized: Result
        let naive: Result
        
        var speedupFactor: Double {
            guard naive.duration > 0 else { return 0 }
            return naive.duration / optimized.duration
        }
        
        var report: String {
            """
            ╔═══════════════════════════════════════════════════════════╗
            ║          MergeBenchmark Results (\(optimized.recordCount) records)         ║
            ╠═══════════════════════════════════════════════════════════╣
            ║ OPTIMIZED (compound predicate + fetchLimit=1)            ║
            ║   Duration:    \(String(format: "%.3f", optimized.duration))s                                  ║
            ║   Per record:  \(String(format: "%.4f", optimized.avgDurationPerRecord))s                                  ║
            ║   Throughput:  \(String(format: "%.0f", optimized.recordsPerSecond)) records/sec                          ║
            ╠═══════════════════════════════════════════════════════════╣
            ║ NAIVE (no predicate, fetchAll)                           ║
            ║   Duration:    \(String(format: "%.3f", naive.duration))s                                  ║
            ║   Per record:  \(String(format: "%.4f", naive.avgDurationPerRecord))s                                  ║
            ║   Throughput:  \(String(format: "%.0f", naive.recordsPerSecond)) records/sec                          ║
            ╠═══════════════════════════════════════════════════════════╣
            ║ SPEEDUP: \(String(format: "%.1f", speedupFactor))x faster                                  ║
            ╚═══════════════════════════════════════════════════════════╝
            """
        }
    }
    
    // MARK: - Run Benchmark
    
    /// Run the full benchmark with the specified number of test records.
    ///
    /// - Parameters:
    ///   - context: SwiftData model context (should be empty or pre-populated)
    ///   - recordCount: Number of records to use for benchmarking
    /// - Returns: BenchmarkResult comparing optimized vs naive
    @MainActor
    static func run(context: ModelContext, recordCount: Int = 1000) throws -> BenchmarkResult {
        logger.info("Starting benchmark with \(recordCount) records")
        
        // 1. Seed the database with test records
        let seedDuration = seedDatabase(context: context, count: recordCount)
        logger.info("Seeded \(recordCount) records in \(seedDuration)s")
        
        // 2. Generate remote records to merge (simulating CloudKit sync)
        let remoteRecords = generateRemoteRecords(count: recordCount / 10) // 10% new records
        
        // 3. Run optimized merge
        let optimizedResult = try benchmarkOptimizedMerge(
            records: remoteRecords,
            context: context
        )
        
        // 4. Run naive merge
        let naiveResult = try benchmarkNaiveMerge(
            records: remoteRecords,
            context: context
        )
        
        let result = BenchmarkResult(optimized: optimizedResult, naive: naiveResult)
        logger.info("Benchmark complete: \(result.speedupFactor)x speedup")
        print(result.report)
        
        return result
    }
    
    // MARK: - Optimized Merge (O(1) per record)
    
    private static func benchmarkOptimizedMerge(
        records: [CKRecord],
        context: ModelContext
    ) throws -> Result {
        let start = Date()
        var fetchCount = 0
        
        for record in records {
            guard let timestamp = record["timestamp"] as? Date,
                  let deviceID = record["deviceID"] as? String else { continue }
            
            // Compound predicate + fetchLimit = O(1)
            let windowStart = timestamp.addingTimeInterval(-60)
            let windowEnd = timestamp.addingTimeInterval(60)
            
            let predicate = #Predicate<StressMeasurement> { measurement in
                measurement.timestamp >= windowStart &&
                measurement.timestamp <= windowEnd &&
                measurement.deviceID == deviceID
            }
            
            var descriptor = FetchDescriptor<StressMeasurement>(
                predicate: predicate
            )
            descriptor.fetchLimit = 1
            
            let existing = try context.fetch(descriptor)
            fetchCount += 1
            
            if existing.isEmpty {
                // Would insert in real code
                _ = StressMeasurement(
                    id: UUID(),
                    timestamp: timestamp,
                    deviceID: deviceID,
                    stressLevel: record["stressLevel"] as? Double ?? 0,
                    hrv: record["hrv"] as? Double ?? 0,
                    heartRate: record["heartRate"] as? Double ?? 0,
                    source: "benchmark"
                )
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        
        return Result(
            method: "Optimized (predicate + fetchLimit)",
            recordCount: records.count,
            duration: duration,
            fetchCount: fetchCount
        )
    }
    
    // MARK: - Naive Merge (O(n) per record)
    
    private static func benchmarkNaiveMerge(
        records: [CKRecord],
        context: ModelContext
    ) throws -> Result {
        let start = Date()
        var fetchCount = 0
        
        for record in records {
            guard let timestamp = record["timestamp"] as? Date,
                  let deviceID = record["deviceID"] as? String else { continue }
            
            // NAIVE: No predicate, fetch all, then filter in memory
            let descriptor = FetchDescriptor<StressMeasurement>()
            let allMeasurements = try context.fetch(descriptor)
            fetchCount += 1
            
            // Linear scan to find match
            let match = allMeasurements.first { measurement in
                abs(measurement.timestamp.timeIntervalSince(timestamp)) < 60 &&
                measurement.deviceID == deviceID
            }
            
            if match == nil {
                _ = StressMeasurement(
                    id: UUID(),
                    timestamp: timestamp,
                    deviceID: deviceID,
                    stressLevel: record["stressLevel"] as? Double ?? 0,
                    hrv: record["hrv"] as? Double ?? 0,
                    heartRate: record["heartRate"] as? Double ?? 0,
                    source: "benchmark"
                )
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        
        return Result(
            method: "Naive (fetchAll + linear scan)",
            recordCount: records.count,
            duration: duration,
            fetchCount: fetchCount
        )
    }
    
    // MARK: - Helpers
    
    /// Seed the database with test data
    @discardableResult
    private static func seedDatabase(context: ModelContext, count: Int) -> TimeInterval {
        let start = Date()
        
        for i in 0..<count {
            let measurement = StressMeasurement(
                timestamp: Date(timeIntervalSince1970: 1700000000 + Double(i) * 60),
                deviceID: "device-\(i % 5)",  // 5 simulated devices
                stressLevel: Double.random(in: 0...1),
                hrv: Double.random(in: 20...100),
                heartRate: Double.random(in: 55...100),
                source: "benchmark"
            )
            context.insert(measurement)
        }
        
        try? context.save()
        return Date().timeIntervalSince(start)
    }
    
    /// Generate fake remote CKRecords for merge testing
    private static func generateRemoteRecords(count: Int) -> [CKRecord] {
        var records: [CKRecord] = []
        
        for i in 0..<count {
            let recordID = CKRecord.ID(recordName: UUID().uuidString)
            let record = CKRecord(recordType: StressMeasurement.recordType, recordID: recordID)
            
            // Mix of timestamps: some match existing (duplicates), some are new
            let isDuplicate = i % 3 == 0
            let baseTime: TimeInterval = isDuplicate
                ? 1700000000 + Double(i * 3) * 60  // Match existing
                : 1700000000 + Double(count + i) * 60  // New timestamps
            
            record["timestamp"] = Date(timeIntervalSince1970: baseTime)
            record["deviceID"] = "device-\(i % 5)"
            record["stressLevel"] = Double.random(in: 0...1)
            record["hrv"] = Double.random(in: 20...100)
            record["heartRate"] = Double.random(in: 55...100)
            record["source"] = "remote"
            
            records.append(record)
        }
        
        return records
    }
}
