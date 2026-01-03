import SwiftUI
import BackgroundTasks

@main
struct CloudPhotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var syncEngine = SyncEngine()
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some Scene {
        WindowGroup {
            if settingsManager.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(syncEngine)
                    .environmentObject(settingsManager)
            } else {
                OnboardingView()
                    .environmentObject(settingsManager)
            }
        }
    }
}
