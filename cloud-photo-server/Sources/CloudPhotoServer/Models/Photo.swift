import Foundation
import Vapor

/// API レスポンス用の写真モデル
struct Photo: Content, Sendable {
    let id: UUID
    let filename: String
    let mimeType: String
    let size: Int64
    let width: Int?
    let height: Int?
    let createdAt: Date
    let takenAt: Date?
    let checksum: String

    init(from metadata: PhotoMetadata) {
        self.id = metadata.id
        self.filename = metadata.originalFilename
        self.mimeType = metadata.mimeType
        self.size = metadata.size
        self.width = metadata.width
        self.height = metadata.height
        self.createdAt = metadata.createdAt
        self.takenAt = metadata.takenAt
        self.checksum = metadata.checksum
    }
}
