import Foundation
import Crypto

/// 画像処理エラー
enum ImageProcessingError: Error {
    case invalidImageData
    case thumbnailGenerationFailed
    case unsupportedFormat
}

/// 画像処理サービス Protocol
protocol ImageProcessingService: Sendable {
    /// EXIF データを抽出
    func extractExifData(from data: Data) async throws -> ExifData?

    /// 画像サイズを取得
    func getImageDimensions(from data: Data) async throws -> (width: Int, height: Int)?

    /// サムネイルを生成
    func generateThumbnail(from data: Data, maxSize: Int) async throws -> Data

    /// SHA256 チェックサムを計算
    func calculateChecksum(from data: Data) -> String
}
