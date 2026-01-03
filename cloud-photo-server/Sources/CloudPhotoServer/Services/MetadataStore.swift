import Foundation

/// メタデータストア Protocol
protocol MetadataStore: Sendable {
    /// 全メタデータを読み込む
    func loadAll() async throws -> [PhotoMetadata]

    /// ID でメタデータを取得
    func get(id: UUID) async throws -> PhotoMetadata?

    /// メタデータを保存
    func save(_ metadata: PhotoMetadata) async throws

    /// メタデータを削除
    func delete(id: UUID) async throws
}
