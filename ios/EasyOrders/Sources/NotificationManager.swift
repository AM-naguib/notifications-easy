import Foundation
import UserNotifications

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    private let orderNotificationIdentifierPrefix = "order-"
    private let orderThreadIdentifier = "easyorders-orders"

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
            content.threadIdentifier = orderThreadIdentifier
            content.userInfo = ["order_id": order.id]

            let delay = TimeInterval((index * safeInterval) + 1)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(orderNotificationIdentifierPrefix)\(order.id)",
                content: content,
                trigger: trigger
            )

            try await add(request: request)
        }
    }

    func clearOrderNotifications() async {
        let center = UNUserNotificationCenter.current()

        let pendingIdentifiers: [String] = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let identifiers = requests
                    .map(\.identifier)
                    .filter { $0.hasPrefix(self.orderNotificationIdentifierPrefix) }
                continuation.resume(returning: identifiers)
            }
        }

        if !pendingIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)
        }

        let deliveredIdentifiers: [String] = await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in
                let identifiers = notifications
                    .map(\.request)
                    .filter { $0.identifier.hasPrefix(self.orderNotificationIdentifierPrefix) }
                    .map(\.identifier)
                continuation.resume(returning: identifiers)
            }
        }

        if !deliveredIdentifiers.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)
        }
    }

    private func add(request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
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
