import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) async throws {
    // リクエストボディサイズ制限 (50MB - 写真アップロード用)
    app.routes.defaultMaxBodySize = "50mb"

    // ストレージ設定
    let basePath = StorageConfig.defaultBasePath()
    let config = StorageConfig(basePath: basePath)
    app.storageConfig = config

    // 画像処理サービス初期化
    let imageProcessor = VipsImageProcessor(thumbnailMaxSize: 300)
    app.imageProcessingService = imageProcessor

    // PostgreSQL 設定 (必須)
    guard let dbConfig = DatabaseConfig.fromEnvironment() else {
        fatalError("Database configuration required. Set DATABASE_HOST, DATABASE_USERNAME, DATABASE_PASSWORD, DATABASE_NAME environment variables.")
    }

    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: dbConfig.hostname,
                port: dbConfig.port,
                username: dbConfig.username,
                password: dbConfig.password,
                database: dbConfig.database,
                tls: .prefer(try .init(configuration: .clientDefault))
            )
        ),
        as: .psql
    )

    // マイグレーション登録・実行
    app.migrations.add(CreatePhotoMetadata())
    app.migrations.add(CreateExifData())
    try await app.autoMigrate()

    // メタデータストア初期化
    let metadataStore = FluentMetadataStore(database: app.db)
    app.metadataStore = metadataStore
    app.logger.info("Using PostgreSQL metadata store")

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
