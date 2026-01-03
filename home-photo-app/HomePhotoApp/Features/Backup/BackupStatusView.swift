import SwiftUI

struct BackupStatusView: View {
    @EnvironmentObject var syncEngine: SyncEngine
    @StateObject private var viewModel = BackupViewModel()

    var body: some View {
        NavigationStack {
            List {
                // Status Section
                Section {
                    SyncStatusCard(state: syncEngine.state)
                }

                // Progress Section
                if syncEngine.state.status.isActive {
                    Section("Progress") {
                        VStack(alignment: .leading, spacing: 8) {
                            ProgressView(value: syncEngine.state.overallProgress)
                                .progressViewStyle(.linear)

                            HStack {
                                Text("\(syncEngine.state.uploadedCount) / \(syncEngine.state.totalCount)")
                                Spacer()
                                Text("\(Int(syncEngine.state.overallProgress * 100))%")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                // Actions Section
                Section {
                    Button {
                        Task {
                            await syncEngine.triggerManualSync()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Backup All Photos Now")
                        }
                    }
                    .disabled(syncEngine.state.status.isActive)

                    if syncEngine.state.status.isActive {
                        Button(role: .destructive) {
                            syncEngine.pauseSync()
                        } label: {
                            HStack {
                                Image(systemName: "pause.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Pause Backup")
                            }
                        }
                    }
                }

                // Statistics Section
                Section("Statistics") {
                    HStack {
                        Text("Photos Backed Up")
                        Spacer()
                        Text("\(viewModel.backedUpCount)")
                            .foregroundStyle(.secondary)
                    }

                    if let lastSync = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Backup")
                            Spacer()
                            Text(lastSync.formatted(.relative(presentation: .named)))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Recent Uploads Section
                if !syncEngine.recentUploads.isEmpty {
                    Section("Recent") {
                        ForEach(syncEngine.recentUploads.prefix(10)) { result in
                            UploadResultRow(result: result)
                        }
                    }
                }
            }
            .navigationTitle("Backup")
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}

struct SyncStatusCard: View {
    let state: SyncState

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(state.status.description)
                    .font(.headline)

                if state.pendingCount > 0 {
                    Text("\(state.pendingCount) photos waiting")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var statusColor: Color {
        switch state.status {
        case .idle:
            return .green
        case .syncing:
            return .blue
        case .paused:
            return .orange
        case .waitingForNetwork, .waitingForWiFi:
            return .yellow
        case .error:
            return .red
        }
    }

    private var statusIcon: String {
        switch state.status {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing:
            return "arrow.up.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .waitingForNetwork, .waitingForWiFi:
            return "wifi.exclamationmark"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }
}

struct UploadResultRow: View {
    let result: UploadResult

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)

            switch result {
            case .success(let photo):
                Text(photo.filename)
            case .skipped(let identifier):
                Text("Skipped: \(identifier.prefix(8))...")
                    .foregroundStyle(.secondary)
            case .failed(let identifier, _):
                Text("Failed: \(identifier.prefix(8))...")
                    .foregroundStyle(.red)
            }

            Spacer()
        }
    }

    private var icon: String {
        switch result {
        case .success:
            return "checkmark.circle.fill"
        case .skipped:
            return "arrow.right.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch result {
        case .success:
            return .green
        case .skipped:
            return .orange
        case .failed:
            return .red
        }
    }
}

#Preview {
    BackupStatusView()
        .environmentObject(SyncEngine())
}
