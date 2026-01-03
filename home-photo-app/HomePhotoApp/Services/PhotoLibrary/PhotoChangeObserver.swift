import Foundation
import Photos

class PhotoChangeObserver: NSObject, PHPhotoLibraryChangeObserver {
    typealias ChangeHandler = ([PHAsset]) -> Void

    private var changeHandler: ChangeHandler?
    private var previousFetchResult: PHFetchResult<PHAsset>?

    init(onChange: @escaping ChangeHandler) {
        self.changeHandler = onChange
        super.init()

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType == %d",
            PHAssetMediaType.image.rawValue
        )
        self.previousFetchResult = PHAsset.fetchAssets(with: options)

        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let previousResult = previousFetchResult,
              let changes = changeInstance.changeDetails(for: previousResult) else {
            return
        }

        previousFetchResult = changes.fetchResultAfterChanges

        let insertedObjects = changes.insertedObjects
        guard !insertedObjects.isEmpty else { return }

        DispatchQueue.main.async { [weak self] in
            self?.changeHandler?(insertedObjects)
        }
    }
}
