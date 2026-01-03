import XCTest
@testable import CloudPhotoApp

final class CloudPhotoAppTests: XCTestCase {
    func testPhotoModelDecoding() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "filename": "test.jpg",
            "mimeType": "image/jpeg",
            "size": 1024,
            "width": 100,
            "height": 100,
            "createdAt": "2024-01-01T00:00:00Z",
            "checksum": "abc123"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let photo = try decoder.decode(Photo.self, from: json.data(using: .utf8)!)

        XCTAssertEqual(photo.filename, "test.jpg")
        XCTAssertEqual(photo.mimeType, "image/jpeg")
        XCTAssertEqual(photo.size, 1024)
    }

    func testSHA256Checksum() throws {
        let data = "Hello, World!".data(using: .utf8)!
        let checksum = data.sha256Checksum()

        XCTAssertEqual(checksum.count, 64)
        XCTAssertTrue(checksum.allSatisfy { $0.isHexDigit })
    }
}
