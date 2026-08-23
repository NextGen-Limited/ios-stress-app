import Foundation

// MARK: - Server Quick Action

/// A quick-action chip suggested by `GET /quick-actions`.
///
/// `type` is `"exercise"`, `"technique"`, `"tips"`, or `"conversation"`
/// server-side, but is kept as a plain `String` because iOS never branches
/// on it — unknown values from a newer backend must decode without throwing
/// rather than fail the whole suggestions fetch.
struct ServerQuickAction: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let title: String
    let type: String
}
