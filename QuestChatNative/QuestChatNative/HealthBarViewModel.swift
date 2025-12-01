import Foundation
import Combine
import SwiftUI

final class HealthBarViewModel: ObservableObject {
    @Published private(set) var inputs: DailyHealthInputs
    @Published private(set) var hp: Int = 40

    private let maxHP: Double = 100

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

    var hpPercentage: Double {
        let clamped = max(0, min(Double(hp), maxHP))
        return clamped / maxHP
    }

    var healthBarColor: Color {
        switch hpPercentage {
        case ..<0.34:
            return .red
        case ..<0.67:
            return .yellow
        default:
            return .green
        }
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
