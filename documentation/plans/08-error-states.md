# Error States

> **Created by:** Phuong Doan
> **Feature:** Error and empty state UI
> **Designs Referenced:** 1 screen
> - `healthkit_access_error_state`

---

## Overview

Error states handle edge cases gracefully:
- HealthKit permission denied
- No measurements available
- Network errors
- Data loading failures

---

## 1. HealthKit Access Error View

**Design:** `healthkit_access_error_state`

```swift
// StressMonitor/Views/ErrorStates/HealthKitAccessErrorView.swift

import SwiftUI
import HealthKit

struct HealthKitAccessErrorView: View {
    @Environment(\.dismiss) private var dismiss
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    init(onRetry: @escaping () -> Void, onOpenSettings: @escaping () -> Void) {
        self.onRetry = onRetry
        self.onOpenSettings = onOpenSettings
    }

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                }

                // Text
                VStack(spacing: 12) {
                    Text("Health Access Required")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("StressMonitor requires access to your HealthKit data to track your HRV and stress levels accurately. Please enable permissions in Settings to continue.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    Button(action: onOpenSettings) {
                        Text("Open Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary)
                    .cornerRadius(26)
                    .shadow(color: Color.primary.opacity(0.3), radius: 8, y: 4)

                    Button(action: onRetry) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    HealthKitAccessErrorView(
        onRetry: { print("Retry") },
        onOpenSettings: { print("Open Settings") }
    )
    .preferredColorScheme(.dark)
}
```

---

## 2. Generic Error State View

```swift
// StressMonitor/Views/ErrorStates/GenericErrorView.swift

import SwiftUI

struct GenericErrorView: View {
    let error: Error
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Error icon
                ZStack {
                    Circle()
                        .fill(Color.stressHigh.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.stressHigh)
                }

                // Error title
                Text("Something Went Wrong")
                    .font(.system(size: 24, weight: .bold))

                // Error message
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    Button(action: onRetry) {
                        Text("Try Again")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.primary)

                    Button(action: onDismiss) {
                        Text("Go Back")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    GenericErrorView(
        error: NSError(domain: "Test", code: 1, userInfo: nil),
        onRetry: { print("Retry") },
        onDismiss: { print("Dismiss") }
    )
}
```

---

## 3. Empty State View

```swift
// StressMonitor/Views/ErrorStates/EmptyStateView.swift

import SwiftUI

struct EmptyStateView: View {
    let icon: String?
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    init(
        icon: String? = nil,
        title: String,
        message: String,
        actionTitle: String = "Take Action",
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon (if provided)
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                }
            }

            // Title
            Text(title)
                .font(.system(size: 20, weight: .bold))

            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Action button
            Button(action: action) {
                Text(actionTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview("No Measurements") {
    EmptyStateView(
        icon: "chart.bar",
        title: "No Measurements",
        message: "Take your first measurement to start tracking your stress levels history.",
        actionTitle: "Measure Now",
        action: { print("Measure") }
    )
    .preferredColorScheme(.dark)
}
```

---

## 4. Loading State View

```swift
// StressMonitor/Views/ErrorStates/LoadingStateView.swift

import SwiftUI

struct LoadingStateView: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    LoadingStateView(message: "Loading your stress data...")
}
```

---

## 5. Network Error View

```swift
// StressMonitor/Views/ErrorStates/NetworkErrorView.swift

import SwiftUI

struct NetworkErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.warningYellow.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.warningYellow)
            }

            // Title
            Text("Connection Error")
                .font(.system(size: 24, weight: .bold))

            // Message
            Text("Unable to load data. Please check your internet connection and try again.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Retry button
            Button(action: onRetry) {
                Text("Try Again")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NetworkErrorView {
        print("Retry")
    }
}
```

---

## 6. Error View Modifier

```swift
// StressMonitor/Views/ErrorStates/ErrorViewModifier.swift

import SwiftUI

struct ErrorViewModifier: ViewModifier {
    let error: Error?
    let isLoading: Bool
    let isEmpty: Bool

    func body(content: Content) -> some View {
        if isLoading {
            return AnyView(
                ZStack {
                    content
                    LoadingStateView(message: "Loading...")
                        .background(Color.backgroundDark)
                }
            )
        } else if let error = error {
            return AnyView(
                GenericErrorView(
                    error: error,
                    onRetry: { /* Retry */ },
                    onDismiss: { /* Dismiss */ }
                )
            )
        } else if isEmpty {
            return AnyView(
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Data",
                    message: "No measurements available yet.",
                    action: { /* Action */ }
                )
            )
        }

        return AnyView(content)
    }
}

extension View {
    func errorState(
        error: Error?,
        isLoading: Bool = false,
        isEmpty: Bool = false
    ) -> some View {
        modifier(ErrorViewModifier(error: error, isLoading: isLoading, isEmpty: isEmpty))
    }
}
```

---

## File Structure

```
StressMonitor/Views/ErrorStates/
├── HealthKitAccessErrorView.swift
├── GenericErrorView.swift
├── EmptyStateView.swift
├── LoadingStateView.swift
├── NetworkErrorView.swift
└── ErrorViewModifier.swift
```

---

## Dependencies

- **Design System:** Colors, tokens from `00-design-system-components.md`
- **HealthKit:** For permission checking
