import SwiftUI

struct ServerConfigView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var host: String = ""
    @State private var port: String = ""
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @Environment(\.dismiss) private var dismiss

    private let photoAPI = PhotoAPI()

    var body: some View {
        Form {
            Section("Server Address") {
                TextField("Host (e.g., 192.168.1.100)", text: $host)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)

                TextField("Port (e.g., 8080)", text: $port)
                    .keyboardType(.numberPad)
            }

            Section {
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.isSuccess ? .green : .red)
                        }
                    }
                }
                .disabled(isTesting || host.isEmpty)

                if let result = testResult, !result.isSuccess {
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button("Save") {
                    saveSettings()
                }
                .disabled(host.isEmpty)
            }
        }
        .navigationTitle("Server Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            host = settingsManager.serverHost
            port = String(settingsManager.serverPort)
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil

        // Temporarily update settings for test
        let originalHost = settingsManager.serverHost
        let originalPort = settingsManager.serverPort

        settingsManager.serverHost = host
        settingsManager.serverPort = Int(port) ?? 8080

        do {
            let health = try await photoAPI.healthCheck()
            testResult = TestResult(
                isSuccess: health.isHealthy,
                message: health.isHealthy ? "Connected successfully" : "Server returned unhealthy status"
            )
        } catch {
            testResult = TestResult(isSuccess: false, message: error.localizedDescription)
            // Restore original settings on failure
            settingsManager.serverHost = originalHost
            settingsManager.serverPort = originalPort
        }

        isTesting = false
    }

    private func saveSettings() {
        settingsManager.serverHost = host
        settingsManager.serverPort = Int(port) ?? 8080
        dismiss()
    }
}

struct TestResult {
    let isSuccess: Bool
    let message: String
}

#Preview {
    NavigationStack {
        ServerConfigView()
            .environmentObject(SettingsManager.shared)
    }
}
