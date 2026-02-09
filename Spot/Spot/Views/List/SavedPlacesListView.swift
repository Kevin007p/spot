import SwiftUI
import SwiftData

struct SavedPlacesListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = PlacesViewModel()
    @StateObject private var locationService = LocationService.shared

    @Query(sort: \SavedPlace.savedAt, order: .reverse) private var allPlaces: [SavedPlace]

    @State private var editingPlace: SavedPlace?
    @State private var editedNote = ""
    @State private var showDuplicateAlert = false
    @State private var selectedPriceFilter: Int?
    @State private var maxDistanceMiles: Double?

    private var filteredPlaces: [SavedPlace] {
        var result = allPlaces

        // Category filter
        if let category = viewModel.selectedFilter {
            result = result.filter { $0.placeCache?.category == category.rawValue }
        }

        // Price filter
        if let price = selectedPriceFilter {
            result = result.filter { $0.placeCache?.priceLevel == price }
        }

        // Distance filter
        if let maxDist = maxDistanceMiles {
            result = result.filter { place in
                guard let lat = place.placeCache?.lat,
                      let lng = place.placeCache?.lng,
                      let distance = locationService.distance(to: lat, lng: lng) else {
                    return true // Keep places without coordinates
                }
                return distance <= maxDist
            }
        }

        return result
    }

    private var placesCount: Int { filteredPlaces.count }

    var body: some View {
        NavigationStack {
            Group {
                if allPlaces.isEmpty {
                    emptyState
                } else {
                    placesListContent
                }
            }
            .navigationTitle("My spots")
            .toolbar {
                if !allPlaces.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text("\(placesCount)")
                            .font(SpotTypography.footnote)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.spotEmerald)
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(item: $editingPlace) { place in
                EditNoteSheet(
                    place: place,
                    noteText: $editedNote,
                    onSave: {
                        try? viewModel.updateNote(
                            for: place,
                            note: editedNote,
                            modelContext: modelContext
                        )
                    }
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("No saved spots yet")
                .font(SpotTypography.title3)
                .foregroundStyle(Color.spotTextPrimary)

            Text("Search & save your first spot")
                .font(SpotTypography.body)
                .foregroundStyle(Color.spotTextSecondary)

            Spacer()
        }
    }

    private var placesListContent: some View {
        VStack(spacing: 0) {
            FilterBarView(selectedFilter: $viewModel.selectedFilter)
                .padding(.vertical, 8)

            List {
                ForEach(filteredPlaces, id: \.id) { place in
                    PlaceCardView(place: place)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                try? viewModel.deletePlace(place, modelContext: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                editedNote = place.noteText
                                editingPlace = place
                            } label: {
                                Label("Edit note", systemImage: "pencil")
                            }
                            .tint(.spotEmerald)
                        }
                }
            }
            .listStyle(.plain)
            .refreshable {
                // Pull-to-refresh: sync from Supabase
                guard let userId = authViewModel.currentUserId else { return }
                await SyncService.shared.pullFromRemote(
                    modelContext: modelContext,
                    userId: userId
                )
            }
        }
    }
}

struct EditNoteSheet: View {
    let place: SavedPlace
    @Binding var noteText: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(place.placeCache?.name ?? "")
                    .font(SpotTypography.title3)

                TextField("Add a note", text: $noteText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Spacer()
            }
            .padding(16)
            .navigationTitle("Edit note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.spotEmerald)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
