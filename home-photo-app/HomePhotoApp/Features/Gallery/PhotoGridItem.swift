import SwiftUI

struct PhotoGridItem: View {
    let photo: Photo

    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true

    private let photoAPI = PhotoAPI()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image = thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "photo")
                                    .foregroundStyle(.gray)
                            }
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
        }
        .aspectRatio(1, contentMode: .fit)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        do {
            let data = try await photoAPI.getThumbnail(id: photo.id)
            if let image = UIImage(data: data) {
                thumbnailImage = image
            }
        } catch {
            print("Failed to load thumbnail: \(error)")
        }
        isLoading = false
    }
}

#Preview {
    PhotoGridItem(photo: Photo(
        id: UUID(),
        filename: "test.jpg",
        mimeType: "image/jpeg",
        size: 1024,
        width: 100,
        height: 100,
        createdAt: Date(),
        takenAt: nil,
        checksum: "abc"
    ))
    .frame(width: 100, height: 100)
}
