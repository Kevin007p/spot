import SwiftUI

struct SaveConfirmationView: View {
    let placeDTO: PlaceCacheDTO
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    @FocusState private var isNoteFieldFocused: Bool

    private var accessibilitySummary: String {
        var parts = [placeDTO.name]
        if !placeDTO.cuisine.isEmpty { parts.append(placeDTO.cuisine) }
        if placeDTO.rating > 0 { parts.append("\(String(format: "%.1f", placeDTO.rating)) stars") }
        if !placeDTO.category.isEmpty { parts.append(placeDTO.category) }
        if !placeDTO.address.isEmpty { parts.append(placeDTO.address) }
        return parts.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Place details card
                VStack(alignment: .leading, spacing: 8) {
                    Text(placeDTO.name)
                        .font(SpotTypography.title3)
                        .foregroundStyle(Color.spotTextPrimary)

                    if !placeDTO.cuisine.isEmpty {
                        Text(placeDTO.cuisine)
                            .font(SpotTypography.subheadline)
                            .foregroundStyle(Color.spotTextSecondary)
                    }

                    HStack(spacing: 4) {
                        if placeDTO.rating > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.orange)
                                Text(String(format: "%.1f", placeDTO.rating))
                                    .font(SpotTypography.subheadline)
                            }
                        }

                        if placeDTO.priceLevel > 0 {
                            Text("·")
                            Text(String(repeating: "$", count: placeDTO.priceLevel))
                                .font(SpotTypography.subheadline)
                        }

                        if !placeDTO.category.isEmpty {
                            Text("·")
                            Text(placeDTO.category)
                                .font(SpotTypography.subheadline)
                        }
                    }
                    .foregroundStyle(Color.spotTextSecondary)

                    if !placeDTO.address.isEmpty {
                        Text(placeDTO.address)
                            .font(SpotTypography.footnote)
                            .foregroundStyle(Color.spotTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.spotCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilitySummary)

                Divider()
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)

                // Note field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a note")
                        .font(SpotTypography.subheadline)
                        .foregroundStyle(Color.spotTextSecondary)

                    TextField("e.g. Must try the spicy ramen", text: $noteText, axis: .vertical)
                        .font(SpotTypography.body)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isNoteFieldFocused)
                }
                .padding(.horizontal, 16)

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .spotOutlineButton()
                    }

                    Button {
                        onSave(noteText)
                        dismiss()
                    } label: {
                        Text("Save")
                            .spotPrimaryButton()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Save this spot?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
