@testable import CloudPhotoServer
import VaporTesting
import Testing
import Foundation

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

    @Test("Test Thumbnail Not Found")
    func thumbnailNotFound() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "api/v1/photos/00000000-0000-0000-0000-000000000000/thumbnail", afterResponse: { res async in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("Test Delete Not Found")
    func deleteNotFound() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.DELETE, "api/v1/photos/00000000-0000-0000-0000-000000000000", afterResponse: { res async in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("Test Upload Invalid File Type")
    func uploadInvalidFileType() async throws {
        try await withApp(configure: configure) { app in
            // テキストファイルはアップロード不可
            let boundary = "test-boundary"
            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition: form-data; name=\"file\"; filename=\"test.txt\"\r\n"
            body += "Content-Type: text/plain\r\n\r\n"
            body += "Hello, World!\r\n"
            body += "--\(boundary)--\r\n"

            try await app.testing().test(
                .POST,
                "api/v1/photos",
                headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"],
                body: .init(string: body),
                afterResponse: { res async in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
}
