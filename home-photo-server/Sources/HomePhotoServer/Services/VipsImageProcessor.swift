import Foundation
import Crypto

/// Linux 用画像処理サービス (libvips + exiftool)
///
/// - サムネイル生成: libvips (`vipsthumbnail`)
/// - EXIF 抽出: exiftool
/// - チェックサム: swift-crypto (SHA256)
final class VipsImageProcessor: ImageProcessingService, Sendable {
    private let thumbnailMaxSize: Int

    init(thumbnailMaxSize: Int = 300) {
        self.thumbnailMaxSize = thumbnailMaxSize
    }

    func extractExifData(from data: Data) async throws -> ExifData? {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        try data.write(to: tempFile)

        // exiftool で JSON 形式で EXIF 情報を取得
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/exiftool")
        process.arguments = ["-json", "-n", tempFile.path]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()

        guard let jsonArray = try? JSONSerialization.jsonObject(with: outputData) as? [[String: Any]],
              let exifDict = jsonArray.first else {
            return nil
        }

        // 撮影日時をパース
        var dateTimeOriginal: Date?
        if let dateStr = exifDict["DateTimeOriginal"] as? String {
            dateTimeOriginal = parseExifDate(dateStr)
        }

        // GPS 座標を取得
        let latitude = exifDict["GPSLatitude"] as? Double
        let longitude = exifDict["GPSLongitude"] as? Double
        let altitude = exifDict["GPSAltitude"] as? Double

        // シャッタースピードをフォーマット
        var shutterSpeed: String?
        if let exposureTime = exifDict["ExposureTime"] as? Double {
            if exposureTime >= 1 {
                shutterSpeed = String(format: "%.1f\"", exposureTime)
            } else {
                shutterSpeed = "1/\(Int(1.0 / exposureTime))"
            }
        }

        return ExifData(
            cameraMake: exifDict["Make"] as? String,
            cameraModel: exifDict["Model"] as? String,
            lensModel: exifDict["LensModel"] as? String,
            focalLength: exifDict["FocalLength"] as? Double,
            aperture: exifDict["FNumber"] as? Double,
            shutterSpeed: shutterSpeed,
            iso: exifDict["ISO"] as? Int,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            dateTimeOriginal: dateTimeOriginal
        )
    }

    func getImageDimensions(from data: Data) async throws -> (width: Int, height: Int)? {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        try data.write(to: tempFile)

        // vipsheader で画像サイズを取得
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/vipsheader")
        process.arguments = ["-f", "width", tempFile.path]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let widthData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let widthStr = String(data: widthData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let width = Int(widthStr) else {
            return nil
        }

        // height を取得
        let process2 = Process()
        let pipe2 = Pipe()

        process2.executableURL = URL(fileURLWithPath: "/usr/bin/vipsheader")
        process2.arguments = ["-f", "height", tempFile.path]
        process2.standardOutput = pipe2
        process2.standardError = FileHandle.nullDevice

        try process2.run()
        process2.waitUntilExit()

        let heightData = pipe2.fileHandleForReading.readDataToEndOfFile()
        guard let heightStr = String(data: heightData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let height = Int(heightStr) else {
            return nil
        }

        return (width, height)
    }

    func generateThumbnail(from data: Data, maxSize: Int) async throws -> Data {
        let tempInput = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        let tempOutput = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "_thumb.jpg")

        defer {
            try? FileManager.default.removeItem(at: tempInput)
            try? FileManager.default.removeItem(at: tempOutput)
        }

        try data.write(to: tempInput)

        // vipsthumbnail でサムネイル生成
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/vipsthumbnail")
        process.arguments = [
            tempInput.path,
            "-s", "\(maxSize)x\(maxSize)",
            "--rotate",  // EXIF に基づいて回転
            "-o", tempOutput.path + "[Q=80]"
        ]
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw AppError.imageProcessingError("Failed to generate thumbnail")
        }

        return try Data(contentsOf: tempOutput)
    }

    func calculateChecksum(from data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Private

    /// EXIF 日付文字列をパース (例: "2025:01:15 10:30:00")
    private func parseExifDate(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateStr)
    }
}
