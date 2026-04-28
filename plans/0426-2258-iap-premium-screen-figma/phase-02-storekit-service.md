# Phase 2: StoreKit Service Protocol + Subscription Model

**Priority:** High | **Effort:** Small | **Status:** Pending

## Overview
Create the data model for subscription plans and a StoreKit service protocol with mock implementation. No real StoreKit yet — protocol-only architecture for future integration.

## Key Insights
- Project uses protocol-based DI (see `HealthKitServiceProtocol`, `StressAlgorithmServiceProtocol`)
- Figma shows 2 plans: Annual ($14.99/mo, save 25%) and Monthly ($19.99/mo)
- **Pricing fix**: Monthly $19.99, Annual $14.99/mo ($179.88/yr) for the "Save 25%" to make sense

<!-- Red Team Fix: Finding #3 — Single source of truth for premium state -->
<!-- Red Team Fix: Finding #4 — No mock-as-default in release builds -->
**CRITICAL: Premium state ownership**
- Create a single `PremiumState` observable that owns `isPremiumUser`
- All views and VMs read from this single source — no scattered `@AppStorage` reads
- `MockStoreKitService` must NOT be the default parameter — use `#if DEBUG` factory

## Related Code Files
- **Create:** `StressMonitor/StressMonitor/Models/SubscriptionPlan.swift`
- **Create:** `StressMonitor/StressMonitor/Services/StoreKit/StoreKitServiceProtocol.swift`
- **Create:** `StressMonitor/StressMonitor/Services/StoreKit/MockStoreKitService.swift`
- **Create:** `StressMonitor/StressMonitor/ViewModels/PremiumViewModel.swift`

## Implementation Steps

### 2.1 Create SubscriptionPlan Model
File: `Models/SubscriptionPlan.swift`

```swift
import Foundation

enum SubscriptionPeriod: String, CaseIterable {
    case annual
    case monthly
}

struct SubscriptionPlan: Identifiable {
    let id: SubscriptionPeriod
    let displayName: String
    let pricePerMonth: Decimal
    let pricePerPeriod: Decimal
    let period: SubscriptionPeriod
    let savingsPercent: Int?
    let isBestValue: Bool
    let subtitle: String?

    var priceDisplay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: pricePerMonth as NSDecimalNumber) ?? "$0.00"
    }

    var savingsDisplay: String? {
        guard let savings = savingsPercent, savings > 0 else { return nil }
        return "Save \(savings)%"
    }

    static let defaultPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: .annual,
            displayName: "Annually",
            pricePerMonth: 14.99,
            pricePerPeriod: 179.88,
            period: .annual,
            savingsPercent: 25,
            isBestValue: true,
            subtitle: "Best value option"
        ),
        SubscriptionPlan(
            id: .monthly,
            displayName: "Monthly",
            pricePerMonth: 19.99,
            pricePerPeriod: 19.99,
            period: .monthly,
            savingsPercent: nil,
            isBestValue: false,
            subtitle: nil
        )
    ]
}
```

### 2.2 Create StoreKit Service Protocol
File: `Services/StoreKit/StoreKitServiceProtocol.swift`

```swift
import Foundation

enum StoreKitError: LocalizedError {
    case purchaseFailed
    case purchaseCancelled
    case restoreFailed
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .purchaseFailed: return "Purchase failed. Please try again."
        case .purchaseCancelled: return "Purchase cancelled."
        case .restoreFailed: return "Could not restore purchases."
        case .productNotFound: return "Product not found."
        }
    }
}

protocol StoreKitServiceProtocol {
    var availablePlans: [SubscriptionPlan] { get async }
    var isPremiumUser: Bool { get async }
    func purchase(_ plan: SubscriptionPlan) async throws
    func restorePurchases() async throws
    func fetchPurchaseHistory() async -> [String]
}
```

### 2.3 Create Premium State Manager (Single Source of Truth)
<!-- Red Team Fix: Finding #3 — One owner for isPremiumUser, no scattered @AppStorage -->
File: `Services/StoreKit/PremiumState.swift`

```swift
import Foundation
import SwiftUI

/// Single source of truth for premium status.
/// All views read from here. Eliminates scattered @AppStorage reads.
@Observable
final class PremiumState {
    static let shared = PremiumState()

    private let defaults = UserDefaults.standard
    private let key = "isPremiumUser"

    var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: key) }
    }

    private init() {
        isPremiumUser = defaults.bool(forKey: key)
    }
}
```

### 2.4 Create Mock StoreKit Service
<!-- Red Team Fix: Finding #4 — Mock must never be default in release -->
File: `Services/StoreKit/MockStoreKitService.swift`

```swift
import Foundation

#if DEBUG
final class MockStoreKitService: StoreKitServiceProtocol {
    private let premiumState: PremiumState

    let availablePlans: [SubscriptionPlan] = SubscriptionPlan.defaultPlans

    var isPremiumUser: Bool { premiumState.isPremiumUser }

    init(premiumState: PremiumState = .shared) {
        self.premiumState = premiumState
    }

    func purchase(_ plan: SubscriptionPlan) async throws {
        try await Task.sleep(for: .seconds(1))
        premiumState.isPremiumUser = true
    }

    func restorePurchases() async throws {
        try await Task.sleep(for: .seconds(1))
        premiumState.isPremiumUser = true
    }

    func fetchPurchaseHistory() async -> [String] {
        return []
    }
}
#endif
```

### 2.5 Create PremiumViewModel
<!-- Red Team Fix: Finding #5 — Plans come from service, not hardcoded -->
<!-- Red Team Fix: Finding #8 — Guard returns with error, not silent -->
File: `ViewModels/PremiumViewModel.swift`

```swift
import Foundation
import SwiftUI

@Observable
final class PremiumViewModel {
    let storeKit: StoreKitServiceProtocol
    let premiumState: PremiumState

    var selectedPlan: SubscriptionPeriod = .annual
    var plans: [SubscriptionPlan] = []
    var isLoading = false
    var showError = false
    var errorMessage: String?
    var showSuccess = false

    // NO default parameter — caller must explicitly provide service
    init(storeKit: StoreKitServiceProtocol, premiumState: PremiumState = .shared) {
        self.storeKit = storeKit
        self.premiumState = premiumState
    }

    var selectedPlanDetails: SubscriptionPlan? {
        plans.first { $0.period == selectedPlan }
    }

    func loadInitialData() async {
        plans = await storeKit.availablePlans
    }

    func purchaseSelectedPlan() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let plan = selectedPlanDetails else {
                errorMessage = "Plan not available. Please try again."
                showError = true
                return
            }
            try await storeKit.purchase(plan)
            premiumState.isPremiumUser = true
            showSuccess = true
        } catch StoreKitError.purchaseCancelled {
            // User cancelled — silent, no error
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await storeKit.restorePurchases()
            if premiumState.isPremiumUser { showSuccess = true }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}
```

## Success Criteria
- [ ] `SubscriptionPlan` model with correct pricing math
- [ ] `StoreKitServiceProtocol` defines purchase/restore/history
- [ ] `MockStoreKitService` uses `@AppStorage("isPremiumUser")` for persistence
- [ ] `PremiumViewModel` handles selection + purchase flow
- [ ] All files compile without errors
- [ ] Each file under 100 lines

## Risk Assessment
- **Low risk**: All new files, no existing code modified
- **@AppStorage in service**: May need to use UserDefaults directly — decide during implementation
