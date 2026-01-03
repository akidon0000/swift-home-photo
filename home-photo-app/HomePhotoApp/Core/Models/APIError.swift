import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case badRequest(String?)
    case notFound
    case duplicate(existingId: UUID?)
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest(let message):
            return message ?? "Bad request"
        case .notFound:
            return "Resource not found"
        case .duplicate:
            return "Photo already exists on server"
        case .serverError(let code):
            return "Server error (\(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

struct ErrorResponse: Codable {
    let error: Bool
    let reason: String
}
