import Foundation

/// ローカルファイルシステムベースの写真ストレージサービス
final class LocalPhotoStorageService: PhotoStorageService, Sendable {
    private let basePath: String
    private let metadataStore: any MetadataStore

    init(basePath: String, metadataStore: any MetadataStore) {
        self.basePath = basePath
        self.metadataStore = metadataStore
    }

    func listPhotos(
        page: Int,
        perPage: Int,
        sortBy: PhotoSortBy,
        order: SortOrder,
        year: Int?,
        month: Int?
    ) async throws -> (photos: [Photo], total: Int) {
        var allMetadata = try await metadataStore.loadAll()

        // フィルタリング
        if let year = year {
            allMetadata = allMetadata.filter { metadata in
                let calendar = Calendar.current
                return calendar.component(.year, from: metadata.createdAt) == year
            }
        }

        if let month = month {
            allMetadata = allMetadata.filter { metadata in
                let calendar = Calendar.current
                return calendar.component(.month, from: metadata.createdAt) == month
            }
        }

        // ソート
        allMetadata.sort { lhs, rhs in
            let comparison: Bool
            switch sortBy {
            case .createdAt:
                comparison = lhs.createdAt < rhs.createdAt
            case .filename:
                comparison = lhs.originalFilename < rhs.originalFilename
            case .size:
                comparison = lhs.size < rhs.size
            }
            return order == .asc ? comparison : !comparison
        }

        let total = allMetadata.count

        // ページネーション
        let startIndex = (page - 1) * perPage
        guard startIndex < total else {
            return (photos: [], total: total)
        }

        let endIndex = min(startIndex + perPage, total)
        let pagedMetadata = Array(allMetadata[startIndex..<endIndex])

        let photos = pagedMetadata.map { Photo(from: $0) }
        return (photos: photos, total: total)
    }

    func getPhoto(id: UUID) async throws -> Photo {
        guard let metadata = try await metadataStore.get(id: id) else {
            throw AppError.photoNotFound
        }
        return Photo(from: metadata)
    }

    func getPhotoFilePath(id: UUID) async throws -> String {
        guard let metadata = try await metadataStore.get(id: id) else {
            throw AppError.photoNotFound
        }

        let fullPath = "\(basePath)/\(metadata.storagePath)"

        guard FileManager.default.fileExists(atPath: fullPath) else {
            throw AppError.storageError("Photo file not found on disk")
        }

        return fullPath
    }

    func photoExists(id: UUID) async throws -> Bool {
        guard let metadata = try await metadataStore.get(id: id) else {
            return false
        }

        let fullPath = "\(basePath)/\(metadata.storagePath)"
        return FileManager.default.fileExists(atPath: fullPath)
    }
}
