import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    @MainActor
    private var baseURL: URL? {
        SettingsManager.shared.apiBaseURL
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        contentType: String? = nil
    ) async throws -> T {
        guard let baseURL = await MainActor.run(body: { self.baseURL }) else {
            throw APIError.invalidURL
        }

        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 400:
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.reason)
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.duplicate(existingId: nil)
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Multipart Upload

    func uploadMultipart(
        endpoint: String,
        fileData: Data,
        filename: String,
        mimeType: String
    ) async throws -> PhotoUploadResponse {
        guard let baseURL = await MainActor.run(body: { self.baseURL }) else {
            throw APIError.invalidURL
        }

        let url = baseURL.appendingPathComponent(endpoint)
        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try decoder.decode(PhotoUploadResponse.self, from: data)
        case 400:
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.reason)
        case 409:
            throw APIError.duplicate(existingId: nil)
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Data Request (for images)

    func requestData(endpoint: String) async throws -> Data {
        guard let baseURL = await MainActor.run(body: { self.baseURL }) else {
            throw APIError.invalidURL
        }

        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw APIError.notFound
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Delete Request

    func delete(endpoint: String) async throws {
        guard let baseURL = await MainActor.run(body: { self.baseURL }) else {
            throw APIError.invalidURL
        }

        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.delete.rawValue

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 404 {
                throw APIError.notFound
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
