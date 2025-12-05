import SwiftUI

/// Coordinates top-level view construction using the dependency container.
final class AppCoordinator: ObservableObject {
    @Published private(set) var hasCompletedOnboarding: Bool

    private let container: DependencyContainer
    private var onboardingViewModel: OnboardingViewModel?

    init(container: DependencyContainer = .shared, userDefaults: UserDefaults = .standard) {
        self.container = container
        hasCompletedOnboarding = userDefaults.bool(forKey: OnboardingViewModel.Keys.hasCompletedOnboarding)
    }

    func makeRootView() -> some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                let viewModel = onboardingViewModel ?? container.makeOnboardingViewModel(onCompletion: { [weak self] in
                    self?.markOnboardingComplete()
                })
                onboardingViewModel = viewModel
                OnboardingView(viewModel: viewModel)
            }
        }
    }

    func makeFocusView(selectedTab: Binding<MainTab>) -> FocusView {
        FocusView(
            viewModel: container.focusViewModel,
            healthBarViewModel: container.healthBarViewModel,
            selectedTab: selectedTab
        )
    }

    private func markOnboardingComplete() {
        hasCompletedOnboarding = true
    }
}
