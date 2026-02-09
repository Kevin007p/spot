import Foundation

struct PlaceSearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let category: String
}

class GooglePlacesService {
    static let shared = GooglePlacesService()

    private let supabase = SupabaseService.shared

    private var baseURL: String {
        // Edge function URL = your Supabase project URL + /functions/v1/google-places-proxy
        return "\(supabase.client.supabaseURL.absoluteString)/functions/v1/google-places-proxy"
    }

    private init() {}

    func autocomplete(query: String) async throws -> [PlaceSearchResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/autocomplete?query=\(encoded)") else {
            return []
        }

        let data = try await authenticatedRequest(url: url)
        return try JSONDecoder().decode([PlaceSearchResult].self, from: data)
    }

    func getPlaceDetails(placeId: String) async throws -> PlaceCacheDTO {
        guard let url = URL(string: "\(baseURL)/details?place_id=\(placeId)") else {
            throw SpotError.networkError("Invalid URL")
        }

        let data = try await authenticatedRequest(url: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(PlaceCacheDTO.self, from: data)
    }

    func searchPlace(query: String) async throws -> [PlaceSearchResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?query=\(encoded)") else {
            return []
        }

        let data = try await authenticatedRequest(url: url)
        return try JSONDecoder().decode([PlaceSearchResult].self, from: data)
    }

    // MARK: - Private

    private func authenticatedRequest(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add Supabase auth headers
        let session = try await supabase.client.auth.session
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabase.client.supabaseKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SpotError.networkError("Request failed")
        }

        return data
    }
}
