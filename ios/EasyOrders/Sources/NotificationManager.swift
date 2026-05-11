import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    private override init() {}

    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: granted)
            }
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func statusLabel(for status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }

    func scheduleNotifications(for orders: [OrderQueueItem], intervalSeconds: Int) async throws {
        let safeInterval = max(1, intervalSeconds)

        for (index, order) in orders.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = order.notificationTitle
            content.body = order.notificationBody
            content.sound = .default
            content.threadIdentifier = "easyorders-orders"
            content.userInfo = ["order_id": order.id]

            let delay = TimeInterval((index * safeInterval) + 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "order-\(order.id)",
                content: content,
                trigger: trigger
            )

            try await add(request: request)
        }
    }

    private func add(request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: ())
            }
        }
    }
}

