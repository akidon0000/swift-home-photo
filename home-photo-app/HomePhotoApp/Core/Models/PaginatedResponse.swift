import Foundation

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
}
