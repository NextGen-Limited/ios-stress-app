import Foundation
import Observation

// MARK: - Credit Service

/// Owns the user's server-side credit balance for display.
///
/// The backend is the sole authority: state only converges from server
/// responses (GET /credits, chat terminal metadata, redemption) — never from
/// client-side arithmetic, which breaks for premium (unlimited sentinel) and
/// concurrent sends.
@MainActor
@Observable
final class CreditService: CreditServiceProtocol {

    private(set) var balance: CreditBalance?

    private let apiClient: StressAPIClient

    init(
        apiClient: StressAPIClient? = nil,
        balance: CreditBalance? = nil
    ) {
        self.apiClient = apiClient ?? StressAPIClient()
        self.balance = balance
    }

    func refreshBalance() async throws {
        balance = try await apiClient.getBalance()
    }

    func apply(_ balance: CreditBalance) {
        self.balance = balance
    }

    func apply(creditsRemaining: Int) {
        guard var updated = balance else { return }
        updated.remaining = creditsRemaining
        balance = updated
    }
}
