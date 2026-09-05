import SwiftUI

// MARK: - Agent Chat View

/// Health Coach chat (POST /agent/chat). Pushed from Settings' Sync & devices
/// card behind `FeatureFlags.agentChatEnabled`. Message bubbles and the
/// composer mirror `ChatBottomSheetView` — user gradient-right, assistant
/// surface-left — so the two chat surfaces read as one product.
struct AgentChatView: View {
    @StateObject private var vm = AgentChatViewModel()
    @State private var draft = ""

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !vm.isStreaming
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            if let error = vm.errorText {
                Text(error)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
            composer
        }
        .background(Color.Wellness.adaptiveBackground)
        .navigationTitle("Health Coach")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("New") { vm.startNewConversation() }
        }
    }

    // MARK: - Message stream

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message, isStreaming: vm.isStreaming)
                            .id(message.id)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: vm.messages.count) {
                scrollToLast(proxy)
            }
            .onChange(of: vm.messages.last?.text) {
                scrollToLast(proxy)
            }
        }
    }

    private func scrollToLast(_ proxy: ScrollViewProxy) {
        guard let last = vm.messages.last else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                TextField("Ask your coach…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .onSubmit { send() }
            }
            .background(Color.Wellness.adaptiveCardBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.Wellness.adaptiveSecondaryText.opacity(0.15), lineWidth: 1)
            )

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(canSend ? Color(hex: "#0288D1") : Color.Wellness.adaptiveSecondaryText.opacity(0.3))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(Color.Wellness.adaptiveBackground.opacity(0.92))
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canSend else { return }
        draft = ""
        Task { await vm.send(text) }
    }
}

// MARK: - Message Bubble

/// Single coach-chat bubble, matching `ChatBottomSheetView`'s
/// `MessageBubbleView`: user gradient-blue trailing, assistant surface
/// leading, continuous 18pt corners, 260pt max width.
private struct MessageBubble: View {
    let message: AgentMessage
    let isStreaming: Bool

    var body: some View {
        HStack {
            if message.role == "user" { Spacer(minLength: 60) }

            Text(bubbleText)
                .font(.system(size: 14))
                .foregroundStyle(message.role == "user" ? .white : Color.Wellness.adaptivePrimaryText)
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == "user"
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color(hex: "#4FC3F7"), Color(hex: "#0288D1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color.Wellness.adaptiveCardBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .frame(maxWidth: 260, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "assistant" { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
    }

    /// In-flight empty assistant bubble shows the streaming ellipsis.
    private var bubbleText: String {
        message.text.isEmpty && isStreaming ? "…" : message.text
    }
}

#Preview {
    NavigationStack {
        AgentChatView()
    }
}
