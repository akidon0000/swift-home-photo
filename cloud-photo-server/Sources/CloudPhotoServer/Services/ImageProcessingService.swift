import Foundation
import Crypto

#if canImport(CoreGraphics)
import CoreGraphics
import ImageIO
#endif

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

#if canImport(CoreGraphics)
/// CoreGraphics ベースの画像処理実装 (macOS専用)
final class CoreGraphicsImageProcessor: ImageProcessingService, Sendable {
    private let thumbnailMaxSize: Int

    init(thumbnailMaxSize: Int = 300) {
        self.thumbnailMaxSize = thumbnailMaxSize
    }

    func extractExifData(from data: Data) async throws -> ExifData? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }

        // EXIF辞書
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        // TIFF辞書
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        // GPS辞書
        let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any]

        // 撮影日時を抽出
        let dateTimeOriginal = parseDateTimeOriginal(from: exif)

        return ExifData(
            cameraMake: tiff?[kCGImagePropertyTIFFMake as String] as? String,
            cameraModel: tiff?[kCGImagePropertyTIFFModel as String] as? String,
            lensModel: exif?[kCGImagePropertyExifLensModel as String] as? String,
            focalLength: exif?[kCGImagePropertyExifFocalLength as String] as? Double,
            aperture: exif?[kCGImagePropertyExifFNumber as String] as? Double,
            shutterSpeed: formatShutterSpeed(exif?[kCGImagePropertyExifExposureTime as String] as? Double),
            iso: (exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first,
            latitude: parseGPSCoordinate(
                gps,
                valueKey: kCGImagePropertyGPSLatitude as String,
                refKey: kCGImagePropertyGPSLatitudeRef as String,
                positiveRef: "N"
            ),
            longitude: parseGPSCoordinate(
                gps,
                valueKey: kCGImagePropertyGPSLongitude as String,
                refKey: kCGImagePropertyGPSLongitudeRef as String,
                positiveRef: "E"
            ),
            altitude: gps?[kCGImagePropertyGPSAltitude as String] as? Double,
            dateTimeOriginal: dateTimeOriginal
        )
    }

    func getImageDimensions(from data: Data) async throws -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            return nil
        }
        return (width, height)
    }

    func generateThumbnail(from data: Data, maxSize: Int) async throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageProcessingError.invalidImageData
        }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw ImageProcessingError.thumbnailGenerationFailed
        }

        // JPEG として書き出し
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            throw ImageProcessingError.thumbnailGenerationFailed
        }

        CGImageDestinationAddImage(destination, thumbnail, [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ImageProcessingError.thumbnailGenerationFailed
        }

        return mutableData as Data
    }

    func calculateChecksum(from data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private Helpers

    private func formatShutterSpeed(_ exposureTime: Double?) -> String? {
        guard let time = exposureTime else { return nil }
        if time >= 1 {
            return String(format: "%.1f", time)
        } else {
            let denominator = Int(round(1.0 / time))
            return "1/\(denominator)"
        }
    }

    private func parseGPSCoordinate(
        _ gps: [String: Any]?,
        valueKey: String,
        refKey: String,
        positiveRef: String
    ) -> Double? {
        guard let gps = gps,
              let value = gps[valueKey] as? Double,
              let ref = gps[refKey] as? String else {
            return nil
        }
        return ref == positiveRef ? value : -value
    }

    private func parseDateTimeOriginal(from exif: [String: Any]?) -> Date? {
        guard let exif = exif,
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}
#endif
