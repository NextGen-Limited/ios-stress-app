import SwiftUI

// MARK: - Chat Bottom Sheet View

/// Bottom sheet wrapper presenting the AI chat interface.
/// Presented via `.sheet` modifier from ActionView.
struct ChatBottomSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChatViewModel

    // MARK: - Initialization

    init(
        stressResult: StressResult?,
        baseline: PersonalBaseline?,
        recentHistory: [StressMeasurement] = []
    ) {
        _viewModel = State(initialValue: ChatViewModel(
            stressResult: stressResult,
            baseline: baseline,
            recentHistory: recentHistory
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isAvailable {
                    chatContent
                } else {
                    unavailableView
                }
            }
            .navigationTitle("Ripple")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.messages.isEmpty {
                        Button {
                            viewModel.clearConversation()
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            // Quick action chips
            if !viewModel.isLoading && viewModel.messages.isEmpty {
                QuickActionChipsView(
                    actions: viewModel.quickActions,
                    onSelect: { viewModel.sendQuickAction($0) }
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Message list
            messageList

            // Streaming indicator
            if viewModel.isLoading && !viewModel.currentStreamingText.isEmpty {
                streamingBubble
            }

            // Error banner
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            // Input bar
            chatInputBar
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message
                    if viewModel.messages.isEmpty {
                        welcomeMessage
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }

                    // Streaming placeholder
                    if viewModel.isLoading && viewModel.currentStreamingText.isEmpty {
                        HStack {
                            typingIndicator
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToLast(proxy)
            }
            .onChange(of: viewModel.currentStreamingText) { _, _ in
                scrollToLast(proxy)
            }
        }
    }

    // MARK: - Welcome Message

    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            RippleCharacterView(mood: viewModel.companionMood, size: 80)

            Text("Hi! I'm Ripple 💧")
                .font(.headline)
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("I'm here to help you understand your stress levels and suggest wellness activities. What would you like to know?")
                .font(.subheadline)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Streaming Bubble

    private var streamingBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    RippleCharacterView(mood: viewModel.companionMood, size: 20)
                        .clipShape(Circle())

                    Text("Ripple")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(viewModel.currentStreamingText)
                    .font(.body)
                    .foregroundStyle(Color.Wellness.adaptivePrimaryText)
            }
            .padding(12)
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .frame(maxWidth: 280, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.Wellness.adaptiveSecondaryText)
                    .frame(width: 6, height: 6)
                    .modifier(TypingDotAnimation(delay: Double(index) * 0.2))
            }
        }
        .padding(12)
        .background(Color.Wellness.adaptiveCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.error.cornerRadius(8))
            .padding(.horizontal, 16)
    }

    // MARK: - Input Bar

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Ripple...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.Wellness.adaptiveCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit { sendMessage() }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.Wellness.adaptiveSecondaryText
                            : Color.accentTeal
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.Wellness.adaptiveBackground)
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)

            Text("AI Chat needs backend auth")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.Wellness.adaptivePrimaryText)

            Text("Connect Supabase Auth and provide SUPABASE_ANON_KEY to stream through the StressMonitor backend.")
                .font(.body)
                .foregroundStyle(Color.Wellness.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers

    @State private var inputText = ""

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        viewModel.send(text)
    }

    private func scrollToLast(_ proxy: ScrollViewProxy) {
        if let lastMessage = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble View

/// Single message bubble in the chat
private struct MessageBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    HStack(spacing: 4) {
                        RippleCharacterView(mood: .serene, size: 20)
                            .clipShape(Circle())

                        Text("Ripple")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(
                        message.role == .user ? .white : Color.Wellness.adaptivePrimaryText
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? Color.accentTeal
                            : Color.Wellness.adaptiveCardBackground
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )
                    .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Typing Dot Animation

private struct TypingDotAnimation: ViewModifier {
    let delay: Double
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .offset(y: isAnimating ? -4 : 4)
            .animation(
                .easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}
