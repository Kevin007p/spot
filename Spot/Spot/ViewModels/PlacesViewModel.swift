import Foundation
import SwiftUI
import SwiftData

@MainActor
class PlacesViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [PlaceSearchResult] = []
    @Published var isSearching = false
    @Published var selectedFilter: PlaceCategory? {
        didSet {
            if let filter = selectedFilter {
                analytics.track(.filterUsed, properties: ["category": filter.rawValue])
            }
        }
    }
    @Published var errorMessage: String?

    private let googlePlacesService = GooglePlacesService.shared
    private let supabaseService = SupabaseService.shared
    private let analytics = AnalyticsService.shared

    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await googlePlacesService.autocomplete(query: query)
            analytics.track(.searchPerformed, properties: [
                "query": query,
                "result_count": searchResults.count
            ])
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
    }

    func getPlaceDetails(placeId: String) async -> PlaceCacheDTO? {
        do {
            let details = try await googlePlacesService.getPlaceDetails(placeId: placeId)
            analytics.track(.searchResultTapped, properties: [
                "place_name": details.name,
                "category": details.category
            ])
            return details
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func savePlace(
        dto: PlaceCacheDTO,
        note: String,
        userId: String,
        modelContext: ModelContext
    ) throws {
        let placeId = dto.googlePlaceId
        let descriptor = FetchDescriptor<SavedPlace>(
            predicate: #Predicate {
                $0.userId == userId && $0.googlePlaceId == placeId
            }
        )
        let existing = try modelContext.fetch(descriptor)

        if !existing.isEmpty {
            analytics.track(.duplicateBlocked, properties: ["place_name": dto.name])
            throw SpotError.duplicatePlace
        }

        let cache = PlaceCache(
            googlePlaceId: dto.googlePlaceId,
            name: dto.name,
            address: dto.address,
            lat: dto.lat,
            lng: dto.lng,
            rating: dto.rating,
            priceLevel: dto.priceLevel,
            category: dto.category,
            cuisine: dto.cuisine
        )
        modelContext.insert(cache)

        let savedPlace = SavedPlace(
            userId: userId,
            googlePlaceId: dto.googlePlaceId,
            noteText: note
        )
        savedPlace.placeCache = cache
        modelContext.insert(savedPlace)

        try modelContext.save()

        analytics.track(.placeSaved, properties: [
            "place_name": dto.name,
            "category": dto.category,
            "cuisine": dto.cuisine,
            "has_note": !note.isEmpty
        ])

        Task {
            try? await supabaseService.upsertPlaceCache(dto)
            let savedDTO = SavedPlaceDTO(
                id: savedPlace.id.uuidString,
                userId: userId,
                googlePlaceId: dto.googlePlaceId,
                noteText: note,
                dateVisited: nil,
                savedAt: savedPlace.savedAt,
                placeCache: nil
            )
            try? await supabaseService.uploadSavedPlace(savedDTO)
        }
    }

    func deletePlace(_ place: SavedPlace, modelContext: ModelContext) throws {
        let placeId = place.id.uuidString
        let placeName = place.placeCache?.name ?? ""
        modelContext.delete(place)
        try modelContext.save()

        analytics.track(.placeDeleted, properties: ["place_name": placeName])

        Task {
            try? await supabaseService.deleteSavedPlace(id: placeId)
        }
    }

    func updateNote(for place: SavedPlace, note: String, modelContext: ModelContext) throws {
        place.noteText = note
        try modelContext.save()

        analytics.track(.noteEdited, properties: [
            "place_name": place.placeCache?.name ?? ""
        ])

        let placeId = place.id.uuidString
        Task {
            try? await supabaseService.updateSavedPlaceNote(id: placeId, note: note)
        }
    }
}

enum SpotError: LocalizedError {
    case duplicatePlace
    case placeNotFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .duplicatePlace:
            return "This spot is already saved"
        case .placeNotFound:
            return "Place not found"
        case .networkError(let message):
            return message
        }
    }
}
