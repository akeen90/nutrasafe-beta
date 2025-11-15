import SwiftUI

// MARK: - Toast Type
enum ToastType {
    case success
    case info
    case warning
    case error

    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.9)
        case .info: return Color.blue.opacity(0.9)
        case .warning: return Color.orange.opacity(0.9)
        case .error: return Color.red.opacity(0.9)
        }
    }

    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// MARK: - Toast Data
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: TimeInterval

    init(type: ToastType, message: String, duration: TimeInterval = 2.5) {
        self.type = type
        self.message = message
        self.duration = duration
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    @Published var toasts: [Toast] = []

    func show(_ toast: Toast) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toasts.append(toast)
        }

        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.dismiss(toast)
        }
    }

    func show(type: ToastType, message: String, duration: TimeInterval = 2.5) {
        let toast = Toast(type: type, message: message, duration: duration)
        show(toast)
    }

    func dismiss(_ toast: Toast) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }

    func dismissAll() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toasts.removeAll()
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.backgroundColor)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Container View Modifier
struct ToastContainerModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack(spacing: 8) {
                Spacer()

                ForEach(toastManager.toasts) { toast in
                    ToastView(toast: toast) {
                        toastManager.dismiss(toast)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.bottom, 20)
            .zIndex(999)
        }
    }
}

// MARK: - View Extension
extension View {
    func toastContainer(toastManager: ToastManager) -> some View {
        modifier(ToastContainerModifier(toastManager: toastManager))
    }
}

// MARK: - Convenience Methods for ToastManager
extension ToastManager {
    // Success messages
    func showSuccess(_ message: String, duration: TimeInterval = 2.5) {
        show(type: .success, message: message, duration: duration)
    }

    // Info messages
    func showInfo(_ message: String, duration: TimeInterval = 2.5) {
        show(type: .info, message: message, duration: duration)
    }

    // Warning messages
    func showWarning(_ message: String, duration: TimeInterval = 2.5) {
        show(type: .warning, message: message, duration: duration)
    }

    // Error messages
    func showError(_ message: String, duration: TimeInterval = 3.0) {
        show(type: .error, message: message, duration: duration)
    }
}

// MARK: - Preview
#Preview {
    struct ToastPreviewWrapper: View {
        @StateObject private var toastManager = ToastManager()

        var body: some View {
            VStack(spacing: 20) {
                Text("Toast Demo")
                    .font(.title)
                    .fontWeight(.bold)

                Button("Show Success Toast") {
                    toastManager.showSuccess("Food added to Breakfast")
                }
                .buttonStyle(.borderedProminent)

                Button("Show Info Toast") {
                    toastManager.showInfo("Reminder set for tomorrow")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)

                Button("Show Warning Toast") {
                    toastManager.showWarning("Some items may be expired")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)

                Button("Show Error Toast") {
                    toastManager.showError("Failed to save changes")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Show Multiple") {
                    toastManager.showSuccess("First action completed")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        toastManager.showInfo("Second action started")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        toastManager.showSuccess("All actions completed")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .toastContainer(toastManager: toastManager)
        }
    }

    return ToastPreviewWrapper()
}
