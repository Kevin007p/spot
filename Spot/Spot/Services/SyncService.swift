import Foundation
import SwiftData
import Network

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing = false

    private let supabase = SupabaseService.shared
    private let monitor = NWPathMonitor()
    private var isOnline = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    /// Pull saved places from Supabase and merge into local SwiftData
    func pullFromRemote(modelContext: ModelContext, userId: String) async {
        guard isOnline else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let remotePlaces = try await supabase.fetchSavedPlaces()

            for dto in remotePlaces {
                // Upsert PlaceCache
                if let cacheDTO = dto.placeCache {
                    let cacheFetch = FetchDescriptor<PlaceCache>(
                        predicate: #Predicate { $0.googlePlaceId == cacheDTO.googlePlaceId }
                    )
                    let existingCache = try modelContext.fetch(cacheFetch)

                    if let existing = existingCache.first {
                        // Update if remote is newer
                        if cacheDTO.lastRefreshed > existing.lastRefreshed {
                            existing.name = cacheDTO.name
                            existing.address = cacheDTO.address
                            existing.lat = cacheDTO.lat
                            existing.lng = cacheDTO.lng
                            existing.rating = cacheDTO.rating
                            existing.priceLevel = cacheDTO.priceLevel
                            existing.category = cacheDTO.category
                            existing.cuisine = cacheDTO.cuisine
                            existing.lastRefreshed = cacheDTO.lastRefreshed
                        }
                    } else {
                        let cache = PlaceCache(
                            googlePlaceId: cacheDTO.googlePlaceId,
                            name: cacheDTO.name,
                            address: cacheDTO.address,
                            lat: cacheDTO.lat,
                            lng: cacheDTO.lng,
                            rating: cacheDTO.rating,
                            priceLevel: cacheDTO.priceLevel,
                            category: cacheDTO.category,
                            cuisine: cacheDTO.cuisine,
                            lastRefreshed: cacheDTO.lastRefreshed
                        )
                        modelContext.insert(cache)
                    }
                }

                // Upsert SavedPlace
                let dtoId = dto.id
                let placeFetch = FetchDescriptor<SavedPlace>(
                    predicate: #Predicate { $0.id.uuidString == dtoId }
                )
                let existingPlace = try modelContext.fetch(placeFetch)

                if existingPlace.isEmpty {
                    let place = SavedPlace(
                        id: UUID(uuidString: dto.id) ?? UUID(),
                        userId: dto.userId,
                        googlePlaceId: dto.googlePlaceId,
                        noteText: dto.noteText,
                        dateVisited: dto.dateVisited,
                        savedAt: dto.savedAt
                    )

                    // Link to cache
                    let gPlaceId = dto.googlePlaceId
                    let cacheLookup = FetchDescriptor<PlaceCache>(
                        predicate: #Predicate { $0.googlePlaceId == gPlaceId }
                    )
                    place.placeCache = try modelContext.fetch(cacheLookup).first

                    modelContext.insert(place)
                } else if let existing = existingPlace.first {
                    // Server wins for conflicts
                    existing.noteText = dto.noteText
                    existing.dateVisited = dto.dateVisited
                }
            }

            try modelContext.save()
        } catch {
            print("Sync pull failed: \(error.localizedDescription)")
        }
    }

    /// Push any locally-created places that may not have synced yet
    func pushToRemote(modelContext: ModelContext, userId: String) async {
        guard isOnline else { return }

        do {
            let descriptor = FetchDescriptor<SavedPlace>(
                predicate: #Predicate { $0.userId == userId }
            )
            let localPlaces = try modelContext.fetch(descriptor)

            let remotePlaces = try await supabase.fetchSavedPlaces()
            let remoteIds = Set(remotePlaces.map { $0.id })

            for local in localPlaces {
                if !remoteIds.contains(local.id.uuidString) {
                    // This place exists locally but not remotely — push it
                    if let cache = local.placeCache {
                        let cacheDTO = PlaceCacheDTO(
                            googlePlaceId: cache.googlePlaceId,
                            name: cache.name,
                            address: cache.address,
                            lat: cache.lat,
                            lng: cache.lng,
                            rating: cache.rating,
                            priceLevel: cache.priceLevel,
                            category: cache.category,
                            cuisine: cache.cuisine,
                            lastRefreshed: cache.lastRefreshed
                        )
                        try? await supabase.upsertPlaceCache(cacheDTO)
                    }

                    let dto = SavedPlaceDTO(
                        id: local.id.uuidString,
                        userId: local.userId,
                        googlePlaceId: local.googlePlaceId,
                        noteText: local.noteText,
                        dateVisited: local.dateVisited,
                        savedAt: local.savedAt,
                        placeCache: nil
                    )
                    try? await supabase.uploadSavedPlace(dto)
                }
            }
        } catch {
            print("Sync push failed: \(error.localizedDescription)")
        }
    }
}
