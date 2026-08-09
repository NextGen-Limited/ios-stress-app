import Foundation
import Testing
@testable import StressMonitor

struct WidgetDataStateTests {
    @Test("nil timestamp resolves to empty")
    func nilTimestampResolvesToEmpty() {
        let now = Date()
        #expect(WidgetDataState.resolve(latestTimestamp: nil, now: now) == .empty)
    }

    @Test("zero elapsed resolves to fresh")
    func zeroElapsedResolvesToFresh() {
        let now = Date()
        #expect(WidgetDataState.resolve(latestTimestamp: now, now: now) == .fresh)
    }

    @Test("elapsed just over 24h resolves to stale")
    func justOver24HoursResolvesToStale() {
        let now = Date()
        let latest = now.addingTimeInterval(-24 * 3600 - 1)
        #expect(WidgetDataState.resolve(latestTimestamp: latest, now: now) == .stale)
    }

    @Test("elapsed exactly 24h resolves to fresh (strictly-greater-than threshold)")
    func exactly24HoursResolvesToFresh() {
        let now = Date()
        let latest = now.addingTimeInterval(-24 * 3600)
        #expect(WidgetDataState.resolve(latestTimestamp: latest, now: now) == .fresh)
    }
}
