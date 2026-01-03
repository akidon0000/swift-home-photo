import Foundation

/// ローカルファイルシステムベースの写真ストレージサービス
final class LocalPhotoStorageService: PhotoStorageService, Sendable {
    private let basePath: String
    private let thumbnailsPath: String
    private let metadataStore: any MetadataStore
    private let imageProcessor: any ImageProcessingService

    init(
        basePath: String,
        thumbnailsPath: String,
        metadataStore: any MetadataStore,
        imageProcessor: any ImageProcessingService
    ) {
        self.basePath = basePath
        self.thumbnailsPath = thumbnailsPath
        self.metadataStore = metadataStore
        self.imageProcessor = imageProcessor
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

    // MARK: - Upload

    func uploadPhoto(
        filename: String,
        data: Data,
        mimeType: String
    ) async throws -> Photo {
        // 1. チェックサム計算
        let checksum = imageProcessor.calculateChecksum(from: data)

        // 2. 重複チェック
        if let existing = try await findByChecksum(checksum) {
            throw AppError.duplicatePhoto(existing.id)
        }

        // 3. 画像情報抽出
        let dimensions = try await imageProcessor.getImageDimensions(from: data)
        let exifData = try await imageProcessor.extractExifData(from: data)

        // 4. ID生成とパス決定
        let id = UUID()
        let fileExtension = getFileExtension(from: filename, mimeType: mimeType)
        let storagePath = generateStoragePath(id: id, extension: fileExtension)
        let thumbnailPath = "\(id.uuidString).jpg"

        // 5. オリジナルファイル保存
        let fullPath = "\(basePath)/\(storagePath)"
        try saveFile(data: data, to: fullPath)

        // 6. サムネイル生成・保存
        do {
            let thumbnailData = try await imageProcessor.generateThumbnail(from: data, maxSize: 300)
            let thumbnailFullPath = "\(thumbnailsPath)/\(thumbnailPath)"
            try saveFile(data: thumbnailData, to: thumbnailFullPath)
        } catch {
            // サムネイル生成失敗時はオリジナルファイルを削除してエラー
            try? FileManager.default.removeItem(atPath: fullPath)
            throw AppError.imageProcessingError("Failed to generate thumbnail: \(error.localizedDescription)")
        }

        // 7. EXIF から撮影日時を抽出
        let takenAt = exifData?.dateTimeOriginal

        // 8. メタデータ作成・保存
        let metadata = PhotoMetadata(
            id: id,
            originalFilename: filename,
            mimeType: mimeType,
            size: Int64(data.count),
            width: dimensions?.width,
            height: dimensions?.height,
            createdAt: Date(),
            takenAt: takenAt,
            checksum: checksum,
            storagePath: storagePath,
            thumbnailPath: thumbnailPath,
            exifData: exifData
        )

        try await metadataStore.save(metadata)

        return Photo(from: metadata)
    }

    // MARK: - Delete

    func deletePhoto(id: UUID) async throws {
        guard let metadata = try await metadataStore.get(id: id) else {
            throw AppError.photoNotFound
        }

        let fm = FileManager.default

        // オリジナルファイル削除
        let photoPath = "\(basePath)/\(metadata.storagePath)"
        if fm.fileExists(atPath: photoPath) {
            try fm.removeItem(atPath: photoPath)
        }

        // サムネイル削除
        if let thumbnailPath = metadata.thumbnailPath {
            let fullThumbnailPath = "\(thumbnailsPath)/\(thumbnailPath)"
            if fm.fileExists(atPath: fullThumbnailPath) {
                try fm.removeItem(atPath: fullThumbnailPath)
            }
        }

        // メタデータ削除
        try await metadataStore.delete(id: id)
    }

    // MARK: - Thumbnail

    func getThumbnailFilePath(id: UUID) async throws -> String {
        guard let metadata = try await metadataStore.get(id: id) else {
            throw AppError.photoNotFound
        }

        guard let thumbnailPath = metadata.thumbnailPath else {
            throw AppError.thumbnailNotFound
        }

        let fullPath = "\(thumbnailsPath)/\(thumbnailPath)"

        guard FileManager.default.fileExists(atPath: fullPath) else {
            throw AppError.thumbnailNotFound
        }

        return fullPath
    }

    // MARK: - Find by Checksum

    func findByChecksum(_ checksum: String) async throws -> Photo? {
        let allMetadata = try await metadataStore.loadAll()
        guard let found = allMetadata.first(where: { $0.checksum == checksum }) else {
            return nil
        }
        return Photo(from: found)
    }

    // MARK: - Private Helpers

    private func generateStoragePath(id: UUID, extension ext: String) -> String {
        // 年/月 形式でサブディレクトリを作成
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return "\(year)/\(String(format: "%02d", month))/\(id.uuidString).\(ext)"
    }

    private func getFileExtension(from filename: String, mimeType: String) -> String {
        // ファイル名から拡張子を取得、なければMIMEタイプから推測
        let ext = (filename as NSString).pathExtension.lowercased()
        if !ext.isEmpty { return ext }

        switch mimeType {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "image/heic", "image/heif": return "heic"
        case "image/webp": return "webp"
        default: return "jpg"
        }
    }

    private func saveFile(data: Data, to path: String) throws {
        let fm = FileManager.default
        let directory = (path as NSString).deletingLastPathComponent

        if !fm.fileExists(atPath: directory) {
            try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        try data.write(to: URL(fileURLWithPath: path))
    }
}
