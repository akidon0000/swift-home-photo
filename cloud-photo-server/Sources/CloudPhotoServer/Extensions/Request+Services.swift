import Vapor

extension Request {
    var photoStorageService: any PhotoStorageService {
        application.photoStorageService
    }

    var metadataStore: any MetadataStore {
        application.metadataStore
    }

    var storageConfig: StorageConfig {
        application.storageConfig
    }
}
