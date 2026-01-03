import Foundation

/// JSON ファイルベースのメタデータストア
actor JSONMetadataStore: MetadataStore {
    private let filePath: String
    private var cache: [UUID: PhotoMetadata] = [:]
    private var isLoaded = false

    init(filePath: String) {
        self.filePath = filePath
    }

    func loadAll() async throws -> [PhotoMetadata] {
        try await ensureLoaded()
        return Array(cache.values)
    }

    func get(id: UUID) async throws -> PhotoMetadata? {
        try await ensureLoaded()
        return cache[id]
    }

    func save(_ metadata: PhotoMetadata) async throws {
        try await ensureLoaded()
        cache[metadata.id] = metadata
        try await persist()
    }

    func delete(id: UUID) async throws {
        try await ensureLoaded()
        cache.removeValue(forKey: id)
        try await persist()
    }

    // MARK: - Private

    private func ensureLoaded() async throws {
        guard !isLoaded else { return }

        let fm = FileManager.default
        guard fm.fileExists(atPath: filePath) else {
            isLoaded = true
            return
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadataList = try decoder.decode([PhotoMetadata].self, from: data)

        cache = Dictionary(uniqueKeysWithValues: metadataList.map { ($0.id, $0) })
        isLoaded = true
    }

    private func persist() async throws {
        let metadataList = Array(cache.values)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(metadataList)

        // ディレクトリが存在しない場合は作成
        let directory = (filePath as NSString).deletingLastPathComponent
        let fm = FileManager.default
        if !fm.fileExists(atPath: directory) {
            try fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }

        try data.write(to: URL(fileURLWithPath: filePath))
    }
}
