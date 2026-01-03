@testable import CloudPhotoServer
import VaporTesting
import Testing

@Suite("App Tests")
struct CloudPhotoServerTests {
    @Test("Test Health Check Route")
    func healthCheck() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "api/v1/health", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("healthy") || res.body.string.contains("degraded"))
            })
        }
    }

    @Test("Test Photos List Route")
    func photosList() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "api/v1/photos", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("data"))
                #expect(res.body.string.contains("pagination"))
            })
        }
    }

    @Test("Test Photo Not Found")
    func photoNotFound() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "api/v1/photos/00000000-0000-0000-0000-000000000000", afterResponse: { res async in
                #expect(res.status == .notFound)
            })
        }
    }
}
