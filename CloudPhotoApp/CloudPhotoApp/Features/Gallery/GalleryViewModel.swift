import Foundation

@MainActor
class GalleryViewModel: ObservableObject {
    @Published private(set) var photos: [Photo] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var error: String?
    @Published private(set) var totalCount = 0

    private let photoAPI = PhotoAPI()
    private var currentPage = 1
    private var hasMorePages = true
    private let perPage = 50

    func loadInitial() async {
        guard photos.isEmpty else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        currentPage = 1

        do {
            let response = try await photoAPI.listPhotos(page: 1, perPage: perPage)
            photos = response.data
            totalCount = response.pagination.totalItems
            hasMorePages = response.pagination.hasNextPage
            currentPage = 1
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func loadMoreIfNeeded(currentPhoto: Photo) {
        guard let lastPhoto = photos.last,
              lastPhoto.id == currentPhoto.id,
              hasMorePages,
              !isLoadingMore else {
            return
        }

        Task {
            await loadMore()
        }
    }

    private func loadMore() async {
        isLoadingMore = true

        do {
            let nextPage = currentPage + 1
            let response = try await photoAPI.listPhotos(page: nextPage, perPage: perPage)
            photos.append(contentsOf: response.data)
            hasMorePages = response.pagination.hasNextPage
            currentPage = nextPage
        } catch {
            print("Failed to load more: \(error)")
        }

        isLoadingMore = false
    }
}
