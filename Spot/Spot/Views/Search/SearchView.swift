import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = PlacesViewModel()

    @State private var placeToSave: PlaceCacheDTO?
    @State private var showConfirmation = false
    @State private var searchTask: Task<Void, Never>?
    @State private var isLoadingDetails = false
    @State private var showDuplicateAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.spotTextSecondary)
                    TextField("Search restaurants, cafes, bars...", text: $viewModel.searchQuery)
                        .font(SpotTypography.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: viewModel.searchQuery) { _, newValue in
                            // Cancel previous debounced search
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 350_000_000)
                                guard !Task.isCancelled else { return }
                                await viewModel.search(query: newValue)
                            }
                        }
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                            viewModel.searchResults = []
                            searchTask?.cancel()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.spotTextSecondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Results
                if viewModel.isSearching || isLoadingDetails {
                    Spacer()
                    ProgressView()
                        .tint(.spotEmerald)
                    Spacer()
                } else if viewModel.searchQuery.isEmpty {
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                    Text("No results found")
                        .font(SpotTypography.body)
                        .foregroundStyle(Color.spotTextSecondary)
                    Spacer()
                } else {
                    List(viewModel.searchResults) { result in
                        Button {
                            Task {
                                isLoadingDetails = true
                                if let details = await viewModel.getPlaceDetails(placeId: result.id) {
                                    placeToSave = details
                                    showConfirmation = true
                                }
                                isLoadingDetails = false
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(SpotTypography.headline)
                                    .foregroundStyle(Color.spotTextPrimary)
                                Text(result.address)
                                    .font(SpotTypography.footnote)
                                    .foregroundStyle(Color.spotTextSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search spots")
            .sheet(isPresented: $showConfirmation) {
                if let place = placeToSave {
                    SaveConfirmationView(
                        placeDTO: place,
                        onSave: { note in
                            guard let userId = authViewModel.currentUserId else { return }
                            do {
                                try viewModel.savePlace(
                                    dto: place,
                                    note: note,
                                    userId: userId,
                                    modelContext: modelContext
                                )
                            } catch SpotError.duplicatePlace {
                                showDuplicateAlert = true
                            } catch {}
                        }
                    )
                }
            }
            .alert("Already saved", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This spot is already in your list.")
            }
        }
    }
}
