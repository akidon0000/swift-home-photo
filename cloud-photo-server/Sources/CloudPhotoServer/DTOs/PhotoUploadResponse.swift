import Vapor

/// アップロード成功レスポンス
struct PhotoUploadResponse: Content {
    let photo: Photo
    let message: String

    init(photo: Photo) {
        self.photo = photo
        self.message = "Photo uploaded successfully"
    }
}

/// ファイルアップロード用の構造体
struct FileUpload: Content {
    var file: File
}

/// アップロードバリデーション
enum PhotoUploadValidator {
    static let allowedMimeTypes: Set<String> = [
        "image/jpeg",
        "image/png",
        "image/heic",
        "image/heif",
        "image/webp"
    ]

    /// 最大ファイルサイズ (50MB)
    static let maxFileSize: Int = 50 * 1024 * 1024

    static func validate(file: File) throws {
        // MIMEタイプチェック
        let mimeType = file.contentType?.serialize() ?? "application/octet-stream"
        guard allowedMimeTypes.contains(mimeType) else {
            throw AppError.invalidRequest("Unsupported file type: \(mimeType). Allowed types: jpeg, png, heic, webp")
        }

        // ファイルサイズチェック
        guard file.data.readableBytes <= maxFileSize else {
            throw AppError.invalidRequest("File too large. Maximum size is 50MB")
        }

        // ファイル名チェック
        guard !file.filename.isEmpty else {
            throw AppError.invalidRequest("Filename is required")
        }
    }
}
