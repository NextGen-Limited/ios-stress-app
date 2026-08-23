import Foundation

// MARK: - Credit Balance

/// Server-authoritative credit balance from `GET /credits`.
///
/// `remaining` is settable only so `CreditService` can converge it from chat
/// terminal metadata; `total` and `used` are server-owned and never computed
/// client-side.
struct CreditBalance: Codable, Sendable, Equatable {
    let total: Int
    let used: Int
    var remaining: Int
    let planType: PlanType
    /// ISO-8601 timestamp string as delivered by the backend (may be null).
    let freeResetAt: String?

    enum PlanType: String, Codable, Sendable {
        case free
        case premium
    }

    enum CodingKeys: String, CodingKey {
        case total
        case used
        case remaining
        case planType = "plan_type"
        case freeResetAt = "free_reset_at"
    }

    /// Premium plans are unlimited — the backend reports a large sentinel as
    /// the remaining count, which must never be formatted for display.
    var isUnlimited: Bool { planType == .premium }

    var displayDescription: String {
        isUnlimited ? "Unlimited" : "\(remaining) credits"
    }
}
