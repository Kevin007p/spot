import Foundation
import SwiftData

@Model
final class PlaceCache {
    @Attribute(.unique) var googlePlaceId: String
    var name: String
    var address: String
    var lat: Double
    var lng: Double
    var rating: Double
    var priceLevel: Int
    var category: String
    var cuisine: String
    var lastRefreshed: Date

    init(
        googlePlaceId: String,
        name: String,
        address: String,
        lat: Double = 0,
        lng: Double = 0,
        rating: Double = 0,
        priceLevel: Int = 0,
        category: String = "",
        cuisine: String = "",
        lastRefreshed: Date = Date()
    ) {
        self.googlePlaceId = googlePlaceId
        self.name = name
        self.address = address
        self.lat = lat
        self.lng = lng
        self.rating = rating
        self.priceLevel = priceLevel
        self.category = category
        self.cuisine = cuisine
        self.lastRefreshed = lastRefreshed
    }
}
