import SwiftUI

extension View {
    func spotCard() -> some View {
        self
            .padding(16)
            .background(Color.spotCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    func spotPrimaryButton() -> some View {
        self
            .font(SpotTypography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.spotEmerald)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func spotOutlineButton() -> some View {
        self
            .font(SpotTypography.headline)
            .foregroundStyle(Color.spotEmerald)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.spotEmerald, lineWidth: 1.5)
            )
    }
}
