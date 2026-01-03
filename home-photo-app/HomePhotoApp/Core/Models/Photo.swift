import Foundation

struct Photo: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let filename: String
    let mimeType: String
    let size: Int64
    let width: Int?
    let height: Int?
    let createdAt: Date
    let takenAt: Date?
    let checksum: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        let date = takenAt ?? createdAt
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
