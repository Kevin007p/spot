import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0 {
        didSet {
            let tabNames = ["list", "search", "profile"]
            AnalyticsService.shared.track(.tabSwitched, properties: [
                "tab": tabNames[selectedTab]
            ])
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SavedPlacesListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(.spotEmerald)
        .task {
            // Sync on launch: pull remote changes, then push any local-only saves
            guard let userId = authViewModel.currentUserId else { return }
            let sync = SyncService.shared
            await sync.pullFromRemote(modelContext: modelContext, userId: userId)
            await sync.pushToRemote(modelContext: modelContext, userId: userId)
        }
    }
}
