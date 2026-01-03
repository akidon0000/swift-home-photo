import Vapor

public func configure(_ app: Application) async throws {
    // リクエストボディサイズ制限 (50MB - 写真アップロード用)
    app.routes.defaultMaxBodySize = "50mb"

    // ストレージ設定
    let basePath = StorageConfig.defaultBasePath()
    let config = StorageConfig(basePath: basePath)
    app.storageConfig = config

    // 画像処理サービス初期化 (プラットフォーム別)
    #if os(Linux)
    let imageProcessor = VipsImageProcessor(thumbnailMaxSize: 300)
    #else
    let imageProcessor = CoreGraphicsImageProcessor(thumbnailMaxSize: 300)
    #endif
    app.imageProcessingService = imageProcessor

    // メタデータストア初期化
    let metadataStore = JSONMetadataStore(filePath: config.metadataPath)
    app.metadataStore = metadataStore

    // 写真ストレージサービス初期化
    let photoService = LocalPhotoStorageService(
        basePath: config.photosPath,
        thumbnailsPath: config.thumbnailsPath,
        metadataStore: metadataStore,
        imageProcessor: imageProcessor
    )
    app.photoStorageService = photoService

    // ストレージディレクトリ作成
    try ensureStorageDirectories(config: config)

    // ルート登録
    try routes(app)

    app.logger.info("Storage configured at: \(basePath)")
}

/// ストレージディレクトリの存在を確認し、なければ作成
private func ensureStorageDirectories(config: StorageConfig) throws {
    let fm = FileManager.default
    let directories = [
        config.basePath,
        config.photosPath,
        config.thumbnailsPath
    ]

    for dir in directories {
        if !fm.fileExists(atPath: dir) {
            try fm.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
    }
}
