import Foundation
import Observation

@Observable
class ObservableModel {
    var isLoading = false
    var errorMessage: String?

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }
}
