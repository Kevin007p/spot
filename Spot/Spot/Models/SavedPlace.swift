import Foundation
import SwiftData

@Model
final class SavedPlace {
    @Attribute(.unique) var id: UUID
    var userId: String
    var googlePlaceId: String
    var noteText: String
    var dateVisited: Date?
    var savedAt: Date

    @Relationship(deleteRule: .nullify)
    var placeCache: PlaceCache?

    init(
        id: UUID = UUID(),
        userId: String,
        googlePlaceId: String,
        noteText: String = "",
        dateVisited: Date? = nil,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.googlePlaceId = googlePlaceId
        self.noteText = noteText
        self.dateVisited = dateVisited
        self.savedAt = savedAt
    }
}
