import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func stressLevelChanged(to category: StressCategory) {
        switch category {
        case .relaxed:
            success()
        case .mild:
            light()
        case .moderate:
            warning()
        case .high:
            error()
        }
    }

    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    private func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
