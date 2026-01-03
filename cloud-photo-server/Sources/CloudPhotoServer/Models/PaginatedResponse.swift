import Vapor

/// ページネーション付きレスポンス
struct PaginatedResponse<T: Content>: Content {
    let data: [T]
    let pagination: PaginationInfo
}

/// ページネーション情報
struct PaginationInfo: Content {
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool

    init(page: Int, perPage: Int, totalItems: Int) {
        self.page = page
        self.perPage = perPage
        self.totalItems = totalItems
        self.totalPages = perPage > 0 ? Int(ceil(Double(totalItems) / Double(perPage))) : 0
        self.hasNextPage = page < self.totalPages
        self.hasPrevPage = page > 1
    }
}
