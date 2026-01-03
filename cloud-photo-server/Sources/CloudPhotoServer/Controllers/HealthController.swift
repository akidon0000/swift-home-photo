import Vapor

/// ヘルスチェック API コントローラー
struct HealthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let health = routes.grouped("api", "v1")
        health.get("health", use: check)
    }

    /// GET /api/v1/health - ヘルスチェック
    @Sendable
    func check(req: Request) async throws -> HealthResponse {
        let config = req.storageConfig
        let storageAvailable = FileManager.default.fileExists(atPath: config.basePath)

        return HealthResponse(
            status: storageAvailable ? "healthy" : "degraded",
            version: "1.0.0",
            storageAvailable: storageAvailable
        )
    }
}

/// ヘルスチェックレスポンス
struct HealthResponse: Content {
    let status: String
    let version: String
    let storageAvailable: Bool
}
