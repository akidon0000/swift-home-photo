import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.photos.isEmpty {
                    ProgressView("Loading...")
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else if viewModel.photos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.gray)
                        Text("No Photos")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Photos you back up will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(viewModel.photos) { photo in
                                NavigationLink(value: photo) {
                                    PhotoGridItem(photo: photo)
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    viewModel.loadMoreIfNeeded(currentPhoto: photo)
                                }
                            }
                        }
                        .padding(.horizontal, 2)

                        if viewModel.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetailView(photo: photo)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(viewModel.totalCount) photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            await viewModel.loadInitial()
        }
    }
}

#Preview {
    GalleryView()
}
