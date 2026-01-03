import Vapor

/// アプリケーションエラー
enum AppError: AbortError {
    case photoNotFound
    case thumbnailNotFound
    case storageError(String)
    case invalidRequest(String)
    case duplicatePhoto(UUID)
    case imageProcessingError(String)

    var status: HTTPResponseStatus {
        switch self {
        case .photoNotFound, .thumbnailNotFound:
            return .notFound
        case .storageError, .imageProcessingError:
            return .internalServerError
        case .invalidRequest:
            return .badRequest
        case .duplicatePhoto:
            return .conflict
        }
    }

    var reason: String {
        switch self {
        case .photoNotFound:
            return "Photo not found"
        case .thumbnailNotFound:
            return "Thumbnail not found"
        case .storageError(let message):
            return message
        case .invalidRequest(let message):
            return message
        case .duplicatePhoto(let id):
            return "Photo already exists with id: \(id)"
        case .imageProcessingError(let message):
            return "Image processing failed: \(message)"
        }
    }
}
