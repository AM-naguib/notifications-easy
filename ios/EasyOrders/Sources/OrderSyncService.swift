import Foundation
import UserNotifications

actor OrderSyncService {
    enum SyncError: LocalizedError {
        case notificationsUnauthorized

        var errorDescription: String? {
            switch self {
            case .notificationsUnauthorized:
                return "Notifications are not authorized on this device."
            }
        }
    }

    static let shared = OrderSyncService()

    private let apiClient = APIClient()

    func performSync(trigger: String, settings: AppSettings? = nil) async throws -> SyncSummary {
        let resolvedSettings = settings ?? AppSettings.load()
        let authorizationStatus = await NotificationManager.shared.authorizationStatus()

        guard authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral else {
            throw SyncError.notificationsUnauthorized
        }

        let fetchedOrders = try await apiClient.fetchPendingOrders(settings: resolvedSettings)
        // Keep the newest orders first for previews and app state.
        let orders = fetchedOrders.sorted { $0.createdAt > $1.createdAt }
        // Schedule the oldest first so the newest notification is delivered last
        // and therefore stays on top in Notification Center.
        let deliveryOrder = orders.reversed()

        guard !orders.isEmpty else {
            return .empty(trigger: trigger)
        }

        if trigger == "manual" {
            await NotificationManager.shared.clearOrderNotifications()
        }

        try await NotificationManager.shared.scheduleNotifications(
            for: Array(deliveryOrder),
            intervalSeconds: resolvedSettings.intervalSeconds
        )

        let acknowledgedIDs = try await apiClient.acknowledgeOrders(
            settings: resolvedSettings,
            ids: orders.map(\.id)
        )

        return SyncSummary(
            orders: orders,
            acknowledgedIDs: acknowledgedIDs,
            trigger: trigger,
            executedAt: .now
        )
    }
}
