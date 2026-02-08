import Foundation
import os.log

// MARK: - Observer Isolated

/// Helper class for thread-safe state observation in @MainActor classes
@Observable
public class ObserverIsolated<T>: Sendable {
    public var wrappedValue: T

    public init(_ value: T) {
        self.wrappedValue = value
    }
}

// MARK: - Logger

public struct DataManagementLogger {
    public static let `default` = DataManagementLogger()

    public func log(_ message: String, category: String = "DataManagement") {
        #if DEBUG
        print("[\(category)] \(message)")
        #endif
        os_log("%{public}@", log: .default, type: .info, message)
    }
}
