import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    static let backgroundSyncTaskIdentifier = "com.cloudphoto.sync"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerBackgroundTasks()
        return true
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundSyncTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundSync(task: task as! BGProcessingTask)
        }
    }

    private func handleBackgroundSync(task: BGProcessingTask) {
        scheduleNextBackgroundSync()

        let syncTask = Task {
            do {
                try await SyncEngine.shared.performBackgroundSync()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            syncTask.cancel()
        }
    }

    func scheduleNextBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundSyncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }
}
