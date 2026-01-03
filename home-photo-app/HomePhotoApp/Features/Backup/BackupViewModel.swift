import Foundation

@MainActor
class BackupViewModel: ObservableObject {
    @Published var backedUpCount: Int = 0
    @Published var lastSyncDate: Date?

    private let uploadStateStore = UploadStateStore()

    func refresh() {
        backedUpCount = uploadStateStore.getUploadedCount()
        lastSyncDate = SettingsManager.shared.lastSyncDate
    }
}
