import Foundation

struct PhotoAPI {
    private let client = APIClient.shared

    // MARK: - List Photos

    func listPhotos(
        page: Int = 1,
        perPage: Int = 20,
        sortBy: String = "createdAt",
        order: String = "desc",
        year: Int? = nil,
        month: Int? = nil
    ) async throws -> PaginatedResponse<Photo> {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "perPage", value: String(perPage)),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "order", value: order)
        ]

        if let year = year {
            queryItems.append(URLQueryItem(name: "year", value: String(year)))
        }

        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: String(month)))
        }

        return try await client.request(
            endpoint: "photos",
            queryItems: queryItems
        )
    }

    // MARK: - Get Photo

    func getPhoto(id: UUID) async throws -> Photo {
        try await client.request(endpoint: "photos/\(id.uuidString)")
    }

    // MARK: - Download Photo

    func downloadPhoto(id: UUID) async throws -> Data {
        try await client.requestData(endpoint: "photos/\(id.uuidString)/download")
    }

    // MARK: - Get Thumbnail

    func getThumbnail(id: UUID) async throws -> Data {
        try await client.requestData(endpoint: "photos/\(id.uuidString)/thumbnail")
    }

    // MARK: - Upload Photo

    func uploadPhoto(
        data: Data,
        filename: String,
        mimeType: String
    ) async throws -> PhotoUploadResponse {
        try await client.uploadMultipart(
            endpoint: "photos",
            fileData: data,
            filename: filename,
            mimeType: mimeType
        )
    }

    // MARK: - Delete Photo

    func deletePhoto(id: UUID) async throws {
        try await client.delete(endpoint: "photos/\(id.uuidString)")
    }

    // MARK: - Health Check

    func healthCheck() async throws -> HealthResponse {
        try await client.request(endpoint: "health")
    }
}
