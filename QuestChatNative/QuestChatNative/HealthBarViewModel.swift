import Foundation
import Combine

final class HealthBarViewModel: ObservableObject {
    @Published private(set) var inputs: DailyHealthInputs
    @Published private(set) var hp: Int = 40

    private let storage: HealthBarStorageProtocol

    init(storage: HealthBarStorageProtocol = DefaultHealthBarStorage()) {
        self.storage = storage
        inputs = storage.loadTodayInputs()
        recalculate()
    }

    func logHydration() {
        inputs.hydrationCount += 1
        recalculate()
        save()
    }

    func logSelfCareSession() {
        inputs.selfCareSessions += 1
        recalculate()
        save()
    }

    func logFocusSprint() {
        inputs.focusSprints += 1
        recalculate()
        save()
    }

    func setGutStatus(_ status: GutStatus) {
        inputs.gutStatus = status
        recalculate()
        save()
    }

    func setMoodStatus(_ status: MoodStatus) {
        inputs.moodStatus = status
        recalculate()
        save()
    }
}

private extension HealthBarViewModel {
    func recalculate() {
        hp = HealthBarCalculator.hp(for: inputs)
    }

    func save() {
        storage.saveTodayInputs(inputs)
    }
}
