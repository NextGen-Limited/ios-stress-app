import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(title)
            }
            .font(Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isDisabled ? Color.gray : Color.primaryBlue)
            .cornerRadius(26)
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .foregroundColor(isDestructive ? Color.error : Color.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isDestructive ? Color.error.opacity(0.1) : Color.primaryBlue.opacity(0.1))
                .cornerRadius(26)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(isDestructive ? Color.error : Color.primaryBlue, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .foregroundColor(.error)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Press-scale removed under Reduce Motion — the motion decision is owned by
/// the helper in Animation+Wellness.swift.
typealias ScaleButtonStyle = MotionAwareScaleButtonStyle
