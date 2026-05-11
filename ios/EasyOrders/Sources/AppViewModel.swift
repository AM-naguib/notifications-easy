import Combine
import Foundation
import UserNotifications

@MainActor
final class AppViewModel: ObservableObject {
    @Published var baseURLString: String
    @Published var appToken: String
    @Published var notificationCount: Int
    @Published var intervalSeconds: Int

    @Published var notificationStatusText = "Checking..."
    @Published var isPermissionButtonVisible = false
    @Published var isSyncing = false
    @Published var errorMessage: String?
    @Published var lastSyncMessage = "No sync has run yet."
    @Published var lastOrders: [OrderQueueItem] = []

    init() {
        let settings = AppSettings.load()
        baseURLString = settings.baseURLString
        appToken = settings.appToken
        notificationCount = settings.notificationCount
        intervalSeconds = settings.intervalSeconds
    }

    func bootstrap() async {
        await refreshAuthorizationStatus()
        await AppIconManager.shared.applyPreferredIconIfNeeded()
        BackgroundRefreshManager.shared.scheduleNextRefresh()
    }

    func persistSettings() {
        buildSettings().save()
    }

    func requestNotificationPermission() async {
        errorMessage = nil

        do {
            _ = try await NotificationManager.shared.requestAuthorization()
            await refreshAuthorizationStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAuthorizationStatus() async {
        let status = await NotificationManager.shared.authorizationStatus()
        notificationStatusText = NotificationManager.shared.statusLabel(for: status)
        isPermissionButtonVisible = status == .notDetermined || status == .denied
    }

    func fetchAndSchedule() async {
        errorMessage = nil
        isSyncing = true
        let settings = buildSettings()
        settings.save()
        defer { isSyncing = false }

        do {
            let authorizationStatus = await NotificationManager.shared.authorizationStatus()
            if authorizationStatus == .notDetermined {
                let granted = try await NotificationManager.shared.requestAuthorization()
                if !granted {
                    throw OrderSyncService.SyncError.notificationsUnauthorized
                }
            }

            let summary = try await OrderSyncService.shared.performSync(
                trigger: "manual",
                settings: settings
            )

            if summary.orders.isEmpty {
                lastSyncMessage = "No pending orders were available."
                lastOrders = []
            } else {
                lastSyncMessage = "Scheduled \(summary.scheduledCount) notification(s) and acknowledged \(summary.acknowledgedIDs.count) order(s)."
                lastOrders = summary.orders
            }

            await refreshAuthorizationStatus()
            BackgroundRefreshManager.shared.scheduleNextRefresh()
        } catch {
            errorMessage = humanReadable(error)
        }
    }

    private func buildSettings() -> AppSettings {
        AppSettings(
            baseURLString: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines),
            appToken: appToken.trimmingCharacters(in: .whitespacesAndNewlines),
            notificationCount: min(max(notificationCount, 1), 50),
            intervalSeconds: min(max(intervalSeconds, 1), 3600)
        )
    }

    private func humanReadable(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }

        return error.localizedDescription
    }
}
