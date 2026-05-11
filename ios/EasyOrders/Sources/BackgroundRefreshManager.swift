import BackgroundTasks
import Foundation

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()

    let taskIdentifier = "com.easyorders.app.refresh"

    private init() {}

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            self.handle(task: refreshTask)
        }
    }

    func scheduleNextRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)

        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Failed to schedule background refresh: \(error.localizedDescription)")
            #endif
        }
    }

    private func handle(task: BGAppRefreshTask) {
        scheduleNextRefresh()

        let syncTask = Task {
            do {
                _ = try await OrderSyncService.shared.performSync(trigger: "background")
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            syncTask.cancel()
        }
    }
}
