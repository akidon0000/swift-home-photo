import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isTesting = false
    @Published var backedUpCount = 0
    @Published var showingClearAlert = false

    private let photoAPI = PhotoAPI()
    private let uploadStateStore = UploadStateStore()

    func refresh() {
        backedUpCount = uploadStateStore.getUploadedCount()
        Task { await testConnection() }
    }

    func testConnection() async {
        isTesting = true
        defer { isTesting = false }

        do {
            let health = try await photoAPI.healthCheck()
            isConnected = health.isHealthy
        } catch {
            isConnected = false
        }
    }

    func clearUploadHistory() {
        uploadStateStore.clearAll()
        backedUpCount = 0
    }
}
