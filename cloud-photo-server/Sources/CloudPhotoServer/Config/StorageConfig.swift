import Foundation
import Vapor

/// ストレージ設定
struct StorageConfig: Sendable {
    let basePath: String
    let photosPath: String
    let thumbnailsPath: String
    let metadataPath: String

    init(basePath: String) {
        self.basePath = basePath
        self.photosPath = "\(basePath)/photos/originals"
        self.thumbnailsPath = "\(basePath)/thumbnails"
        self.metadataPath = "\(basePath)/metadata.json"
    }

    /// デフォルトのストレージパスを取得
    static func defaultBasePath() -> String {
        if let customPath = Environment.get("PHOTO_STORAGE_PATH") {
            return customPath
        }

        #if os(Linux)
        // Linux (Docker) では /app/data を使用
        return "/app/data"
        #else
        // macOS では Application Support を使用
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Application Support/CloudPhotoServer"
        #endif
    }
}

/// Application Storage Key
struct StorageConfigKey: StorageKey {
    typealias Value = StorageConfig
}

extension Application {
    var storageConfig: StorageConfig {
        get {
            guard let config = storage[StorageConfigKey.self] else {
                fatalError("StorageConfig not configured. Call configure() first.")
            }
            return config
        }
        set {
            storage[StorageConfigKey.self] = newValue
        }
    }
}
