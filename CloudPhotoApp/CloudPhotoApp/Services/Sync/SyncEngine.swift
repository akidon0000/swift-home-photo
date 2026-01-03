import Foundation
import Photos
import Combine

@MainActor
class SyncEngine: ObservableObject {
    static let shared = SyncEngine()

    @Published private(set) var state = SyncState()
    @Published private(set) var recentUploads: [UploadResult] = []

    private let photoAPI = PhotoAPI()
    private let photoLibraryService = PhotoLibraryService()
    private let uploadStateStore = UploadStateStore()

    private var syncTask: Task<Void, Never>?
    private var changeObserver: PhotoChangeObserver?

    init() {}

    // MARK: - Public API

    func startAutoSync() {
        guard state.isEnabled else { return }

        changeObserver = PhotoChangeObserver { [weak self] addedAssets in
            Task { @MainActor in
                await self?.handleNewPhotos(addedAssets)
            }
        }
    }

    func stopAutoSync() {
        changeObserver = nil
        syncTask?.cancel()
        syncTask = nil
    }

    func enableAutoSync(_ enabled: Bool) {
        state.isEnabled = enabled
        if enabled {
            startAutoSync()
        } else {
            stopAutoSync()
        }
    }

    func triggerManualSync() async {
        guard state.status != .syncing else { return }

        state.status = .syncing
        state.uploadedCount = 0
        state.failedCount = 0

        do {
            let assetsToUpload = try await findPhotosToUpload()
            state.totalCount = assetsToUpload.count
            state.pendingCount = assetsToUpload.count

            for asset in assetsToUpload {
                guard state.status == .syncing else { break }

                do {
                    try await uploadPhoto(asset)
                    state.uploadedCount += 1
                } catch {
                    state.failedCount += 1
                    print("Failed to upload photo: \(error)")
                }
                state.pendingCount -= 1
            }

            state.status = .idle
            SettingsManager.shared.lastSyncDate = Date()

        } catch {
            state.status = .error(error.localizedDescription)
        }
    }

    func pauseSync() {
        guard state.status == .syncing else { return }
        state.status = .paused
        syncTask?.cancel()
    }

    func resumeSync() {
        guard state.status == .paused else { return }
        Task {
            await triggerManualSync()
        }
    }

    // MARK: - Background Sync

    nonisolated func performBackgroundSync() async throws {
        await MainActor.run {
            state.status = .syncing
        }

        let assetsToUpload = try await findPhotosToUpload()

        for asset in assetsToUpload.prefix(50) {
            try await uploadPhoto(asset)
        }

        await MainActor.run {
            state.status = .idle
            SettingsManager.shared.lastSyncDate = Date()
        }
    }

    // MARK: - Private Methods

    private func findPhotosToUpload() async throws -> [PHAsset] {
        let authStatus = await photoLibraryService.requestAuthorization()
        guard authStatus == .authorized || authStatus == .limited else {
            throw SyncError.photoLibraryAccessDenied
        }

        let allAssets = photoLibraryService.fetchAllPhotos()
        let uploadedIdentifiers = uploadStateStore.getUploadedIdentifiers()

        var assetsToUpload: [PHAsset] = []
        allAssets.enumerateObjects { asset, _, _ in
            if !uploadedIdentifiers.contains(asset.localIdentifier) {
                assetsToUpload.append(asset)
            }
        }

        return assetsToUpload
    }

    private func uploadPhoto(_ asset: PHAsset) async throws {
        state.currentPhotoId = asset.localIdentifier

        let (data, filename, mimeType) = try await photoLibraryService.exportPhotoData(asset: asset)

        let checksum = data.sha256Checksum()

        if uploadStateStore.exists(checksum: checksum) {
            uploadStateStore.markAsUploaded(
                localIdentifier: asset.localIdentifier,
                serverPhotoId: nil,
                checksum: checksum
            )
            addUploadResult(.skipped(asset.localIdentifier))
            return
        }

        do {
            let response = try await photoAPI.uploadPhoto(
                data: data,
                filename: filename,
                mimeType: mimeType
            )

            uploadStateStore.markAsUploaded(
                localIdentifier: asset.localIdentifier,
                serverPhotoId: response.photo.id,
                checksum: checksum
            )

            addUploadResult(.success(response.photo))

        } catch APIError.duplicate {
            uploadStateStore.markAsUploaded(
                localIdentifier: asset.localIdentifier,
                serverPhotoId: nil,
                checksum: checksum
            )
            addUploadResult(.skipped(asset.localIdentifier))
        }
    }

    private func handleNewPhotos(_ assets: [PHAsset]) async {
        guard state.isEnabled else { return }

        for asset in assets {
            do {
                try await uploadPhoto(asset)
            } catch {
                print("Failed to upload new photo: \(error)")
            }
        }
    }

    private func addUploadResult(_ result: UploadResult) {
        recentUploads.insert(result, at: 0)
        if recentUploads.count > 50 {
            recentUploads.removeLast()
        }
    }
}

// MARK: - Supporting Types

enum SyncError: LocalizedError {
    case photoLibraryAccessDenied
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access denied"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

enum UploadResult: Identifiable {
    case success(Photo)
    case skipped(String)
    case failed(String, Error)

    var id: String {
        switch self {
        case .success(let photo):
            return photo.id.uuidString
        case .skipped(let identifier):
            return "skipped-\(identifier)"
        case .failed(let identifier, _):
            return "failed-\(identifier)"
        }
    }
}
