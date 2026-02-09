import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "Welcome",
                    subtitle: "Never lose track of a restaurant, cafe, bar, or dessert spot you want to try"
                )
                .tag(0)

                OnboardingPageView(
                    title: "Search any place",
                    subtitle: "Find restaurants, cafes, bars and more"
                )
                .tag(1)

                OnboardingPageView(
                    title: "Your personal list",
                    subtitle: "Save places with notes, filter by category, and never lose a spot"
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 24) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.spotEmerald : Color.spotDivider)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .accessibilityLabel("Page \(currentPage + 1) of 3")

                // Button
                Button {
                    if currentPage < 2 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        AnalyticsService.shared.track(.onboardingCompleted)
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < 2 ? "Next" : "Get started")
                        .spotPrimaryButton()
                }
                .padding(.horizontal, 24)
                .accessibilityHint(currentPage < 2 ? "Go to next page" : "Finish onboarding and sign in")
            }
            .padding(.bottom, 48)
        }
        .background(Color.spotBackground)
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(title)
                .font(SpotTypography.largeTitle)
                .foregroundStyle(Color.spotTextPrimary)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(SpotTypography.body)
                .foregroundStyle(Color.spotTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
