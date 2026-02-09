import SwiftUI

struct PlaceCardView: View {
    let place: SavedPlace

    private var accessibilityDescription: String {
        var parts: [String] = []
        if let name = place.placeCache?.name { parts.append(name) }
        if let category = place.placeCache?.category, !category.isEmpty { parts.append(category) }
        if let cuisine = place.placeCache?.cuisine, !cuisine.isEmpty { parts.append(cuisine) }
        if let rating = place.placeCache?.rating, rating > 0 {
            parts.append("\(String(format: "%.1f", rating)) stars")
        }
        if let address = place.placeCache?.address, !address.isEmpty { parts.append(address) }
        if !place.noteText.isEmpty { parts.append("Note: \(place.noteText)") }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name and category
            HStack {
                Text(place.placeCache?.name ?? "Unknown")
                    .font(SpotTypography.headline)
                    .foregroundStyle(Color.spotTextPrimary)

                Spacer()

                if let category = place.placeCache?.category, !category.isEmpty {
                    Text(category)
                        .font(SpotTypography.caption)
                        .foregroundStyle(Color.spotEmerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.spotEmerald.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Cuisine
            if let cuisine = place.placeCache?.cuisine, !cuisine.isEmpty {
                Text(cuisine)
                    .font(SpotTypography.subheadline)
                    .foregroundStyle(Color.spotTextSecondary)
            }

            // Rating, price, address row
            HStack(spacing: 4) {
                if let rating = place.placeCache?.rating, rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text(String(format: "%.1f", rating))
                            .font(SpotTypography.footnote)
                            .foregroundStyle(Color.spotTextSecondary)
                    }
                }

                if let price = place.placeCache?.priceLevel, price > 0 {
                    Text("·")
                        .foregroundStyle(Color.spotTextSecondary)
                    Text(String(repeating: "$", count: price))
                        .font(SpotTypography.footnote)
                        .foregroundStyle(Color.spotTextSecondary)
                }

                if let address = place.placeCache?.address, !address.isEmpty {
                    Text("·")
                        .foregroundStyle(Color.spotTextSecondary)
                    Text(address)
                        .font(SpotTypography.footnote)
                        .foregroundStyle(Color.spotTextSecondary)
                        .lineLimit(1)
                }
            }

            // Note preview
            if !place.noteText.isEmpty {
                Text(place.noteText)
                    .font(SpotTypography.footnote)
                    .foregroundStyle(Color.spotTextSecondary)
                    .lineLimit(1)
                    .italic()
            }

            // Saved date
            Text("Saved \(place.savedAt.formatted(.relative(presentation: .named)))")
                .font(SpotTypography.caption)
                .foregroundStyle(Color.spotTextSecondary.opacity(0.7))
        }
        .padding(16)
        .background(Color.spotCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}
