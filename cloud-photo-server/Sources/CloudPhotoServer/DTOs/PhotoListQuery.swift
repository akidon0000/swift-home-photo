import Vapor

/// 写真一覧取得のクエリパラメータ
struct PhotoListQuery: Content {
    var page: Int?
    var perPage: Int?
    var sortBy: String?
    var order: String?
    var year: Int?
    var month: Int?

    /// バリデーション済みのページ番号
    var validatedPage: Int {
        max(1, page ?? 1)
    }

    /// バリデーション済みのページサイズ
    var validatedPerPage: Int {
        min(100, max(1, perPage ?? 50))
    }

    /// バリデーション済みのソート基準
    var validatedSortBy: PhotoSortBy {
        guard let sortBy = sortBy else { return .createdAt }
        return PhotoSortBy(rawValue: sortBy) ?? .createdAt
    }

    /// バリデーション済みのソート順
    var validatedOrder: SortOrder {
        guard let order = order else { return .desc }
        return SortOrder(rawValue: order) ?? .desc
    }
}
