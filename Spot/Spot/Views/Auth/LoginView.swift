import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 8) {
                Text("spot.")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.spotEmerald)

                Text("Save every spot worth visiting")
                    .font(SpotTypography.body)
                    .foregroundStyle(Color.spotTextSecondary)
            }

            Spacer()

            // Auth buttons
            VStack(spacing: 12) {
                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            await authViewModel.signInWithApple(authorization: authorization)
                        }
                    case .failure(let error):
                        authViewModel.errorMessage = error.localizedDescription
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(authViewModel.isLoading)

                // Sign in with Google
                Button {
                    Task {
                        await authViewModel.signInWithGoogle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Sign in with Google")
                            .font(SpotTypography.headline)
                    }
                    .foregroundStyle(Color.spotTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.spotDivider, lineWidth: 1)
                    )
                }
                .disabled(authViewModel.isLoading)
                .opacity(authViewModel.isLoading ? 0.6 : 1)
            }
            .padding(.horizontal, 24)

            // Loading indicator
            if authViewModel.isLoading {
                ProgressView()
                    .tint(.spotEmerald)
                    .padding(.top, 16)
                    .transition(.opacity)
            }

            // Error message
            if let error = authViewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 13))
                    Text(error)
                        .font(SpotTypography.footnote)
                }
                .foregroundStyle(Color.spotDanger)
                .padding(.top, 12)
                .padding(.horizontal, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            authViewModel.errorMessage = nil
                        }
                    }
                }
            }

            // Terms
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(SpotTypography.caption)
                .foregroundStyle(Color.spotTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 24)
                .padding(.bottom, 48)
        }
        .background(Color.spotBackground)
        .animation(.easeInOut(duration: 0.2), value: authViewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: authViewModel.errorMessage)
    }
}
