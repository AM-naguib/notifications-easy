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

        let orders = try await apiClient.fetchPendingOrders(settings: resolvedSettings)
        guard !orders.isEmpty else {
            return .empty(trigger: trigger)
        }

        try await NotificationManager.shared.scheduleNotifications(
            for: orders,
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

