import Foundation

/// 内部管理用のメタデータモデル
struct PhotoMetadata: Codable, Sendable {
    let id: UUID
    let originalFilename: String
    let mimeType: String
    let size: Int64
    let width: Int?
    let height: Int?
    let createdAt: Date
    let takenAt: Date?
    let checksum: String
    let storagePath: String
    let thumbnailPath: String?
    let exifData: ExifData?

    init(
        id: UUID = UUID(),
        originalFilename: String,
        mimeType: String,
        size: Int64,
        width: Int? = nil,
        height: Int? = nil,
        createdAt: Date = Date(),
        takenAt: Date? = nil,
        checksum: String,
        storagePath: String,
        thumbnailPath: String? = nil,
        exifData: ExifData? = nil
    ) {
        self.id = id
        self.originalFilename = originalFilename
        self.mimeType = mimeType
        self.size = size
        self.width = width
        self.height = height
        self.createdAt = createdAt
        self.takenAt = takenAt
        self.checksum = checksum
        self.storagePath = storagePath
        self.thumbnailPath = thumbnailPath
        self.exifData = exifData
    }
}
