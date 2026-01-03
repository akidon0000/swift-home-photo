import Foundation

struct HealthResponse: Codable {
    let status: String
    let version: String
    let storageAvailable: Bool?

    var isHealthy: Bool {
        status == "healthy"
    }
}
