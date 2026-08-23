import Foundation

// MARK: - Credit Service Protocol

/// Read-side seam over the server credit balance so views and tests can
/// substitute a double without a live backend. The backend is the sole
/// authority; conformers only cache and converge display state.
@MainActor
protocol CreditServiceProtocol: AnyObject {
    /// Last converged balance, or nil before the first successful fetch.
    var balance: CreditBalance? { get }

    /// Fetches the authoritative balance from `GET /credits`.
    func refreshBalance() async throws

    /// Replaces the cached balance wholesale (GET /credits, redemption).
    func apply(_ balance: CreditBalance)

    /// Converges `remaining` from a chat terminal-metadata event.
    func apply(creditsRemaining: Int)
}
