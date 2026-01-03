import Foundation
import Crypto

#if os(Linux)
/// libvips を使用した Linux 向け画像処理実装
/// コマンドラインの vips/vipsthumbnail を使用
final class VipsImageProcessor: ImageProcessingService, Sendable {
    private let thumbnailMaxSize: Int

    init(thumbnailMaxSize: Int = 300) {
        self.thumbnailMaxSize = thumbnailMaxSize
    }

    func extractExifData(from data: Data) async throws -> ExifData? {
        // Linux では EXIF 抽出は vips では難しいため、簡易実装
        // 将来的には libexif などを使用可能
        return nil
    }

    func getImageDimensions(from data: Data) async throws -> (width: Int, height: Int)? {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            try data.write(to: tempFile)
            defer { try? FileManager.default.removeItem(at: tempFile) }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/vipsheader")
            process.arguments = ["-f", "width", tempFile.path]

            let widthPipe = Pipe()
            process.standardOutput = widthPipe
            process.standardError = FileHandle.nullDevice

            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else { return nil }

            let widthData = widthPipe.fileHandleForReading.readDataToEndOfFile()
            guard let widthStr = String(data: widthData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let width = Int(widthStr) else { return nil }

            // Get height
            let heightProcess = Process()
            heightProcess.executableURL = URL(fileURLWithPath: "/usr/bin/vipsheader")
            heightProcess.arguments = ["-f", "height", tempFile.path]

            let heightPipe = Pipe()
            heightProcess.standardOutput = heightPipe
            heightProcess.standardError = FileHandle.nullDevice

            try heightProcess.run()
            heightProcess.waitUntilExit()

            guard heightProcess.terminationStatus == 0 else { return nil }

            let heightData = heightPipe.fileHandleForReading.readDataToEndOfFile()
            guard let heightStr = String(data: heightData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let height = Int(heightStr) else { return nil }

            return (width, height)
        } catch {
            return nil
        }
    }

    func generateThumbnail(from data: Data, maxSize: Int) async throws -> Data {
        let tempInput = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        let tempOutput = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_thumb.jpg")

        defer {
            try? FileManager.default.removeItem(at: tempInput)
            try? FileManager.default.removeItem(at: tempOutput)
        }

        try data.write(to: tempInput)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/vipsthumbnail")
        process.arguments = [
            tempInput.path,
            "-s", "\(maxSize)x\(maxSize)",
            "-o", tempOutput.path + "[Q=80]"
        ]
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ImageProcessingError.thumbnailGenerationFailed
        }

        return try Data(contentsOf: tempOutput)
    }

    func calculateChecksum(from data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
#endif
