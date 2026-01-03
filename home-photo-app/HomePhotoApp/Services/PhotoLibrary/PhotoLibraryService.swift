import Foundation
import Photos

actor PhotoLibraryService {
    static let shared = PhotoLibraryService()

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func checkAuthorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    nonisolated func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.image.rawValue
        )
        return PHAsset.fetchAssets(with: options)
    }

    nonisolated func fetchPhotosAfter(date: Date) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType == %d AND creationDate > %@",
            PHAssetMediaType.image.rawValue,
            date as NSDate
        )
        return PHAsset.fetchAssets(with: options)
    }

    func exportPhotoData(asset: PHAsset) async throws -> (Data, String, String) {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, uti, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: PhotoLibraryError.exportFailed)
                    return
                }

                let mimeType = self.mimeType(for: uti)
                let filename = self.filename(for: asset, uti: uti)
                continuation.resume(returning: (data, filename, mimeType))
            }
        }
    }

    private nonisolated func mimeType(for uti: String?) -> String {
        guard let uti = uti else { return "image/jpeg" }

        switch uti {
        case "public.jpeg", "public.jpg":
            return "image/jpeg"
        case "public.png":
            return "image/png"
        case "public.heic", "public.heif":
            return "image/heic"
        case "org.webmproject.webp":
            return "image/webp"
        default:
            return "image/jpeg"
        }
    }

    private nonisolated func filename(for asset: PHAsset, uti: String?) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        if let originalFilename = resources.first?.originalFilename {
            return originalFilename
        }

        let ext: String
        switch uti {
        case "public.png":
            ext = "png"
        case "public.heic", "public.heif":
            ext = "heic"
        case "org.webmproject.webp":
            ext = "webp"
        default:
            ext = "jpg"
        }

        return "IMG_\(asset.localIdentifier.prefix(8)).\(ext)"
    }
}

enum PhotoLibraryError: LocalizedError {
    case exportFailed
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "Failed to export photo data"
        case .accessDenied:
            return "Photo library access denied"
        }
    }
}
