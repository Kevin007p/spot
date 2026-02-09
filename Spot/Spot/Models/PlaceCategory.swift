import Foundation

enum PlaceCategory: String, CaseIterable, Codable {
    case restaurant = "Restaurant"
    case cafe = "Cafe"
    case bar = "Bar"
    case dessert = "Dessert"
    case activity = "Activity"
    case other = "Other"

    static func from(googleTypes: [String]) -> PlaceCategory {
        for type in googleTypes {
            switch type {
            case "restaurant", "meal_delivery", "meal_takeaway":
                return .restaurant
            case "cafe":
                return .cafe
            case "bar", "night_club":
                return .bar
            case "bakery", "ice_cream_shop":
                return .dessert
            case "amusement_park", "bowling_alley", "gym", "movie_theater",
                 "museum", "park", "spa", "stadium", "tourist_attraction",
                 "zoo":
                return .activity
            default:
                continue
            }
        }
        return .other
    }
}
