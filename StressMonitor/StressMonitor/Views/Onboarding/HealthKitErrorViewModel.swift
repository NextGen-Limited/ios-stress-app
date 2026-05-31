import Foundation
import UIKit

@MainActor
@Observable
final class HealthKitErrorViewModel {
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    func dismissToWelcome() {
        // Navigate back to welcome screen
        // This would be handled by parent navigation
    }
}
