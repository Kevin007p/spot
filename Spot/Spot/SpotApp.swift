import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct SpotApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        AnalyticsService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                } else if authViewModel.isLoading {
                    // Splash / session restore
                    VStack {
                        Text("spot.")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(Color.spotEmerald)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.spotBackground)
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .task {
                // Restore session on launch
                await authViewModel.checkSession()
            }
            .onOpenURL { url in
                // Handle Google Sign-In callback URL
                GIDSignIn.sharedInstance.handle(url)
            }
        }
        .modelContainer(for: [SavedPlace.self, PlaceCache.self])
    }
}
