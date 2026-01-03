import Vapor

func routes(_ app: Application) throws {
    // Photo API
    try app.register(collection: PhotoController())

    // Health API
    try app.register(collection: HealthController())
}
