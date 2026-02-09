import SwiftUI

struct FilterBarView: View {
    @Binding var selectedFilter: PlaceCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }

                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedFilter == category
                    ) {
                        selectedFilter = category
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Category filters")
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SpotTypography.subheadline)
                .foregroundStyle(isSelected ? .white : Color.spotTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.spotEmerald : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.spotDivider, lineWidth: 1)
                )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel("\(title) filter")
    }
}
