import Foundation
import Vapor

/// ストレージ設定
///
/// 写真ファイルの保存先パスを管理する。
/// メタデータは PostgreSQL で管理するため、ファイルパスは含まない。
struct StorageConfig: Sendable {
    /// ベースディレクトリ
    let basePath: String

    /// オリジナル画像の保存先
    let photosPath: String

    /// サムネイル画像の保存先
    let thumbnailsPath: String

    init(basePath: String) {
        self.basePath = basePath
        self.photosPath = "\(basePath)/photos/originals"
        self.thumbnailsPath = "\(basePath)/thumbnails"
    }

    /// デフォルトのストレージパスを取得
    ///
    /// 優先順位:
    /// 1. 環境変数 `PHOTO_STORAGE_PATH`
    /// 2. デフォルト: `/app/data`
    static func defaultBasePath() -> String {
        if let customPath = Environment.get("PHOTO_STORAGE_PATH") {
            return customPath
        }
        return "/app/data"
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
