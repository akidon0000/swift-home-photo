import Foundation

/// ソート基準
enum PhotoSortBy: String, Sendable {
    case createdAt
    case filename
    case size
}

/// ソート順
enum SortOrder: String, Sendable {
    case asc
    case desc
}

/// 写真ストレージサービス Protocol
protocol PhotoStorageService: Sendable {
    /// 写真一覧を取得
    func listPhotos(
        page: Int,
        perPage: Int,
        sortBy: PhotoSortBy,
        order: SortOrder,
        year: Int?,
        month: Int?
    ) async throws -> (photos: [Photo], total: Int)

    /// ID で写真を取得
    func getPhoto(id: UUID) async throws -> Photo

    /// 写真ファイルのパスを取得
    func getPhotoFilePath(id: UUID) async throws -> String

    /// 写真が存在するか確認
    func photoExists(id: UUID) async throws -> Bool

    /// 写真をアップロード
    func uploadPhoto(
        filename: String,
        data: Data,
        mimeType: String
    ) async throws -> Photo

    /// 写真を削除
    func deletePhoto(id: UUID) async throws

    /// サムネイルファイルパスを取得
    func getThumbnailFilePath(id: UUID) async throws -> String

    /// チェックサムで重複を検索
    func findByChecksum(_ checksum: String) async throws -> Photo?
}
