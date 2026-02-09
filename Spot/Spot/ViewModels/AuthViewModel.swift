import Foundation
import SwiftUI
import AuthenticationServices
import GoogleSignIn

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true  // Start true so splash shows during session check
    @Published var errorMessage: String?
    @Published var currentUserId: String?
    @Published var userEmail: String?

    private let supabaseService = SupabaseService.shared
    private let analytics = AnalyticsService.shared

    func checkSession() async {
        defer { isLoading = false }

        do {
            if let session = try await supabaseService.getCurrentSession() {
                currentUserId = session.userId
                userEmail = session.email
                isAuthenticated = true

                analytics.identify(userId: session.userId, traits: [
                    "provider": session.provider
                ])

                // If account was soft-deleted, cancel the deletion on sign-in
                if let profile = try? await supabaseService.getUserProfile(),
                   profile.deletedAt != nil {
                    try? await supabaseService.cancelDeleteAccount()
                }
            }
        } catch {
            isAuthenticated = false
        }
    }

    func signInWithApple(authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Failed to get Apple ID credentials"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabaseService.signInWithApple(idToken: tokenString)
            currentUserId = userId
            if let email = credential.email {
                userEmail = email
            }
            isAuthenticated = true

            analytics.identify(userId: userId, traits: ["provider": "apple"])
            analytics.track(.signInCompleted, properties: ["provider": "apple"])
        } catch {
            errorMessage = "Sign in failed. Please try again."
        }
    }

    func signInWithGoogle() async {
        isLoading = true

        do {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                isLoading = false
                errorMessage = "Cannot present sign-in screen"
                return
            }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                isLoading = false
                errorMessage = "Missing Google ID token"
                return
            }

            let accessToken = result.user.accessToken.tokenString

            let userId = try await supabaseService.signInWithGoogle(
                idToken: idToken,
                accessToken: accessToken
            )
            currentUserId = userId
            userEmail = result.user.profile?.email
            isAuthenticated = true
            isLoading = false

            analytics.identify(userId: userId, traits: ["provider": "google"])
            analytics.track(.signInCompleted, properties: ["provider": "google"])
        } catch {
            isLoading = false
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                errorMessage = "Sign in failed. Please try again."
            }
        }
    }

    func signOut() async {
        do {
            try await supabaseService.signOut()
            GIDSignIn.sharedInstance.signOut()

            analytics.track(.signedOut)
            analytics.reset()

            isAuthenticated = false
            currentUserId = nil
            userEmail = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabaseService.softDeleteAccount()
            GIDSignIn.sharedInstance.signOut()

            analytics.track(.accountDeleteRequested)
            analytics.reset()

            isAuthenticated = false
            currentUserId = nil
            userEmail = nil
        } catch {
            errorMessage = "Failed to delete account. Please try again."
        }
    }
}
