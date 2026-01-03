import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var syncEngine: SyncEngine

    var body: some View {
        TabView {
            GalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }

            BackupStatusView()
                .tabItem {
                    Label("Backup", systemImage: "arrow.up.circle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SyncEngine())
}
