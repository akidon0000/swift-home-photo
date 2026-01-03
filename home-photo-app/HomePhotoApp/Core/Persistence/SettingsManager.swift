import Foundation
import Combine

@MainActor
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let serverHost = "serverHost"
        static let serverPort = "serverPort"
        static let autoBackupEnabled = "autoBackupEnabled"
        static let wifiOnlyEnabled = "wifiOnlyEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
    }

    @Published var serverHost: String {
        didSet {
            defaults.set(serverHost, forKey: Keys.serverHost)
        }
    }

    @Published var serverPort: Int {
        didSet {
            defaults.set(serverPort, forKey: Keys.serverPort)
        }
    }

    @Published var autoBackupEnabled: Bool {
        didSet {
            defaults.set(autoBackupEnabled, forKey: Keys.autoBackupEnabled)
        }
    }

    @Published var wifiOnlyEnabled: Bool {
        didSet {
            defaults.set(wifiOnlyEnabled, forKey: Keys.wifiOnlyEnabled)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    @Published var lastSyncDate: Date? {
        didSet {
            defaults.set(lastSyncDate, forKey: Keys.lastSyncDate)
        }
    }

    var serverURL: URL? {
        URL(string: "http://\(serverHost):\(serverPort)")
    }

    var apiBaseURL: URL? {
        serverURL?.appendingPathComponent("api/v1")
    }

    private init() {
        let storedPort = defaults.integer(forKey: Keys.serverPort)

        self.serverHost = defaults.string(forKey: Keys.serverHost) ?? "192.168.1.1"
        self.serverPort = storedPort == 0 ? 8080 : storedPort
        self.autoBackupEnabled = defaults.bool(forKey: Keys.autoBackupEnabled)
        self.wifiOnlyEnabled = defaults.object(forKey: Keys.wifiOnlyEnabled) as? Bool ?? true
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.lastSyncDate = defaults.object(forKey: Keys.lastSyncDate) as? Date
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
