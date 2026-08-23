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

    /// Resolves a server-suggested chip id to the prompt its tap sends.
    ///
    /// Verbatim mirror of the backend's own table
    /// (stress-app-be/src/lib/quick-actions.ts, `getQuickActionPrompt`) — the
    /// server's `GET /quick-actions` returns ids + titles only, so taps must
    /// resolve prompts on-device through the credit-metered `/chat` path
    /// instead of the unmetered `POST /quick-actions` completion route.
    /// Update the two tables in lockstep. Unknown ids return nil and are
    /// dropped from the chip row.
    static func prompt(forServerActionId id: String) -> String? {
        switch id {
        case "breathing":
            return "Guide me through a box breathing exercise right now."
        case "grounding":
            return "Help me with the 5-4-3-2-1 grounding technique."
        case "sleep_tips":
            return "Give me practical tips to sleep better tonight."
        case "mini_walk":
            return "Suggest a simple 5-minute movement routine I can do right now."
        case "recovery":
            return "What recovery strategies should I focus on given my current state?"
        case "resilience":
            return "How can I build long-term stress resilience?"
        case "talk":
            return "I want to talk more about how I'm feeling right now."
        default:
            return nil
        }
    }
}
