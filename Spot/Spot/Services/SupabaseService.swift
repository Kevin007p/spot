import Foundation
import Supabase

struct UserSession {
    let userId: String
    let email: String?
    let provider: String
}

class SupabaseService {
    static let shared = SupabaseService()

    // MARK: - Configuration
    // Replace these with your Supabase project credentials from:
    // Dashboard → Settings → API → Project URL and anon/public key
    let client = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )

    private init() {}

    // MARK: - Auth

    func getCurrentSession() async throws -> UserSession? {
        let session = try await client.auth.session
        return UserSession(
            userId: session.user.id.uuidString,
            email: session.user.email,
            provider: session.user.appMetadata["provider"]?.stringValue ?? ""
        )
    }

    func signInWithApple(idToken: String) async throws -> String {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
        return session.user.id.uuidString
    }

    func signInWithGoogle(idToken: String, accessToken: String) async throws -> String {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
        return session.user.id.uuidString
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Account Management

    func softDeleteAccount() async throws {
        try await client.rpc("soft_delete_account").execute()
        try await signOut()
    }

    func cancelDeleteAccount() async throws {
        try await client.rpc("cancel_delete_account").execute()
    }

    func getUserProfile() async throws -> UserProfile? {
        let session = try await client.auth.session
        let response: [UserProfile] = try await client.from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .execute()
            .value
        return response.first
    }

    func updateProfilePrivacy(isPrivate: Bool) async throws {
        let session = try await client.auth.session
        try await client.from("users")
            .update(["profile_private": isPrivate])
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    // MARK: - Saved Places

    func fetchSavedPlaces() async throws -> [SavedPlaceDTO] {
        let response: [SavedPlaceDTO] = try await client.from("saved_places")
            .select("*, place_cache(*)")
            .order("saved_at", ascending: false)
            .execute()
            .value
        return response
    }

    func uploadSavedPlace(_ place: SavedPlaceDTO) async throws {
        try await client.from("saved_places")
            .insert(place)
            .execute()
    }

    func updateSavedPlaceNote(id: String, note: String) async throws {
        try await client.from("saved_places")
            .update(["note_text": note])
            .eq("id", value: id)
            .execute()
    }

    func deleteSavedPlace(id: String) async throws {
        try await client.from("saved_places")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Place Cache

    func upsertPlaceCache(_ place: PlaceCacheDTO) async throws {
        try await client.from("place_cache")
            .upsert(place)
            .execute()
    }
}

// MARK: - DTOs (Data Transfer Objects for Supabase)

struct UserProfile: Codable {
    let id: String
    let email: String?
    let authProvider: String
    let profilePrivate: Bool
    let createdAt: Date
    let deletedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case authProvider = "auth_provider"
        case profilePrivate = "profile_private"
        case createdAt = "created_at"
        case deletedAt = "deleted_at"
    }
}

struct SavedPlaceDTO: Codable {
    let id: String
    let userId: String
    let googlePlaceId: String
    let noteText: String
    let dateVisited: Date?
    let savedAt: Date
    let placeCache: PlaceCacheDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case googlePlaceId = "google_place_id"
        case noteText = "note_text"
        case dateVisited = "date_visited"
        case savedAt = "saved_at"
        case placeCache = "place_cache"
    }
}

struct PlaceCacheDTO: Codable {
    let googlePlaceId: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let rating: Double
    let priceLevel: Int
    let category: String
    let cuisine: String
    let lastRefreshed: Date

    enum CodingKeys: String, CodingKey {
        case googlePlaceId = "google_place_id"
        case name, address, lat, lng, rating
        case priceLevel = "price_level"
        case category, cuisine
        case lastRefreshed = "last_refreshed"
    }
}
