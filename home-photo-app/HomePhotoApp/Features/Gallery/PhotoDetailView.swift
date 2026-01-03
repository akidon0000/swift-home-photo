import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo

    @State private var fullImage: UIImage?
    @State private var isLoading = true
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    private let photoAPI = PhotoAPI()

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    // Image
                    Group {
                        if let image = fullImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: geo.size.width)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(
                                    CGFloat(photo.width ?? 4) / CGFloat(photo.height ?? 3),
                                    contentMode: .fit
                                )
                                .overlay {
                                    if isLoading {
                                        ProgressView()
                                    }
                                }
                        }
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        MetadataRow(label: "Filename", value: photo.filename)
                        MetadataRow(label: "Size", value: photo.formattedSize)

                        if let width = photo.width, let height = photo.height {
                            MetadataRow(label: "Dimensions", value: "\(width) x \(height)")
                        }

                        MetadataRow(label: "Uploaded", value: photo.createdAt.formatted())

                        if let takenAt = photo.takenAt {
                            MetadataRow(label: "Taken", value: takenAt.formatted())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(photo.filename)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deletePhoto() }
            }
        } message: {
            Text("This will permanently delete the photo from the server.")
        }
        .task {
            await loadFullImage()
        }
    }

    private func loadFullImage() async {
        do {
            let data = try await photoAPI.downloadPhoto(id: photo.id)
            if let image = UIImage(data: data) {
                fullImage = image
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        isLoading = false
    }

    private func deletePhoto() async {
        do {
            try await photoAPI.deletePhoto(id: photo.id)
            dismiss()
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    NavigationStack {
        PhotoDetailView(photo: Photo(
            id: UUID(),
            filename: "IMG_0001.jpg",
            mimeType: "image/jpeg",
            size: 2456789,
            width: 4000,
            height: 3000,
            createdAt: Date(),
            takenAt: Date().addingTimeInterval(-86400),
            checksum: "abc123"
        ))
    }
}
