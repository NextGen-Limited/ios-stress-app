import Foundation

// MARK: - Quick Action

/// A pre-built prompt suggestion for the AI chat
struct ChatQuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let prompt: String

    init(title: String, icon: String, prompt: String) {
        self.id = title
        self.title = title
        self.icon = icon
        self.prompt = prompt
    }
}

// MARK: - Quick Actions Catalog

/// Pre-built prompts for common wellness interactions
enum ChatQuickActions {

    /// Returns quick actions contextualized to the current stress level
    static func actions(for stressCategory: StressCategory?) -> [ChatQuickAction] {
        let baseActions: [ChatQuickAction] = [
            ChatQuickAction(
                title: "Why stressed?",
                icon: "questionmark.bubble.fill",
                prompt: "What factors are contributing to my current stress level?"
            ),
            ChatQuickAction(
                title: "Sleep impact",
                icon: "bed.double.fill",
                prompt: "How is my sleep affecting my stress levels?"
            ),
            ChatQuickAction(
                title: "Analyze trends",
                icon: "chart.line.uptrend.xyaxis",
                prompt: "What patterns do you see in my recent stress data?"
            ),
            ChatQuickAction(
                title: "Quick tip",
                icon: "lightbulb.fill",
                prompt: "What can I do right now to feel better?"
            )
        ]

        // Add breathing exercise suggestion when stress is elevated
        if let category = stressCategory, category == .moderate || category == .high {
            let breathingAction = ChatQuickAction(
                title: "Breathe",
                icon: "wind",
                prompt: "Guide me through a quick breathing exercise for stress relief."
            )
            return [breathingAction] + baseActions
        }

        return baseActions
    }
}
