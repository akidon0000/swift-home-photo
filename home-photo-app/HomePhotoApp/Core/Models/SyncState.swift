import Foundation

struct SyncState: Equatable {
    var isEnabled: Bool = false
    var status: Status = .idle
    var pendingCount: Int = 0
    var uploadedCount: Int = 0
    var failedCount: Int = 0
    var totalCount: Int = 0
    var currentPhotoId: String?
    var currentProgress: Double = 0

    enum Status: Equatable {
        case idle
        case syncing
        case paused
        case waitingForNetwork
        case waitingForWiFi
        case error(String)

        var description: String {
            switch self {
            case .idle:
                return "Idle"
            case .syncing:
                return "Syncing..."
            case .paused:
                return "Paused"
            case .waitingForNetwork:
                return "Waiting for network"
            case .waitingForWiFi:
                return "Waiting for WiFi"
            case .error(let message):
                return "Error: \(message)"
            }
        }

        var isActive: Bool {
            if case .syncing = self {
                return true
            }
            return false
        }
    }

    var overallProgress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(uploadedCount) / Double(totalCount)
    }
}
