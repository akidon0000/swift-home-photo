import SwiftUI
import Photos

struct OnboardingView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var currentStep = 0
    @State private var serverHost = ""
    @State private var serverPort = "8080"
    @State private var isTestingConnection = false
    @State private var connectionTestPassed = false
    @State private var photoPermissionGranted = false
    @State private var errorMessage: String?

    private let photoAPI = PhotoAPI()

    var body: some View {
        VStack {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            TabView(selection: $currentStep) {
                // Step 1: Welcome
                WelcomeStepView()
                    .tag(0)

                // Step 2: Server Configuration
                ServerSetupStepView(
                    host: $serverHost,
                    port: $serverPort,
                    isTestingConnection: $isTestingConnection,
                    connectionTestPassed: $connectionTestPassed,
                    errorMessage: $errorMessage,
                    onTest: testConnection
                )
                .tag(1)

                // Step 3: Photo Permission
                PhotoPermissionStepView(
                    permissionGranted: $photoPermissionGranted,
                    onRequestPermission: requestPhotoPermission
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(currentStep == 2 ? "Get Started" : "Next") {
                    handleNextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
            .padding()
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return connectionTestPassed
        case 2:
            return photoPermissionGranted
        default:
            return false
        }
    }

    private func handleNextStep() {
        if currentStep == 2 {
            // Complete onboarding
            settingsManager.serverHost = serverHost
            settingsManager.serverPort = Int(serverPort) ?? 8080
            settingsManager.completeOnboarding()
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func testConnection() async {
        isTestingConnection = true
        errorMessage = nil

        // Temporarily set settings for test
        settingsManager.serverHost = serverHost
        settingsManager.serverPort = Int(serverPort) ?? 8080

        do {
            let health = try await photoAPI.healthCheck()
            connectionTestPassed = health.isHealthy
            if !health.isHealthy {
                errorMessage = "Server is not healthy"
            }
        } catch {
            connectionTestPassed = false
            errorMessage = error.localizedDescription
        }

        isTestingConnection = false
    }

    private func requestPhotoPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoPermissionGranted = status == .authorized || status == .limited
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to CloudPhoto")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Back up your photos to your personal server automatically.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

struct ServerSetupStepView: View {
    @Binding var host: String
    @Binding var port: String
    @Binding var isTestingConnection: Bool
    @Binding var connectionTestPassed: Bool
    @Binding var errorMessage: String?
    let onTest: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Connect to Your Server")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                TextField("Server IP (e.g., 192.168.1.100)", text: $host)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .keyboardType(.URL)

                TextField("Port (default: 8080)", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal, 40)

            Button {
                Task { await onTest() }
            } label: {
                HStack {
                    if isTestingConnection {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if connectionTestPassed {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(connectionTestPassed ? "Connected!" : "Test Connection")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(connectionTestPassed ? .green : .blue)
            .disabled(host.isEmpty || isTestingConnection)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}

struct PhotoPermissionStepView: View {
    @Binding var permissionGranted: Bool
    let onRequestPermission: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: permissionGranted ? "checkmark.circle.fill" : "photo.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(permissionGranted ? .green : .blue)

            Text("Photo Library Access")
                .font(.title)
                .fontWeight(.bold)

            Text("CloudPhoto needs access to your photo library to back up your photos.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if !permissionGranted {
                Button("Grant Access") {
                    Task { await onRequestPermission() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Access Granted")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SettingsManager.shared)
}
