import Foundation
import Combine

final class PlayerTitleStore: ObservableObject {
    @Published private(set) var unlockedTitles: Set<String>
    @Published private(set) var equippedOverrideTitle: String?
    @Published private(set) var baseLevelTitle: String?

    var activeTitle: String? {
        equippedOverrideTitle ?? baseLevelTitle
    }

    init(
        unlockedTitles: Set<String> = [],
        equippedOverrideTitle: String? = nil,
        baseLevelTitle: String? = nil
    ) {
        self.unlockedTitles = unlockedTitles
        self.equippedOverrideTitle = equippedOverrideTitle
        self.baseLevelTitle = baseLevelTitle
    }

    func unlock(title: String) {
        unlockedTitles.insert(title)
    }

    func equipOverride(title: String) {
        guard unlockedTitles.contains(title) || title == baseLevelTitle else { return }
        equippedOverrideTitle = title
    }

    func clearOverride() {
        equippedOverrideTitle = nil
    }

    func updateBaseLevelTitle(_ title: String) {
        baseLevelTitle = title
    }
}
