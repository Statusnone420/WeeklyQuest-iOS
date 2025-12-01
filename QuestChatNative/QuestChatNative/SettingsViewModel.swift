import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    private let resetter: GameDataResetter

    init(resetter: GameDataResetter) {
        self.resetter = resetter
    }

    func reset(window: ResetWindow) {
        resetter.reset(window)
    }
}

