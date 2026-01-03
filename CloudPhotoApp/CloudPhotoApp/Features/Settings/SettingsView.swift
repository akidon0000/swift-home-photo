import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var syncEngine: SyncEngine
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Server Section
                Section("Server") {
                    NavigationLink {
                        ServerConfigView()
                    } label: {
                        HStack {
                            Text("Server Address")
                            Spacer()
                            Text("\(settingsManager.serverHost):\(settingsManager.serverPort)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Connection")
                        Spacer()
                        ConnectionStatusBadge(isConnected: viewModel.isConnected)
                    }

                    Button("Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .disabled(viewModel.isTesting)
                }

                // Backup Settings Section
                Section("Backup Settings") {
                    Toggle("Auto Backup", isOn: Binding(
                        get: { settingsManager.autoBackupEnabled },
                        set: { newValue in
                            settingsManager.autoBackupEnabled = newValue
                            syncEngine.enableAutoSync(newValue)
                        }
                    ))

                    Toggle("WiFi Only", isOn: $settingsManager.wifiOnlyEnabled)
                }

                // Storage Section
                Section("Storage") {
                    HStack {
                        Text("Photos Backed Up")
                        Spacer()
                        Text("\(viewModel.backedUpCount)")
                            .foregroundStyle(.secondary)
                    }

                    if let lastSync = settingsManager.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync.formatted())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Actions Section
                Section {
                    Button("Clear Upload History", role: .destructive) {
                        viewModel.showingClearAlert = true
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Upload History?", isPresented: $viewModel.showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    viewModel.clearUploadHistory()
                }
            } message: {
                Text("This will allow all photos to be re-uploaded. Server data will not be affected.")
            }
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}

struct ConnectionStatusBadge: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isConnected ? .green : .red)
                .frame(width: 8, height: 8)
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(SyncEngine())
}
