import Foundation

class UploadStateStore {
    private let fileManager = FileManager.default
    private var uploadedPhotos: [String: UploadedPhoto] = [:]
    private let storeURL: URL

    init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storeURL = documentsURL.appendingPathComponent("uploaded_photos.json")
        loadFromDisk()
    }

    struct UploadedPhoto: Codable {
        let localIdentifier: String
        let serverPhotoId: UUID?
        let checksum: String
        let uploadedAt: Date
    }

    func getUploadedIdentifiers() -> Set<String> {
        Set(uploadedPhotos.keys)
    }

    func exists(checksum: String) -> Bool {
        uploadedPhotos.values.contains { $0.checksum == checksum }
    }

    func exists(localIdentifier: String) -> Bool {
        uploadedPhotos[localIdentifier] != nil
    }

    func markAsUploaded(localIdentifier: String, serverPhotoId: UUID?, checksum: String) {
        let uploadedPhoto = UploadedPhoto(
            localIdentifier: localIdentifier,
            serverPhotoId: serverPhotoId,
            checksum: checksum,
            uploadedAt: Date()
        )
        uploadedPhotos[localIdentifier] = uploadedPhoto
        saveToDisk()
    }

    func remove(localIdentifier: String) {
        uploadedPhotos.removeValue(forKey: localIdentifier)
        saveToDisk()
    }

    func getUploadedCount() -> Int {
        uploadedPhotos.count
    }

    func clearAll() {
        uploadedPhotos.removeAll()
        saveToDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard fileManager.fileExists(atPath: storeURL.path) else { return }

        do {
            let data = try Data(contentsOf: storeURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let photos = try decoder.decode([String: UploadedPhoto].self, from: data)
            uploadedPhotos = photos
        } catch {
            print("Failed to load upload state: \(error)")
        }
    }

    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(uploadedPhotos)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            print("Failed to save upload state: \(error)")
        }
    }
}
