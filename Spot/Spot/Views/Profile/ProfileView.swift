import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isPrivateProfile = true
    @State private var showDeleteConfirmation = false

    private var userInitial: String {
        if let email = authViewModel.userEmail, let first = email.first {
            return String(first).uppercased()
        }
        return "U"
    }

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.spotEmerald)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(userInitial)
                                    .font(SpotTypography.title3)
                                    .foregroundStyle(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authViewModel.userEmail ?? "User")
                                .font(SpotTypography.headline)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Privacy section
                Section("Privacy") {
                    Toggle("Private Profile", isOn: $isPrivateProfile)
                        .tint(.spotEmerald)
                        .onChange(of: isPrivateProfile) { _, newValue in
                            Task {
                                try? await SupabaseService.shared.updateProfilePrivacy(isPrivate: newValue)
                            }
                        }
                }

                // Account section
                Section("Account") {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Account")
                            .foregroundStyle(Color.spotDanger)
                    }
                }

                // Log out section
                Section {
                    Button {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        Text("Log out")
                            .font(SpotTypography.headline)
                            .foregroundStyle(Color.spotEmerald)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.spotEmerald, lineWidth: 1.5)
                            )
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Profile")
            .task {
                // Load profile privacy setting from Supabase
                if let profile = try? await SupabaseService.shared.getUserProfile() {
                    isPrivateProfile = profile.profilePrivate
                }
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Your account will be scheduled for deletion. You have 30 days to sign back in to cancel this request.")
            }
        }
    }
}
